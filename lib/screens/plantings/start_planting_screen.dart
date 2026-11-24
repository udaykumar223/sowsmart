import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/crop_rules_repository.dart';
import '../../models/crop_rule.dart';
import '../../models/field.dart';
import '../../models/task_item.dart';
import '../../state/fields_state.dart';
import '../../state/plantings_state.dart';

class StartPlantingScreen extends StatefulWidget {
  const StartPlantingScreen({super.key});

  @override
  State<StartPlantingScreen> createState() => _StartPlantingScreenState();
}

class _StartPlantingScreenState extends State<StartPlantingScreen> {
  final _formKey = GlobalKey<FormState>();
  Field? _selectedField;
  CropRule? _selectedCrop;
  DateTime _sowingDate = DateTime.now();
  late TextEditingController _seasonController;

  List<CropRule> _availableCrops = [];
  bool _isLoadingCrops = true;
  List<TaskItem> _schedulePreview = [];

  @override
  void initState() {
    super.initState();
    _seasonController = TextEditingController(text: 'Kharif ${DateTime.now().year}');
    _loadCrops();
  }

  @override
  void dispose() {
    _seasonController.dispose();
    super.dispose();
  }

  Future<void> _loadCrops() async {
    final cropRepo = context.read<CropRulesRepository>();
    try {
      final crops = await cropRepo.getAllCrops();
      if (mounted) {
        setState(() {
          _availableCrops = crops;
          if (crops.isNotEmpty) {
            _selectedCrop = crops.first;
          }
          _isLoadingCrops = false;
        });
        _updatePreview();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCrops = false);
      }
    }
  }

  void _updatePreview() {
    if (_selectedCrop == null) return;
    final plantingsState = context.read<PlantingsState>();
    final soil = _selectedField?.soilType ?? 'loamy';

    setState(() {
      _schedulePreview = plantingsState.previewSchedule(
        crop: _selectedCrop!,
        sowingDate: _sowingDate,
        soilType: soil,
      );
    });
  }

  Future<void> _selectSowingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null && picked != _sowingDate) {
      setState(() => _sowingDate = picked);
      _updatePreview();
    }
  }

  Future<void> _handleStartPlanting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedField == null || _selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a field and a crop')),
      );
      return;
    }

    final plantingsState = context.read<PlantingsState>();
    final success = await plantingsState.createPlantingWithGeneratedSchedule(
      fieldId: _selectedField!.id,
      crop: _selectedCrop!,
      sowingDate: _sowingDate,
      seasonLabel: _seasonController.text.trim(),
      soilType: _selectedField!.soilType,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Created planting with ${_schedulePreview.length} generated tasks!',
          ),
        ),
      );
      context.pop();
    } else if (plantingsState.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(plantingsState.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldsState = context.watch<FieldsState>();
    final plantingsState = context.watch<PlantingsState>();
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, dd MMM yyyy');

    if (_selectedField == null && fieldsState.fields.isNotEmpty) {
      _selectedField = fieldsState.fields.first;
      WidgetsBinding.instance.addPostFrameCallback((_) => _updatePreview());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Crop Planting'),
      ),
      body: _isLoadingCrops
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Field Selection
                    if (fieldsState.fields.isEmpty) ...[
                      Card(
                        color: theme.colorScheme.errorContainer.withAlpha(128),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('No fields available. Please add a field first.'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => context.push('/fields/add'),
                                child: const Text('Add Field Now'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else
                      DropdownButtonFormField<Field>(
                        initialValue: _selectedField,
                        decoration: const InputDecoration(
                          labelText: 'Select Field *',
                          prefixIcon: Icon(Icons.terrain_outlined),
                        ),
                        items: fieldsState.fields.map((f) {
                          return DropdownMenuItem(
                            value: f,
                            child: Text('${f.name} (${f.areaAcres} Ac, ${f.soilType})'),
                          );
                        }).toList(),
                        onChanged: (field) {
                          setState(() => _selectedField = field);
                          _updatePreview();
                        },
                      ),
                    const SizedBox(height: 16),

                    // Crop Selection
                    DropdownButtonFormField<CropRule>(
                      initialValue: _selectedCrop,
                      decoration: const InputDecoration(
                        labelText: 'Select Crop *',
                        prefixIcon: Icon(Icons.eco_outlined),
                      ),
                      items: _availableCrops.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text('${c.cropName} (${c.durationDays} days)'),
                        );
                      }).toList(),
                      onChanged: (crop) {
                        setState(() => _selectedCrop = crop);
                        _updatePreview();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sowing Date Picker Tile
                    InkWell(
                      onTap: _selectSowingDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Sowing Date *',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateFormat.format(_sowingDate)),
                            const Icon(Icons.edit_calendar_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Season Label
                    TextFormField(
                      controller: _seasonController,
                      decoration: const InputDecoration(
                        labelText: 'Season Label',
                        hintText: 'e.g. Kharif 2026',
                        prefixIcon: Icon(Icons.bookmark_outline),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Schedule Preview Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Generated Schedule Preview',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_schedulePreview.length} Tasks',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_selectedCrop != null) ...[
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Expected Harvest:'),
                              Text(
                                dateFormat.format(
                                  _sowingDate.add(
                                    Duration(days: _selectedCrop!.durationDays),
                                  ),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Preview Task List
                    Container(
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _schedulePreview.isEmpty
                          ? const Center(child: Text('No tasks to preview'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _schedulePreview.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final task = _schedulePreview[idx];
                                return ListTile(
                                  dense: true,
                                  leading: _getTaskIcon(task.type, theme),
                                  title: Text(
                                    task.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(task.stage),
                                  trailing: Text(
                                    DateFormat('dd MMM').format(task.dueDate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 32),

                    // Confirm Action Button
                    ElevatedButton.icon(
                      onPressed: plantingsState.isLoading || _selectedField == null
                          ? null
                          : _handleStartPlanting,
                      icon: plantingsState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.rocket_launch_rounded),
                      label: const Text('Confirm & Generate Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _getTaskIcon(String type, ThemeData theme) {
    switch (type.toLowerCase()) {
      case 'irrigation':
        return const Icon(Icons.water_drop_outlined, color: Colors.blue);
      case 'fertilizer':
        return const Icon(Icons.grain_rounded, color: Colors.orange);
      case 'spray':
        return const Icon(Icons.pest_control_outlined, color: Colors.purple);
      case 'weeding':
        return const Icon(Icons.content_cut_rounded, color: Colors.green);
      default:
        return const Icon(Icons.task_alt_rounded, color: Colors.grey);
    }
  }
}
