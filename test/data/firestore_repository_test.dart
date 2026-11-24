import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/data/firestore_repository.dart';
import 'package:sowsmart/domain/schedule_generator.dart';
import 'package:sowsmart/models/crop_rule.dart';
import 'package:sowsmart/models/field.dart';
import 'package:sowsmart/models/planting.dart';

void main() {
  group('FirestoreRepository Tests (Acceptance: Creating planting creates right number of dated tasks)', () {
    late InMemoryFirestoreRepository repo;
    late ScheduleGenerator generator;
    const testUid = 'user_test_42';

    setUp(() {
      repo = InMemoryFirestoreRepository();
      generator = ScheduleGenerator();
    });

    test('Field CRUD operations work correctly in repository', () async {
      final field = Field(
        id: 'f1',
        name: 'North Acre',
        areaAcres: 2.0,
        soilType: 'clay',
        lat: 11.0,
        lon: 76.0,
        createdAt: DateTime(2026, 6, 1),
      );

      // Add field
      await repo.addField(testUid, field);
      var fields = await repo.getFields(testUid);
      expect(fields.length, equals(1));
      expect(fields.first.name, equals('North Acre'));

      // Update field
      final updatedField = field.copyWith(name: 'North Acre Renamed');
      await repo.updateField(testUid, updatedField);
      fields = await repo.getFields(testUid);
      expect(fields.first.name, equals('North Acre Renamed'));

      // Delete field
      await repo.deleteField(testUid, 'f1');
      fields = await repo.getFields(testUid);
      expect(fields, isEmpty);
    });

    test('Creating a planting with generated tasks creates the right number of dated tasks atomically', () async {
      const crop = CropRule(
        cropId: 'tomato_test',
        cropName: 'Tomato Test',
        durationDays: 135,
        stages: [
          CropStage(name: 'Vegetative', startDay: 0, endDay: 30),
          CropStage(name: 'Flowering', startDay: 31, endDay: 70),
        ],
        tasks: [
          CropTaskRule(
            id: 'irr',
            stage: 'Vegetative',
            type: 'irrigation',
            title: 'Watering',
            notes: '',
            startDay: 5,
            repeatEveryDays: 5,
            endDay: 20, // days 5, 10, 15, 20 -> 4 tasks
          ),
          CropTaskRule(
            id: 'spray',
            stage: 'Flowering',
            type: 'spray',
            title: 'Spray',
            notes: '',
            startDay: 40, // 1 task
          ),
        ],
        soilModifiers: {'loamy': 1.0},
        source: 'TEST',
      );

      final sowingDate = DateTime(2026, 6, 1);
      final tasks = generator.generate(
        crop: crop,
        sowingDate: sowingDate,
        soilType: 'loamy',
        plantingId: 'p_101',
      );

      // Verify generator created 4 irrigation tasks + 1 spray task = 5 tasks
      expect(tasks.length, equals(5));

      final planting = Planting(
        id: 'p_101',
        fieldId: 'f1',
        cropId: crop.cropId,
        cropName: crop.cropName,
        sowingDate: sowingDate,
        seasonLabel: 'Kharif 2026',
        status: 'active',
        expectedHarvestDate: sowingDate.add(const Duration(days: 135)),
        createdAt: DateTime.now(),
      );

      // Save planting and tasks in batched write
      await repo.createPlantingWithTasks(testUid, planting, tasks);

      // Retrieve planting
      final savedPlanting = await repo.getPlanting(testUid, 'p_101');
      expect(savedPlanting, isNotNull);
      expect(savedPlanting!.cropName, equals('Tomato Test'));

      // Retrieve saved tasks from repository
      final savedTasks = await repo.getPlantingTasks(testUid, 'p_101');
      expect(savedTasks.length, equals(5));

      // Verify each task has a correct, chronologically ordered due date
      expect(savedTasks[0].dueDate, equals(DateTime(2026, 6, 6))); // day 5
      expect(savedTasks[1].dueDate, equals(DateTime(2026, 6, 11))); // day 10
      expect(savedTasks[2].dueDate, equals(DateTime(2026, 6, 16))); // day 15
      expect(savedTasks[3].dueDate, equals(DateTime(2026, 6, 21))); // day 20
      expect(savedTasks[4].dueDate, equals(DateTime(2026, 7, 11))); // day 40 (July 11)
    });
  });
}
