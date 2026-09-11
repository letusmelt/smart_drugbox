import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_drugbox/main.dart';
import 'package:smart_drugbox/medicine.dart';

void main() {
  testWidgets('edit labels stay above fields on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          initial: [
            Medicine('测试药品名称较长', '10ml', '每日三次', '口服', sourceText: '测试原文'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(5));
    expect(
      tester.getBottomLeft(find.text('药品名称')).dy,
      lessThan(tester.getTopLeft(find.byType(TextField).first).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
