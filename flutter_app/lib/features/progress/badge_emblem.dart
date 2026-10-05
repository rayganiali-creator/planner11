// نشان (Badge): طراحیِ هندسیِ ظریف، خطی و مینیمال — نه پیکسل‌آرت، نه مدالِ بازی.
// همه‌ی رنگ‌ها از «توکن‌های نشان» می‌آیند که از پالتِ تمِ جاری ساخته می‌شوند (Light/Dark و همه‌ی تم‌ها).
import 'dart:math' as math;

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

/// نشان: تصویرِ شیتِ ۴۸ نشان (assets/badges/badge_NN.png). قفل = خاکستریِ کم‌رنگ، Near = کمی روشن‌تر + کمانِ پیشرفت.
class BadgeEmblem extends StatelessWidget {
  final AchDef def;
  final AchState state;
  final double ratio; // پیشرفت (برای حالتِ Near)
  final double size;
  final bool premium; // سازگاریِ API؛ ظاهرِ نشان‌ها یکسان است
  const BadgeEmblem({super.key, required this.def, required this.state, this.ratio = 0, this.size = 72, this.premium = false});

  static const _gray = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final n = badgeArt(def);
    Widget img = Image.asset('assets/badges/badge_${n.toString().padLeft(2, '0')}.png', width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.medium, gaplessPlayback: true, excludeFromSemantics: true);
    if (state != AchState.unlocked) {
      img = Opacity(opacity: state == AchState.near ? 0.62 : 0.34, child: ColorFiltered(colorFilter: _gray, child: img));
    }
    return Semantics(
      label: '${def.nameFa} — ${state == AchState.unlocked ? 'دریافت شده' : 'قفل'}',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: Stack(alignment: Alignment.center, children: [
            img,
            if (state == AchState.near) CustomPaint(size: Size.square(size), painter: _ArcPainter(ratio, p.primary, 0.95)),
          ]),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double ratio, radius;
  final Color color;
  _ArcPainter(this.ratio, this.color, this.radius);

  @override
  void paint(Canvas canvas, Size s) {
    final R = s.width / 2;
    final rect = Rect.fromCircle(center: s.center(Offset.zero), radius: R * radius);
    canvas.drawArc(rect, 0, math.pi * 2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = R * 0.05..color = color.withValues(alpha: 0.16));
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * ratio.clamp(0, 1), false, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = R * 0.05..color = color);
  }

  @override
  bool shouldRepaint(_ArcPainter o) => o.ratio != ratio || o.color != color || o.radius != radius;
}
