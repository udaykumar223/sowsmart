import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/field.dart';
import '../../state/fields_state.dart';

class AddEditFieldScreen extends StatefulWidget {
  final Field? existingField;

  const AddEditFieldScreen({super.key, this.existingField});

  @override
  State<AddEditFieldScreen> createState() => _AddEditFieldScreenState();
}

class _AddEditFieldScreenState extends State<AddEditFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _acresController;
  late TextEditingController _latController;
  late TextEditingController _lonController;

  String _selectedSoilType = 'loamy';
  bool _isFetchingLocation = false;

  final List<String> _soilOptions = ['clay', 'loamy', 'sandy'];

  @override
  void initState() {
    super.initState();
    final f = widget.existingField;
    _nameController = TextEditingController(text: f?.name ?? '');
    _acresController = TextEditingController(
      text: f != null && f.areaAcres > 0 ? f.areaAcres.toString() : '',
    );
    _latController = TextEditingController(
      text: f != null && f.lat != 0.0 ? f.lat.toString() : '',
    );
    _lonController = TextEditingController(
      text: f != null && f.lon != 0.0 ? f.lon.toString() : '',
    );

    if (f != null && _soilOptions.contains(f.soilType.toLowerCase())) {
      _selectedSoilType = f.soilType.toLowerCase();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _acresController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _handleUseMyLocation() async {
    setState(() => _isFetchingLocation = true);
    final fieldsState = context.read<FieldsState>();

    final pos = await fieldsState.getCurrentLocation();
    setState(() => _isFetchingLocation = false);

    if (pos != null && mounted) {
      _latController.text = pos.latitude.toStringAsFixed(6);
      _lonController.text = pos.longitude.toStringAsFixed(6);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates populated from GPS')),
      );
    } else if (fieldsState.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fieldsState.errorMessage!)),
      );
    }
  }

  Future<void> _saveField() async {
    if (!_formKey.currentState!.validate()) return;

    final fieldsState = context.read<FieldsState>();
    final name = _nameController.text.trim();
    final acres = double.tryParse(_acresController.text.trim()) ?? 1.0;
    final lat = double.tryParse(_latController.text.trim()) ?? 0.0;
    final lon = double.tryParse(_lonController.text.trim()) ?? 0.0;

    bool success;
    if (widget.existingField != null) {
      final updated = widget.existingField!.copyWith(
        name: name,
        areaAcres: acres,
        soilType: _selectedSoilType,
        lat: lat,
        lon: lon,
      );
      success = await fieldsState.updateField(updated);
    } else {
      success = await fieldsState.addField(
        name: name,
        areaAcres: acres,
        soilType: _selectedSoilType,
        lat: lat,
        lon: lon,
      );
    }

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingField != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Field' : 'Add New Field'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Field Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Field Name *',
                  hintText: 'e.g. North Canal Plot',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a field name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Area in Acres
              TextFormField(
                controller: _acresController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Area (Acres) *',
                  hintText: 'e.g. 2.5',
                  prefixIcon: Icon(Icons.square_foot_outlined),
                ),
                validator: (val) {
                  final numVal = double.tryParse(val ?? '');
                  if (numVal == null || numVal <= 0) {
                    return 'Please enter a valid acreage greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Soil Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedSoilType,
                decoration: const InputDecoration(
                  labelText: 'Soil Type *',
                  prefixIcon: Icon(Icons.grass_outlined),
                ),
                items: _soilOptions.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      '${type[0].toUpperCase()}${type.substring(1)} Soil',
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedSoilType = val);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Location Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Field Location (GPS)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isFetchingLocation ? null : _handleUseMyLocation,
                    icon: _isFetchingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Use My Location'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '11.0168',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lonController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '76.9558',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Action Button
              ElevatedButton.icon(
                onPressed: _saveField,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(isEditing ? 'Save Changes' : 'Create Field'),
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
}
