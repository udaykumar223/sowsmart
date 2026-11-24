import 'dart:convert';
import '../models/crop_rule.dart';

/// Abstract contract for fetching crop rules and templates.
abstract class CropRulesRepository {
  Future<List<CropRule>> getAllCrops();
  Future<CropRule?> getCropById(String cropId);
}

/// In-memory or JSON-string driven implementation of CropRulesRepository.
/// Keeps data access decoupled from Flutter AssetBundle for fast pure Dart tests.
class StaticCropRulesRepository implements CropRulesRepository {
  final Future<String> Function() _jsonLoader;
  List<CropRule>? _cachedCrops;

  StaticCropRulesRepository({required Future<String> Function() jsonLoader})
      : _jsonLoader = jsonLoader;

  @override
  Future<List<CropRule>> getAllCrops() async {
    if (_cachedCrops != null) {
      return _cachedCrops!;
    }

    final jsonString = await _jsonLoader();
    final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;

    _cachedCrops = decoded
        .map((e) => CropRule.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return _cachedCrops!;
  }

  @override
  Future<CropRule?> getCropById(String cropId) async {
    final crops = await getAllCrops();
    try {
      return crops.firstWhere((c) => c.cropId == cropId);
    } catch (_) {
      return null;
    }
  }
}
