// نوار ناوبری هیچ‌وقت روی محتوا نمی‌افتد: بدنه‌ی هر تب بالای نوار تمام می‌شود و آخرین ردیف با اسکرول کاملاً دیده می‌شود.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/shell.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';

void main() {
  for (final view in AppView.values) {
    testWidgets('تب ${view.name}: آخرِ صفحه پشتِ نوار پایین نمی‌ماند', (tester) async {
      tester.view.physicalSize = const Size(1080, 1800); // ۳۶۰×۶۰۰ منطقی
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final dir = Directory.systemTemp.createTempSync('rp_bt');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = AppStore('${dir.path}/s.json')..load();
      final a = AppActions(store, ToastBus());
      for (int i = 0; i < 3; i++) {
        a.saveHabit(HabitForm(a.todayISO)..name = 'عادت $i');
      }
      final nav = NavController()..go(view);
      await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: a.toasts, actions: a));
      await tester.pump(const Duration(milliseconds: 600));
      final navTop = tester.getTopLeft(find.byType(GlassNav)).dy;
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        final viewport = tester.getRect(scrollables.first);
        expect(viewport.bottom, lessThanOrEqualTo(navTop + 0.5), reason: '${view.name}: ناحیه‌ی اسکرول زیرِ نوار می‌رود');
        await tester.drag(scrollables.first, const Offset(0, -6000));
        await tester.pump(const Duration(milliseconds: 600));
        final pos = tester.state<ScrollableState>(scrollables.first).position;
        expect(pos.pixels, greaterThanOrEqualTo(pos.maxScrollExtent - 4), reason: '${view.name}: به انتها نمی‌رسد');
      }
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpWidget(const SizedBox());
    });
  }
}
