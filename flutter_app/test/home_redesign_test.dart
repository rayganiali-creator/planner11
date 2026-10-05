import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/avatar_ops.dart';
import 'package:routine_planner/features/avatar/avatar_compose.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AvData data;
  setUpAll(() async => data = await AvData.load());

  Future<(AppStore, AppActions, String)> boot(WidgetTester tester, {int hour = 12, bool gender = true}) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_home');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/s.json';
    final store = AppStore(path)..load();
    final a = AppActions(store, ToastBus(), clock: () => DateTime(2025, 3, 10, hour, 30));
    if (gender) a.chooseGender('female');
    store.state['habits'] = [
      {'id': 'h1', 'name': 'Salavat', 'type': 'numeric', 'numericTarget': 100, 'numericUnit': 'x', 'reward': 10, 'direction': 'more', 'permanent': true, 'start': '2025-01-01'},
      {'id': 'h2', 'name': 'Run', 'type': 'binary', 'reward': 10, 'permanent': true, 'start': '2025-01-01'},
    ];
    await tester.pumpWidget(RoutineApp(store: store, nav: NavController(), toasts: a.toasts, actions: a, avData: data));
    await tester.pump(const Duration(milliseconds: 500));
    return (store, a, path);
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('خانه: ثبتِ مستقیمِ مقدار برای عادت عددی (و عادت دوحالتی مثل قبل)', (tester) async {
    final (store, _, _) = await boot(tester);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('value-h1')), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 300));
    // دکمه‌های عادت دوحالتی هنوز هستند
    expect(find.byKey(const ValueKey('value-h2')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('value-h1')), '۲۵'); // رقم فارسی هم پذیرفته می‌شود
    await tester.tap(find.byKey(const ValueKey('save-h1')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('رد شدن')); // پنجره‌ی «چرا؟» (۲۵ از ۱۰۰ = ناموفق)
    await tester.pump(const Duration(milliseconds: 500));
    final rec = ((store.state['records'] as Map).values.first as Map)['h1'] as Map;
    expect(rec['value'], '25'); // مثل JS رشته
    expect(rec['targetAtTime'], 100);
    await drain(tester);
  });

  testWidgets('خانه: «پیشرفت عادت‌ها» آکاردئون است؛ پیش‌فرض بسته و وضعیت ذخیره می‌شود', (tester) async {
    final (store, a, path) = await boot(tester);
    final toggle = find.byKey(const ValueKey('habits-progress-toggle'));
    await tester.scrollUntilVisible(toggle, 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('۳۰ روز اخیر'), findsNothing); // بسته: فقط ردیف مینیمال
    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('۳۰ روز اخیر'), findsWidgets);
    expect(store.state['homeProgressOpen'], true);
    // پس از راه‌اندازیِ دوباره هنوز باز است
    final again = AppStore(path)..load();
    expect(again.state['homeProgressOpen'], true);
    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('۳۰ روز اخیر'), findsNothing);
    expect(a.store.state['homeProgressOpen'], false);
    await drain(tester);
  });

  testWidgets('انتخابِ اولیه‌ی آواتار: پنجره‌ی جمع‌وجور و انتخابِ جنسیت', (tester) async {
    final (_, a, _) = await boot(tester, gender: false);
    await tester.pump(const Duration(seconds: 9));
    await tester.tap(find.text('آواتار خودت را بساز').first);
    await tester.pump(const Duration(milliseconds: 600));
    final dlg = tester.getSize(find.descendant(of: find.byType(Dialog), matching: find.byType(Column)).first);
    expect(dlg.height, lessThan(520)); // دیگر بلند و عمودی نیست
    expect(dlg.width, lessThan(330));
    await tester.tap(find.byKey(const ValueKey('gender-female')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(a.avState().gender, 'female');
    await drain(tester);
  });


  for (final lang in ['fa', 'en']) {
    testWidgets('خانه: بدون overflow روی صفحه‌ی باریک (۳۲۰dp) با فونت بزرگ — $lang', (tester) async {
      tester.view.physicalSize = const Size(960, 2000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final dir = Directory.systemTemp.createTempSync('rp_home2');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = AppStore('${dir.path}/s.json')..load();
      store.state['fontSize'] = 'large';
      store.state['lang'] = lang;
      final a = AppActions(store, ToastBus(), clock: () => DateTime(2025, 3, 10, 22, 30))..chooseGender('male');
      store.state['habits'] = [
        {'id': 'h1', 'name': 'صلوات بسیار طولانی برای آزمون سرریز', 'type': 'numeric', 'numericTarget': 1000, 'numericUnit': 'بار', 'permanent': true, 'start': '2025-01-01'},
      ];
      await tester.pumpWidget(RoutineApp(store: store, nav: NavController(), toasts: a.toasts, actions: a, avData: data));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.scrollUntilVisible(find.byKey(const ValueKey('value-h1')), 200, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await drain(tester);
    });
  }

  testWidgets('خانه: روزهای پیاپی برای عادتِ مدت‌دار (غیردائمی) هم کار می‌کند', (tester) async {
    final (store, a, _) = await boot(tester);
    store.state['habits'] = [
      {'id': 'h9', 'name': 'Limited', 'type': 'binary', 'permanent': false, 'durationDays': 30, 'reward': 10, 'start': '2025-03-01', 'createdAt': DateTime(2025, 3, 1).millisecondsSinceEpoch},
    ];
    store.state['records'] = {
      '2025-03-09': {'h9': 'success'},
      '2025-03-10': {'h9': 'success'},
    };
    a.renderAll();
    await tester.pump(const Duration(milliseconds: 300));
    expect(((store.state['scores'] as Map)['streak'] as num).toInt(), 2);
    expect(find.byKey(const ValueKey('hero-streak')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('hero-streak'))).data, '۲');
    await drain(tester);
  });
}
