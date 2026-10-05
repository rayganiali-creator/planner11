// تحلیل: روند (میله‌ای، هفته/ماه/سال)، نمودار دایره‌ای، مقایسه‌ی عادت‌ها، آمار و گزارش هفتگی.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/i18n.dart';
import '../../app/nav.dart';
import '../../core/calendar.dart';
import '../../core/habits.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/charts.dart';
import '../../ui/custom_theme.dart';
import '../../ui/tokens.dart';
import '../onboarding/onboarding.dart';
import '../../ui/widgets.dart';

String weeklyReport(Map st, DateTime today, bool fa) {
  final s = getWeekStart(st.cast<String, dynamic>(), today);
  int done = 0, all = 0;
  final t = startOfDay(today);
  for (int i = 0; i < 7; i++) {
    final d = addDays(s, i);
    if (d.isAfter(t)) break;
    final ds = dayStats(st.cast<String, dynamic>(), dateToISO(d));
    done += ds.success;
    all += ds.total;
  }
  final pct = all > 0 ? jsRoundPct(done, all) : 0;
  return fa
      ? 'این هفته $done از $all عادت موفق ($pct%). ${pct >= 70 ? 'عالی! 💪' : 'کمی بیشتر تلاش کن! 🌱'}'
      : 'This week $done of $all habits successful ($pct%). ${pct >= 70 ? 'Great! 💪' : 'Keep going! 🌱'}';
}

int jsRoundPct(int a, int b) => (a / b * 100 + 0.5).floor();

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String range = 'week';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final a = context.read<AppActions>();
    final p = context.rp;
    final fa = context.isFa;
    final st = store.state;
    final now = a.today;
    final series = collectSeries(st, range, now);
    final totals = getTotalStats(st, range, now);
    final nv = series.values.whereType<int>().toList();
    final avg = nv.isEmpty ? 0 : (nv.reduce((x, y) => x + y) / nv.length + 0.5).floor();
    final habits = (st['habits'] as List).cast<Map>();
    final tc = (st['tileColors'] is Map ? st['tileColors'] as Map : const {});
    final dark = st['theme'] == 'dark';
    final okC = tileColor(parseHex(tc['success']) ?? p.ok, dark), badC = tileColor(parseHex(tc['fail']) ?? p.bad, dark);
    final labels = series.labels.map((l) => fa ? toPersianDigits(l) : l).toList();
    final total = totals.success + totals.fail;
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Row(children: [Expanded(child: Text(context.tr('تحلیل', 'Analytics'), style: rpText(RpType.titleL, weight: 800, color: p.text))), HelpButton('progress')]),
        const SizedBox(height: RpSpace.s3),
        Wrap(spacing: 8, children: [
          for (final r in const [('week', 'هفته', 'Week'), ('month', 'ماه', 'Month'), ('year', 'سال', 'Year')])
            ChoiceChip(label: Text(fa ? r.$2 : r.$3), selected: range == r.$1, onSelected: (_) => setState(() => range = r.$1)),
        ]),
        const SizedBox(height: RpSpace.s3),
        Row(children: [
          _Tile(context.n('$avg%'), context.tr('میانگین', 'Average'), p.primary, p.primarySoft),
          const SizedBox(width: 8),
          _Tile(context.n(computeStreak(st, now)), context.tr('استریک', 'Streak'), p.fire, p.goldSoft),
          const SizedBox(width: 8),
          _Tile(context.n(habits.length), context.tr('عادت‌ها', 'Habits'), p.blueInk, p.blueSoft),
        ]),
        const SizedBox(height: RpSpace.s3),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('روند پیشرفت', 'Progress trend'), style: rpText(RpType.body, weight: 800, color: p.text)),
            const SizedBox(height: RpSpace.s3),
            Directionality(textDirection: TextDirection.ltr, child: RpBarChart(labels: labels, values: series.values, color: p.primary, semantics: context.tr('نمودار میله‌ای پیشرفت', 'Progress bar chart'))),
          ]),
        ),
        const SizedBox(height: RpSpace.s3),
        AppCard(
          child: Row(children: [
            RpDonut(
              success: totals.success,
              fail: totals.fail,
              okColor: okC,
              badColor: badC,
              emptyColor: p.line,
              size: 130,
              center: Text(total == 0 ? '—' : context.n('${(totals.success / total * 100 + 0.5).floor()}%'), style: rpText(RpType.title, weight: 800, color: p.text)),
            ),
            const SizedBox(width: RpSpace.s4),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Legend(okC, context.tr('موفق', 'Success'), context.n(totals.success)),
                const SizedBox(height: 8),
                _Legend(badC, context.tr('ناموفق', 'Failed'), context.n(totals.fail)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: RpSpace.s3),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('مقایسه‌ی عادت‌ها (۳۰ روز اخیر)', 'Habit comparison (last 30 days)'), style: rpText(RpType.body, weight: 800, color: p.text)),
            const SizedBox(height: RpSpace.s2),
            if (habits.isEmpty)
              Text(context.tr('هنوز عادتی اضافه نکردی.', "You haven't added any habits yet."), style: rpText(RpType.body, weight: 500, color: p.muted))
            else
              for (final h in habits) RpHBar(label: '${h['name']}', value: habitProgressPct(st, h, now), color: p.primary),
          ]),
        ),
        const SizedBox(height: RpSpace.s3),
        AppCard(child: Text(weeklyReport(st, now, fa), style: rpText(RpType.body, weight: 600, color: p.text, height: 1.9))),
        const SizedBox(height: RpSpace.s3),
        _SmartLink(),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String v, label;
  final Color fg, bg;
  const _Tile(this.v, this.label, this.fg, this.bg);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: RpSpace.s3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(RpRadius.md)),
          child: Column(children: [Text(v, style: rpText(RpType.title, weight: 800, color: fg)), Text(label, style: rpText(RpType.caption, weight: 600, color: context.rp.muted))]),
        ),
      );
}

class _Legend extends StatelessWidget {
  final Color c;
  final String label, value;
  const _Legend(this.c, this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: rpText(RpType.body, weight: 600, color: context.rp.text))),
        Text(value, style: rpText(RpType.body, weight: 800, color: context.rp.text)),
      ]);
}

class _SmartLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return AppCard(
      onTap: () => context.read<NavController>().go(AppView.smart),
      child: Row(children: [
        Icon(LucideIcons.brain, color: p.xpInk),
        const SizedBox(width: 12),
        Expanded(child: Text(context.tr('تحلیل هوشمند رفتار', 'Smart behavior analysis'), style: rpText(RpType.body, weight: 800, color: p.text))),
        Icon(context.isFa ? LucideIcons.chevronLeft : LucideIcons.chevronRight, size: 18, color: p.muted),
      ]),
    );
  }
}
