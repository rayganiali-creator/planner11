// داشبورد: هدر، صحنه‌ی آواتار (روز/شب)، آمار، خلاصه‌ی امروز و عادت‌های امروز.
// فقط نمایش است؛ هر ثبت از AppActions می‌گذرد (همان منطقِ نسخه‌ی HTML).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../app/nav.dart';
import '../../core/calendar.dart';
import '../../core/date_fmt.dart';
import '../../core/doc.dart';
import '../../core/format.dart';
import '../../core/gameplay.dart';
import '../../core/habits.dart';
import '../../core/smart.dart';
import '../../core/smart_extras.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../avatar/avatar_compose.dart';
import '../avatar/avatar_scene.dart';
import '../challenges/challenges_sheet.dart';
import '../avatar/avatar_panel.dart';
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
    final stats = dayStats(st, iso);
    final streak = (scores['streak'] as num?)?.toInt() ?? computeStreak(st, now); // مثل «روزهای موفقیت متوالی» HTML (همه‌ی عادت‌ها، نه فقط دائمی)
    final pct = stats.total == 0 ? 0.0 : stats.success / stats.total;
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        _Header(text: clockText(_now, fa: fa, jalali: isJalali(st))),
        const SizedBox(height: RpSpace.s4),
        _HeroCard(state: st, now: now, cond: cond, hp: hp, streak: streak, level: (scores['level'] as num?)?.toInt() ?? 1, coins: (scores['coins'] as num?) ?? 0, points: (scores['points'] as num?) ?? 0),
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
        _HabitsProgress(state: st, now: now),
        const SizedBox(height: RpSpace.s3),
        _ChallengesCard(state: st),
        const SizedBox(height: RpSpace.s3),
        _SmartTeaser(state: st, now: now),
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

/// کارتِ بالای خانه: آواتار (کادر تقریباً مربع) سمت راست؛ استریک (برجسته) و HP/سکه/امتیاز سمت چپ.
class _HeroCard extends StatelessWidget {
  final Map state;
  final DateTime now;
  final String cond;
  final int hp, streak, level;
  final num coins, points;
  const _HeroCard({required this.state, required this.now, required this.cond, required this.hp, required this.streak, required this.level, required this.coins, required this.points});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final dir = Directionality.of(context);
    return LayoutBuilder(builder: (context, c) {
      final side = math.min(156.0, c.maxWidth * .44);
      return Directionality(
        textDirection: TextDirection.ltr, // آواتار همیشه سمت راست (فارسی و انگلیسی)
        child: SizedBox(
          height: side,
          child: Row(children: [
            Expanded(
              child: Directionality(
                textDirection: dir,
                // کارتِ HUD ارتفاع ثابت دارد؛ مقیاسِ متن را محدود می‌کنیم تا سرریز نشود
                child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.0, child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _StreakPanel(streak: streak),
                  _HpRow(hp: hp),
                  Row(children: [
                    Expanded(child: _MiniStat(icon: LucideIcons.coins, value: context.n(coins.toInt()), label: context.tr('سکه', 'Coins'), color: p.goldInk)),
                    Expanded(child: _MiniStat(icon: LucideIcons.sparkles, value: context.n(points.round()), label: context.tr('امتیاز', 'Points'), color: p.xpInk)),
                  ]),
                ])),
              ),
            ),
            const SizedBox(width: RpSpace.s3),
            SizedBox(
              width: side,
              height: side,
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(RpRadius.xl), boxShadow: RpShadow.e2(context.rpBrightness)),
                child: AvatarScene(
                  daylight: daylightAt(now),
                  radius: BorderRadius.circular(RpRadius.xl),
                  child: Stack(children: [
                    Positioned.fill(child: Align(alignment: (state['avatar'] is Map && (state['avatar'] as Map)['gender'] != null) ? const Alignment(0, .92) : const Alignment(0, -.25), child: _StageAvatar(state: state, cond: cond, height: side * .86))),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Directionality(textDirection: dir, child: RpChip(context.tr('سطح ${context.n(level)}', 'Lv $level'), icon: LucideIcons.award)),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

class _StreakPanel extends StatelessWidget {
  final int streak;
  const _StreakPanel({required this.streak});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RpRadius.lg),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.fire.withValues(alpha: .20), p.fire.withValues(alpha: .06)]),
        border: Border.all(color: p.fire.withValues(alpha: .35)),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.fire.withValues(alpha: .85), p.fire]), boxShadow: [BoxShadow(color: p.fire.withValues(alpha: .35), blurRadius: 10)]),
          child: const Icon(LucideIcons.flame, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(context.n(streak), key: const ValueKey('hero-streak'), style: rpText(30, weight: 900, color: p.fire, height: 1.0))),
            Text(context.tr('روز پیاپی', 'day streak'), maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.caption, weight: 700, color: p.muted)),
          ]),
        ),
      ]),
    );
  }
}

class _HpRow extends StatelessWidget {
  final int hp;
  const _HpRow({required this.hp});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(LucideIcons.heart, size: 14, color: p.hpInk),
        const SizedBox(width: 4),
        Text('HP', style: rpText(RpType.caption, weight: 700, color: p.muted)),
        const Spacer(),
        Text(context.n(hp), style: rpText(RpType.label, weight: 800, color: p.hpInk)),
      ]),
      const SizedBox(height: 4),
      RpProgressBar(value: (hp / 100).clamp(0.0, 1.0).toDouble(), colors: [p.hp, p.hpInk], height: 6),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _MiniStat({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, style: rpText(RpType.label, weight: 800, color: p.text, height: 1.1))),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(10, weight: 600, color: p.muted, height: 1.1)),
        ]),
      ),
    ]);
  }
}

class _StageAvatar extends StatelessWidget {
  final Map state;
  final String cond;
  final double height;
  const _StageAvatar({required this.state, required this.cond, required this.height});
  @override
  Widget build(BuildContext context) {
    final data = context.read<AvData?>();
    final av = state['avatar'];
    final g = av is Map ? av['gender'] as String? : null;
    if (data == null || g == null) {
      return GestureDetector(
        onTap: () => showAvatarPanel(context),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.userPlus, size: 44, color: Colors.white.withValues(alpha: .92)),
          const SizedBox(height: 6),
          Text(context.tr('آواتار خودت را بساز', 'Create your avatar'), textAlign: TextAlign.center, style: rpText(RpType.label, weight: 800, color: Colors.white, height: 1.4).copyWith(shadows: const [Shadow(color: Color(0x66000000), blurRadius: 6)])),
        ]),
      );
    }
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => showAvatarPanel(context), child: AvatarView(data: data, gender: g, equipped: data.equippedFor(state as Doc, g), cond: cond, height: height, cropToContent: true));
  }
}

/// «چالش‌ها»: بخشِ کشویی؛ بسته فقط شمارِ فعال‌ها، باز: ردیف‌های پیشرفت + دکمه‌ی مدیریت.
class _ChallengesCard extends StatelessWidget {
  final Map state;
  const _ChallengesCard({required this.state});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    final active = ((state['challenges'] as List?) ?? const []).whereType<Map>().where((c) => c['status'] == 'active' || c['status'] == 'pending_review').toList()
      ..sort((x, y) => ((y['createdAt'] as num?) ?? 0).compareTo((x['createdAt'] as num?) ?? 0));
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return RpCollapsible(
      key: const ValueKey('home-challenges'),
      persistKey: 'homeChallenges',
      icon: LucideIcons.trophy,
      title: context.tr('چالش‌ها', 'Challenges'),
      summary: active.isEmpty ? context.tr('فعالی نیست', 'None active') : context.tr('${context.n(active.length)} فعال', '${active.length} active'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (active.isEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(context.tr('چالش فعالی نداری.', 'No active challenges.'), style: rpText(RpType.body, weight: 500, color: p.muted))),
        for (final c in active.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(builder: (_) {
              double pct;
              String meta;
              final countish = c['kind'] == 'count' || c['kind'] == 'both';
              if (countish) {
                pct = (((c['progressCount'] as num?) ?? 0) / (c['targetCount'] as num)).clamp(0.0, 1.0).toDouble();
                meta = fa ? '${toPersianDigits(c['progressCount'] ?? 0)} از ${toPersianDigits(c['targetCount'])} ${c['unit'] ?? ''}' : '${c['progressCount'] ?? 0} / ${c['targetCount']} ${c['unit'] ?? ''}';
                if (c['kind'] == 'both' && c['deadlineAt'] is num) meta += ' · ${formatCountdown((c['deadlineAt'] as num).toInt() - nowMs, fa)}';
              } else {
                final remain = (c['deadlineAt'] as num).toInt() - nowMs;
                final total = (c['deadlineAt'] as num).toInt() - (c['createdAt'] as num).toInt();
                pct = total > 0 ? (1 - remain / total).clamp(0.0, 1.0).toDouble() : 0;
                meta = formatCountdown(remain, fa);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text('${c['icon']} ${c['name']}', style: rpText(RpType.body, weight: 700, color: p.text))), Text(meta, style: rpText(RpType.caption, weight: 600, color: p.muted))]),
                const SizedBox(height: 4),
                RpProgressBar(value: pct, colors: [p.gold, p.goldSoft]),
              ]);
            }),
          ),
        RpButton(context.tr('مدیریت چالش‌ها', 'Manage challenges'), small: true, kind: BtnKind.tonal, onTap: () => showChallenges(context, tab: 'active')),
      ]),
    );
  }
}

/// «پیشرفت عادت‌ها»: بخشِ کشویی؛ پیش‌فرض بسته (خانه خلوت می‌ماند) و وضعیت ذخیره می‌شود.
class _HabitsProgress extends StatelessWidget {
  final Doc state;
  final DateTime now;
  const _HabitsProgress({required this.state, required this.now});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final habits = ((state['habits'] as List?) ?? const []).cast<Map>();
    final fa = context.isFa;
    return RpCollapsible(
      key: const ValueKey('home-progress'),
      persistKey: 'homeProgress',
      icon: LucideIcons.chartNoAxesColumn,
      title: context.tr('پیشرفت عادت‌ها', 'Habits progress'),
      summary: habits.isEmpty ? null : context.tr('${context.n(habits.length)} عادت', '${habits.length} habits'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (habits.isEmpty)
          Text(context.tr('هنوز عادتی اضافه نکردی.', "You haven't added any habits yet."), style: rpText(RpType.body, weight: 500, color: p.muted))
        else
          for (final h in habits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Builder(builder: (_) {
                final perm = h['permanent'] != false;
                final pct = habitProgressPct(state, h, now);
                final streak = perm ? computeHabitStreak(state, h, now) : 0;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${h['name']}', style: rpText(RpType.body, weight: 700, color: p.text)),
                        if (perm) TextSpan(text: fa ? '  (۳۰ روز اخیر)' : '  (last 30 days)', style: rpText(RpType.caption, weight: 400, color: p.muted)),
                      ])),
                    ),
                    Text('${context.n(pct)}%', style: rpText(RpType.label, weight: 800, color: p.text)),
                    if (perm && streak > 0) Text('  🔥${context.n(streak)}', style: rpText(RpType.label, weight: 800, color: p.fire)),
                  ]),
                  const SizedBox(height: 4),
                  RpProgressBar(value: pct / 100, colors: [p.primary, p.primary2]),
                ]);
              }),
            ),
      ]),
    );
  }
}

/// ورودِ مینیمال به «تحلیل هوشمند» از خانه: امتیازِ ماه + داوریِ کوتاه (برای غیرپرو: دعوت)
class _SmartTeaser extends StatelessWidget {
  final Doc state;
  final DateTime now;
  const _SmartTeaser({required this.state, required this.now});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    String sub;
    if (state['isPremium'] != true) {
      sub = context.tr('ویژه‌ی پرو', 'Pro');
    } else {
      final score = smartScore(saCompute(state, saPeriod('month', 0, now)));
      sub = score == null ? context.tr('داده‌ی کافی نیست', 'Not enough data') : '${context.n(score)} · ${smartVerdict(score, fa)}';
    }
    return AppCard(
      key: const ValueKey('home-smart'),
      onTap: () => context.read<NavController>().go(AppView.smart),
      child: Row(children: [
        Icon(LucideIcons.brain, color: p.xpInk),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('تحلیل هوشمند', 'Smart Analysis'), style: rpText(RpType.body, weight: 800, color: p.text)),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.caption, weight: 600, color: p.muted)),
          ]),
        ),
        Icon(fa ? LucideIcons.chevronLeft : LucideIcons.chevronRight, size: 18, color: p.muted),
      ]),
    );
  }
}
