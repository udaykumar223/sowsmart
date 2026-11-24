import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/domain/schedule_generator.dart';
import 'package:sowsmart/models/crop_rule.dart';

void main() {
  group('ScheduleGenerator Tests', () {
    late ScheduleGenerator generator;
    late CropRule sampleCrop;

    setUp(() {
      generator = ScheduleGenerator();
      sampleCrop = const CropRule(
        cropId: 'test_paddy',
        cropName: 'Paddy Test',
        durationDays: 120,
        stages: [
          CropStage(name: 'Nursery', startDay: 0, endDay: 20),
          CropStage(name: 'Tillering', startDay: 21, endDay: 60),
        ],
        tasks: [
          CropTaskRule(
            id: 'sow',
            stage: 'Nursery',
            type: 'other',
            title: 'Sowing Seeds',
            notes: 'Scatter seeds on nursery bed',
            startDay: 0,
          ),
          CropTaskRule(
            id: 'irrigate',
            stage: 'Nursery',
            type: 'irrigation',
            title: 'Nursery Irrigation',
            notes: 'Light watering',
            startDay: 2,
            repeatEveryDays: 4,
            endDay: 10,
          ),
          CropTaskRule(
            id: 'fert_tillering',
            stage: 'Tillering',
            type: 'fertilizer',
            title: 'Urea Top Dressing',
            notes: 'Apply 25kg/acre',
            startDay: 30,
          ),
        ],
        soilModifiers: {
          'clay': 1.25,
          'loamy': 1.0,
          'sandy': 0.75,
        },
        source: 'TEST SOURCE',
      );
    });

    test('Generates tasks with correct due dates for single and repeating rules', () {
      final sowingDate = DateTime(2026, 6, 1);
      final tasks = generator.generate(
        crop: sampleCrop,
        sowingDate: sowingDate,
        soilType: 'loamy',
      );

      // Sowing task (day 0) -> June 1
      // Irrigation (day 2, 6, 10) -> June 3, June 7, June 11
      // Fertilizer (day 30) -> July 1
      expect(tasks.length, equals(5));

      expect(tasks[0].title, equals('Sowing Seeds'));
      expect(tasks[0].dueDate, equals(DateTime(2026, 6, 1)));

      expect(tasks[1].title, equals('Nursery Irrigation'));
      expect(tasks[1].dueDate, equals(DateTime(2026, 6, 3)));

      expect(tasks[2].dueDate, equals(DateTime(2026, 6, 7)));
      expect(tasks[3].dueDate, equals(DateTime(2026, 6, 11)));

      expect(tasks[4].title, equals('Urea Top Dressing'));
      expect(tasks[4].dueDate, equals(DateTime(2026, 7, 1)));
    });

    test('Applies clay soil modifier to stretch irrigation intervals', () {
      final sowingDate = DateTime(2026, 6, 1);
      // For clay, interval = 4 * 1.25 = 5 days.
      // Days: 2, 7 (day 12 is > endDay 10, so only 2 irrigation tasks)
      final tasks = generator.generate(
        crop: sampleCrop,
        sowingDate: sowingDate,
        soilType: 'clay',
      );

      final irrigationTasks =
          tasks.where((t) => t.type == 'irrigation').toList();
      expect(irrigationTasks.length, equals(2));
      expect(irrigationTasks[0].dueDate, equals(DateTime(2026, 6, 3))); // day 2
      expect(irrigationTasks[1].dueDate, equals(DateTime(2026, 6, 8))); // day 2 + 5 = day 7
    });

    test('Applies sandy soil modifier to shorten irrigation intervals', () {
      final sowingDate = DateTime(2026, 6, 1);
      // For sandy, interval = round(4 * 0.75) = 3 days.
      // Days: 2, 5, 8 (next would be 11 > 10, so 3 tasks)
      final tasks = generator.generate(
        crop: sampleCrop,
        sowingDate: sowingDate,
        soilType: 'sandy',
      );

      final irrigationTasks =
          tasks.where((t) => t.type == 'irrigation').toList();
      expect(irrigationTasks.length, equals(3));
      expect(irrigationTasks[0].dueDate, equals(DateTime(2026, 6, 3))); // day 2
      expect(irrigationTasks[1].dueDate, equals(DateTime(2026, 6, 6))); // day 5
      expect(irrigationTasks[2].dueDate, equals(DateTime(2026, 6, 9))); // day 8
    });

    test('Handles leap year transition correctly', () {
      // Leap year 2028: Feb has 29 days
      final sowingDate = DateTime(2028, 2, 27);
      final tasks = generator.generate(
        crop: sampleCrop,
        sowingDate: sowingDate,
        soilType: 'loamy',
      );

      // day 0: Feb 27
      expect(tasks[0].dueDate, equals(DateTime(2028, 2, 27)));
      // day 2: Feb 29 (leap day!)
      expect(tasks[1].dueDate, equals(DateTime(2028, 2, 29)));
      // day 6: Mar 4 (Feb 27 + 6 days = Mar 4 in leap year)
      expect(tasks[2].dueDate, equals(DateTime(2028, 3, 4)));
    });

    test('Calculates expected harvest date accurately', () {
      final sowingDate = DateTime(2026, 1, 1);
      final harvestDate =
          generator.calculateExpectedHarvestDate(sowingDate, 120);

      // 120 days from Jan 1, 2026 (non-leap year: 31 + 28 + 31 + 30 = 120 -> May 1)
      expect(harvestDate, equals(DateTime(2026, 5, 1)));
    });

    test('Handles unknown soil type with 1.0 default fallback multiplier', () {
      final sowingDate = DateTime(2026, 3, 1);
      final tasks = generator.generate(
        crop: sampleCrop,
        sowingDate: sowingDate,
        soilType: 'unknown_black_cotton',
      );

      final irrigationTasks =
          tasks.where((t) => t.type == 'irrigation').toList();
      // Uses 4-day interval: day 2, 6, 10
      expect(irrigationTasks.length, equals(3));
    });
  });
}
