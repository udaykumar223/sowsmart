import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/planting.dart';
import '../../state/fields_state.dart';
import '../../state/finance_state.dart';

class HarvestScreen extends StatefulWidget {
  final Planting planting;

  const HarvestScreen({super.key, required this.planting});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _harvestDate;
  final _yieldQtyController = TextEditingController();
  final _saleIncomeController = TextEditingController();
  String _yieldUnit = 'quintals';
  bool _isSubmitting = false;

  final List<String> _yieldUnits = [
    'quintals',
    'kg',
    'tons',
    'crates',
    'bags',
  ];

  @override
  void initState() {
    super.initState();
    _harvestDate = DateTime.now();
  }

  @override
  void dispose() {
    _yieldQtyController.dispose();
    _saleIncomeController.dispose();
    super.dispose();
  }

  Future<void> _pickHarvestDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: widget.planting.sowingDate,
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _harvestDate = picked;
      });
    }
  }

  Future<void> _submitHarvest() async {
    if (!_formKey.currentState!.validate()) return;

    final yieldQty = double.tryParse(_yieldQtyController.text.trim()) ?? 0.0;
    final saleIncome = double.tryParse(_saleIncomeController.text.trim()) ?? 0.0;

    setState(() => _isSubmitting = true);

    try {
      await context.read<FinanceState>().recordHarvest(
            planting: widget.planting,
            harvestDate: _harvestDate,
            yieldQty: yieldQty,
            yieldUnit: _yieldUnit,
            saleIncome: saleIncome,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Harvest recorded for ${widget.planting.cropName}! Sale of ₹${saleIncome.toStringAsFixed(2)} added.',
            ),
            backgroundColor: Colors.green.shade800,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete harvest: $e')),
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
    final p = widget.planting;
    final fieldsState = context.watch<FieldsState>();
    final field = fieldsState.getFieldById(p.fieldId);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    final daysInGround = _harvestDate.difference(p.sowingDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Harvest'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Crop Info Card
            Card(
              color: theme.colorScheme.primaryContainer.withAlpha(128),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          p.cropName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Field: ${field?.name ?? "Unknown Field"} (${field?.areaAcres.toStringAsFixed(1) ?? "0"} acres)'),
                    Text('Sowing Date: ${dateFormat.format(p.sowingDate)}'),
                    Text('Expected Harvest: ${dateFormat.format(p.expectedHarvestDate)}'),
                    const SizedBox(height: 4),
                    Text(
                      'Crop Duration: $daysInGround days in field',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Harvest Date Picker
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: const Icon(Icons.event_available_rounded),
                title: const Text('Actual Harvest Date *'),
                subtitle: Text(dateFormat.format(_harvestDate)),
                trailing: TextButton(
                  onPressed: _pickHarvestDate,
                  child: const Text('Change'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Yield Quantity and Unit Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _yieldQtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total Yield *',
                      hintText: 'e.g. 45.5',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Enter yield';
                      }
                      final numVal = double.tryParse(val.trim());
                      if (numVal == null || numVal <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _yieldUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: _yieldUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _yieldUnit = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Final Sale Income
            TextFormField(
              controller: _saleIncomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Sale Income (₹) *',
                hintText: 'e.g. 68000',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
                helperText: 'Revenue earned from selling the harvest',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter sale income';
                }
                final numVal = double.tryParse(val.trim());
                if (numVal == null || numVal < 0) {
                  return 'Income cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Informational Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recording harvest will close this crop cycle, mark its status as HARVESTED, and automatically commit the sale revenue to your profit tracker.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSubmitting ? null : _submitHarvest,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isSubmitting ? 'Closing Cycle...' : 'Complete Harvest & Close Cycle',
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
