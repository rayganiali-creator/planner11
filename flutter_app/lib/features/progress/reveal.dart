// نمایشِ ظریفِ «سطح بالا رفت» و «دستاورد باز شد»: Scale نرم، درخششِ بسیار ملایم، نوارِ پیشرفت و Badge Reveal.
// بدونِ Confetti، انفجار، آتش‌بازی، صدا، چشمک یا متنِ غول‌پیکر.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../core/progress/achievements.dart';
import '../../core/progress/config.dart';
import '../../core/progress/engine.dart';
import '../../data/actions.dart';
import '../../ui/tokens.dart';
import 'badge_emblem.dart';
import 'profile_card.dart';
import 'progress_data.dart';

/// اگر رخدادِ اعلام‌نشده‌ای هست، به‌ترتیب (سطح، سپس نشان‌ها) نشان می‌دهد و بعد «اعلام‌شده» ثبت می‌کند.
Future<void> showPendingReveals(BuildContext context) async {
  final a = context.read<AppActions>();
  final pend = pendingAnnouncements(a.store.state);
  if (pend.isEmpty) return;
  {
    if (pend.level != null) {
      await _show(context, _LevelReveal(pend.level!));
      if (!context.mounted) return;
    }
    for (final id in pend.badges) {
      final def = achById(id);
      if (def == null) continue;
      await _show(context, _BadgeReveal(def));
      if (!context.mounted) return;
    }
    markAnnounced(a.store.state);
    a.store.save();
  }
}

Future<void> _show(BuildContext context, Widget w) => showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => Center(child: w),
      transitionBuilder: (ctx, anim, _, child) {
        final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(opacity: c, child: ScaleTransition(scale: Tween<double>(begin: .92, end: 1).animate(c), child: child));
      },
    );

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(RpRadius.xl), border: Border.all(color: p.line), boxShadow: RpShadow.e3(context.rpBrightness)),
        child: child,
      ),
    );
  }
}

class _BadgeReveal extends StatelessWidget {
  final AchDef def;
  const _BadgeReveal(this.def);
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return _Card(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(context.tr('دستاورد جدید', 'Achievement unlocked'), key: const ValueKey('reveal-title'), style: rpText(RpType.label, weight: 600, color: p.muted)),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
          builder: (_, t, child) => Stack(alignment: Alignment.center, children: [
            Opacity(opacity: (1 - (t - .55).abs() * 2).clamp(0.0, 1.0) * .35, child: Container(width: 150 * t, height: 150 * t, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [p.gold.withValues(alpha: .5), p.gold.withValues(alpha: 0)])))),
            Transform.scale(scale: .6 + .4 * t.clamp(0.0, 1.0), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
          ]),
          child: BadgeEmblem(def: def, state: AchState.unlocked, size: 120),
        ),
        const SizedBox(height: 14),
        Text(achName(context, def), key: const ValueKey('reveal-name'), textAlign: TextAlign.center, style: rpText(RpType.title, weight: 800, color: p.text)),
        const SizedBox(height: 4),
        Text(achDesc(context, def), textAlign: TextAlign.center, style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.8)),
        const SizedBox(height: 10),
        TextButton(key: const ValueKey('reveal-ok'), onPressed: () => Navigator.of(context).pop(), child: Text(context.tr('ادامه', 'Continue'))),
      ]),
    );
  }
}

class _LevelReveal extends StatelessWidget {
  final int level;
  const _LevelReveal(this.level);
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final rank = rankForLevel(level);
    final d = progressDataOf(context, watch: false);
    return _Card(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(context.tr('سطح جدید', 'Level up'), key: const ValueKey('reveal-title'), style: rpText(RpType.label, weight: 600, color: p.muted)),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, t, _) => SizedBox(
            width: 130,
            height: 130,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 130, height: 130, child: CircularProgressIndicator(value: d.snap.ratio * t, strokeWidth: 5, backgroundColor: p.line, color: p.primary, strokeCap: StrokeCap.round)),
              Opacity(opacity: t, child: Text(context.n(level), key: const ValueKey('reveal-level'), style: rpText(46, weight: 800, color: p.text, height: 1.0))),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text(rankName(context, rank), style: rpText(RpType.bodyL, weight: 700, color: p.primary)),
        const SizedBox(height: 4),
        Text(context.tr('با فعالیت واقعی‌ات به سطح ${context.n(level)} رسیدی.', 'You reached level $level through real activity.'), textAlign: TextAlign.center, style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.8)),
        const SizedBox(height: 10),
        TextButton(key: const ValueKey('reveal-ok'), onPressed: () => Navigator.of(context).pop(), child: Text(context.tr('ادامه', 'Continue'))),
      ]),
    );
  }
}
