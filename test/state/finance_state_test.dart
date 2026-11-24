import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/data/firestore_repository.dart';
import 'package:sowsmart/domain/profit_calculator.dart';
import 'package:sowsmart/models/planting.dart';
import 'package:sowsmart/models/transaction.dart';
import 'package:sowsmart/state/finance_state.dart';

void main() {
  final epoch = DateTime(2026, 1, 1);
  final profitCalculator = ProfitCalculator();

  Planting makePlanting(String id, String fieldId) => Planting(
        id: id,
        fieldId: fieldId,
        cropId: 'paddy_ir20',
        cropName: 'Paddy IR 20',
        sowingDate: epoch,
        seasonLabel: 'Kharif 2026',
        status: 'active',
        expectedHarvestDate: epoch.add(const Duration(days: 120)),
        createdAt: epoch,
      );

  Transaction makeTx({
    required String id,
    required String plantingId,
    required String kind,
    required String category,
    required double amount,
  }) =>
      Transaction(
        id: id,
        plantingId: plantingId,
        fieldId: 'f1',
        kind: kind,
        category: category,
        amount: amount,
        date: epoch,
      );

  late InMemoryFirestoreRepository repo;
  late FinanceState state;
  const uid = 'user1';

  setUp(() {
    repo = InMemoryFirestoreRepository();
    state = FinanceState(repo, profitCalculator, uid);
  });

  group('FinanceState – transaction management', () {
    test('addTransaction stores tx and updates list', () async {
      final tx = makeTx(
        id: 'tx1',
        plantingId: 'p1',
        kind: 'expense',
        category: 'seed',
        amount: 1500.0,
      );

      await state.addTransaction(tx);

      expect(state.transactions.length, equals(1));
      expect(state.transactions.first.id, equals('tx1'));
      expect(state.transactions.first.amount, equals(1500.0));
    });

    test('deleteTransaction removes tx from list', () async {
      final tx = makeTx(
        id: 'tx1',
        plantingId: 'p1',
        kind: 'expense',
        category: 'labour',
        amount: 800.0,
      );

      await state.addTransaction(tx);
      expect(state.transactions.length, equals(1));

      await state.deleteTransaction('tx1');
      expect(state.transactions, isEmpty);
    });

    test('filteredTransactions returns all when no planting filter', () async {
      await state.addTransaction(
          makeTx(id: 'tx1', plantingId: 'p1', kind: 'expense', category: 'seed', amount: 1000.0));
      await state.addTransaction(
          makeTx(id: 'tx2', plantingId: 'p2', kind: 'income', category: 'sale', amount: 5000.0));

      expect(state.filteredTransactions.length, equals(2));
    });

    test('filteredTransactions filters by selectedPlantingId', () async {
      await state.addTransaction(
          makeTx(id: 'tx1', plantingId: 'p1', kind: 'expense', category: 'seed', amount: 1000.0));
      await state.addTransaction(
          makeTx(id: 'tx2', plantingId: 'p2', kind: 'income', category: 'sale', amount: 5000.0));

      state.setSelectedPlantingId('p1');
      expect(state.filteredTransactions.length, equals(1));
      expect(state.filteredTransactions.first.plantingId, equals('p1'));
    });
  });

  group('FinanceState – profit calculation', () {
    test('calculateSummary matches manual computation', () async {
      await state.addTransaction(
          makeTx(id: 'tx1', plantingId: 'p1', kind: 'expense', category: 'seed', amount: 2000.0));
      await state.addTransaction(
          makeTx(id: 'tx2', plantingId: 'p1', kind: 'expense', category: 'labour', amount: 3000.0));
      await state.addTransaction(
          makeTx(id: 'tx3', plantingId: 'p1', kind: 'income', category: 'sale', amount: 15000.0));

      final summary = state.calculateSummary(state.transactions, 2.0);

      // totalIncome = 15000, totalExpense = 5000, net = 10000, per acre = 10000/2 = 5000
      expect(summary.totalIncome, closeTo(15000.0, 0.01));
      expect(summary.totalExpense, closeTo(5000.0, 0.01));
      expect(summary.netProfit, closeTo(10000.0, 0.01));
      expect(summary.profitPerAcre, closeTo(5000.0, 0.01));
      expect(summary.isProfitable, isTrue);
    });

    test('calculateSummaryForPlanting isolates correct transactions', () async {
      await state.addTransaction(
          makeTx(id: 'tx1', plantingId: 'p1', kind: 'expense', category: 'seed', amount: 2000.0));
      await state.addTransaction(
          makeTx(id: 'tx2', plantingId: 'p2', kind: 'expense', category: 'fertilizer', amount: 4000.0));
      await state.addTransaction(
          makeTx(id: 'tx3', plantingId: 'p1', kind: 'income', category: 'sale', amount: 8000.0));

      final p1Summary = state.calculateSummaryForPlanting('p1', 1.0);
      expect(p1Summary.netProfit, closeTo(6000.0, 0.01));
      expect(p1Summary.profitPerAcre, closeTo(6000.0, 0.01));

      final p2Summary = state.calculateSummaryForPlanting('p2', 1.5);
      expect(p2Summary.netProfit, closeTo(-4000.0, 0.01));
      expect(p2Summary.isProfitable, isFalse);
    });

    test('profitPerAcre is 0 when areaAcres is 0', () async {
      await state.addTransaction(
          makeTx(id: 'tx1', plantingId: 'p1', kind: 'income', category: 'sale', amount: 5000.0));

      final summary = state.calculateSummary(state.transactions, 0.0);
      expect(summary.profitPerAcre, equals(0.0));
    });
  });

  group('FinanceState – harvest recording', () {
    test('recordHarvest marks planting harvested and adds income tx', () async {
      final planting = makePlanting('p1', 'f1');
      await repo.createPlantingWithTasks(uid, planting, []);

      final harvestDate = epoch.add(const Duration(days: 100));

      await state.recordHarvest(
        planting: planting,
        harvestDate: harvestDate,
        yieldQty: 45.0,
        yieldUnit: 'quintals',
        saleIncome: 67500.0,
      );

      // Sale income tx should have been added to repo
      final txs = await repo.getTransactions(uid);
      expect(txs.length, equals(1));
      expect(txs.first.kind, equals('income'));
      expect(txs.first.category, equals('sale'));
      expect(txs.first.amount, closeTo(67500.0, 0.01));

      // Planting should be marked as harvested
      final updated = await repo.getPlanting(uid, 'p1');
      expect(updated?.status, equals('harvested'));
      expect(updated?.yieldQty, closeTo(45.0, 0.01));
      expect(updated?.yieldUnit, equals('quintals'));
    });

    test('recordHarvest with zero saleIncome does not add income tx', () async {
      final planting = makePlanting('p2', 'f1');
      await repo.createPlantingWithTasks(uid, planting, []);

      await state.recordHarvest(
        planting: planting,
        harvestDate: epoch.add(const Duration(days: 90)),
        yieldQty: 20.0,
        yieldUnit: 'tons',
        saleIncome: 0.0,
      );

      final txs = await repo.getTransactions(uid);
      expect(txs, isEmpty);
    });
  });

  group('InMemoryFirestoreRepository – transaction CRUD', () {
    test('addTransaction and getTransactions round-trip', () async {
      final tx = makeTx(
          id: 'txA', plantingId: 'p1', kind: 'expense', category: 'fertilizer', amount: 3200.0);
      await repo.addTransaction(uid, tx);

      final fetched = await repo.getTransactions(uid);
      expect(fetched.length, equals(1));
      expect(fetched.first.id, equals('txA'));
    });

    test('getTransactions filtered by plantingId', () async {
      await repo.addTransaction(uid,
          makeTx(id: 'tx1', plantingId: 'p1', kind: 'expense', category: 'seed', amount: 100.0));
      await repo.addTransaction(uid,
          makeTx(id: 'tx2', plantingId: 'p2', kind: 'expense', category: 'labour', amount: 200.0));
      await repo.addTransaction(uid,
          makeTx(id: 'tx3', plantingId: 'p1', kind: 'income', category: 'sale', amount: 500.0));

      final p1Txs = await repo.getTransactions(uid, 'p1');
      expect(p1Txs.length, equals(2));
      expect(p1Txs.every((t) => t.plantingId == 'p1'), isTrue);
    });

    test('deleteTransaction removes from storage', () async {
      await repo.addTransaction(uid,
          makeTx(id: 'tx1', plantingId: 'p1', kind: 'expense', category: 'seed', amount: 100.0));
      await repo.deleteTransaction(uid, 'tx1');

      final txs = await repo.getTransactions(uid);
      expect(txs, isEmpty);
    });
  });
}
