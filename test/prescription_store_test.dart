import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_drugbox/care_store.dart';
import 'package:smart_drugbox/medicine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'migrates old prescription and retains dated entries after reload and delete',
    () async {
      final old = Medicine('旧处方药品', '1片', '每日一次', '口服');
      SharedPreferences.setMockInitialValues({
        'care.v1': jsonEncode({
          'prescription': [medicineJson(old)],
          'plan': [],
          'events': [],
        }),
      });
      final store = CareStore();
      await store.load();
      expect(store.prescriptions.single['id'], 'legacy');
      expect(store.prescriptions.single['date'], isNull);
      await store.savePrescription([
        Medicine('新处方药品', '2片', '每日一次', '口服'),
      ], date: DateTime(2026, 9, 1));
      final id = store.selectedPrescriptionId!;
      await store.savePrescription([
        Medicine('修改药品', '2片', '每日一次', '口服'),
      ], id: id);
      expect(store.prescriptions.length, 2);
      final restored = CareStore();
      await restored.load();
      expect(restored.prescriptions.length, 2);
      expect(
        restored.prescriptions.first['date'],
        DateTime(2026, 9, 1).toIso8601String(),
      );
      await restored.deletePrescription('legacy');
      expect(restored.prescription.single.name, '修改药品');
      await restored.deletePrescription(id);
      final empty = CareStore();
      await empty.load();
      expect(empty.prescriptions, isEmpty);
      expect(empty.prescription, isEmpty);
    },
  );
}
