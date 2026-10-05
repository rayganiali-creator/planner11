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
  smartTests();
  test('گزارش هفتگی: بدون داده null (نه عددِ ساختگی)', () {
    final st = defaultState();
    final now = DateTime(2026, 9, 30, 12);
    expect(weeklyReport(st, now, true), isNull);
    expect(weeklyReport(st, now, false), isNull);
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
    expect(find.text('روند تکمیل'), findsOneWidget);
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

void smartTests() {
  testWidgets('تحلیل هوشمند (پرو): همه‌ی بخش‌ها با داده‌ی واقعی بدون سرریز؛ ژورنال رفتاری', (tester) async {
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_sm');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    store.state['isPremium'] = true;
    final old = DateTime.now().subtract(const Duration(days: 40)).toIso8601String().substring(0, 10);
    a.saveHabit(HabitForm(old)..name = 'ورزش');
    a.saveHabit(HabitForm(old)..name = 'مطالعه');
    final hs = (store.state['habits'] as List).cast<Map>();
    final now = a.today;
    // سی روز سابقه: ورزش اغلب شکست با علت «خسته بودم» و محرک «تنهایی»
    for (int i = 1; i <= 25; i++) {
      final iso = now.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
      final rec = (store.state['records'] as Map).putIfAbsent(iso, () => <String, dynamic>{}) as Map;
      rec[hs[0]['id']] = i % 3 == 0 ? 'success' : 'fail';
      rec[hs[1]['id']] = i % 5 == 0 ? 'fail' : 'success';
      if (i % 3 != 0) {
        ((store.state['reasons'] as Map).putIfAbsent(hs[0]['id'], () => <String, dynamic>{}) as Map)[iso] = {'status': 'fail', 'reason': 'خسته بودم', 'timestamp': 1};
        ((store.state['triggers'] as Map).putIfAbsent(hs[0]['id'], () => <Map>[]) as List).add({'trigger': 'تنهایی', 'date': iso, 'type': 'trigger', 'id': 't$i'});
      }
    }
    store.save();
    final nav = NavController()..go(AppView.smart);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    // امتیاز، داوری و تمرکزِ امروز
    expect(find.byKey(const ValueKey('smart-score')), findsOneWidget);
    expect(find.byKey(const ValueKey('smart-focus')), findsOneWidget); // امروز ثبت نشده ← ضعیف‌ترین عادت
    expect(find.textContaining('مانع اصلی', skipOffstage: false), findsWidgets); // «خسته بودم» مانع اصلی شد
    // بخش‌های کشویی: بسته‌اند، با ضربه باز می‌شوند
    expect(find.text('نقشه‌ی روزهای هفته'), findsNothing);
    await tester.ensureVisible(find.textContaining('ژورنال رفتاری', skipOffstage: false));
    await tester.tap(find.textContaining('ژورنال رفتاری'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('ثبت یادداشت', skipOffstage: false));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.widgetWithText(TextField, '').last, 'باید زودتر بخوابم');
    await tester.tap(find.text('ثبت یادداشت'));
    await tester.pump(const Duration(milliseconds: 300));
    expect((store.state['behaviorJournal'] as Map)['خسته بودم'].single['text'], 'باید زودتر بخوابم');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });
}
