import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';

void main() {
  test('ساخت، ثبت، ویرایش (قفلِ هدف) و حذفِ کامل عادت', () {
    final dir = Directory.systemTemp.createTempSync('rp_h');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus());
    final f = HabitForm(a.todayISO)..name = 'مطالعه'..type = 'numeric'..numericTarget = 10..important = true;
    expect(a.saveHabit(HabitForm(a.todayISO)), isNull); // نام خالی
    final id = a.saveHabit(f)!;
    final h = (store.state['habits'] as List).single as Map;
    expect(h['important'], true);
    expect(h.containsKey('rewardPoints'), isFalse);
    expect(h['numericUnit'], 'بار');
    a.setValue(a.todayISO, id, 12);
    (store.state['reasons'] as Map)[id] = {'x': 1};
    final f2 = HabitForm.from(h)..numericTarget = 20;
    a.saveHabit(f2, editingId: id);
    final rec = ((store.state['records'] as Map)[a.todayISO] as Map)[id];
    expect((rec as Map)['targetAtTime'], 10); // رکوردِ گذشته با هدفِ قدیمی قفل شد
    expect(h['numericTarget'], 20);
    a.deleteHabit(id);
    expect(store.state['habits'], isEmpty);
    expect((store.state['records'] as Map).containsKey(a.todayISO), isFalse);
    expect((store.state['reasons'] as Map).containsKey(id), isFalse);
  });

  testWidgets('تب عادت‌ها: فهرست، ثبتِ تیک و بازشدنِ ویرایشگر', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_h2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
    final nav = NavController()..go(AppView.habits);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ورزش'), findsOneWidget);
    await tester.tap(find.text('عادت جدید'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ذخیره', skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
