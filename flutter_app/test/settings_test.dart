import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/state_model.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/ui/custom_theme.dart';
import 'package:routine_planner/ui/tokens.dart';
import 'tokens_test.dart' show contrast;

void main() {
  test('هر ۶ رنگِ اصلی × روشن/تاریک: متنِ روی دکمه خوانا (≥ ۴٫۵)', () {
    final bad = <String>[];
    for (final a in accents) {
      for (final dark in [false, true]) {
        final st = defaultState()..['accentTheme'] = a.id..['theme'] = dark ? 'dark' : 'light'..['themeIntensity'] = dark ? 100 : 0;
        final p = paletteFromState(st);
        final r = contrast(p.onPrimary, p.primary);
        if (r < 4.5) bad.add('${a.id} ${dark ? 'dark' : 'light'}: ${r.toStringAsFixed(2)}');
      }
    }
    expect(bad, isEmpty);
  });

  test('شدتِ روشن/تاریک: ۰ = روشن، ۱۰۰ = تاریک، میانه مخلوط؛ سازگار با بدون‌مقدار', () {
    final light = paletteFromState(defaultState()..['themeIntensity'] = 0);
    final dark = paletteFromState(defaultState()..['theme'] = 'dark'..['themeIntensity'] = 100);
    final mid = paletteFromState(defaultState()..['themeIntensity'] = 50);
    expect(light.surface, const Color(0xFFFFFFFF));
    expect(dark.text, RpPalette.dark.text);
    expect(mid.surface, isNot(light.surface));
    expect(mid.surface, isNot(dark.surface));
    final legacy = defaultState()..['theme'] = 'dark'..remove('themeIntensity');
    expect(intensityOf(legacy), 1.0);
  });

  test('HSL رفت‌وبرگشت و رنگِ کاشی در تاریک روشن‌تر', () {
    for (final h in ['#3E9B4F', '#C0483B', '#E5DBC8', '#146B69']) {
      final c = parseHex(h)!;
      final v = hexToHsl(c);
      final back = hslToColor(v.h, v.s, v.l);
      expect((back.r - c.r).abs() * 255, lessThan(1.5));
      expect((back.g - c.g).abs() * 255, lessThan(1.5));
      expect((back.b - c.b).abs() * 255, lessThan(1.5));
      final want = hexToHsl(c);
      final got = hexToHsl(tileColor(c, true));
      expect(got.l, closeTo((want.l + 22 < 72 ? want.l + 22 : 72), 1.0)); // deriveTileColor
    }
    expect(tileColor(const Color(0xFF3E9B4F), false), const Color(0xFF3E9B4F));
  });

  testWidgets('تنظیمات: زبان، اندازه فونت، تقویم و رنگ اصلی ذخیره می‌شوند', (tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_s');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    final nav = NavController()..go(AppView.settings);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('بزرگ'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.state['fontSize'], 'large');
    Future<void> tapText(String t) async {
      await tester.ensureVisible(find.text(t));
      await tester.pump();
      await tester.tap(find.text(t));
      await tester.pump(const Duration(milliseconds: 200));
    }

    await tapText('یکشنبه');
    await tapText('میلادی');
    await tapText('آبی');
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.state['weekStart'], 1);
    expect(store.state['calendarType'], 'gregorian');
    expect(store.state['accentTheme'], 'blue');
    await tapText('English');
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.state['lang'], 'en');
    expect(find.text('Language'), findsOneWidget);
    // ذخیره روی دیسک
    expect(File('${dir.path}/s.json').readAsStringSync(), contains('"accentTheme":"blue"'));
    await tester.pumpWidget(const SizedBox());
  });
}
