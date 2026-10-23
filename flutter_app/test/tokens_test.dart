// تضمینِ خوانایی: هر جفتِ متن/زمینه‌ای که Design System می‌سازد باید از WCAG 2.x بگذرد.
// (متن ≥ ۴٫۵ ، آیکون/عنصر غیرمتنی ≥ ۳٫۰) — برای هر دو تم.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/ui/tokens.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final entry in {'روشن': RpPalette.light, 'تاریک': RpPalette.dark}.entries) {
    final p = entry.value;
    group('کنتراست ${entry.key}', () {
      // [متن, زمینه, حداقل, توضیح]
      final pairs = <List<Object>>[
        [p.text, p.bg, 4.5, 'متن روی زمینه'],
        [p.text, p.surface, 4.5, 'متن روی کارت'],
        [p.muted, p.bg, 4.5, 'متن ثانویه روی زمینه'],
        [p.muted, p.surface, 4.5, 'متن ثانویه روی کارت'],
        [p.muted, p.surface2, 4.5, 'متن ثانویه روی کارت دوم'],
        [p.primary, p.surface, 4.5, 'لینک/برند روی کارت'],
        [p.primary, p.primarySoft, 4.5, 'برچسب برند'],
        [p.goldInk, p.goldSoft, 4.5, 'برچسب طلایی'],
        [p.xpInk, p.xpSoft, 4.5, 'برچسب XP'],
        [p.hpInk, p.hpSoft, 4.5, 'برچسب HP'],
        [p.okInk, p.okSoft, 4.5, 'برچسب موفق'],
        [p.badInk, p.badSoft, 4.5, 'برچسب ناموفق'],
        [p.blueInk, p.blueSoft, 4.5, 'برچسب آبی'],
        [p.goldInk, p.surface, 4.5, 'عدد سکه روی کارت'],
        [p.xpInk, p.surface, 4.5, 'عدد XP روی کارت'],
        [p.hpInk, p.surface, 4.5, 'عدد HP روی کارت'],
        [p.okInk, p.surface, 4.5, 'موفق روی کارت'],
        [p.badInk, p.surface, 4.5, 'ناموفق روی کارت'],
        [p.fire, p.surface2, 3.0, 'آیکون آتش (streak) روی کارت دوم'],
        [p.onPrimary, p.btnA, 4.5, 'متن دکمه — ابتدای گرادیان'],
        [p.onPrimary, p.btnB, 4.5, 'متن دکمه — انتهای گرادیان'],
        [p.onOk, p.ok, 3.0, 'آیکون تیک روی دکمه‌ی موفق'],
        [p.onGold, p.gold, 4.5, 'آیکون + روی دکمه‌ی طلایی'],
      ];
      for (final c in pairs) {
        test('${c[3]}', () {
          final r = contrast(c[0] as Color, c[1] as Color);
          expect(r, greaterThanOrEqualTo(c[2] as double), reason: '${c[3]}: ${r.toStringAsFixed(2)} < ${c[2]}');
        });
      }
    });
  }

  test('هر دو تم ساخته می‌شوند و پالت را در اختیار می‌گذارند', () {
    for (final b in Brightness.values) {
      final t = buildRpTheme(b);
      expect(t.extension<RpTheme>(), isNotNull);
      expect(t.brightness, b);
      expect(t.scaffoldBackgroundColor, (b == Brightness.dark ? RpPalette.dark : RpPalette.light).bg);
    }
  });

  test('مقیاس تایپوگرافی دقیقاً ۷ پله و شعاع‌ها ۶ مقدار است', () {
    expect({RpType.display, RpType.titleL, RpType.title, RpType.bodyL, RpType.body, RpType.label, RpType.caption}.length, 7);
    expect({RpRadius.xs, RpRadius.sm, RpRadius.md, RpRadius.lg, RpRadius.xl, RpRadius.pill}.length, 6);
  });
}
