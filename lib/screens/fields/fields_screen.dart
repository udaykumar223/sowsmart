import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/field.dart';
import '../../state/fields_state.dart';

class FieldsScreen extends StatelessWidget {
  const FieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fieldsState = context.watch<FieldsState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fields'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/fields/add'),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Field'),
      ),
      body: Builder(
        builder: (context) {
          if (fieldsState.isLoading && fieldsState.fields.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (fieldsState.errorMessage != null && fieldsState.fields.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(fieldsState.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => fieldsState.clearError(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (fieldsState.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.landscape_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Fields Added Yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your farm plots with acreage, soil type, and GPS coordinates to start scheduling crops.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/fields/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Field'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: fieldsState.fields.length,
            itemBuilder: (context, index) {
              final field = fieldsState.fields[index];
              return _buildFieldCard(context, field);
            },
          );
        },
      ),
    );
  }

  Widget _buildFieldCard(BuildContext context, Field field) {
    final fieldsState = context.read<FieldsState>();
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.terrain_rounded, color: theme.colorScheme.primary),
        ),
        title: Text(
          field.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                _buildChip(theme, '${field.areaAcres} Acres', Icons.square_foot_rounded),
                const SizedBox(width: 8),
                _buildChip(theme, field.soilType.toUpperCase(), Icons.grass_rounded),
              ],
            ),
            if (field.lat != 0.0 || field.lon != 0.0) ...[
              const SizedBox(height: 6),
              Text(
                'GPS: ${field.lat.toStringAsFixed(4)}, ${field.lon.toStringAsFixed(4)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              context.push('/fields/edit/${field.id}', extra: field);
            } else if (value == 'delete') {
              _showDeleteDialog(context, fieldsState, field);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    FieldsState state,
    Field field,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Field?'),
        content: Text('Are you sure you want to remove "${field.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await state.deleteField(field.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
