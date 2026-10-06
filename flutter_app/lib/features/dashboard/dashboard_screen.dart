// داشبورد: هدر، صحنه‌ی آواتار (روز/شب)، آمار، خلاصه‌ی امروز و عادت‌های امروز.
// فقط نمایش است؛ هر ثبت از AppActions می‌گذرد (همان منطقِ نسخه‌ی HTML).
import 'dart:async';
import '../onboarding/onboarding.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../app/nav.dart';
import '../../core/analytics.dart';
import '../../core/calendar.dart';
import '../../core/date_fmt.dart';
import '../../core/doc.dart';
import '../../core/format.dart';
import '../../core/habits.dart';
import '../../core/smart.dart';
import '../../ui/pro_widgets.dart';
import '../../core/smart_extras.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../challenges/challenges_sheet.dart';
import '../progress/profile_card.dart';

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
    final stats = dayStats(st, iso);
    final pct = stats.total == 0 ? 0.0 : stats.success / stats.total;
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        _Header(text: clockText(_now, fa: fa, jalali: isJalali(st))),
        const SizedBox(height: RpSpace.s4),
        const ProfileCard(),
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
    final dark = context.rpBrightness == Brightness.dark; // حالتِ مؤثر (سیستم هم لحاظ می‌شود)
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr('روتین پلنر', 'Routine Planner'), style: rpText(RpType.titleL, weight: 800, color: p.text)),
          Text(text, style: rpText(RpType.label, weight: 500, color: p.muted)),
        ]),
      ),
      const HelpButton('home'),
      IconButton(
        tooltip: context.tr('تم', 'Theme'),
        onPressed: () {
          store.state['theme'] = dark ? 'light' : 'dark';
          store.state['themeIntensity'] = dark ? 0 : 100; // کلیدِ سازگار با بکاپ
          store.save();
        },
        icon: Icon(dark ? LucideIcons.sun : LucideIcons.moon, color: p.text),
      ),
    ]);
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
                final pct = habitCompletionPct(state, h, now);
                final streak = perm ? computeHabitStreak(state, h, now) : 0;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${h['name']}', style: rpText(RpType.body, weight: 700, color: p.text)),
                        if (perm) TextSpan(text: fa ? '  (۳۰ روز اخیر)' : '  (last 30 days)', style: rpText(RpType.caption, weight: 400, color: p.muted)),
                      ])),
                    ),
                    Text(pct == null ? context.tr('داده کافی نیست', 'Not enough data') : '${context.n(pct)}%', style: rpText(RpType.label, weight: 600, color: pct == null ? p.muted : p.text)),
                    if (perm && streak > 0) Text('  🔥${context.n(streak)}', style: rpText(RpType.label, weight: 800, color: p.fire)),
                  ]),
                  const SizedBox(height: 4),
                  RpProgressBar(value: (pct ?? 0) / 100, colors: [p.primary, p.primary2]),
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
    String? sub;
    if (state['isPremium'] != true) {
      sub = null; // کاربر رایگان: فقط قفل کوچک؛ توضیح در خودِ صفحه
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
            if (sub != null) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.caption, weight: 500, color: p.muted)),
          ]),
        ),
        const ProLockIcon(),
        const SizedBox(width: 6),
        Icon(fa ? LucideIcons.chevronLeft : LucideIcons.chevronRight, size: 18, color: p.muted),
      ]),
    );
  }
}
