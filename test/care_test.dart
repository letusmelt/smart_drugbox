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
    await tester.pumpWidget(
      MaterialApp(home: TodayPage(store: store, active: true)),
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
    final trigger = tester.getRect(find.text('晚上 · 18:00'));
    await tester.tap(find.text('晚上 · 18:00'));
    await tester.pumpAndSettle();
    expect(find.text('早上'), findsOneWidget);
    expect(find.text('中午'), findsOneWidget);
    expect(find.text('晚上'), findsOneWidget);
    expect(tester.getTopLeft(find.text('早上')).dy, greaterThan(trigger.bottom));
    await tester.tap(find.text('早上'));
    await tester.pumpAndSettle();
    expect(selected, 480);
    expect(find.text('早上 · 08:00'), findsOneWidget);
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
