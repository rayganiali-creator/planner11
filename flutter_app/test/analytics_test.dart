import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/state_model.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/features/analytics/analytics_screen.dart';

void main() {
  test('گزارش هفتگی: آستانه‌ی ۷۰٪ و متن', () {
    final st = defaultState();
    final now = DateTime(2026, 9, 30, 12);
    expect(weeklyReport(st, now, true), 'این هفته 0 از 0 عادت موفق (0%). کمی بیشتر تلاش کن! 🌱');
    expect(weeklyReport(st, now, false), 'This week 0 of 0 habits successful (0%). Keep going! 🌱');
    expect(jsRoundPct(1, 2), 50);
    expect(jsRoundPct(2, 3), 67);
  });

  testWidgets('صفحه‌ی تحلیل: سه بازه، مقایسه و گزارش', (tester) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_an');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
    final hid = (store.state['habits'] as List).first['id'] as String;
    a.setBinary(a.todayISO, hid, 'success');
    final nav = NavController()..go(AppView.analytics);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('روند پیشرفت'), findsOneWidget);
    expect(find.text('ورزش'), findsOneWidget);
    for (final r in ['ماه', 'سال', 'هفته']) {
      await tester.tap(find.text(r));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CustomPaint), findsWidgets);
    }
    expect(find.textContaining('این هفته'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
