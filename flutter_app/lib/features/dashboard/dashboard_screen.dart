// داشبورد: هدر، صحنه‌ی آواتار (روز/شب)، آمار، خلاصه‌ی امروز و عادت‌های امروز.
// فقط نمایش است؛ هر ثبت از AppActions می‌گذرد (همان منطقِ نسخه‌ی HTML).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../app/nav.dart';
import '../../core/calendar.dart';
import '../../core/doc.dart';
import '../../core/format.dart';
import '../../core/gameplay.dart';
import '../../core/habits.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../avatar/avatar_compose.dart';
import '../challenges/challenges_sheet.dart';
import '../avatar/avatar_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 20), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final actions = context.read<AppActions>();
    final p = context.rp;
    final fa = store.state['lang'] != 'en';
    final st = store.state;
    final now = actions.today;
    final iso = dateToISO(startOfDay(now));
    final scores = (st['scores'] is Map ? st['scores'] as Map : const {});
    final hp = computeAvatarHP(st, now);
    final cond = avConditionOf(hp, now.hour);
    final day = isDay(now.hour);
    final stats = dayStats(st, iso);
    final streak = computePermanentStreak(st, now);
    final pct = stats.total == 0 ? 0.0 : stats.success / stats.total;
    final habits = applicableHabitsForISO(st, iso);

    return ListView(
      padding: const EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, 120),
      children: [
        _Header(text: clockText(_now, fa: fa)),
        const SizedBox(height: RpSpace.s4),
        _Stage(state: st, day: day, cond: cond, hp: hp, level: (scores['level'] as num?)?.toInt() ?? 1),
        const SizedBox(height: RpSpace.s3),
        Row(children: [
          _Stat(icon: LucideIcons.heart, label: 'HP', value: context.n(hp), color: p.hpInk, soft: p.hpSoft),
          const SizedBox(width: RpSpace.s2),
          _Stat(icon: LucideIcons.coins, label: context.tr('سکه', 'Coins'), value: context.n((scores['coins'] as num?)?.toInt() ?? 0), color: p.goldInk, soft: p.goldSoft),
          const SizedBox(width: RpSpace.s2),
          _Stat(icon: LucideIcons.flame, label: context.tr('استریک', 'Streak'), value: context.n(streak), color: p.fire, soft: p.goldSoft),
          const SizedBox(width: RpSpace.s2),
          _Stat(icon: LucideIcons.sparkles, label: context.tr('امتیاز', 'Points'), value: context.n((scores['points'] as num?)?.round() ?? 0), color: p.xpInk, soft: p.xpSoft),
        ]),
        const SizedBox(height: RpSpace.s4),
        AppCard(
          child: Row(children: [
            RpRing(
              value: pct,
              size: 72,
              center: Text(context.n('${(pct * 100).round()}%'), style: rpText(RpType.label, weight: 800, color: p.text)),
            ),
            const SizedBox(width: RpSpace.s4),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('پیشرفت امروز', "Today's progress"), style: rpText(RpType.bodyL, weight: 800, color: p.text)),
                const SizedBox(height: 4),
                Text(
                  context.tr('${context.n(stats.success)} از ${context.n(stats.total)} عادت انجام شد', '${stats.success} of ${stats.total} habits done'),
                  style: rpText(RpType.body, weight: 500, color: p.muted),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: RpSpace.s3),
        _ChallengesCard(state: st),
        const SizedBox(height: RpSpace.s4),
        SectionHeader(
          context.tr('عادت‌های امروز', "Today's habits"),
          action: context.tr('همه', 'All'),
          onAction: () => context.read<NavController>().go(AppView.habits),
        ),
        if (habits.isEmpty)
          AppCard(child: Text(context.tr('امروز عادتی سررسید ندارد.', 'No habits are due today.'), style: rpText(RpType.body, weight: 500, color: p.muted)))
        else
          for (final h in habits) _HabitRow(habit: h, iso: iso),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header({required this.text});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final store = context.read<AppStore>();
    final dark = store.state['theme'] == 'dark';
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr('روتین پلنر', 'Routine Planner'), style: rpText(RpType.titleL, weight: 800, color: p.text)),
          Text(text, style: rpText(RpType.label, weight: 500, color: p.muted)),
        ]),
      ),
      IconButton(
        tooltip: context.tr('تم', 'Theme'),
        onPressed: () {
          store.state['theme'] = dark ? 'light' : 'dark';
          store.state['themeIntensity'] = dark ? 0 : 100; // مثل دکمه‌ی تم در HTML
          store.save();
        },
        icon: Icon(dark ? LucideIcons.sun : LucideIcons.moon, color: p.text),
      ),
    ]);
  }
}

class _Stage extends StatelessWidget {
  final Map state;
  final bool day;
  final String cond;
  final int hp, level;
  const _Stage({required this.state, required this.day, required this.cond, required this.hp, required this.level});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RpRadius.xl),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.skyTop, p.skyBottom]),
        boxShadow: RpShadow.e2(context.rpBrightness),
      ),
      child: Stack(children: [
        Positioned(top: 16, right: 20, child: Icon(day ? LucideIcons.sun : LucideIcons.moon, size: 28, color: day ? p.gold : p.skyBottom)),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(height: 56, decoration: BoxDecoration(color: p.ground, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(RpRadius.xl)))),
        ),
        Center(child: _StageAvatar(state: state, cond: cond)),
        Positioned(
          left: 16, bottom: 12,
          child: RpChip(context.tr('سطح ${context.n(level)}', 'Level $level'), icon: LucideIcons.award),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, soft;
  const _Stat({required this.icon, required this.label, required this.value, required this.color, required this.soft});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: RpSpace.s3, horizontal: RpSpace.s2),
        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(RpRadius.md)),
        child: Column(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value, style: rpText(RpType.bodyL, weight: 800, color: color)),
          Text(label, style: rpText(RpType.caption, weight: 600, color: p.muted)),
        ]),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Map habit;
  final String iso;
  const _HabitRow({required this.habit, required this.iso});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final store = context.watch<AppStore>();
    final actions = context.read<AppActions>();
    final ok = habitSuccessOnISO(store.state, habit, iso);
    final binary = habit['type'] == 'binary';
    final id = habit['id'] as String;
    return Padding(
      padding: const EdgeInsets.only(bottom: RpSpace.s2),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: RpSpace.s4, vertical: RpSpace.s3),
        child: Row(children: [
          Expanded(child: Text('${habit['name'] ?? ''}', style: rpText(RpType.body, weight: 700, color: p.text))),
          if (binary) ...[
            _Btn(icon: LucideIcons.x, on: ok == false, color: p.badInk, soft: p.badSoft, onTap: () => ok == false ? actions.clear(iso, id) : actions.setBinary(iso, id, 'fail')),
            const SizedBox(width: RpSpace.s2),
            _Btn(icon: LucideIcons.check, on: ok == true, color: p.okInk, soft: p.okSoft, onTap: () => ok == true ? actions.clear(iso, id) : actions.setBinary(iso, id, 'success')),
          ] else
            Icon(ok == true ? LucideIcons.circleCheck : LucideIcons.circle, color: ok == true ? p.okInk : p.muted),
        ]),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final bool on;
  final Color color, soft;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.on, required this.color, required this.soft, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: RpMotion.fast,
          width: 44, height: 44,
          decoration: BoxDecoration(color: on ? color : soft, borderRadius: BorderRadius.circular(RpRadius.sm)),
          child: Icon(icon, size: 20, color: on ? Colors.white : color),
        ),
      );
}

class _StageAvatar extends StatelessWidget {
  final Map state;
  final String cond;
  const _StageAvatar({required this.state, required this.cond});
  @override
  Widget build(BuildContext context) {
    final data = context.read<AvData?>();
    final av = state['avatar'];
    final g = av is Map ? av['gender'] as String? : null;
    if (data == null || g == null) {
      return Icon(LucideIcons.user, size: 72, color: context.rp.onPrimary.withValues(alpha: .85));
    }
    return AvatarView(data: data, gender: g, equipped: data.equippedFor(state as Doc, g), cond: cond, height: 190);
  }
}

class _ChallengesCard extends StatelessWidget {
  final Map state;
  const _ChallengesCard({required this.state});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final active = ((state['challenges'] as List?) ?? const []).where((c) => c is Map && (c['status'] == 'active' || c['status'] == 'pending_review')).length;
    return AppCard(
      onTap: () => showChallenges(context, tab: 'active'),
      child: Row(children: [
        Icon(LucideIcons.trophy, color: p.goldInk),
        const SizedBox(width: RpSpace.s3),
        Expanded(child: Text(context.tr('چالش‌ها', 'Challenges'), style: rpText(RpType.bodyL, weight: 800, color: p.text))),
        Text(active == 0 ? context.tr('چالش فعالی نیست', 'None active') : context.tr('${context.n(active)} فعال', '$active active'), style: rpText(RpType.label, weight: 600, color: p.muted)),
        const SizedBox(width: 6),
        Icon(LucideIcons.chevronLeft, size: 18, color: p.muted),
      ]),
    );
  }
}
