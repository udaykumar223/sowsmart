import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/data/firestore_repository.dart';
import 'package:sowsmart/domain/schedule_generator.dart';
import 'package:sowsmart/models/crop_rule.dart';
import 'package:sowsmart/state/fields_state.dart';
import 'package:sowsmart/state/plantings_state.dart';

void main() {
  group('FieldsState and PlantingsState Tests', () {
    late InMemoryFirestoreRepository repo;
    late ScheduleGenerator generator;
    const testUid = 'user_state_test';

    setUp(() {
      repo = InMemoryFirestoreRepository();
      generator = ScheduleGenerator();
    });

    test('FieldsState adds field and emits non-empty list', () async {
      final state = FieldsState(repo, testUid);

      final success = await state.addField(
        name: 'South Field',
        areaAcres: 3.0,
        soilType: 'clay',
        lat: 12.9716,
        lon: 77.5946,
      );

      expect(success, isTrue);
      expect(state.fields.length, equals(1));
      expect(state.fields.first.name, equals('South Field'));
      expect(state.isEmpty, isFalse);
    });

    test('PlantingsState generates preview and writes planting with tasks', () async {
      final plantingsState = PlantingsState(repo, generator, testUid);

      const testCrop = CropRule(
        cropId: 'paddy_test',
        cropName: 'Paddy',
        durationDays: 100,
        stages: [CropStage(name: 'Main', startDay: 0, endDay: 100)],
        tasks: [
          CropTaskRule(
            id: 't1',
            stage: 'Main',
            type: 'irrigation',
            title: 'Watering',
            notes: '',
            startDay: 10,
          ),
        ],
        soilModifiers: {'loamy': 1.0},
        source: 'TEST',
      );

      // Verify schedule preview
      final preview = plantingsState.previewSchedule(
        crop: testCrop,
        sowingDate: DateTime(2026, 5, 1),
        soilType: 'loamy',
      );
      expect(preview.length, equals(1));
      expect(preview.first.title, equals('Watering'));

      // Create planting
      final created = await plantingsState.createPlantingWithGeneratedSchedule(
        fieldId: 'f1',
        crop: testCrop,
        sowingDate: DateTime(2026, 5, 1),
        seasonLabel: 'Kharif 2026',
        soilType: 'loamy',
      );

      expect(created, isTrue);
      expect(plantingsState.plantings.length, equals(1));
      expect(plantingsState.plantings.first.cropName, equals('Paddy'));
    });
  });
}
