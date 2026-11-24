import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/crop_rules_repository.dart';
import '../../models/crop_rule.dart';
import '../../models/planting.dart';
import '../../models/task_item.dart';
import '../../state/plantings_state.dart';

class PlantingDetailScreen extends StatefulWidget {
  final Planting planting;

  const PlantingDetailScreen({super.key, required this.planting});

  @override
  State<PlantingDetailScreen> createState() => _PlantingDetailScreenState();
}

class _PlantingDetailScreenState extends State<PlantingDetailScreen> {
  CropRule? _cropRule;
  bool _isLoadingRule = true;

  @override
  void initState() {
    super.initState();
    _loadCropRule();
  }

  Future<void> _loadCropRule() async {
    final repo = context.read<CropRulesRepository>();
    final rule = await repo.getCropById(widget.planting.cropId);
    if (mounted) {
      setState(() {
        _cropRule = rule;
        _isLoadingRule = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantingsState = context.watch<PlantingsState>();
    final theme = Theme.of(context);
    final p = widget.planting;
    final dateFormat = DateFormat('dd MMM yyyy');

    final daysElapsed = DateTime.now().difference(p.sowingDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.cropName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Card
          Card(
            color: theme.colorScheme.primaryContainer.withAlpha(128),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.cropName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.status == 'harvested'
                              ? Colors.green
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Season: ${p.seasonLabel}'),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sown: ${dateFormat.format(p.sowingDate)}'),
                      Text('Expected Harvest: ${dateFormat.format(p.expectedHarvestDate)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Days since sowing: ${daysElapsed >= 0 ? daysElapsed : 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Crop Stage Progress Indicator
          Text(
            'Stage Progress',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          if (_isLoadingRule)
            const Center(child: CircularProgressIndicator())
          else if (_cropRule != null)
            _buildStageProgressTimeline(theme, _cropRule!, daysElapsed),

          const SizedBox(height: 20),

          // Scheduled Tasks
          Text(
            'Cultivation Tasks',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          StreamBuilder<List<TaskItem>>(
            stream: plantingsState.watchTasksForPlanting(p.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No tasks found for this planting'),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _buildTaskTile(context, task);
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Finance & Harvest Action Buttons
          if (widget.planting.status == 'active') ...[
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.account_balance_wallet_rounded),
                    label: const Text('Finance'),
                    onPressed: () => context.push('/finance'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                    icon: const Icon(Icons.agriculture_rounded),
                    label: const Text('Record Harvest'),
                    onPressed: () => context.push(
                      '/plantings/harvest/${widget.planting.id}',
                      extra: widget.planting,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (widget.planting.status == 'harvested') ...[
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harvest Completed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          if (widget.planting.harvestDate != null)
                            Text(
                              'Harvested on ${DateFormat('dd MMM yyyy').format(widget.planting.harvestDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade800,
                              ),
                            ),
                          if (widget.planting.yieldQty != null)
                            Text(
                              'Yield: ${widget.planting.yieldQty} ${widget.planting.yieldUnit ?? ""}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade800,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/finance'),
                      child: const Text('View P&L'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStageProgressTimeline(ThemeData theme, CropRule rule, int daysElapsed) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: rule.stages.map((stage) {
            final isCurrent = daysElapsed >= stage.startDay && daysElapsed <= stage.endDay;
            final isCompleted = daysElapsed > stage.endDay;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : isCurrent
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                    color: isCompleted
                        ? Colors.green
                        : isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stage.name,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                  Text(
                    'Days ${stage.startDay}-${stage.endDay}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, TaskItem task) {
    final theme = Theme.of(context);
    final isDone = task.status == 'done';
    final isPostponed = task.status == 'postponed';

    return Card(
      elevation: 0.5,
      child: ListTile(
        leading: Icon(
          isDone ? Icons.task_alt_rounded : Icons.pending_actions_rounded,
          color: isDone
              ? Colors.green
              : isPostponed
                  ? Colors.amber
                  : theme.colorScheme.primary,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('${task.stage} • ${task.type}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('dd MMM').format(task.dueDate),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              task.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: isDone
                    ? Colors.green
                    : isPostponed
                        ? Colors.amber[800]
                        : theme.colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
