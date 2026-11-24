import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/models/field.dart';
import 'package:sowsmart/models/planting.dart';
import 'package:sowsmart/models/task_item.dart';
import 'package:sowsmart/models/transaction.dart';
import 'package:sowsmart/models/crop_rule.dart';

void main() {
  group('Models Serialization and Deserialization Tests', () {
    test('Field toMap and fromJson round-trip', () {
      final field = Field(
        id: 'f_101',
        name: 'South Field',
        areaAcres: 3.5,
        soilType: 'clay',
        lat: 11.0168,
        lon: 76.9558,
        createdAt: DateTime(2026, 3, 15, 10, 0),
      );

      final map = field.toMap();
      final revived = Field.fromJson(map);

      expect(revived.id, equals(field.id));
      expect(revived.name, equals('South Field'));
      expect(revived.areaAcres, equals(3.5));
      expect(revived.soilType, equals('clay'));
      expect(revived.lat, equals(11.0168));
      expect(revived.lon, equals(76.9558));
    });

    test('Planting toMap and fromJson round-trip', () {
      final planting = Planting(
        id: 'p_202',
        fieldId: 'f_101',
        cropId: 'paddy_ir20',
        cropName: 'Paddy (IR 20)',
        sowingDate: DateTime(2026, 6, 1),
        seasonLabel: 'Kharif 2026',
        status: 'active',
        expectedHarvestDate: DateTime(2026, 9, 30),
        harvestDate: null,
        yieldQty: null,
        yieldUnit: 'quintals',
        createdAt: DateTime(2026, 6, 1, 8, 30),
      );

      final map = planting.toMap();
      final revived = Planting.fromJson(map);

      expect(revived.id, equals('p_202'));
      expect(revived.cropName, equals('Paddy (IR 20)'));
      expect(revived.status, equals('active'));
      expect(revived.sowingDate, equals(planting.sowingDate));
    });

    test('TaskItem toMap and fromJson round-trip', () {
      final task = TaskItem(
        id: 't_303',
        plantingId: 'p_202',
        ruleId: 'irr_1',
        type: 'irrigation',
        title: 'Nursery Irrigation',
        notes: 'Water evenly',
        stage: 'Nursery',
        dueDate: DateTime(2026, 6, 5),
        originalDueDate: DateTime(2026, 6, 3),
        status: 'postponed',
        completedAt: null,
      );

      final map = task.toMap();
      final revived = TaskItem.fromJson(map);

      expect(revived.id, equals('t_303'));
      expect(revived.type, equals('irrigation'));
      expect(revived.status, equals('postponed'));
      expect(revived.originalDueDate, equals(DateTime(2026, 6, 3)));
    });

    test('Transaction toMap and fromJson round-trip', () {
      final tx = Transaction(
        id: 'tx_404',
        plantingId: 'p_202',
        fieldId: 'f_101',
        kind: 'expense',
        category: 'fertilizer',
        amount: 3200.0,
        date: DateTime(2026, 6, 25),
        note: 'Purchased Urea & Potash',
      );

      final map = tx.toMap();
      final revived = Transaction.fromJson(map);

      expect(revived.id, equals('tx_404'));
      expect(revived.kind, equals('expense'));
      expect(revived.amount, equals(3200.0));
      expect(revived.note, equals('Purchased Urea & Potash'));
    });

    test('CropRule toMap and fromJson parses stages, tasks, and modifiers', () {
      final json = {
        'cropId': 'tomato_hybrid',
        'cropName': 'Tomato (Hybrid)',
        'durationDays': 135,
        'stages': [
          {'name': 'Vegetative', 'startDay': 0, 'endDay': 45},
          {'name': 'Flowering', 'startDay': 46, 'endDay': 90},
        ],
        'tasks': [
          {
            'id': 'irr_1',
            'stage': 'Vegetative',
            'type': 'irrigation',
            'title': 'Drip Irrigation',
            'notes': 'Daily drip',
            'startDay': 1,
            'repeatEveryDays': 2,
            'endDay': 45
          }
        ],
        'soilModifiers': {'sandy': 0.8, 'clay': 1.2},
        'source': 'REPLACE WITH VERIFIED DATA - TNAU'
      };

      final crop = CropRule.fromJson(json);

      expect(crop.cropId, equals('tomato_hybrid'));
      expect(crop.durationDays, equals(135));
      expect(crop.stages.length, equals(2));
      expect(crop.tasks.first.repeatEveryDays, equals(2));
      expect(crop.soilModifiers['sandy'], equals(0.8));
      expect(crop.source, contains('REPLACE WITH VERIFIED DATA'));
    });
  });
}
