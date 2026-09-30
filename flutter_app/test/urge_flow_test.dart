import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/data/urge_data.dart';
import 'package:routine_planner/data/urge_ops.dart';

Future<(AppStore, AppActions, NavController, ToastBus, Directory)> setup() async {
  final dir = Directory.systemTemp.createTempSync('rp_u');
  final store = AppStore('${dir.path}/s.json')..load();
  final toasts = ToastBus();
  final a = AppActions(store, toasts);
  return (store, a, NavController(), toasts, dir);
}

void main() {
  test('داده‌ی وسوسه: ۴۰ پیشنهاد، متن عیناً HTML؛ افزودن/حذف/پنهان‌کردن', () async {
    expect(urgeSuggestions.length, 40);
    expect(urgeSuggestions.first.$3, 'آیت‌الکرسی بخوان');
    expect(urgeSuggestions[39].$4, "Remember your streak and don't break it");
    final (store, a, _, _, dir) = await setup();
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(a.allUrgeSuggestions().length, 40);
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
    final hid = (store.state['habits'] as List).first['id'] as String;
    expect(a.addUrge('  ', null), isFalse);
    expect(a.addUrge('عمومی من', null), isTrue);
    expect(a.addUrge('مخصوص', hid), isTrue);
    var all = a.allUrgeSuggestions();
    expect(all.length, 42);
    expect(all.last.scope, 'ورزش');
    a.deleteUrge(all.first); // پیش‌فرض → پنهان
    a.deleteUrge(all[40]); // عمومیِ من
    a.deleteUrge(all.last); // مخصوص عادت
    all = a.allUrgeSuggestions();
    expect(all.length, 39);
    expect((store.state['urgeHiddenIds'] as List), ['d1']);
    expect(a.shuffledUrges().length, 39);
  });

  test('دلیل‌ها و پاداش/تنبیه', () async {
    final (store, a, _, _, dir) = await setup();
    addTearDown(() => dir.deleteSync(recursive: true));
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش'..rewardText = ' بستنی '..punishmentText = '');
    final hid = (store.state['habits'] as List).first['id'] as String;
    a.saveReason(hid, '2026-09-30', 'fail', 'خسته بودم');
    a.saveReason(hid, '2026-09-29', 'fail', '');
    a.saveReason(hid, '2026-09-28', 'success', 'انگیزه');
    expect(a.previousReasons(hid, 'fail'), ['خسته بودم']); // «بدون دلیل» حذف
    expect(a.previousReasons(hid, 'success'), ['انگیزه']);
    expect(a.rewardPunish(hid, 'success')!.$3, 'بستنی');
    expect(a.rewardPunish(hid, 'fail'), isNull); // تنبیه خالی
    expect(a.rewardPunish('نیست', 'success'), isNull);
  });

  testWidgets('جریان ثبت: دلیل ← رکورد ← پاداش؛ انصراف = هیچ؛ برداشتن بی‌پرسش', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (store, a, nav, toasts, dir) = await setup();
    addTearDown(() => dir.deleteSync(recursive: true));
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش'..rewardText = 'بستنی');
    final hid = (store.state['habits'] as List).first['id'] as String;
    nav.go(AppView.habits);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    Future<void> settle() => tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    Object? rec() => ((store.state['records'] as Map?)?[a.todayISO] as Map?)?[hid];

    await tester.tap(find.byIcon(LucideIcons.check));
    await settle();
    expect(find.text('چرا؟'), findsOneWidget);
    await tester.tap(find.text('انصراف'));
    await settle();
    expect(rec(), isNull); // انصراف: هیچ
    await tester.tap(find.byIcon(LucideIcons.check));
    await settle();
    await tester.tap(find.text('ثبت')); // بدون متن ← هشدار، پنجره باز می‌ماند
    await tester.pump(const Duration(milliseconds: 300));
    expect(rec(), isNull);
    await tester.enterText(find.byType(TextField).last, 'حالم خوب بود');
    await tester.tap(find.text('ثبت'));
    await settle();
    expect(rec(), 'success');
    expect(((store.state['reasons'] as Map)[hid] as Map)[a.todayISO]['reason'], 'حالم خوب بود');
    expect(find.text('🎉 پاداش شما!'), findsOneWidget);
    expect(find.text('بستنی'), findsOneWidget);
    await tester.tap(find.text('باشه'));
    await settle();
    await tester.tap(find.byIcon(LucideIcons.check)); // دوباره روی فعال: بی‌پرسش برمی‌دارد
    await settle();
    expect(find.text('چرا؟'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('برگه‌ی وسوسه از منوی +', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (store, a, nav, toasts, dir) = await setup();
    addTearDown(() => dir.deleteSync(recursive: true));
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    // منوی + را مستقیم از دکمه‌ی وسط نوار باز می‌کنیم
    await tester.tap(find.byIcon(LucideIcons.plus).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    await tester.tap(find.text('لحظه‌ی وسوسه'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    expect(find.text('⚡ لحظه‌ی وسوسه'), findsOneWidget);
    await tester.tap(find.text('⚙️ مدیریت پیشنهادها'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('مدیریت پیشنهادها'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
