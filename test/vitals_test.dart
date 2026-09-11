import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_drugbox/care_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('vitals persist across undo and reload', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CareStore();
    await store.load();
    store.events = [
      {'id': 'test', 'taken': null},
    ];
    await store.mark('test', true);
    expect(store.events.single['taken'], isNotNull);
    await store.saveVitals('test', {'temperature': '36.5', 'note': '记录'});
    await store.mark('test', false);
    final restored = CareStore();
    await restored.load();
    expect(restored.events.single['taken'], isNull);
    expect(restored.events.single['vitals']['temperature'], '36.5');
    await restored.mark('test', true);
    expect(restored.events.single['taken'], isNotNull);
  });
}
