import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_drugbox/model_picker.dart';

void main() {
  testWidgets('model choice is displayed and persisted', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ModelPicker())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qwen3-VL-8B-Instruct'));
    await tester.pumpAndSettle();
    expect(recognitionModel.value, recognitionModels[1]);
    expect(find.text('识别模型 · Qwen3-VL-8B-Instruct'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('recognition.model'),
      recognitionModels[1],
    );
    expect(tester.takeException(), isNull);
  });
}
