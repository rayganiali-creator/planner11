import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/avatar_ops.dart';
import 'package:routine_planner/features/avatar/avatar_compose.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('خرید/پوشیدن/درآوردن/سازگاری جنسیت/لباس یک‌تکه و شلوار', () async {
    final data = await AvData.load();
    final dir = Directory.systemTemp.createTempSync('rp_av');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus());
    a.chooseGender('male');
    expect(a.avState().gender, 'male');
    final top = data.items['clothes/top_01']!; // ۸۰۰ سکه
    expect(a.avAction(data, top, armed: false), 'pro'); // بدون پرو
    store.state['isPremium'] = true;
    (store.state['scores'] as Map)['coins'] = 100;
    expect(a.avAction(data, top, armed: false), 'armed');
    expect(a.avAction(data, top, armed: true), 'nocoins'); // سکه کم
    (store.state['scores'] as Map)['coins'] = 1000;
    expect(a.avAction(data, top, armed: false), 'armed');
    expect(a.avAction(data, top, armed: true), 'bought');
    expect((store.state['scores'] as Map)['coins'], 200);
    expect(a.avState().equippedOf('male')['clothes'], 'clothes/top_01');
    expect(a.avAction(data, top, armed: false), 'unequipped'); // پوشیده: درآوردن
    expect(a.avState().equippedOf('male').containsKey('clothes'), isFalse);
    expect(a.avAction(data, top, armed: false), 'equipped'); // خریداری‌شده: بدون هزینه
    expect((store.state['scores'] as Map)['coins'], 200);
    // لباس یک‌تکه شلوار را برمی‌دارد
    a.avState().equippedOf('male')['pants'] = 'pants/pants_01';
    a.avState().owned['clothes/om_01'] = true;
    a.avEquip(data, data.items['clothes/om_01']!);
    expect(a.avState().equippedOf('male').containsKey('pants'), isFalse);
    // ناسازگار با جنسیت پوشیده نمی‌شود
    a.avState().owned['clothes/ow_01'] = true;
    a.avEquip(data, data.items['clothes/ow_01']!);
    expect(a.avState().equippedOf('male')['clothes'], 'clothes/om_01');
    // تغییر جنسیت: کمد جدا
    a.switchGender('female');
    expect(a.avState().equippedOf('female').isEmpty, isTrue);
    expect(data.equippedFor(store.state, 'male')['clothes'], 'clothes/om_01'); // پرو هست
    store.state['isPremium'] = false;
    expect(data.equippedFor(store.state, 'male').containsKey('clothes'), isFalse); // بدون پرو نمایش داده نمی‌شود، خرید می‌ماند
    expect(a.avState().owned['clothes/om_01'], true);
    // مدل پایه رایگان
    a.switchGender('male');
    expect(a.avAction(data, data.items['base/male_2']!, armed: false), 'equipped');
    expect(a.baseIdFor(data, 'male'), 'base/male_2');
  });

}
