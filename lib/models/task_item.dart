/// Represents an individual scheduled field task (e.g. irrigation, fertilizer, spraying).
/// Pure Dart model without framework dependencies.
class TaskItem {
  final String id;
  final String plantingId;
  final String ruleId;
  final String type; // 'irrigation', 'fertilizer', 'spray', 'weeding', 'other'
  final String title;
  final String notes;
  final String stage;
  final DateTime dueDate;
  final DateTime originalDueDate;
  final String status; // 'pending', 'done', 'postponed', 'skipped'
  final DateTime? completedAt;

  const TaskItem({
    required this.id,
    this.plantingId = '',
    required this.ruleId,
    required this.type,
    required this.title,
    required this.notes,
    required this.stage,
    required this.dueDate,
    required this.originalDueDate,
    required this.status,
    this.completedAt,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json, [String? id]) {
    final due = json['dueDate'] != null
        ? DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now()
        : DateTime.now();

    final orig = json['originalDueDate'] != null
        ? DateTime.tryParse(json['originalDueDate'].toString()) ?? due
        : due;

    return TaskItem(
      id: id ?? json['id'] as String? ?? '',
      plantingId: json['plantingId'] as String? ?? '',
      ruleId: json['ruleId'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      stage: json['stage'] as String? ?? '',
      dueDate: due,
      originalDueDate: orig,
      status: json['status'] as String? ?? 'pending',
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantingId': plantingId,
      'ruleId': ruleId,
      'type': type,
      'title': title,
      'notes': notes,
      'stage': stage,
      'dueDate': dueDate.toIso8601String(),
      'originalDueDate': originalDueDate.toIso8601String(),
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  TaskItem copyWith({
    String? id,
    String? plantingId,
    String? ruleId,
    String? type,
    String? title,
    String? notes,
    String? stage,
    DateTime? dueDate,
    DateTime? originalDueDate,
    String? status,
    DateTime? completedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      plantingId: plantingId ?? this.plantingId,
      ruleId: ruleId ?? this.ruleId,
      type: type ?? this.type,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      stage: stage ?? this.stage,
      dueDate: dueDate ?? this.dueDate,
      originalDueDate: originalDueDate ?? this.originalDueDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          title == other.title &&
          dueDate == other.dueDate &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, type, title, dueDate, status);
}
