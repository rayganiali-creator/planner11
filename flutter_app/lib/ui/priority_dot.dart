// اولویتِ عادت: سه سطحِ طلایی (بالا)، نقره‌ای (متوسط)، برنزی (پایین). هر سطح یک دایره‌ی کوچکِ مینیمال و درخشان است.
// مقدارهای قدیمی (gold/red/yellow/green از نسخه‌ی HTML) به این سه نگاشت می‌شوند؛ داده‌ی کاربر دست نمی‌خورد.
import 'package:flutter/material.dart';

enum HabitPriority { gold, silver, bronze }

/// gold|red → طلایی، yellow|silver (و ناشناخته) → نقره‌ای، green|bronze → برنزی
HabitPriority habitPriorityOf(Object? v) => switch ('$v') {
      'gold' || 'red' => HabitPriority.gold,
      'bronze' || 'green' => HabitPriority.bronze,
      _ => HabitPriority.silver,
    };

String habitPriorityNameFa(HabitPriority p) => const ['طلایی', 'نقره‌ای', 'برنزی'][p.index];
String habitPriorityNameEn(HabitPriority p) => const ['Gold', 'Silver', 'Bronze'][p.index];
String habitPriorityHintFa(HabitPriority p) => const ['اولویت بالا', 'اولویت متوسط', 'اولویت پایین'][p.index];
String habitPriorityHintEn(HabitPriority p) => const ['High priority', 'Medium priority', 'Low priority'][p.index];

class PriorityDot extends StatelessWidget {
  final HabitPriority level;
  final double size;
  const PriorityDot(this.level, {super.key, this.size = 11});

  static (Color, Color, Color) _c(HabitPriority l) => switch (l) {
        HabitPriority.gold => (const Color(0xFFFFF0A8), const Color(0xFFE5A400), const Color(0xFFFFC21A)),
        HabitPriority.silver => (const Color(0xFFFFFFFF), const Color(0xFF9FB2CC), const Color(0xFFA9C4F0)),
        HabitPriority.bronze => (const Color(0xFFFFD2A6), const Color(0xFFC0642A), const Color(0xFFF09048)),
      };

  @override
  Widget build(BuildContext context) {
    final (hi, lo, glow) = _c(level);
    return Container(
      key: ValueKey('prio-${level.name}'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-0.35, -0.4), radius: 0.95, colors: [hi, lo]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 0.7),
        boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.6), blurRadius: size * 0.9, spreadRadius: size * 0.04)],
      ),
    );
  }
}
