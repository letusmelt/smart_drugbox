import 'dart:convert';

import 'package:smart_drugbox/period_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_drugbox/care.dart';
import 'package:smart_drugbox/medicine.dart';
import 'package:smart_drugbox/main.dart' show MedicineApp;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('app opens all three tabs without layout errors', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MedicineApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日用药').last);
    await tester.pumpAndSettle();
    expect(find.text('请在“处方”中设置每日提醒'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('用药记录').last);
    await tester.pumpAndSettle();
    expect(find.text('这一天没有用药安排记录'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('eight colored medicine rows never overlap on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = CareStore();
    await store.load();
    store.start = dayKey(DateTime.now());
    store.plan = List.generate(
      8,
      (i) => {
        'slot': i,
        'name': '测试药$i',
        'dose': '1片',
        'method': '口服',
        'times': [480, 720, 1080],
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TodayPage(store: store, active: true)),
      ),
    );
    await tester.pumpAndSettle();
    final tiles = find.byType(DoseTile);
    expect(tiles, findsNWidgets(8));
    for (var i = 0; i < 7; i++) {
      final a = tester.getRect(tiles.at(i));
      final b = tester.getRect(tiles.at(i + 1));
      expect(b.top - a.bottom, greaterThanOrEqualTo(15));
      expect(a.width, lessThanOrEqualTo(280));
    }
    final container = tester.widget<AnimatedContainer>(
      find
          .descendant(of: tiles.first, matching: find.byType(AnimatedContainer))
          .first,
    );
    expect(
      (container.decoration as BoxDecoration).color,
      isNot(const Color(0xFFE8E9EB)),
    );
    final titleTop = tester.getTopLeft(find.text('今日用药')).dy;
    final progressTop = tester.getTopLeft(find.text('吃药进度 0/0')).dy;
    final firstTileTop = tester.getTopLeft(tiles.first).dy;
    await tester.drag(tiles.first, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('今日用药')).dy, titleTop);
    expect(tester.getTopLeft(find.text('吃药进度 0/0')).dy, progressTop);
    expect(tester.getTopLeft(tiles.first).dy, lessThan(firstTileTop));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('period popup opens below its trigger and selects morning', (
    tester,
  ) async {
    int selected = 1080;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(top: 120, left: 20),
            child: StatefulBuilder(
              builder: (context, setState) => PeriodPicker(
                times: const [480, 720, 1080],
                selected: selected,
                onSelected: (time) => setState(() => selected = time),
              ),
            ),
          ),
        ),
      ),
    );
    final trigger = tester.getRect(find.text('晚上'));
    await tester.tap(find.text('晚上'));
    await tester.pumpAndSettle();
    expect(find.text('早上'), findsOneWidget);
    expect(find.text('中午'), findsOneWidget);
    expect(find.text('晚上'), findsNWidgets(2));
    expect(tester.getTopLeft(find.text('早上')).dy, greaterThan(trigger.bottom));
    await tester.tap(find.text('早上'));
    await tester.pumpAndSettle();
    expect(selected, 480);
    expect(find.text('早上'), findsOneWidget);
    expect(find.text('中午'), findsNothing);
  });
  test('only plain daily frequencies receive suggestions', () {
    expect(suggestedTimes('一日三次'), [480, 720, 1080]);
    expect(suggestedTimes('每日2次'), [480, 1080]);
    for (final f in ['每隔8小时', '必要时每日三次', '每日三次，逐日递减', '隔日一次', '待确认']) {
      expect(suggestedTimes(f), isEmpty);
    }
  });
  test(
    'daily events are unique, historical snapshots persist and undo survives reload',
    () async {
      final store = CareStore();
      await store.load();
      store.plan = [
        {
          'name': '测试药',
          'dose': '1片',
          'method': '口服',
          'slot': 0,
          'times': [480, 720, 1080],
        },
      ];
      store.start = '2026-01-01';
      store.end = '2026-01-02';
      store.created = DateTime(2026, 1, 1);
      store.revision = 'test';
      store.refresh(now: DateTime(2026, 1, 2, 19), save: false);
      expect(store.events.length, 6);
      store.refresh(now: DateTime(2026, 1, 3), save: false);
      expect(store.events.length, 6);
      final id = store.events.first['id'] as String;
      expect(await store.mark(id, true), isTrue);
      expect(store.events.where((e) => e['taken'] != null).length, 1);
      final restored = CareStore();
      await restored.load();
      expect(restored.events.first['taken'], isNotNull);
      expect(await restored.mark(id, false), isTrue);
      final again = CareStore();
      await again.load();
      expect(again.events.first['taken'], isNull);
      expect(
        again.events
            .where((e) => e['day'] == '2026-01-02')
            .every((e) => e['taken'] == null),
        isTrue,
      );
    },
  );
  test('does not manufacture missed doses before setup time', () async {
    final store = CareStore();
    await store.load();
    store.plan = [
      {
        'name': '测试药',
        'slot': 0,
        'times': [480, 1080],
      },
    ];
    store.start = '2026-01-01';
    store.created = DateTime(2026, 1, 1, 12);
    store.revision = 'test';
    store.refresh(now: DateTime(2026, 1, 1, 19), save: false);
    expect(store.events.length, 1);
    expect(store.events.single['minute'], 1080);
  });
  test(
    'updating a plan refreshes medicine details and preserves records',
    () async {
      final store = CareStore();
      await store.load();
      final now = DateTime.now();
      final today = dayKey(now);
      final due = DateTime(now.year, now.month, now.day, 0, 1);
      store.events = [
        {
          'id': 'old/$today/0/1',
          'day': today,
          'minute': 1,
          'due': due.toIso8601String(),
          'slot': 0,
          'times': [1],
          'name': '旧药名',
          'dose': '旧剂量',
          'method': '旧用法',
          'taken': now.toIso8601String(),
          'vitals': {'note': '正常'},
        },
      ];

      await store.setPlan(
        [
          {
            'slot': 0,
            'times': [1],
            'name': '新药名',
            'dose': '新剂量',
            'method': '新用法',
            'frequency': '每日一次',
          },
        ],
        DateTime(now.year, now.month, now.day),
        null,
      );

      expect(store.events.single['name'], '新药名');
      expect(store.events.single['dose'], '新剂量');
      expect(store.events.single['taken'], isNotNull);
      expect(store.events.single['vitals'], {'note': '正常'});
    },
  );
  test(
    'loading repairs stale historical events from the current plan',
    () async {
      final now = DateTime.now();
      final historicalDay = dayKey(now.subtract(const Duration(days: 2)));
      SharedPreferences.setMockInitialValues({
        'care.v1': jsonEncode({
          'prescription': [],
          'prescriptions': [],
          'plan': [
            {
              'slot': 0,
              'times': [1],
              'name': '已编辑药名',
              'dose': '新剂量',
              'method': '新用法',
            },
          ],
          'events': [
            {
              'id': 'old/$historicalDay/0/1',
              'day': historicalDay,
              'minute': 1,
              'due': DateTime(
                now.year,
                now.month,
                now.day - 2,
                0,
                1,
              ).toIso8601String(),
              'slot': 0,
              'times': [1],
              'name': '旧药名',
              'dose': '旧剂量',
              'method': '旧用法',
              'taken': null,
            },
          ],
          'start': historicalDay,
          'revision': 'old',
          'created': DateTime(now.year, now.month, now.day).toIso8601String(),
        }),
      });

      final store = CareStore();
      await store.load();

      final historicalEvent = store.events.singleWhere(
        (event) => event['day'] == historicalDay && event['minute'] == 1,
      );
      expect(historicalEvent['name'], '已编辑药名');
      expect(historicalEvent['dose'], '新剂量');
    },
  );
  test('prescription text persists without storing large photos', () async {
    final store = CareStore();
    await store.load();
    await store.savePrescription([
      Medicine('测试药', '1片', '一日三次', '饭后', sourceText: '原文'),
    ]);
    final restored = CareStore();
    await restored.load();
    expect(restored.prescription.single.sourceText, '原文');
  });
  testWidgets(
    'short tap speaks, incomplete hold cancels, full hold confirms once',
    (tester) async {
      int taps = 0, holds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              child: DoseTile(
                slot: 0,
                name: '测试药',
                dose: '1片',
                taken: false,
                scheduled: true,
                onTap: () => taps++,
                onHold: () => holds++,
              ),
            ),
          ),
        ),
      );
      final target = find.byType(DoseTile);
      await tester.tap(target);
      await tester.pump();
      expect(taps, 1);
      expect(holds, 0);
      var gesture = await tester.startGesture(tester.getCenter(target));
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.up();
      await tester.pump();
      expect(holds, 0);
      gesture = await tester.startGesture(tester.getCenter(target));
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump(const Duration(milliseconds: 700));
      expect(holds, 1);
      await gesture.up();
      await tester.pump();
      expect(taps, 1);
    },
  );
  testWidgets('large text still lays out in a narrow medicine card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 165,
                child: DoseTile(
                  slot: 0,
                  name: '较长的测试药品名称',
                  dose: '每次一片饭后服用',
                  taken: false,
                  scheduled: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
