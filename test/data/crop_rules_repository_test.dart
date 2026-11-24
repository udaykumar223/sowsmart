import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/data/crop_rules_repository.dart';

void main() {
  group('CropRulesRepository and assets/crop_rules.json Tests', () {
    test('assets/crop_rules.json loads and parses all 3 crops with valid schema', () async {
      final file = File('assets/crop_rules.json');
      expect(await file.exists(), isTrue,
          reason: 'assets/crop_rules.json must exist in project root');

      final repo = StaticCropRulesRepository(
        jsonLoader: () async => await file.readAsString(),
      );

      final crops = await repo.getAllCrops();

      // Must have at least 3 crops as per blueprint
      expect(crops.length, greaterThanOrEqualTo(3));

      for (final crop in crops) {
        expect(crop.cropId, isNotEmpty);
        expect(crop.cropName, isNotEmpty);
        expect(crop.durationDays, greaterThan(0));
        expect(crop.stages, isNotEmpty);
        expect(crop.tasks, isNotEmpty);
        expect(crop.source, contains('REPLACE WITH VERIFIED DATA'),
            reason: 'All placeholder data must be clearly marked as per blueprint');
      }

      // Verify specific crops can be fetched by ID
      final paddy = await repo.getCropById('paddy_ir20');
      expect(paddy, isNotNull);
      expect(paddy!.cropName, contains('Paddy'));

      final tomato = await repo.getCropById('tomato_hybrid');
      expect(tomato, isNotNull);
      expect(tomato!.durationDays, equals(135));

      final banana = await repo.getCropById('banana_grand_naine');
      expect(banana, isNotNull);
      expect(banana!.durationDays, equals(330));
    });

    test('getCropById returns null for unknown crop ID', () async {
      final repo = StaticCropRulesRepository(
        jsonLoader: () async => '[]',
      );

      final crop = await repo.getCropById('unknown_crop_99');
      expect(crop, isNull);
    });
  });
}
