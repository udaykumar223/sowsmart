/// Crop stage metadata (e.g. Nursery, Tillering, Panicle Initiation, Harvest).
class CropStage {
  final String name;
  final int startDay;
  final int endDay;

  const CropStage({
    required this.name,
    required this.startDay,
    required this.endDay,
  });

  factory CropStage.fromJson(Map<String, dynamic> json) {
    return CropStage(
      name: json['name'] as String? ?? '',
      startDay: (json['startDay'] as num?)?.toInt() ?? 0,
      endDay: (json['endDay'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startDay': startDay,
      'endDay': endDay,
    };
  }
}

/// Template rule for generating crop tasks.
class CropTaskRule {
  final String id;
  final String stage;
  final String type; // 'irrigation', 'fertilizer', 'spray', 'weeding', 'other'
  final String title;
  final String notes;
  final int startDay;
  final int? repeatEveryDays;
  final int? endDay;

  const CropTaskRule({
    required this.id,
    required this.stage,
    required this.type,
    required this.title,
    required this.notes,
    required this.startDay,
    this.repeatEveryDays,
    this.endDay,
  });

  factory CropTaskRule.fromJson(Map<String, dynamic> json) {
    return CropTaskRule(
      id: json['id'] as String? ?? '',
      stage: json['stage'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      startDay: (json['startDay'] as num?)?.toInt() ?? 0,
      repeatEveryDays: (json['repeatEveryDays'] as num?)?.toInt(),
      endDay: (json['endDay'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stage': stage,
      'type': type,
      'title': title,
      'notes': notes,
      'startDay': startDay,
      'repeatEveryDays': repeatEveryDays,
      'endDay': endDay,
    };
  }
}

/// Agronomy rule set for a crop, loaded from assets/crop_rules.json.
class CropRule {
  final String cropId;
  final String cropName;
  final int durationDays;
  final List<CropStage> stages;
  final List<CropTaskRule> tasks;
  final Map<String, double> soilModifiers;
  final String source;

  const CropRule({
    required this.cropId,
    required this.cropName,
    required this.durationDays,
    required this.stages,
    required this.tasks,
    required this.soilModifiers,
    required this.source,
  });

  factory CropRule.fromJson(Map<String, dynamic> json) {
    final stagesRaw = json['stages'] as List<dynamic>? ?? [];
    final tasksRaw = json['tasks'] as List<dynamic>? ?? [];
    final modifiersRaw = json['soilModifiers'] as Map<String, dynamic>? ?? {};

    return CropRule(
      cropId: json['cropId'] as String? ?? '',
      cropName: json['cropName'] as String? ?? '',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      stages: stagesRaw
          .map((e) => CropStage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      tasks: tasksRaw
          .map((e) => CropTaskRule.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      soilModifiers: modifiersRaw.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      source: json['source'] as String? ?? 'REPLACE WITH VERIFIED DATA',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropId': cropId,
      'cropName': cropName,
      'durationDays': durationDays,
      'stages': stages.map((s) => s.toMap()).toList(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'soilModifiers': soilModifiers,
      'source': source,
    };
  }
}
