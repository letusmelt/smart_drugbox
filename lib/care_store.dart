import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'medicine.dart';

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String clockText(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
const boxNames = ['浅绿色', '翠绿色', '深青色', '天蓝色', '蓝紫色', '深紫色', '青绿色', '浅蓝紫色'];
Map<String, dynamic> medicineJson(Medicine m) => {
  'name': m.name,
  'dose': m.dose,
  'frequency': m.frequency,
  'method': m.method,
  'specification': m.specification,
  'sourceText': m.sourceText,
  'warnings': m.warnings,
};
Medicine readMedicine(Map<String, dynamic> j) => Medicine(
  j['name'],
  j['dose'],
  j['frequency'],
  j['method'],
  specification: j['specification'] ?? '待确认',
  sourceText: j['sourceText'] ?? '',
  warnings: j['warnings'] ?? '',
);
List<int> suggestedTimes(String frequency) {
  final f = frequency.replaceAll(' ', '');
  // Interval, conditional and tapering directions require manual scheduling.
  if (RegExp(r'小时|必要|需要|隔日|每周|递|隔天').hasMatch(f)) return [];
  if (RegExp(r'^(每日|一日|一天|每天)(3|三)次$').hasMatch(f)) return [480, 720, 1080];
  if (RegExp(r'^(每日|一日|一天|每天)(2|二|两)次$').hasMatch(f)) return [480, 1080];
  if (RegExp(r'^(每日|一日|一天|每天)(1|一)次$').hasMatch(f)) return [480];
  return [];
}

class CareStore extends ChangeNotifier {
  List<Medicine> prescription = [];
  List<Map<String, dynamic>> prescriptions = [];
  String? selectedPrescriptionId;
  List<Map<String, dynamic>> plan = [];
  List<Map<String, dynamic>> events = [];
  String? start, end, revision;
  DateTime? created;
  bool ready = false;
  bool loadFailed = false;
  String? error;
  Future<void> _writes = Future.value();
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('care.v1');
      if (raw != null) {
        final data = jsonDecode(raw);
        prescription = (data['prescription'] as List)
            .map((m) => readMedicine(Map<String, dynamic>.from(m)))
            .toList();
        prescriptions = (data['prescriptions'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        selectedPrescriptionId = data['selectedPrescriptionId'];
        if (!data.containsKey('prescriptions') && prescription.isNotEmpty) {
          selectedPrescriptionId = 'legacy';
          prescriptions = [
            {
              'id': 'legacy',
              'date': null,
              'medicines': prescription.map(medicineJson).toList(),
            },
          ];
        }
        plan = (data['plan'] as List)
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        events = (data['events'] as List)
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        start = data['start'];
        end = data['end'];
        revision = data['revision'];
        created = DateTime.tryParse(data['created'] ?? '');
      }
      refresh();
    } catch (_) {
      loadFailed = true;
      error = '本机数据读取失败，请勿继续设置，先重新打开页面。';
    }
    ready = true;
    notifyListeners();
  }

  Future<bool> persist() {
    if (loadFailed) return Future.value(false);
    final encoded = jsonEncode({
      'prescription': prescription.map(medicineJson).toList(),
      'prescriptions': prescriptions,
      'selectedPrescriptionId': selectedPrescriptionId,
      'plan': plan,
      'events': events,
      'start': start,
      'end': end,
      'revision': revision,
      'created': created?.toIso8601String(),
    });
    final result = _writes.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setString('care.v1', encoded)) {
          throw StateError('write');
        }
        error = null;
        notifyListeners();
        return true;
      } catch (_) {
        error = '本机保存失败，请检查浏览器存储空间；当前操作可能无法保留。';
        notifyListeners();
        return false;
      }
    });
    _writes = result.then((_) {});
    return result;
  }

  Future<bool> savePrescription(
    List<Medicine> values, {
    String? id,
    DateTime? date,
  }) async {
    final oldRows = List<Map<String, dynamic>>.from(prescriptions);
    final old = prescription;
    final oldId = selectedPrescriptionId;
    final key = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final index = prescriptions.indexWhere((p) => p['id'] == key);
    final row = {
      'id': key,
      'date':
          date?.toIso8601String() ??
          (index >= 0
              ? prescriptions[index]['date']
              : DateTime.now().toIso8601String()),
      'medicines': values.map(medicineJson).toList(),
    };
    if (index >= 0) {
      prescriptions[index] = row;
    } else {
      prescriptions.insert(0, row);
    }
    selectedPrescriptionId = key;
    prescription = values.map((m) => m.copy()).toList();
    if (await persist()) return true;
    prescriptions = oldRows;
    prescription = old;
    selectedPrescriptionId = oldId;
    notifyListeners();
    return false;
  }

  Future<bool> deletePrescription(String id) async {
    final oldRows = List<Map<String, dynamic>>.from(prescriptions);
    final old = prescription;
    final oldId = selectedPrescriptionId;
    prescriptions.removeWhere((p) => p['id'] == id);
    if (selectedPrescriptionId == id) {
      prescription = [];
      selectedPrescriptionId = null;
    }
    if (await persist()) return true;
    prescriptions = oldRows;
    prescription = old;
    selectedPrescriptionId = oldId;
    notifyListeners();
    return false;
  }

  Future<bool> setPlan(
    List<Map<String, dynamic>> rows,
    DateTime from,
    DateTime? until,
  ) async {
    final now = DateTime.now();
    // Keep historical snapshots, remove only future pending items of the replaced plan.
    events.removeWhere(
      (e) => e['taken'] == null && DateTime.parse(e['due']).isAfter(now),
    );
    plan = rows;
    start = dayKey(from);
    end = until == null ? null : dayKey(until);
    created = now;
    revision = now.microsecondsSinceEpoch.toString();
    refresh(now: now, save: false);
    notifyListeners();
    return persist();
  }

  void refresh({DateTime? now, bool save = true}) {
    now ??= DateTime.now();
    if (start == null || revision == null) return;
    var day = DateTime.parse(start!);
    final today = DateTime(now.year, now.month, now.day);
    final last = end == null
        ? today
        : DateTime.parse(end!).isBefore(today)
        ? DateTime.parse(end!)
        : today;
    final keys = events.map((e) => e['id']).toSet();
    bool changed = false;
    while (!day.isAfter(last)) {
      for (final row in plan) {
        for (final time in (row['times'] as List).cast<int>()) {
          final due = DateTime(
            day.year,
            day.month,
            day.day,
            time ~/ 60,
            time % 60,
          );
          if (created != null && due.isBefore(created!)) continue;
          final id = '$revision/${dayKey(day)}/${row['slot']}/$time';
          if (keys.add(id)) {
            events.add({
              ...row,
              'id': id,
              'day': dayKey(day),
              'minute': time,
              'due': due.toIso8601String(),
              'taken': null,
            });
            changed = true;
          }
        }
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    if (changed) {
      notifyListeners();
      if (save) persist();
    }
  }

  Future<bool> saveVitals(String id, Map<String, String> values) async {
    final event = events.firstWhere((e) => e['id'] == id);
    final old = event['vitals'];
    event['vitals'] = {
      ...values,
      'recordedAt': DateTime.now().toIso8601String(),
    };
    if (await persist()) return true;
    if (old == null) {
      event.remove('vitals');
    } else {
      event['vitals'] = old;
    }
    notifyListeners();
    return false;
  }

  Future<bool> mark(String id, bool taken) async {
    final e = events.firstWhere((e) => e['id'] == id);
    if (taken && e['taken'] != null) return true;
    final old = e['taken'];
    e['taken'] = taken ? DateTime.now().toIso8601String() : null;
    notifyListeners();
    if (await persist()) return true;
    e['taken'] = old;
    notifyListeners();
    return false;
  }
}
