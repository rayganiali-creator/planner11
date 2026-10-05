// محیطِ آواتار: آسمان، خورشید/ماهِ نقاشی‌شده، ابر، ستاره و تپه‌های ملایم. فقط به ساعتِ واقعیِ دستگاه بستگی دارد
// (نه به حالت روشن/تاریک برنامه) و عوض‌شدن روز/شب نرم انیمیت می‌شود.
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// ۰ = شب کامل، ۱ = روز کامل؛ طلوع ≈ ۷:۰۰ و غروب ≈ ۱۹:۰۰ (هم‌خوان با isDay)
double daylightAt(DateTime t) {
  final h = t.hour + t.minute / 60;
  double smooth(double x) => x * x * (3 - 2 * x);
  if (h < 6.5 || h >= 19.5) return 0;
  if (h < 7.5) return smooth(h - 6.5);
  if (h < 18.5) return 1;
  return smooth(1 - (h - 18.5));
}

class AvatarScene extends StatelessWidget {
  final double daylight;
  final Widget? child;
  final BorderRadius radius;
  const AvatarScene({super.key, required this.daylight, this.child, this.radius = const BorderRadius.all(Radius.circular(20))});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: radius,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: daylight),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeInOutCubic,
          builder: (_, f, c) => CustomPaint(painter: ScenePainter(f), child: c),
          child: child,
        ),
      );
}

class ScenePainter extends CustomPainter {
  final double f; // 0 شب … 1 روز
  ScenePainter(this.f);

  static const _skyDayTop = Color(0xFF86B6D2), _skyDayBot = Color(0xFFD6E8E2);
  static const _skyNightTop = Color(0xFF0B1A33), _skyNightBot = Color(0xFF1E3F5A);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height, m = math.min(w, h);
    final rect = Offset.zero & s;
    // آسمان
    c.drawRect(
      rect,
      Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [Color.lerp(_skyNightTop, _skyDayTop, f)!, Color.lerp(_skyNightBot, _skyDayBot, f)!]),
    );
    // درخششِ گرمِ طلوع/غروب
    final warm = math.sin(math.pi * f) * (f < 1 && f > 0 ? 1 : 0);
    if (warm > 0.01) {
      c.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset(0, h * .35), Offset(0, h), [const Color(0x00FFB07A), const Color(0xFFFFB07A).withValues(alpha: .30 * warm)]));
    }
    // ستاره‌ها
    final starA = (1 - f) * .75;
    if (starA > .02) {
      const pts = [(.12, .12), (.27, .30), (.42, .10), (.58, .24), (.71, .08), (.86, .20), (.93, .38), (.07, .42), (.50, .36), (.34, .18), (.78, .33), (.20, .05)];
      for (int i = 0; i < pts.length; i++) {
        final r = (i % 3 == 0 ? 1.4 : 1.0) * m / 150;
        c.drawCircle(Offset(pts[i].$1 * w, pts[i].$2 * h), r, Paint()..color = Colors.white.withValues(alpha: starA * (i.isEven ? 1 : .7)));
      }
    }
    // خورشید
    final sunA = f;
    if (sunA > .01) {
      final o = Offset(w * .26, h * (0.62 - 0.38 * f));
      c.drawCircle(o, m * .36, Paint()..shader = ui.Gradient.radial(o, m * .36, [const Color(0xFFFFE9A8).withValues(alpha: .55 * sunA), const Color(0x00FFE9A8)]));
      c.drawCircle(o, m * .105, Paint()..shader = ui.Gradient.radial(o, m * .105, [const Color(0xFFFFF6D8).withValues(alpha: sunA), const Color(0xFFFFD36B).withValues(alpha: sunA)]));
    }
    // ماه (هلال نرم)
    final moonA = 1 - f;
    if (moonA > .01) {
      final o = Offset(w * .28, h * (0.24 + 0.34 * f));
      final r = m * .095;
      c.drawCircle(o, m * .30, Paint()..shader = ui.Gradient.radial(o, m * .30, [const Color(0xFFBFD4FF).withValues(alpha: .28 * moonA), const Color(0x00BFD4FF)]));
      final full = Path()..addOval(Rect.fromCircle(center: o, radius: r));
      final cut = Path()..addOval(Rect.fromCircle(center: o + Offset(r * .55, -r * .25), radius: r * .88));
      c.drawPath(Path.combine(PathOperation.difference, full, cut), Paint()..color = const Color(0xFFF3F1E4).withValues(alpha: moonA));
    }
    // ابر (فقط روز)
    if (f > .02) {
      final cp = Paint()
        ..color = Colors.white.withValues(alpha: .55 * f)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, m * .03);
      void cloud(double cx, double cy, double sc) {
        final o = Offset(cx * w, cy * h);
        c.drawOval(Rect.fromCenter(center: o, width: m * .34 * sc, height: m * .10 * sc), cp);
        c.drawOval(Rect.fromCenter(center: o + Offset(m * .07 * sc, -m * .04 * sc), width: m * .20 * sc, height: m * .10 * sc), cp);
      }

      cloud(.62, .22, 1);
      cloud(.18, .50, .7);
    }
    // تپه‌های دور و نزدیک
    Path hill(double base, double amp, double phase) {
      final p = Path()..moveTo(0, h);
      for (double x = 0; x <= w; x += 4) {
        p.lineTo(x, h * base - amp * h * math.sin(x / w * math.pi * 1.6 + phase));
      }
      return p..lineTo(w, h)..close();
    }

    c.drawPath(hill(.80, .045, 0.6), Paint()..color = Color.lerp(const Color(0xFF14313A), const Color(0xFFA9CDBB), f)!);
    c.drawPath(hill(.90, .035, 2.4), Paint()..color = Color.lerp(const Color(0xFF0D262B), const Color(0xFF86B8A4), f)!);
  }

  @override
  bool shouldRepaint(ScenePainter o) => o.f != f;
}
