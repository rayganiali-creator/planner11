import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/features/onboarding/onboarding.dart';
import 'package:routine_planner/ui/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppTexts texts;
  setUpAll(() async => texts = await AppTexts.load());

  test('متن‌های استخراج‌شده از HTML کامل‌اند', () {
    expect(texts.onboarding.length, 15);
    expect(texts.terms.length, 9);
    expect(texts.help.keys, containsAll(['pomodoro', 'habits', 'challenge', 'calendar', 'progress']));
    expect(texts.onboarding.first['titleFa'], 'خوش آمدید');
    expect(texts.termsVersion, 5);
    expect(texts.onboardingVersion, 3);
    expect(needsTerms({'termsAcceptedVersion': 4}, texts), isTrue);
    expect(needsTerms({'termsAcceptedVersion': 5}, texts), isFalse);
    expect(needsOnboarding({'onboardingDone': true, 'onboardingVersion': 2}, texts), isTrue);
    expect(needsOnboarding({'onboardingDone': true, 'onboardingVersion': 3}, texts), isFalse);
  });

  testWidgets('اولین اجرا: زبان ← قوانین (تأیید لازم) ← آموزش ۱۵ اسلاید', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_ob');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    await tester.pumpWidget(RoutineApp(store: store, nav: NavController(), toasts: toasts, actions: a, texts: texts));
    Future<void> settle() => tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    await settle();
    expect(find.text('فارسی یا English؟'), findsOneWidget);
    await tester.tap(find.text('🌐 English'));
    await settle();
    expect(store.state['lang'], 'en');
    expect(store.state['langChosen'], true);
    expect(find.text('Terms of Use'), findsOneWidget);
    // تا تیک نزنیم دکمه غیرفعال است
    final btn = find.widgetWithText(RpButton, 'I accept the terms');
    expect(tester.widget<RpButton>(btn).onTap, isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await settle();
    await tester.tap(find.text('I accept the terms'));
    await settle();
    expect(store.state['termsAcceptedVersion'], 5);
    expect(btn, findsNothing);
    // آموزش
    expect(find.text('Welcome'), findsOneWidget);
    for (int i = 0; i < 14; i++) {
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text("You're all set"), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await settle();
    expect(store.state['onboardingDone'], true);
    expect(store.state['onboardingVersion'], 3);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });
}
