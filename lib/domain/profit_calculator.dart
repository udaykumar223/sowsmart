import '../models/transaction.dart';

/// Aggregated financial summary of a crop planting.
class ProfitSummary {
  final double totalIncome;
  final double totalExpense;
  final double netProfit;
  final double profitPerAcre;
  final Map<String, double> costByCategory;

  const ProfitSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
    required this.profitPerAcre,
    required this.costByCategory,
  });

  bool get isProfitable => netProfit > 0;
}

/// Pure Dart domain service to compute crop expenses, revenue, and profit per acre.
class ProfitCalculator {
  /// Computes the complete profit summary for a planting given its transactions and field area.
  ProfitSummary calculate({
    required List<Transaction> transactions,
    required double areaAcres,
  }) {
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final Map<String, double> costByCategory = {};

    for (final tx in transactions) {
      final amount = tx.amount;
      if (tx.kind.toLowerCase() == 'income') {
        totalIncome += amount;
      } else if (tx.kind.toLowerCase() == 'expense') {
        totalExpense += amount;
        final cat = tx.category.toLowerCase().trim();
        costByCategory[cat] = (costByCategory[cat] ?? 0.0) + amount;
      }
    }

    final netProfit = totalIncome - totalExpense;

    // Guard against zero or negative area to prevent division by zero
    final double profitPerAcre = areaAcres > 0.0 ? (netProfit / areaAcres) : 0.0;

    return ProfitSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netProfit: netProfit,
      profitPerAcre: profitPerAcre,
      costByCategory: costByCategory,
    );
  }
}
