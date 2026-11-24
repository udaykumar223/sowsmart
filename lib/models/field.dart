/// Represents a farmer's agricultural plot or field.
/// Pure Dart model without framework dependencies.
class Field {
  final String id;
  final String name;
  final double areaAcres;
  final String soilType; // 'clay', 'loamy', 'sandy'
  final double lat;
  final double lon;
  final DateTime createdAt;

  const Field({
    required this.id,
    required this.name,
    required this.areaAcres,
    required this.soilType,
    required this.lat,
    required this.lon,
    required this.createdAt,
  });

  factory Field.fromJson(Map<String, dynamic> json, [String? id]) {
    return Field(
      id: id ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      areaAcres: (json['areaAcres'] as num?)?.toDouble() ?? 0.0,
      soilType: json['soilType'] as String? ?? 'loamy',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'areaAcres': areaAcres,
      'soilType': soilType,
      'lat': lat,
      'lon': lon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Field copyWith({
    String? id,
    String? name,
    double? areaAcres,
    String? soilType,
    double? lat,
    double? lon,
    DateTime? createdAt,
  }) {
    return Field(
      id: id ?? this.id,
      name: name ?? this.name,
      areaAcres: areaAcres ?? this.areaAcres,
      soilType: soilType ?? this.soilType,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Field &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          areaAcres == other.areaAcres &&
          soilType == other.soilType &&
          lat == other.lat &&
          lon == other.lon;

  @override
  int get hashCode => Object.hash(id, name, areaAcres, soilType, lat, lon);
}
