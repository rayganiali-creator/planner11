import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/challenge_ops.dart';
import 'package:routine_planner/features/challenges/challenges_sheet.dart';

void main() {
  test('فرمت شمارش معکوس مثل HTML', () {
    expect(formatCountdown(0, true), 'در حال بررسی…');
    expect(formatCountdown(0, false), 'checking…');
    expect(formatCountdown(((2 * 86400) + 3 * 3600) * 1000, false), '2d 3h');
    expect(formatCountdown((3 * 3600 + 5 * 60) * 1000, false), '3h 5m');
    expect(formatCountdown((5 * 60 + 7) * 1000, false), '5m 7s');
    expect(formatCountdown((5 * 60 + 7) * 1000, true), '۵دقیقه ۷ثانیه'); // عیناً خروجیِ JS: بدون فاصله بعد از عدد
    expect(formatCountdown(((2 * 86400) + 3 * 3600) * 1000, true), '۲روز ۳ساعت');
  });

  test('آماده‌ها، چالش شخصیِ پرو، جایزه با سقف، مدال، مهلت و پاسخ', () {
    final dir = Directory.systemTemp.createTempSync('rp_c');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    var now = DateTime(2026, 9, 30, 12);
    final a = AppActions(store, ToastBus(), clock: () => now);
    // آماده‌ی تعدادی
    final w = a.joinPreset('preset_workout10')!;
    expect(a.joinPreset('preset_workout10'), isNull); // دوباره نه
    for (int i = 0; i < 9; i++) {
      a.incrementChallenge(w['id'], 1);
    }
    expect(w['status'], 'active');
    a.incrementChallenge(w['id'], 1);
    expect(w['status'], 'success');
    expect(store.state['scores']['coins'], 0, reason: 'دیگر سکه‌ای در کار نیست');
    expect(store.state['medals'], isNull); // رایگان: مدال نه
    // شخصی فقط پرو
    final f = ChallengeForm()..name = 'مطالعه'..kind = 'both'..target = 3..durationValue = 2..durationUnit = 'hours'..rewardText = 'شیرینی';
    expect(a.createChallenge(f), 'pro');
    store.state['isPremium'] = true;
    expect(a.createChallenge(ChallengeForm()..name = ' '), 'name');
    expect(a.createChallenge(ChallengeForm()..name = 'x'..kind = 'timed'..deadlineMode = 'exact'..exactAt = now.millisecondsSinceEpoch - 1), 'date');
    expect(a.createChallenge(f), isNull);
    final c = a.challenges.last;
    expect(c.containsKey('rewardCoins'), isFalse); // بدون ارز
    expect(c['deadlineAt'], now.add(const Duration(hours: 2)).millisecondsSinceEpoch);
    // مهلت نرسیده
    expect(a.checkChallengeDeadlines(), isEmpty);
    now = now.add(const Duration(hours: 2, seconds: 1));
    expect(a.checkChallengeDeadlines(), [c['id']]);
    expect(c['status'], 'pending_review');
    expect(a.checkChallengeDeadlines(), isEmpty); // دوباره صف نمی‌شود
    a.resolveCheckin(c['id'], true);
    expect(c['status'], 'success');
    expect(store.state['scores']['coins'], 0);
    final medals = store.state['medals'] as List;
    expect(medals.single['tier'], 'bronze'); // ۳ + ۲ساعت ≈ ۳٫۱
    a.awardChallenge(c);
    expect((store.state['medals'] as List).length, 1); // مدال تکراری نه
    // شکست/لغو
    a.createChallenge(ChallengeForm()..name = 'دو'..kind = 'count'..target = 5);
    final c2 = a.challenges.last;
    a.cancelChallenge(c2['id']);
    expect(c2['status'], 'cancelled');
    a.incrementChallenge(c2['id'], 1); // لغوشده: اثری ندارد
    expect(c2['progressCount'], 0);
    expect(medalTier({'targetCount': 25}), 'gold');
    expect(medalTier({'targetCount': 7}), 'silver');
  });

  testWidgets('برگه‌ی چالش‌ها: شرکت در چالش آماده', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_c2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    final nav = NavController();
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('چالش‌ها')); // بخشِ کشوییِ خانه باز می‌شود
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(find.text('مدیریت چالش‌ها'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('مدیریت چالش‌ها'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    await tester.tap(find.text('ساخت'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('۱۰ جلسه ورزش'), findsOneWidget);
    await tester.tap(find.text('شرکت').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(a.challenges.length, 1);
    expect(find.text('+1'), findsOneWidget);
    await tester.tap(find.text('+1'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(a.challenges.single['progressCount'], 1);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });
}
