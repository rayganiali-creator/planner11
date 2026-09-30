import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/data/trigger_ops.dart';

void main() {
  test('محرک/مشوق/علت: افزودن، شمارش، حذف، پنجره‌ی رایگان ۷ روز', () {
    final dir = Directory.systemTemp.createTempSync('rp_tg');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus());
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
    final hid = (store.state['habits'] as List).first['id'] as String;
    a.addTrigger(hid, ' استرس ', 'trigger');
    a.addTrigger(hid, 'استرس', 'trigger');
    a.addTrigger(hid, 'پاداش', 'incentive');
    expect(a.triggerFreq(hid, 'trigger'), {'استرس': 2});
    expect(a.triggerFreq(hid, 'incentive'), {'پاداش': 1});
    final tid = a.triggersFor(hid).first['id'] as String;
    a.removeTrigger(hid, tid);
    expect(a.triggerFreq(hid, 'trigger'), {'استرس': 1});
    a.removeTrigger(hid, a.triggersFor(hid).firstWhere((t) => t['trigger'] == 'استرس')['id'] as String);
    a.removeTrigger(hid, a.triggersFor(hid).first['id'] as String);
    expect((store.state['triggers'] as Map).containsKey(hid), isFalse); // کلیدِ خالی حذف می‌شود
    // علت‌ها
    a.addManualReason(hid, 'fail', ' خستگی ');
    a.addManualReason(hid, 'fail', 'خستگی');
    a.addManualReason(hid, 'success', 'برنامه‌ریزی');
    (store.state['reasons'][hid] as Map)['2020-01-01'] = {'status': 'fail', 'reason': 'قدیمی', 'timestamp': 1};
    expect(a.reasonFreq(hid, 'fail'), {'خستگی': 2}); // رایگان: «قدیمی» بیرون از ۷ روز
    store.state['isPremium'] = true;
    expect(a.reasonFreq(hid, 'fail'), {'خستگی': 2, 'قدیمی': 1});
    a.deleteReasonFromHabit(hid, 'خستگی', 'fail');
    expect(a.reasonFreq(hid, 'fail'), {'قدیمی': 1});
  });

  testWidgets('نمودارهای عادت از منوی کارت: افزودن محرک', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_tg2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
    final hid = (store.state['habits'] as List).first['id'] as String;
    final nav = NavController()..go(AppView.habits);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    Future<void> settle() => tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle();
    await tester.tap(find.text('📊 نمودارهای عادت'));
    await settle();
    await tester.enterText(find.byType(TextField), 'بیدار شدن');
    await tester.tap(find.text('افزودن'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(a.triggerFreq(hid, 'trigger'), {'بیدار شدن': 1});
    expect(find.text('بیدار شدن'), findsWidgets);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });
}
