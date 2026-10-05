// سیستم Theme: ۶ تم × (روشن/تاریک) — توکن‌های کامل، خوانایی (WCAG)، پایداری، تمایز و رندر در همه‌ی صفحه‌ها.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/state_model.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/ui/app_themes.dart';
import 'package:routine_planner/ui/tokens.dart';
import 'tokens_test.dart' show contrast;

void main() {
  test('دقیقاً ۶ تمِ آماده، هرکدام با نسخه‌ی روشن و تاریکِ مستقل', () {
    expect(appThemes.length, 6);
    expect({for (final t in appThemes) t.id}.length, 6);
    for (final t in appThemes) {
      expect(t.light.bg, isNot(t.dark.bg), reason: t.id);
      expect(t.light.text, isNot(t.dark.text), reason: t.id);
      expect(t.light.chart.length, 6);
      expect(t.dark.chart.length, 6);
      expect(t.light.primary, isNot(t.dark.primary), reason: '${t.id}: تاریک فقط وارونه‌ی روشن نیست');
    }
  });

  test('تم‌ها واقعاً متمایزند (پالتِ اصلی/زمینه/نمودار تکراری نیست)', () {
    for (final dark in [false, true]) {
      final ps = [for (final t in appThemes) t.of(dark)];
      expect({for (final p in ps) p.primary.toARGB32()}.length, 6);
      expect({for (final p in ps) p.bg.toARGB32()}.length, 6);
      expect({for (final p in ps) p.chart.map((c) => c.toARGB32()).join(',')}.length, 6);
    }
  });

  for (final t in appThemes) {
    for (final dark in [false, true]) {
      final p = t.of(dark);
      group('خوانایی ${t.id} ${dark ? 'dark' : 'light'}', () {
        final pairs = <List<Object>>[
          [p.text, p.bg, 7.0, 'متن روی زمینه'],
          [p.text, p.surface, 4.5, 'متن روی کارت'],
          [p.text, p.surface2, 4.5, 'متن روی کارت دوم/ورودی'],
          [p.muted, p.bg, 4.5, 'متن ثانویه/placeholder روی زمینه'],
          [p.muted, p.surface, 4.5, 'متن ثانویه روی کارت'],
          [p.muted, p.surface2, 4.5, 'متن ثانویه روی ورودی'],
          [p.primary, p.surface, 4.5, 'لینک/برند روی کارت'],
          [p.primary, p.bg, 4.5, 'برند روی زمینه'],
          [p.primary, p.primarySoft, 4.5, 'برچسب برند'],
          [p.onPrimary, p.btnA, 4.5, 'متن دکمه'],
          [p.onPrimary, p.btnB, 4.5, 'متن دکمه (انتهای گرادیان)'],
          [p.goldInk, p.goldSoft, 4.5, 'برچسب طلایی'],
          [p.xpInk, p.xpSoft, 4.5, 'برچسب XP'],
          [p.hpInk, p.hpSoft, 4.5, 'برچسب HP'],
          [p.okInk, p.okSoft, 4.5, 'برچسب موفق'],
          [p.badInk, p.badSoft, 4.5, 'برچسب ناموفق'],
          [p.blueInk, p.blueSoft, 4.5, 'برچسب آبی'],
          [p.goldInk, p.surface, 4.5, 'سکه روی کارت'],
          [p.okInk, p.surface, 4.5, 'موفق روی کارت'],
          [p.badInk, p.surface, 4.5, 'ناموفق روی کارت'],
          [p.line, p.bg, 1.05, 'خط جداکننده دیده می‌شود'],
        ];
        for (final c in pairs) {
          test('${c[3]}', () {
            final r = contrast(c[0] as Color, c[1] as Color);
            expect(r, greaterThanOrEqualTo(c[2] as double), reason: '${t.id} ${dark ? 'dark' : 'light'} ${c[3]}: ${r.toStringAsFixed(2)}');
          });
        }
        test('رنگ‌های نمودار روی کارت دیده می‌شوند (≥ ۳)', () {
          for (final c in p.chart) {
            expect(contrast(c, p.surface), greaterThanOrEqualTo(3.0), reason: '${t.id} ${dark ? 'dark' : 'light'} chart ${c.toARGB32().toRadixString(16)}');
          }
        });
      });
    }
  }

  test('شناسه‌های قدیمیِ رنگِ اصلی به تمِ جدیدِ نزدیک نگاشت می‌شوند و مقدارِ ناشناخته امن است', () {
    expect(themeById('teal').id, 'emerald');
    expect(themeById('blue').id, 'ocean');
    expect(themeById('purple').id, 'midnight');
    expect(themeById('rose').id, 'rose');
    expect(themeById('amber').id, 'amber');
    expect(themeById('slate').id, 'mono');
    expect(themeById(null).id, defaultThemeId);
    expect(themeById('???').id, defaultThemeId);
    expect(defaultThemeId, 'emerald');
  });

  test('حالت روشن/تاریک/سیستم مستقل از تم است', () {
    final st = defaultState()..['accentTheme'] = 'ocean';
    st['theme'] = 'light';
    expect(isDarkMode(st, Brightness.dark), isFalse);
    st['theme'] = 'dark';
    expect(isDarkMode(st, Brightness.light), isTrue);
    st['theme'] = 'system';
    expect(isDarkMode(st, Brightness.dark), isTrue);
    expect(isDarkMode(st, Brightness.light), isFalse);
    expect(paletteFor(st, Brightness.dark).bg, themeById('ocean').dark.bg);
    expect(paletteFor(st, Brightness.light).bg, themeById('ocean').light.bg);
    st['theme'] = 'weird';
    expect(themeMode(st), 'light');
  });

  test('تم و حالت ذخیره می‌شوند و پس از راه‌اندازیِ دوباره برمی‌گردند', () {
    final dir = Directory.systemTemp.createTempSync('rp_th');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/s.json';
    final a = AppStore(path)..load();
    a.state['accentTheme'] = 'rose';
    a.state['theme'] = 'system';
    a.save();
    final b = AppStore(path)..load();
    expect(b.state['accentTheme'], 'rose');
    expect(b.state['theme'], 'system');
    expect(themeById(b.state['accentTheme']).id, 'rose');
  });

  testWidgets('تنظیمات: انتخابِ آزادِ رنگ حذف شده؛ کارت‌های تم و حالت هست و کار می‌کند', (tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_th2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus());
    await tester.pumpWidget(RoutineApp(store: store, nav: NavController()..go(AppView.settings), toasts: a.toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 600));
    // هیچ انتخابگرِ آزاد/اسلایدرِ رنگ/شدت
    for (final gone in ['رنگ پس‌زمینه (طیف کامل)', 'رنگ اصلی (دکمه‌ها و متن‌های برجسته)', '🌗 روشن / تاریک', 'Pick any color you like']) {
      expect(find.text(gone, skipOffstage: false), findsNothing, reason: gone);
    }
    expect(find.byType(Slider, skipOffstage: false), findsNothing);
    for (final t in appThemes) {
      expect(find.byKey(ValueKey('theme-${t.id}'), skipOffstage: false), findsOneWidget);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('theme-rose')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('theme-rose')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.state['accentTheme'], 'rose');
    await tester.ensureVisible(find.byKey(const ValueKey('mode-system')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('mode-system')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.state['theme'], 'system');
    expect(store.state['accentTheme'], 'rose'); // تم با عوض‌شدنِ حالت دست‌نخورده می‌ماند
    await tester.ensureVisible(find.byKey(const ValueKey('mode-dark')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('mode-dark')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.state['theme'], 'dark');
    await tester.pump(const Duration(milliseconds: 400)); // انیمیشنِ گذارِ تم
    expect(Theme.of(tester.element(find.byKey(const ValueKey('mode-dark')))).extension<RpTheme>()!.p.bg, themeById('rose').dark.bg);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpWidget(const SizedBox());
  });

  group('همه‌ی صفحه‌ها با همه‌ی تم‌ها بدون خطای رندر/سرریز', () {
    for (final t in appThemes) {
      for (final mode in ['light', 'dark']) {
        testWidgets('${t.id} / $mode', (tester) async {
          tester.view.physicalSize = const Size(1080, 2000);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          final dir = Directory.systemTemp.createTempSync('rp_th3');
          addTearDown(() => dir.deleteSync(recursive: true));
          final store = AppStore('${dir.path}/s.json')..load();
          store.state['accentTheme'] = t.id;
          store.state['theme'] = mode;
          store.state['isPremium'] = true;
          final a = AppActions(store, ToastBus());
          final nav = NavController();
          await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: a.toasts, actions: a));
          await tester.pump(const Duration(milliseconds: 500));
          for (final v in AppView.values) {
            nav.go(v);
            await tester.pump(const Duration(milliseconds: 450));
            expect(tester.takeException(), isNull, reason: '${t.id}/$mode/${v.name}');
          }
          await tester.pump(const Duration(seconds: 10));
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
