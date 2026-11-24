import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/domain/profit_calculator.dart';
import 'package:sowsmart/models/transaction.dart';

void main() {
  group('ProfitCalculator Tests', () {
    late ProfitCalculator calculator;

    setUp(() {
      calculator = ProfitCalculator();
    });

    test('Calculates positive profit, profit per acre, and category breakdown correctly', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          plantingId: 'p1',
          fieldId: 'f1',
          kind: 'expense',
          category: 'seed',
          amount: 2500.0,
          date: DateTime(2026, 6, 1),
        ),
        Transaction(
          id: 'tx2',
          plantingId: 'p1',
          fieldId: 'f1',
          kind: 'expense',
          category: 'fertilizer',
          amount: 4000.0,
          date: DateTime(2026, 6, 20),
        ),
        Transaction(
          id: 'tx3',
          plantingId: 'p1',
          fieldId: 'f1',
          kind: 'expense',
          category: 'labour',
          amount: 3500.0,
          date: DateTime(2026, 7, 5),
        ),
        Transaction(
          id: 'tx4',
          plantingId: 'p1',
          fieldId: 'f1',
          kind: 'income',
          category: 'sale',
          amount: 30000.0,
          date: DateTime(2026, 9, 30),
        ),
      ];

      // Field area: 2.5 acres
      final summary = calculator.calculate(transactions: transactions, areaAcres: 2.5);

      expect(summary.totalIncome, equals(30000.0));
      expect(summary.totalExpense, equals(10000.0));
      expect(summary.netProfit, equals(20000.0));
      // 20000 / 2.5 = 8000 profit per acre
      expect(summary.profitPerAcre, equals(8000.0));
      expect(summary.isProfitable, isTrue);

      expect(summary.costByCategory['seed'], equals(2500.0));
      expect(summary.costByCategory['fertilizer'], equals(4000.0));
      expect(summary.costByCategory['labour'], equals(3500.0));
    });

    test('Handles loss (negative profit) correctly', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          plantingId: 'p1',
          fieldId: 'f1',
          kind: 'expense',
          category: 'seed',
          amount: 5000.0,
          date: DateTime(2026, 6, 1),
        ),
        Transaction(
          id: 'tx2',
          plantingId: 'p1',
          fieldId: 'f1',
          kind: 'income',
          category: 'sale',
          amount: 3000.0,
          date: DateTime(2026, 9, 1),
        ),
      ];

      final summary = calculator.calculate(transactions: transactions, areaAcres: 2.0);

      expect(summary.netProfit, equals(-2000.0));
      expect(summary.profitPerAcre, equals(-1000.0));
      expect(summary.isProfitable, isFalse);
    });

    test('Safely handles zero or negative area without division by zero', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          plantingId: 'p1',
          fieldId: 'f1',
          kind: 'income',
          category: 'sale',
          amount: 15000.0,
          date: DateTime(2026, 8, 1),
        ),
      ];

      final zeroAreaSummary = calculator.calculate(transactions: transactions, areaAcres: 0.0);
      expect(zeroAreaSummary.profitPerAcre, equals(0.0));

      final negAreaSummary = calculator.calculate(transactions: transactions, areaAcres: -1.5);
      expect(negAreaSummary.profitPerAcre, equals(0.0));
    });

    test('Handles empty transactions list cleanly', () {
      final summary = calculator.calculate(transactions: [], areaAcres: 3.0);

      expect(summary.totalIncome, equals(0.0));
      expect(summary.totalExpense, equals(0.0));
      expect(summary.netProfit, equals(0.0));
      expect(summary.profitPerAcre, equals(0.0));
      expect(summary.costByCategory, isEmpty);
      expect(summary.isProfitable, isFalse);
    });
  });
}
