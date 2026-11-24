import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/firestore_repository.dart';
import '../domain/profit_calculator.dart';
import '../models/planting.dart';
import '../models/transaction.dart';

/// State management for crop finances, cost breakdowns, and harvest records.
class FinanceState extends ChangeNotifier {
  final FirestoreRepository _repository;
  final ProfitCalculator _profitCalculator;
  String? _uid;

  List<Transaction> _transactions = [];
  StreamSubscription<List<Transaction>>? _transactionsSub;
  String? _selectedPlantingId;
  bool _isLoading = false;
  String? _errorMessage;

  FinanceState(
    this._repository,
    this._profitCalculator, [
    this._uid,
  ]) {
    if (_uid != null) {
      _subscribeToTransactions();
    }
  }

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  String? get selectedPlantingId => _selectedPlantingId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Transaction> get filteredTransactions {
    if (_selectedPlantingId == null || _selectedPlantingId!.isEmpty) {
      return List.unmodifiable(_transactions);
    }
    return List.unmodifiable(
      _transactions.where((t) => t.plantingId == _selectedPlantingId).toList(),
    );
  }

  void setSelectedPlantingId(String? plantingId) {
    if (_selectedPlantingId != plantingId) {
      _selectedPlantingId = plantingId;
      notifyListeners();
    }
  }

  void updateUid(String? newUid) {
    if (_uid != newUid) {
      _uid = newUid;
      _transactionsSub?.cancel();
      _transactionsSub = null;
      _transactions = [];
      if (_uid != null) {
        _subscribeToTransactions();
      }
      notifyListeners();
    }
  }

  void _subscribeToTransactions() {
    if (_uid == null) return;
    _transactionsSub = _repository.watchTransactions(_uid!).listen(
      (items) {
        _transactions = List<Transaction>.from(items);
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  ProfitSummary calculateSummary(List<Transaction> txs, double areaAcres) {
    return _profitCalculator.calculate(
      transactions: txs,
      areaAcres: areaAcres,
    );
  }

  ProfitSummary calculateSummaryForPlanting(String plantingId, double areaAcres) {
    final plantingTxs = _transactions.where((t) => t.plantingId == plantingId).toList();
    return _profitCalculator.calculate(
      transactions: plantingTxs,
      areaAcres: areaAcres,
    );
  }

  ProfitSummary calculateOverallSummary(double totalAcres) {
    return _profitCalculator.calculate(
      transactions: _transactions,
      areaAcres: totalAcres,
    );
  }

  Future<void> addTransaction(Transaction tx) async {
    if (_uid == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Optimistic update
      _transactions = [tx, ..._transactions];
      notifyListeners();

      await _repository.addTransaction(_uid!, tx);
    } catch (e) {
      _errorMessage = e.toString();
      _transactions.removeWhere((t) => t.id == tx.id);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String txId) async {
    if (_uid == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final previousList = List<Transaction>.from(_transactions);
    try {
      // Optimistic update
      _transactions = _transactions.where((t) => t.id != txId).toList();
      notifyListeners();

      await _repository.deleteTransaction(_uid!, txId);
    } catch (e) {
      _errorMessage = e.toString();
      _transactions = previousList;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordHarvest({
    required Planting planting,
    required DateTime harvestDate,
    required double yieldQty,
    required String yieldUnit,
    required double saleIncome,
  }) async {
    if (_uid == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.recordHarvest(
        uid: _uid!,
        planting: planting,
        harvestDate: harvestDate,
        yieldQty: yieldQty,
        yieldUnit: yieldUnit,
        saleIncome: saleIncome,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _transactionsSub?.cancel();
    super.dispose();
  }
}
