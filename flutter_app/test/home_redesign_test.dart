import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(AppStore, AppActions, String)> boot(WidgetTester tester, {int hour = 12, AppView view = AppView.dashboard}) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_home');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/s.json';
    final store = AppStore(path)..load();
    final a = AppActions(store, ToastBus(), clock: () => DateTime(2025, 3, 10, hour, 30));
    store.state['habits'] = [
      {'id': 'h1', 'name': 'Salavat', 'type': 'numeric', 'numericTarget': 100, 'numericUnit': 'x', 'reward': 10, 'direction': 'more', 'permanent': true, 'start': '2025-01-01'},
      {'id': 'h2', 'name': 'Run', 'type': 'binary', 'reward': 10, 'permanent': true, 'start': '2025-01-01'},
    ];
    await tester.pumpWidget(RoutineApp(store: store, nav: NavController()..go(view), toasts: a.toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    return (store, a, path);
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('تب عادت‌ها: ثبتِ درجای مقدار برای عادت عددی (و عادت دوحالتی دکمه دارد)', (tester) async {
    final (store, _, _) = await boot(tester, view: AppView.habits);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('value-h1')), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('value-h2')), findsNothing); // عادت دوحالتی ورودیِ عددی ندارد
    expect(find.text('انجام شد'), findsWidgets);
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

  testWidgets('خانه: «پیشرفت عادت‌ها» و «چالش‌ها» کشویی‌اند؛ پیش‌فرض بسته و وضعیت ذخیره می‌شود', (tester) async {
    final (store, _, path) = await boot(tester);
    // فهرستِ «عادت‌های امروز» از خانه حذف شده
    expect(find.text('عادت‌های امروز'), findsNothing);
    final toggle = find.text('پیشرفت عادت‌ها');
    await tester.scrollUntilVisible(toggle, 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('۳۰ روز اخیر'), findsNothing); // بسته: فقط ردیف مینیمال
    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('۳۰ روز اخیر'), findsWidgets);
    expect(((store.state['uiOpen'] as Map)['homeProgress']), true);
    final again = AppStore(path)..load();
    expect((again.state['uiOpen'] as Map)['homeProgress'], true); // پس از راه‌اندازیِ دوباره هم باز است
    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('۳۰ روز اخیر'), findsNothing);
    expect(((store.state['uiOpen'] as Map)['homeProgress']), false);
    // چالش‌ها: بسته → باز
    expect(find.text('مدیریت چالش‌ها'), findsNothing);
    await tester.tap(find.text('چالش‌ها'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('مدیریت چالش‌ها'), findsOneWidget);
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
      final a = AppActions(store, ToastBus(), clock: () => DateTime(2025, 3, 10, 22, 30));
      store.state['habits'] = [
        {'id': 'h1', 'name': 'صلوات بسیار طولانی برای آزمون سرریز', 'type': 'numeric', 'numericTarget': 1000, 'numericUnit': 'بار', 'permanent': true, 'start': '2025-01-01'},
      ];
      final nav = NavController();
      await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: a.toasts, actions: a));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      nav.go(AppView.habits);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.scrollUntilVisible(find.byKey(const ValueKey('value-h1')), 200, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await drain(tester);
    });
  }

  testWidgets('خانه: روزهای پیاپی برای عادتِ مدت‌دار (غیردائمی) هم کار می‌کند', (tester) async {
    final (store, a, _) = await boot(tester);
    store.state['habits'] = [
      {'id': 'h9', 'name': 'Limited', 'type': 'binary', 'permanent': false, 'durationDays': 30, 'reward': 10, 'start': '2025-03-01', 'createdAt': '2025-03-01'},
    ];
    store.state['records'] = {
      '2025-03-09': {'h9': 'success'},
      '2025-03-10': {'h9': 'success'},
    };
    a.renderAll();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('profile-streak')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('profile-streak'))).data, contains('۲'));
    await drain(tester);
  });
}
