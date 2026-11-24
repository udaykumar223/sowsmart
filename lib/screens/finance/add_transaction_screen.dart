import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/planting.dart';
import '../../models/transaction.dart';
import '../../state/finance_state.dart';
import '../../state/plantings_state.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialPlantingId;

  const AddTransactionScreen({super.key, this.initialPlantingId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPlantingId;
  String _kind = 'expense'; // 'expense' or 'income'
  String _category = 'seed';
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  final List<String> _expenseCategories = [
    'seed',
    'labour',
    'fertilizer',
    'pesticide',
    'irrigation',
    'machinery',
    'transport',
    'other',
  ];

  final List<String> _incomeCategories = [
    'sale',
    'subsidy',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlantingId = widget.initialPlantingId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatCategoryLabel(String cat) {
    return cat[0].toUpperCase() + cat.substring(1);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlantingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop planting.')),
      );
      return;
    }

    final plantingsState = context.read<PlantingsState>();
    final Planting? planting = plantingsState.plantings
        .cast<Planting?>()
        .firstWhere((p) => p?.id == _selectedPlantingId, orElse: () => null);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final txId = 'tx_${DateTime.now().millisecondsSinceEpoch}';

    final transaction = Transaction(
      id: txId,
      plantingId: _selectedPlantingId!,
      fieldId: planting?.fieldId ?? '',
      kind: _kind,
      category: _category,
      amount: amount,
      date: _selectedDate,
      note: _noteController.text.trim(),
    );
    setState(() => _isSubmitting = true);

    try {
      await context.read<FinanceState>().addTransaction(transaction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_kind == 'expense' ? 'Expense' : 'Income'} of ₹${amount.toStringAsFixed(2)} recorded!',
            ),
            backgroundColor: _kind == 'expense' ? Colors.orange.shade800 : Colors.green.shade700,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantings = context.watch<PlantingsState>().plantings;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    if (_selectedPlantingId == null && plantings.isNotEmpty) {
      _selectedPlantingId = plantings.first.id;
    }

    final currentCategories = _kind == 'expense' ? _expenseCategories : _incomeCategories;
    if (!currentCategories.contains(_category)) {
      _category = currentCategories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: plantings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No plantings found. Please create a crop planting before logging transactions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Kind Selector: Expense vs Income
                  Center(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'expense',
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_downward, color: Colors.red),
                        ),
                        ButtonSegment(
                          value: 'income',
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_upward, color: Colors.green),
                        ),
                      ],
                      selected: {_kind},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _kind = newSelection.first;
                          _category = _kind == 'expense'
                              ? _expenseCategories.first
                              : _incomeCategories.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Crop Planting Selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPlantingId,
                    decoration: const InputDecoration(
                      labelText: 'Crop Planting *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.agriculture_rounded),
                    ),
                    items: plantings.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          '${p.cropName} (${p.seasonLabel})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPlantingId = val;
                      });
                    },
                    validator: (val) => val == null ? 'Please select a crop' : null,
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: _kind == 'expense' ? 'Cost Category *' : 'Income Category *',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        _kind == 'expense' ? Icons.category_rounded : Icons.monetization_on_rounded,
                      ),
                    ),
                    items: currentCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(_formatCategoryLabel(cat)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _category = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹) *',
                      hintText: 'e.g. 2500',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter the amount';
                      }
                      final numVal = double.tryParse(val.trim());
                      if (numVal == null || numVal <= 0) {
                        return 'Amount must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Picker Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Transaction Date'),
                      subtitle: Text(dateFormat.format(_selectedDate)),
                      trailing: TextButton(
                        onPressed: _pickDate,
                        child: const Text('Change'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes / Description
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'e.g., 2 bags of DAP fertilizer',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _saveTransaction,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSubmitting ? 'Saving...' : 'Save Transaction',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
