// نشان (Badge): طراحیِ هندسیِ ظریف، خطی و مینیمال — نه پیکسل‌آرت، نه مدالِ بازی.
// همه‌ی رنگ‌ها از «توکن‌های نشان» می‌آیند که از پالتِ تمِ جاری ساخته می‌شوند (Light/Dark و همه‌ی تم‌ها).
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/progress/achievements.dart';
import '../../ui/tokens.dart';

/// توکن‌های طراحیِ نشان: تغییرِ ظاهرِ همه‌ی نشان‌ها فقط از همین‌جا.
class BadgeTokens {
  final Color surface, border, icon, locked, progress, unlocked, legendary;
  final Color metalLight, metalDark;
  const BadgeTokens({required this.surface, required this.border, required this.icon, required this.locked, required this.progress, required this.unlocked, required this.legendary, required this.metalLight, required this.metalDark});

  static (Color, Color) _metal(BadgeTier t) => switch (t) {
        BadgeTier.bronze => (const Color(0xFFDDA983), const Color(0xFF8C5B3B)),
        BadgeTier.silver => (const Color(0xFFDADFE6), const Color(0xFF8993A2)),
        BadgeTier.gold => (const Color(0xFFEBD07F), const Color(0xFFA8812A)),
        BadgeTier.platinum => (const Color(0xFFD3E7F0), const Color(0xFF6C93AA)),
        BadgeTier.legendary => (const Color(0xFFF2E4B4), const Color(0xFFA48BD6)),
      };

  factory BadgeTokens.of(RpPalette p, BadgeTier tier) {
    final (l, d) = _metal(tier);
    // رنگِ فلز کمی با رنگِ اصلیِ تم هماهنگ می‌شود (تفاوتِ Tier ظریف می‌ماند)
    Color tint(Color c, double t) => Color.lerp(c, p.primary, t)!;
    return BadgeTokens(
      surface: p.surface,
      border: p.line,
      icon: Color.lerp(tint(d, 0.12), p.text, 0.22)!,
      locked: p.muted,
      progress: p.primary,
      unlocked: tint(l, 0.10),
      legendary: tier == BadgeTier.legendary ? const Color(0xFFB79CE8) : d,
      metalLight: tint(l, 0.10),
      metalDark: tint(d, 0.12),
    );
  }
}

String tierNameFa(BadgeTier t) => const ['برنز', 'نقره', 'طلا', 'پلاتین', 'افسانه‌ای'][t.index];
String tierNameEn(BadgeTier t) => const ['Bronze', 'Silver', 'Gold', 'Platinum', 'Legendary'][t.index];
String rarityNameFa(BadgeRarity r) => const ['رایج', 'نسبتاً کمیاب', 'کمیاب', 'حماسی', 'افسانه‌ای'][r.index];
String rarityNameEn(BadgeRarity r) => const ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'][r.index];

class BadgeEmblem extends StatelessWidget {
  final AchDef def;
  final AchState state;
  final double ratio; // پیشرفت (برای حالتِ Near)
  final double size;
  final bool premium; // نسخه‌ی Premium (پرو): حلقه‌ی فلزیِ ظریف‌تر
  const BadgeEmblem({super.key, required this.def, required this.state, this.ratio = 0, this.size = 72, this.premium = false});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Semantics(
      label: '${def.nameFa} — ${state == AchState.unlocked ? 'دریافت شده' : 'قفل'}',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _EmblemPainter(def, state, ratio, BadgeTokens.of(p, def.tier), premium),
        ),
      ),
    );
  }
}

int _sides(String cat) => switch (cat) { 'consistency' => 6, 'productivity' => 4, 'challenges' => 5, 'discipline' => 8, 'season' => 6, _ => 0 };

class _EmblemPainter extends CustomPainter {
  final AchDef def;
  final AchState state;
  final double ratio;
  final BadgeTokens t;
  final bool premium;
  _EmblemPainter(this.def, this.state, this.ratio, this.t, this.premium);

  Path _shape(Offset c, double r) {
    final cat = def.cat;
    final n = _sides(cat);
    final path = Path();
    if (n == 0) {
      if (cat == 'reading') {
        // طاقِ کتاب: مستطیلِ گرد با بالای قوسی
        path.addRRect(RRect.fromRectAndCorners(Rect.fromCenter(center: c, width: r * 1.62, height: r * 1.9), topLeft: Radius.circular(r * 0.81), topRight: Radius.circular(r * 0.81), bottomLeft: Radius.circular(r * 0.22), bottomRight: Radius.circular(r * 0.22)));
      } else if (cat == 'reflection') {
        path.addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: r * 1.7, height: r * 1.7), Radius.circular(r * 0.5)));
      } else {
        path.addOval(Rect.fromCircle(center: c, radius: r));
      }
      return path;
    }
    final rot = switch (cat) { 'productivity' => math.pi / 4, 'season' => math.pi / 6, 'consistency' => 0.0, _ => -math.pi / 2 };
    final rr = cat == 'productivity' ? r * 1.02 : r;
    for (int i = 0; i < n; i++) {
      final a = rot + i * 2 * math.pi / n + (cat == 'consistency' ? -math.pi / 2 : 0);
      final o = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    return path..close();
  }

  void _symbol(Canvas cv, Offset c, double u, Paint stroke, Paint fill) {
    Offset P(double x, double y) => Offset(c.dx + x * u, c.dy + y * u);
    Path poly(List<(double, double)> pts) {
      final p = Path()..moveTo(P(pts[0].$1, pts[0].$2).dx, P(pts[0].$1, pts[0].$2).dy);
      for (final e in pts.skip(1)) {
        final o = P(e.$1, e.$2);
        p.lineTo(o.dx, o.dy);
      }
      return p;
    }

    switch (def.cat) {
      case 'consistency':
        cv.drawPath(poly([(-0.9, 0.6), (-0.3, 0.6), (-0.3, 0.1), (0.3, 0.1), (0.3, -0.4), (0.9, -0.4)]), stroke);
      case 'productivity':
        cv.drawPath(poly([(-0.7, 0.05), (-0.2, 0.55), (0.75, -0.55)]), stroke);
      case 'focus':
        cv.drawCircle(c, u * 0.82, stroke);
        cv.drawCircle(c, u * 0.44, stroke);
        cv.drawCircle(c, u * 0.1, fill);
      case 'reading':
        cv.drawPath(poly([(0, -0.5), (-0.8, -0.62), (-0.8, 0.52), (0, 0.66), (0.8, 0.52), (0.8, -0.62), (0, -0.5)]), stroke);
        cv.drawLine(P(0, -0.5), P(0, 0.66), stroke);
      case 'challenges':
        cv.drawPath(poly([(-0.9, 0.6), (-0.35, -0.35), (0.05, 0.2), (0.4, -0.6), (0.9, 0.6)]), stroke);
      case 'discipline':
        cv.drawPath(poly([(-0.7, 0.05), (0, -0.55), (0.7, 0.05)]), stroke);
        cv.drawPath(poly([(-0.7, 0.62), (0, 0.02), (0.7, 0.62)]), stroke);
      case 'mastery':
        final p = Path()
          ..moveTo(P(0, -0.95).dx, P(0, -0.95).dy)
          ..quadraticBezierTo(P(0.12, -0.12).dx, P(0.12, -0.12).dy, P(0.95, 0).dx, P(0.95, 0).dy)
          ..quadraticBezierTo(P(0.12, 0.12).dx, P(0.12, 0.12).dy, P(0, 0.95).dx, P(0, 0.95).dy)
          ..quadraticBezierTo(P(-0.12, 0.12).dx, P(-0.12, 0.12).dy, P(-0.95, 0).dx, P(-0.95, 0).dy)
          ..quadraticBezierTo(P(-0.12, -0.12).dx, P(-0.12, -0.12).dy, P(0, -0.95).dx, P(0, -0.95).dy);
        cv.drawPath(p, stroke);
      case 'reflection':
        cv.drawLine(P(-0.75, -0.42), P(0.75, -0.42), stroke);
        cv.drawLine(P(-0.75, 0), P(0.45, 0), stroke);
        cv.drawLine(P(-0.75, 0.42), P(0.15, 0.42), stroke);
      default: // season
        cv.drawCircle(c, u * 0.36, stroke);
        for (int i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          cv.drawLine(P(math.cos(a) * 0.62, math.sin(a) * 0.62), P(math.cos(a) * 0.92, math.sin(a) * 0.92), stroke);
        }
    }
  }

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final R = s.width / 2;
    final r = R * 0.80;
    final unlocked = state == AchState.unlocked;
    final stroke = R * 0.052;
    final shape = _shape(c, r);

    if (unlocked) {
      canvas.drawShadow(shape.shift(Offset(0, R * 0.05)), Colors.black.withValues(alpha: 0.28), R * 0.08, false);
      canvas.drawPath(
        shape,
        Paint()
          ..shader = ui.Gradient.linear(Offset(c.dx - r, c.dy - r), Offset(c.dx + r, c.dy + r), [Color.lerp(t.surface, t.metalLight, 0.40)!, Color.lerp(t.surface, t.metalDark, 0.22)!]),
      );
    } else {
      canvas.drawPath(shape, Paint()..color = Color.lerp(t.surface, t.locked, 0.08)!);
    }
    // لبه‌ی فلزیِ ظریف
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..shader = unlocked ? ui.Gradient.linear(Offset(c.dx - r, c.dy - r), Offset(c.dx + r, c.dy + r), [t.metalLight, t.metalDark, t.metalLight], [0, 0.55, 1]) : null
      ..color = t.locked.withValues(alpha: 0.38);
    canvas.drawPath(shape, border);
    // خطِ ریزِ داخلی (جزئیاتِ ظریف)
    final inner = _shape(c, r * 0.80);
    canvas.drawPath(inner, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke * 0.42..strokeJoin = StrokeJoin.round..color = (unlocked ? t.metalDark : t.locked).withValues(alpha: unlocked ? 0.38 : 0.18));
    if (unlocked) {
      // درخششِ بسیار ملایم (Gloss) بالا-چپ
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawCircle(Offset(c.dx - r * 0.5, c.dy - r * 0.62), r * 0.9, Paint()..shader = ui.Gradient.radial(Offset(c.dx - r * 0.5, c.dy - r * 0.62), r * 0.9, [Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0)]));
      canvas.restore();
    }
    // نمادِ خطی
    final symColor = unlocked ? t.icon : t.locked.withValues(alpha: 0.5);
    final sp = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke * 0.95..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = symColor;
    _symbol(canvas, c, r * 0.44, sp, Paint()..color = symColor);
    // نقطه‌های Tier (پایین)
    if (unlocked) {
      final n = def.tier.index + 1;
      for (int i = 0; i < n; i++) {
        final x = c.dx + (i - (n - 1) / 2) * R * 0.11;
        canvas.drawCircle(Offset(x, c.dy + r * 0.80), R * 0.034, Paint()..color = t.metalDark.withValues(alpha: 0.85));
      }
    }
    if (def.tier == BadgeTier.legendary || premium) {
      // حلقه‌ی بیرونیِ بسیار ظریف + نشانه‌های ریز
      final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = R * 0.016..color = (unlocked ? t.legendary : t.locked).withValues(alpha: unlocked ? 0.75 : 0.25);
      canvas.drawCircle(c, R * 0.97, ring);
      if (unlocked && def.tier == BadgeTier.legendary) {
        for (int i = 0; i < 24; i++) {
          final a = i * 2 * math.pi / 24;
          canvas.drawLine(Offset(c.dx + math.cos(a) * R * 0.93, c.dy + math.sin(a) * R * 0.93), Offset(c.dx + math.cos(a) * R * 0.97, c.dy + math.sin(a) * R * 0.97), ring);
        }
      }
    }
    // پیشرفت (Near Unlock): کمانِ ظریفِ دورِ نشان
    if (state == AchState.near) {
      final rect = Rect.fromCircle(center: c, radius: R * 0.95);
      canvas.drawArc(rect, 0, math.pi * 2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = R * 0.05..color = t.progress.withValues(alpha: 0.16));
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * ratio.clamp(0, 1), false, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = R * 0.05..color = t.progress);
    }
  }

  @override
  bool shouldRepaint(_EmblemPainter o) => o.def != def || o.state != state || o.ratio != ratio || o.t.metalDark != t.metalDark || o.t.surface != t.surface || o.premium != premium;
}
