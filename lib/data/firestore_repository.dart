import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Field, Transaction;
import '../models/field.dart';
import '../models/planting.dart';
import '../models/task_item.dart';
import '../models/transaction.dart';

/// Abstract contract for user data persistence in Firestore.
/// Both CloudFirestoreRepository and InMemoryFirestoreRepository implement this.
abstract class FirestoreRepository {
  // Fields
  Stream<List<Field>> watchFields(String uid);
  Future<List<Field>> getFields(String uid);
  Future<void> addField(String uid, Field field);
  Future<void> updateField(String uid, Field field);
  Future<void> deleteField(String uid, String fieldId);

  // Plantings
  Stream<List<Planting>> watchPlantings(String uid);
  Future<Planting?> getPlanting(String uid, String plantingId);
  Future<void> createPlantingWithTasks(String uid, Planting planting, List<TaskItem> tasks);
  Future<void> updatePlanting(String uid, Planting planting);
  Future<void> deletePlanting(String uid, String plantingId);

  // Tasks
  Stream<List<TaskItem>> watchPlantingTasks(String uid, String plantingId);
  Future<List<TaskItem>> getPlantingTasks(String uid, String plantingId);
  Future<void> updateTask(String uid, String plantingId, TaskItem task);
  Future<void> batchUpdateTasks(String uid, String plantingId, List<TaskItem> tasks);

  // Transactions
  Stream<List<Transaction>> watchTransactions(String uid, [String? plantingId]);
  Future<List<Transaction>> getTransactions(String uid, [String? plantingId]);
  Future<void> addTransaction(String uid, Transaction tx);
  Future<void> deleteTransaction(String uid, String txId);

  // Harvest Completion
  Future<void> recordHarvest({
    required String uid,
    required Planting planting,
    required DateTime harvestDate,
    required double yieldQty,
    required String yieldUnit,
    required double saleIncome,
  });
}

/// Production implementation backed by Google Cloud Firestore with offline cache.
class CloudFirestoreRepository implements FirestoreRepository {
  final FirebaseFirestore _firestore;

  CloudFirestoreRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // --- Fields ---
  @override
  Stream<List<Field>> watchFields(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fields')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Field.fromJson(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<Field>> getFields(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('fields')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Field.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> addField(String uid, Field field) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fields')
        .doc(field.id)
        .set(field.toMap());
  }

  @override
  Future<void> updateField(String uid, Field field) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fields')
        .doc(field.id)
        .update(field.toMap());
  }

  @override
  Future<void> deleteField(String uid, String fieldId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fields')
        .doc(fieldId)
        .delete();
  }

  // --- Plantings & Batched Tasks ---
  @override
  Stream<List<Planting>> watchPlantings(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('plantings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Planting.fromJson(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<Planting?> getPlanting(String uid, String plantingId) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('plantings')
        .doc(plantingId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return Planting.fromJson(doc.data()!, doc.id);
  }

  @override
  Future<void> createPlantingWithTasks(
    String uid,
    Planting planting,
    List<TaskItem> tasks,
  ) async {
    // Single atomic batched write for planting record and all generated tasks
    final batch = _firestore.batch();
    final plantingRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('plantings')
        .doc(planting.id);

    batch.set(plantingRef, planting.toMap());

    for (final task in tasks) {
      final taskRef = plantingRef.collection('tasks').doc(task.id);
      batch.set(taskRef, task.toMap());
    }

    await batch.commit();
  }

  @override
  Future<void> updatePlanting(String uid, Planting planting) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('plantings')
        .doc(planting.id)
        .update(planting.toMap());
  }

  @override
  Future<void> deletePlanting(String uid, String plantingId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('plantings')
        .doc(plantingId)
        .delete();
  }

  // --- Tasks ---
  @override
  Stream<List<TaskItem>> watchPlantingTasks(String uid, String plantingId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('plantings')
        .doc(plantingId)
        .collection('tasks')
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskItem.fromJson(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<TaskItem>> getPlantingTasks(String uid, String plantingId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('plantings')
        .doc(plantingId)
        .collection('tasks')
        .orderBy('dueDate')
        .get();
    return snapshot.docs
        .map((doc) => TaskItem.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> updateTask(String uid, String plantingId, TaskItem task) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('plantings')
        .doc(plantingId)
        .collection('tasks')
        .doc(task.id)
        .update(task.toMap());
  }

  @override
  Future<void> batchUpdateTasks(
    String uid,
    String plantingId,
    List<TaskItem> tasks,
  ) async {
    final batch = _firestore.batch();
    final tasksCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('plantings')
        .doc(plantingId)
        .collection('tasks');

    for (final task in tasks) {
      batch.update(tasksCol.doc(task.id), task.toMap());
    }

    await batch.commit();
  }

  // --- Transactions ---
  @override
  Stream<List<Transaction>> watchTransactions(String uid, [String? plantingId]) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions');

    if (plantingId != null && plantingId.isNotEmpty) {
      query = query.where('plantingId', isEqualTo: plantingId);
    }

    return query
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromJson(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<Transaction>> getTransactions(String uid, [String? plantingId]) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions');

    if (plantingId != null && plantingId.isNotEmpty) {
      query = query.where('plantingId', isEqualTo: plantingId);
    }

    final snapshot = await query.orderBy('date', descending: true).get();
    return snapshot.docs
        .map((doc) => Transaction.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> addTransaction(String uid, Transaction tx) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(tx.id)
        .set(tx.toMap());
  }

  @override
  Future<void> deleteTransaction(String uid, String txId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(txId)
        .delete();
  }

  @override
  Future<void> recordHarvest({
    required String uid,
    required Planting planting,
    required DateTime harvestDate,
    required double yieldQty,
    required String yieldUnit,
    required double saleIncome,
  }) async {
    final batch = _firestore.batch();
    final plantingRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('plantings')
        .doc(planting.id);

    final updatedPlanting = planting.copyWith(
      status: 'harvested',
      harvestDate: harvestDate,
      yieldQty: yieldQty,
      yieldUnit: yieldUnit,
    );
    batch.update(plantingRef, updatedPlanting.toMap());

    if (saleIncome > 0) {
      final txRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc();

      final tx = Transaction(
        id: txRef.id,
        plantingId: planting.id,
        fieldId: planting.fieldId,
        kind: 'income',
        category: 'sale',
        amount: saleIncome,
        date: harvestDate,
        note: 'Harvest sale ($yieldQty $yieldUnit)',
      );
      batch.set(txRef, tx.toMap());
    }

    await batch.commit();
  }
}

/// In-memory fake repository for lightning-fast testing and offline development.
class InMemoryFirestoreRepository implements FirestoreRepository {
  final Map<String, Map<String, Field>> _fields = {};
  final Map<String, Map<String, Planting>> _plantings = {};
  final Map<String, TaskItem> _tasks = {}; // key: "${plantingId}_${taskId}"
  final Map<String, Map<String, Transaction>> _transactions = {}; // key: uid -> txId -> Transaction

  final _fieldsStreamControllers = <String, StreamController<List<Field>>>{};
  final _plantingsStreamControllers = <String, StreamController<List<Planting>>>{};
  final _tasksStreamControllers = <String, StreamController<List<TaskItem>>>{};
  final _transactionsStreamControllers = <String, StreamController<List<Transaction>>>{};

  StreamController<List<Transaction>> _getTransactionController(String uid) {
    return _transactionsStreamControllers.putIfAbsent(
      uid,
      () => StreamController<List<Transaction>>.broadcast(onListen: () {
        _notifyTransactions(uid);
      }),
    );
  }

  void _notifyTransactions(String uid) {
    final list = _transactions[uid]?.values.toList() ?? [];
    list.sort((a, b) => b.date.compareTo(a.date));
    _getTransactionController(uid).add(list);
  }

  StreamController<List<Field>> _getFieldController(String uid) {
    return _fieldsStreamControllers.putIfAbsent(
      uid,
      () => StreamController<List<Field>>.broadcast(onListen: () {
        _notifyFields(uid);
      }),
    );
  }

  void _notifyFields(String uid) {
    final list = _fields[uid]?.values.toList() ?? [];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _getFieldController(uid).add(list);
  }

  StreamController<List<Planting>> _getPlantingController(String uid) {
    return _plantingsStreamControllers.putIfAbsent(
      uid,
      () => StreamController<List<Planting>>.broadcast(onListen: () {
        _notifyPlantings(uid);
      }),
    );
  }

  void _notifyPlantings(String uid) {
    final list = _plantings[uid]?.values.toList() ?? [];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _getPlantingController(uid).add(list);
  }

  StreamController<List<TaskItem>> _getTaskController(String plantingId) {
    return _tasksStreamControllers.putIfAbsent(
      plantingId,
      () => StreamController<List<TaskItem>>.broadcast(onListen: () {
        _notifyTasks(plantingId);
      }),
    );
  }

  void _notifyTasks(String plantingId) {
    final prefix = '${plantingId}_';
    final list = _tasks.entries
        .where((e) => e.key.startsWith(prefix))
        .map((e) => e.value)
        .toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    _getTaskController(plantingId).add(list);
  }

  @override
  Stream<List<Field>> watchFields(String uid) => _getFieldController(uid).stream;

  @override
  Future<List<Field>> getFields(String uid) async {
    final list = _fields[uid]?.values.toList() ?? [];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> addField(String uid, Field field) async {
    _fields.putIfAbsent(uid, () => {})[field.id] = field;
    _notifyFields(uid);
  }

  @override
  Future<void> updateField(String uid, Field field) async {
    _fields.putIfAbsent(uid, () => {})[field.id] = field;
    _notifyFields(uid);
  }

  @override
  Future<void> deleteField(String uid, String fieldId) async {
    _fields[uid]?.remove(fieldId);
    _notifyFields(uid);
  }

  @override
  Stream<List<Planting>> watchPlantings(String uid) =>
      _getPlantingController(uid).stream;

  @override
  Future<Planting?> getPlanting(String uid, String plantingId) async {
    return _plantings[uid]?[plantingId];
  }

  @override
  Future<void> createPlantingWithTasks(
    String uid,
    Planting planting,
    List<TaskItem> tasks,
  ) async {
    _plantings.putIfAbsent(uid, () => {})[planting.id] = planting;
    for (final task in tasks) {
      _tasks['${planting.id}_${task.id}'] = task;
    }
    _notifyPlantings(uid);
    _notifyTasks(planting.id);
  }

  @override
  Future<void> updatePlanting(String uid, Planting planting) async {
    _plantings.putIfAbsent(uid, () => {})[planting.id] = planting;
    _notifyPlantings(uid);
  }

  @override
  Future<void> deletePlanting(String uid, String plantingId) async {
    _plantings[uid]?.remove(plantingId);
    final prefix = '${plantingId}_';
    _tasks.removeWhere((k, _) => k.startsWith(prefix));
    _notifyPlantings(uid);
    _notifyTasks(plantingId);
  }

  @override
  Stream<List<TaskItem>> watchPlantingTasks(String uid, String plantingId) =>
      _getTaskController(plantingId).stream;

  @override
  Future<List<TaskItem>> getPlantingTasks(String uid, String plantingId) async {
    final prefix = '${plantingId}_';
    final list = _tasks.entries
        .where((e) => e.key.startsWith(prefix))
        .map((e) => e.value)
        .toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  @override
  Future<void> updateTask(String uid, String plantingId, TaskItem task) async {
    _tasks['${plantingId}_${task.id}'] = task;
    _notifyTasks(plantingId);
  }

  @override
  Future<void> batchUpdateTasks(
    String uid,
    String plantingId,
    List<TaskItem> tasks,
  ) async {
    for (final task in tasks) {
      _tasks['${plantingId}_${task.id}'] = task;
    }
    _notifyTasks(plantingId);
  }

  // --- Transactions ---
  @override
  Stream<List<Transaction>> watchTransactions(String uid, [String? plantingId]) {
    return _getTransactionController(uid).stream.map((List<Transaction> list) {
      if (plantingId != null && plantingId.isNotEmpty) {
        return list.where((tx) => tx.plantingId == plantingId).toList();
      }
      return list;
    });
  }

  @override
  Future<List<Transaction>> getTransactions(String uid, [String? plantingId]) async {
    var list = _transactions[uid]?.values.toList() ?? [];
    list.sort((a, b) => b.date.compareTo(a.date));
    if (plantingId != null && plantingId.isNotEmpty) {
      list = list.where((tx) => tx.plantingId == plantingId).toList();
    }
    return list;
  }

  @override
  Future<void> addTransaction(String uid, Transaction tx) async {
    _transactions.putIfAbsent(uid, () => {})[tx.id] = tx;
    _notifyTransactions(uid);
  }

  @override
  Future<void> deleteTransaction(String uid, String txId) async {
    _transactions[uid]?.remove(txId);
    _notifyTransactions(uid);
  }

  @override
  Future<void> recordHarvest({
    required String uid,
    required Planting planting,
    required DateTime harvestDate,
    required double yieldQty,
    required String yieldUnit,
    required double saleIncome,
  }) async {
    final updatedPlanting = planting.copyWith(
      status: 'harvested',
      harvestDate: harvestDate,
      yieldQty: yieldQty,
      yieldUnit: yieldUnit,
    );
    _plantings.putIfAbsent(uid, () => {})[planting.id] = updatedPlanting;
    _notifyPlantings(uid);

    if (saleIncome > 0) {
      final tx = Transaction(
        id: 'tx_harvest_${DateTime.now().millisecondsSinceEpoch}',
        plantingId: planting.id,
        fieldId: planting.fieldId,
        kind: 'income',
        category: 'sale',
        amount: saleIncome,
        date: harvestDate,
        note: 'Harvest sale ($yieldQty $yieldUnit)',
      );
      _transactions.putIfAbsent(uid, () => {})[tx.id] = tx;
      _notifyTransactions(uid);
    }
  }
}
