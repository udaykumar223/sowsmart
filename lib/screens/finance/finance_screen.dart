import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/planting.dart';
import '../../models/transaction.dart';
import '../../state/fields_state.dart';
import '../../state/finance_state.dart';
import '../../state/plantings_state.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _touchedPieIndex = -1;

  final Map<String, Color> _categoryColors = {
    'seed': const Color(0xFF558B2F),
    'labour': const Color(0xFF1976D2),
    'fertilizer': const Color(0xFFF57F17),
    'pesticide': const Color(0xFF7B1FA2),
    'irrigation': const Color(0xFF0097A7),
    'machinery': const Color(0xFFE64A19),
    'transport': const Color(0xFF5D4037),
    'sale': const Color(0xFF2E7D32),
    'subsidy': const Color(0xFF388E3C),
    'other': const Color(0xFF616161),
  };

  final Map<String, IconData> _categoryIcons = {
    'seed': Icons.eco_rounded,
    'labour': Icons.groups_rounded,
    'fertilizer': Icons.grain_rounded,
    'pesticide': Icons.bug_report_rounded,
    'irrigation': Icons.water_drop_rounded,
    'machinery': Icons.agriculture_rounded,
    'transport': Icons.local_shipping_rounded,
    'sale': Icons.monetization_on_rounded,
    'subsidy': Icons.account_balance_rounded,
    'other': Icons.receipt_long_rounded,
  };

  String _formatCategory(String cat) {
    if (cat.isEmpty) return 'Other';
    return cat[0].toUpperCase() + cat.substring(1);
  }

  void _showDeleteDialog(BuildContext context, Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this ${tx.kind} of ₹${tx.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<FinanceState>().deleteTransaction(tx.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeState = context.watch<FinanceState>();
    final plantingsState = context.watch<PlantingsState>();
    final fieldsState = context.watch<FieldsState>();
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat('#,##,##0.00');
    final dateFormat = DateFormat('dd MMM yyyy');

    final plantings = plantingsState.plantings;
    final selectedPlantingId = financeState.selectedPlantingId;

    // Determine relevant area in acres for profit/acre calculation
    double relevantArea = 0.0;
    if (selectedPlantingId != null && selectedPlantingId.isNotEmpty) {
      final Planting? planting = plantings
          .cast<Planting?>()
          .firstWhere((p) => p?.id == selectedPlantingId, orElse: () => null);
      final field = planting != null ? fieldsState.getFieldById(planting.fieldId) : null;
      relevantArea = field?.areaAcres ?? 0.0;
    } else {
      // Sum up area of all unique fields across all plantings
      final fieldIds = plantings.map((p) => p.fieldId).toSet();
      for (final fid in fieldIds) {
        final f = fieldsState.getFieldById(fid);
        if (f != null) relevantArea += f.areaAcres;
      }
    }

    final summary = financeState.calculateSummary(
      financeState.filteredTransactions,
      relevantArea,
    );

    final transactions = financeState.filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Transaction',
            onPressed: () => context.push('/finance/add-transaction'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/finance/add-transaction'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Filter Selector: All Plantings vs Specific Planting
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedPlantingId,
                        isExpanded: true,
                        hint: const Text('All Crops & Seasons'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'All Crops & Seasons (Overall)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...plantings.map((p) {
                            return DropdownMenuItem<String?>(
                              value: p.id,
                              child: Text(
                                '${p.cropName} (${p.seasonLabel})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          financeState.setSelectedPlantingId(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // P&L Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  theme: theme,
                  title: 'Total Revenue',
                  amount: '₹${currencyFormat.format(summary.totalIncome)}',
                  color: Colors.green.shade700,
                  icon: Icons.trending_up_rounded,
                  background: Colors.green.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  theme: theme,
                  title: 'Total Expenses',
                  amount: '₹${currencyFormat.format(summary.totalExpense)}',
                  color: Colors.red.shade700,
                  icon: Icons.trending_down_rounded,
                  background: Colors.red.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Net Profit and Profit/Acre
          Card(
            color: summary.isProfitable
                ? Colors.green.shade100.withAlpha(160)
                : Colors.orange.shade100.withAlpha(160),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.isProfitable ? 'NET PROFIT' : 'NET MARGIN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: summary.isProfitable
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.netProfit >= 0 ? "+" : ""}₹${currencyFormat.format(summary.netProfit)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: summary.isProfitable
                                  ? Colors.green.shade900
                                  : Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: summary.isProfitable
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          relevantArea > 0
                              ? '₹${currencyFormat.format(summary.profitPerAcre)} / acre'
                              : '₹0 / acre',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (relevantArea > 0) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Calculated over ${relevantArea.toStringAsFixed(1)} acres of cultivated land.',
                        style: TextStyle(
                          fontSize: 12,
                          color: summary.isProfitable
                              ? Colors.green.shade900.withAlpha(180)
                              : Colors.orange.shade900.withAlpha(180),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Expense Breakdown Pie Chart
          Text(
            'Cost Breakdown by Category',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          if (summary.costByCategory.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No expenses recorded yet. Tap "+ Add Entry" to record seed, labour, fertilizer, or other costs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedPieIndex = -1;
                                  return;
                                }
                                _touchedPieIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _buildPieSections(summary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Legend
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: summary.costByCategory.entries.map((e) {
                        final color = _categoryColors[e.key] ?? Colors.grey;
                        final percentage = summary.totalExpense > 0
                            ? (e.value / summary.totalExpense * 100).toStringAsFixed(0)
                            : '0';
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_formatCategory(e.key)}: ₹${e.value.toStringAsFixed(0)} ($percentage%)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Transaction History List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions (${transactions.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (transactions.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No transactions recorded for this selection.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ...transactions.map((tx) {
              final isIncome = tx.kind.toLowerCase() == 'income';
              final color = isIncome ? Colors.green.shade700 : Colors.red.shade700;
              final icon = _categoryIcons[tx.category.toLowerCase()] ?? Icons.receipt_rounded;

              final Planting? planting = plantings
                  .cast<Planting?>()
                  .firstWhere((p) => p?.id == tx.plantingId, orElse: () => null);
              final plantingName = planting?.cropName ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Row(
                    children: [
                      Text(
                        _formatCategory(tx.category),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (tx.note.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '• ${tx.note}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${dateFormat.format(tx.date)}${plantingName.isNotEmpty ? " • $plantingName" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isIncome ? "+" : "-"}₹${currencyFormat.format(tx.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        color: Colors.grey.shade600,
                        onPressed: () => _showDeleteDialog(context, tx),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 80), // Room for FAB
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required ThemeData theme,
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    required Color background,
  }) {
    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(dynamic summary) {
    int index = 0;
    return summary.costByCategory.entries.map<PieChartSectionData>((entry) {
      final isTouched = index == _touchedPieIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final color = _categoryColors[entry.key] ?? Colors.grey;

      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: entry.value > 0 ? '₹${entry.value.toStringAsFixed(0)}' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
