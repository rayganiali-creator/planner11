// Design System یکپارچه: تایپوگرافی (Medium پیش‌فرض)، مودال‌ها (compact/یکسان)، Free/Pro مرکزی، دکمه‌ی کتابخانه.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/pro_features.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/ui/pro_widgets.dart';
import 'package:routine_planner/ui/tokens.dart';
import 'package:routine_planner/ui/widgets.dart';

Future<(AppStore, AppActions, NavController)> boot(WidgetTester tester, {bool pro = false, AppView view = AppView.dashboard, Size size = const Size(1080, 2000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final dir = Directory.systemTemp.createTempSync('rp_ui');
  addTearDown(() => dir.deleteSync(recursive: true));
  final store = AppStore('${dir.path}/s.json')..load();
  store.state['isPremium'] = pro;
  final a = AppActions(store, ToastBus());
  final nav = NavController()..go(view);
  await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: a.toasts, actions: a));
  await tester.pump(const Duration(milliseconds: 600));
  return (store, a, nav);
}

Future<void> drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpWidget(const SizedBox());
}

void main() {
  test('وزنِ تایپوگرافی: متنِ معمولی همیشه Medium؛ ۱۶ تا سقفِ ۶۰۰؛ فقط تیترها سنگین‌تر', () {
    expect(rpEffectiveWeight(RpType.caption, 900), 500);
    expect(rpEffectiveWeight(RpType.label, 800), 500);
    expect(rpEffectiveWeight(RpType.body, 700), 500);
    expect(rpEffectiveWeight(RpType.bodyL, 800), 600);
    expect(rpEffectiveWeight(RpType.title, 700), 700);
    expect(rpEffectiveWeight(RpType.titleL, 800), 800);
    expect(rpText(RpType.body, weight: 800).fontWeight, FontWeight.w500);
    expect(rpText(RpType.label).fontWeight, FontWeight.w500);
  });

  for (final view in [AppView.dashboard, AppView.habits, AppView.settings, AppView.todo, AppView.library, AppView.analytics, AppView.smart]) {
    testWidgets('تایپوگرافی ${view.name}: متنِ معمولی Medium، تیترها فقط در صورت نیاز سنگین‌تر', (tester) async {
      final (_, a, _) = await boot(tester, view: view);
      a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
      await tester.pump(const Duration(milliseconds: 500));
      final bad = <String>[];
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        final st = t.style;
        if (st == null || st.fontSize == null || st.fontWeight == null) continue;
        final w = st.fontWeight!.value;
        if (st.fontSize! < RpType.bodyL && w != 500) bad.add('${t.data ?? t.textSpan?.toPlainText()}: ${st.fontSize} w$w');
        if (st.fontSize! >= RpType.bodyL && st.fontSize! < RpType.title && w > 600) bad.add('${t.data}: ${st.fontSize} w$w');
      }
      expect(bad, isEmpty, reason: bad.take(8).join('\n'));
      await drain(tester);
    });
  }

  testWidgets('کتابخانه: دکمه‌ی «کتاب جدید» کوچک و بالای صفحه (کنار عنوان) است', (tester) async {
    await boot(tester, view: AppView.library);
    final btn = find.byKey(const ValueKey('add-book'));
    expect(btn, findsOneWidget);
    final r = tester.getRect(btn);
    final title = tester.getRect(find.text('کتابخانه').first);
    expect((r.center.dy - title.center.dy).abs(), lessThan(30)); // هم‌ترازِ عنوان، نه وسطِ صفحه
    expect(r.height, lessThanOrEqualTo(48));
    expect(r.height, greaterThanOrEqualTo(36)); // برای لمسِ موبایل
    expect(r.width, lessThan(200));
    expect(r.top, lessThan(160)); // بالای صفحه
    await tester.tap(btn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(RpSheetHeader), findsOneWidget); // ویرایشگر کتاب با سرِ یکپارچه
    await drain(tester);
  });

  group('مودال‌ها: compact، سرِ یکسان با دکمه‌ی بستن، بدون سرریز', () {
    Future<void> check(WidgetTester tester, {required Size size}) async {
      final h = size.height / 3;
      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      final body = find.descendant(of: sheet, matching: find.byType(Material)).first; // خودِ برگه (نه Alignِ تمام‌عرض)
      expect(tester.getSize(body).height, lessThanOrEqualTo(h * 0.9 + 1), reason: 'ارتفاع برگه');
      expect(tester.getSize(body).width, lessThanOrEqualTo(560 + 0.5), reason: 'عرض برگه');
      expect(find.byType(RpSheetHeader), findsOneWidget);
      expect(find.byKey(const ValueKey('sheet-close')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('sheet-close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BottomSheet), findsNothing);
    }

    testWidgets('عادت جدید (موبایل کوتاه)', (tester) async {
      const size = Size(1080, 1500); // ۳۶۰×۵۰۰
      await boot(tester, view: AppView.habits, size: size);
      await tester.tap(find.byKey(const ValueKey('new-habit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await check(tester, size: size);
      await drain(tester);
    });

    testWidgets('عادت جدید (دسکتاپ عریض): عرضِ مودال محدود می‌ماند', (tester) async {
      const size = Size(3000, 2400); // ۱۰۰۰×۸۰۰ منطقی
      await boot(tester, view: AppView.habits, size: size);
      await tester.tap(find.byKey(const ValueKey('new-habit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await check(tester, size: size);
      await drain(tester);
    });

    testWidgets('کتاب جدید', (tester) async {
      const size = Size(1080, 1800);
      await boot(tester, view: AppView.library, size: size);
      await tester.tap(find.byKey(const ValueKey('add-book')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await check(tester, size: size);
      await drain(tester);
    });

    testWidgets('تأییدِ حذف (دیالوگ): گوشه و عرض از تم یکپارچه', (tester) async {
      final (_, a, _) = await boot(tester, view: AppView.habits);
      a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('حذف').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final d = find.byType(AlertDialog);
      expect(d, findsOneWidget);
      final box = find.descendant(of: d, matching: find.byType(Material)).first;
      expect(tester.getSize(box).width, lessThanOrEqualTo(1080 / 3 - 48 + 0.5));
      final shape = Theme.of(tester.element(d)).dialogTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(RpRadius.lg));
      await drain(tester);
    });
  });

  group('Free / Pro: منبعِ واحد، بدون هیچ ردپای خریدی برای کاربر Pro', () {
    for (final f in ProFeature.values) {
      testWidgets('ProNotice(${f.name})', (tester) async {
        for (final pro in [false, true]) {
          tester.view.physicalSize = const Size(1080, 2000);
          tester.view.devicePixelRatio = 3;
          final dir = Directory.systemTemp.createTempSync('rp_pn');
          addTearDown(() => dir.deleteSync(recursive: true));
          final store = AppStore('${dir.path}/s.json')..load();
          store.state['isPremium'] = pro;
          final a = AppActions(store, ToastBus());
          final nav = NavController();
          await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: a.toasts, actions: a));
          await tester.pump(const Duration(milliseconds: 400));
          final ctx = tester.element(find.byType(Scaffold).first);
          // ProNotice را موقتاً در صفحه می‌گذاریم
          final entry = OverlayEntry(builder: (_) => Align(alignment: Alignment.topCenter, child: Material(child: ProNotice(f))));
          Overlay.of(ctx).insert(entry);
          await tester.pump();
          final notice = find.byKey(ValueKey('pro-notice-${f.name}'));
          if (pro) {
            expect(notice, findsNothing, reason: '${f.name}: کاربر Pro نباید توضیح/CTA ببیند');
            expect(find.byKey(const ValueKey('pro-cta')), findsNothing);
          } else {
            expect(notice, findsOneWidget);
            expect(find.textContaining(proInfos[f]!.titleFa), findsWidgets);
            expect(find.textContaining('رایگان:'), findsOneWidget);
            expect(find.textContaining('پرو:'), findsOneWidget);
            expect(find.byKey(const ValueKey('pro-cta')), findsOneWidget);
          }
          entry.remove();
          await tester.pump(const Duration(seconds: 10));
          await tester.pumpWidget(const SizedBox());
        }
      });
    }

    testWidgets('اعلانِ محدودیت: Free توست دارد، Pro هرگز', (tester) async {
      for (final pro in [false, true]) {
        final (store, a, _) = await boot(tester, pro: pro, view: AppView.habits);
        final ctx = tester.element(find.byType(Scaffold).first);
        var shown = 0;
        a.toasts.addListener(() => shown++);
        showProBlocked(ctx, ProFeature.habits);
        await tester.pump(const Duration(milliseconds: 300));
        expect(shown, pro ? 0 : 1, reason: 'pro=$pro');
        expect(isProState(store.state), pro);
        await drain(tester);
      }
    });

    testWidgets('خریدها: جدولِ مقایسه فقط برای Free؛ برای Pro و نشانِ قفلِ کارت‌ها نیست', (tester) async {
      await boot(tester, pro: false, view: AppView.purchases);
      expect(find.byKey(const ValueKey('pro-pitch')), findsOneWidget); // توضیحِ چندخطیِ پرو برای Free
      await tester.scrollUntilVisible(find.byKey(const ValueKey('pro-comparison')), 300, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const ValueKey('pro-comparison')), findsOneWidget);
      await drain(tester);
      await boot(tester, pro: true, view: AppView.purchases);
      expect(find.byKey(const ValueKey('pro-comparison')), findsNothing);
      expect(find.byKey(const ValueKey('pro-pitch')), findsNothing); // با پرو حذف می‌شود
      expect(find.byIcon(Icons.lock), findsNothing);
      await drain(tester);
    });

    testWidgets('خانه: کارت تحلیل هوشمند برای Free قفل کوچک دارد و برای Pro ندارد', (tester) async {
      await boot(tester, pro: false);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('home-smart')), 300, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const ValueKey('home-smart')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('home-smart')), matching: find.byType(ProLockIcon)), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsNothing); // ProLockIcon از Lucide است؛ ولی وجود دارد
      await drain(tester);
      await boot(tester, pro: true);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('home-smart')), 300, scrollable: find.byType(Scrollable).first);
      final lock = find.descendant(of: find.byKey(const ValueKey('home-smart')), matching: find.byType(Icon));
      // برای Pro: فقط آیکن مغز و فلش (بدون قفل)
      expect(lock.evaluate().length, 2);
      await drain(tester);
    });
  });
}
