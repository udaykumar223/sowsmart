/// Represents a specific crop cultivation cycle on a designated field.
/// Pure Dart model without framework dependencies.
class Planting {
  final String id;
  final String fieldId;
  final String cropId;
  final String cropName;
  final DateTime sowingDate;
  final String seasonLabel; // e.g., 'Kharif 2026', 'Rabi 2026'
  final String status; // 'active', 'harvested', 'cancelled'
  final DateTime expectedHarvestDate;
  final DateTime? harvestDate;
  final double? yieldQty;
  final String? yieldUnit; // 'kg', 'quintals', 'tons'
  final DateTime createdAt;

  const Planting({
    required this.id,
    required this.fieldId,
    required this.cropId,
    required this.cropName,
    required this.sowingDate,
    required this.seasonLabel,
    required this.status,
    required this.expectedHarvestDate,
    this.harvestDate,
    this.yieldQty,
    this.yieldUnit,
    required this.createdAt,
  });

  factory Planting.fromJson(Map<String, dynamic> json, [String? id]) {
    return Planting(
      id: id ?? json['id'] as String? ?? '',
      fieldId: json['fieldId'] as String? ?? '',
      cropId: json['cropId'] as String? ?? '',
      cropName: json['cropName'] as String? ?? '',
      sowingDate: json['sowingDate'] != null
          ? DateTime.tryParse(json['sowingDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      seasonLabel: json['seasonLabel'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      expectedHarvestDate: json['expectedHarvestDate'] != null
          ? DateTime.tryParse(json['expectedHarvestDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      harvestDate: json['harvestDate'] != null
          ? DateTime.tryParse(json['harvestDate'].toString())
          : null,
      yieldQty: (json['yieldQty'] as num?)?.toDouble(),
      yieldUnit: json['yieldUnit'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'cropId': cropId,
      'cropName': cropName,
      'sowingDate': sowingDate.toIso8601String(),
      'seasonLabel': seasonLabel,
      'status': status,
      'expectedHarvestDate': expectedHarvestDate.toIso8601String(),
      'harvestDate': harvestDate?.toIso8601String(),
      'yieldQty': yieldQty,
      'yieldUnit': yieldUnit,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Planting copyWith({
    String? id,
    String? fieldId,
    String? cropId,
    String? cropName,
    DateTime? sowingDate,
    String? seasonLabel,
    String? status,
    DateTime? expectedHarvestDate,
    DateTime? harvestDate,
    double? yieldQty,
    String? yieldUnit,
    DateTime? createdAt,
  }) {
    return Planting(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      sowingDate: sowingDate ?? this.sowingDate,
      seasonLabel: seasonLabel ?? this.seasonLabel,
      status: status ?? this.status,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
      harvestDate: harvestDate ?? this.harvestDate,
      yieldQty: yieldQty ?? this.yieldQty,
      yieldUnit: yieldUnit ?? this.yieldUnit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
