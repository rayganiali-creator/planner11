// تحلیل: روند (میله‌ای، هفته/ماه/سال)، نمودار دایره‌ای، مقایسه‌ی عادت‌ها، آمار و گزارش هفتگی.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/i18n.dart';
import '../../app/nav.dart';
import '../../core/analytics.dart';
import '../../core/calendar.dart';
import '../../core/habits.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/charts.dart';
import '../../ui/custom_theme.dart';
import '../../ui/tokens.dart';
import '../onboarding/onboarding.dart';
import '../../ui/widgets.dart';

/// گزارش هفته از دادهٔ واقعی؛ بدون داده null (UI باید «داده کافی نیست» بنویسد)
String? weeklyReport(Map st, DateTime today, bool fa) {
  final rep = buildRangeReport(st.cast<String, dynamic>(), 'week', today);
  final t = rep.total;
  final pct = rep.completion;
  if (pct == null) return null;
  final n = fa ? toPersianDigits : (Object x) => '$x';
  return fa
      ? 'این هفته ${n(t.success)} از ${n(t.due)} عادتِ سررسید موفق بود (${n(pct)}٪).'
      : 'This week ${t.success} of ${t.due} due habits were successful ($pct%).';
}

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
    final rep = buildRangeReport(st.cast<String, dynamic>(), range, now);
    final habits = (st['habits'] as List).cast<Map>();
    final tc = (st['tileColors'] is Map ? st['tileColors'] as Map : const {});
    final dark = context.rpBrightness == Brightness.dark;
    final okC = tileColor(parseHex(tc['success']) ?? p.ok, dark), badC = tileColor(parseHex(tc['fail']) ?? p.bad, dark);
    final labels = [for (final d in rep.days) d.label];
    final values = [for (final d in rep.days) d.pct];
    final t = rep.total;
    final pct = rep.completion;
    final noData = t.due == 0;
    final report = weeklyReport(st, now, fa);
    String insufficient = context.tr('داده کافی برای تحلیل وجود ندارد.', 'Not enough data to analyze.');
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Row(children: [Expanded(child: Text(context.tr('تحلیل', 'Analytics'), style: rpText(RpType.titleL, weight: 700, color: p.text))), HelpButton('progress')]),
        const SizedBox(height: RpSpace.s3),
        Wrap(spacing: 8, children: [
          for (final r in const [('week', 'هفته', 'Week'), ('month', 'ماه', 'Month'), ('year', 'سال', 'Year')])
            ChoiceChip(key: ValueKey('an-${r.$1}'), label: Text(fa ? r.$2 : r.$3), selected: range == r.$1, onSelected: (_) => setState(() => range = r.$1)),
        ]),
        const SizedBox(height: RpSpace.s3),
        Row(children: [
          _Tile(pct == null ? '—' : context.n('$pct%'), context.tr('تکمیل', 'Completion'), p.primary, p.primarySoft),
          const SizedBox(width: 8),
          _Tile(context.n(computeStreak(st, now)), context.tr('زنجیره', 'Streak'), p.fire, p.goldSoft),
          const SizedBox(width: 8),
          _Tile(context.n(habits.length), context.tr('عادت‌ها', 'Habits'), p.blueInk, p.blueSoft),
        ]),
        const SizedBox(height: RpSpace.s3),
        if (noData)
          AppCard(child: Text(insufficient, key: const ValueKey('an-nodata'), style: rpText(RpType.body, weight: 500, color: p.muted)))
        else ...[
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr('روند تکمیل', 'Completion trend'), style: rpText(RpType.body, weight: 600, color: p.text)),
              const SizedBox(height: RpSpace.s3),
              Directionality(textDirection: TextDirection.ltr, child: RpBarChart(labels: labels, values: values, color: p.primary, semantics: context.tr('نمودار میله‌ای تکمیل', 'Completion bar chart'))),
            ]),
          ),
          const SizedBox(height: RpSpace.s3),
          AppCard(
            child: Row(children: [
              RpDonut(
                success: t.success,
                fail: t.fail,
                unset: t.unset,
                okColor: okC,
                badColor: badC,
                emptyColor: p.line,
                size: 130,
                center: Text(pct == null ? '—' : context.n('$pct%'), style: rpText(RpType.title, weight: 700, color: p.text)),
              ),
              const SizedBox(width: RpSpace.s4),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Legend(okC, context.tr('موفق', 'Success'), context.n(t.success)),
                  const SizedBox(height: 8),
                  _Legend(badC, context.tr('ناموفق', 'Failed'), context.n(t.fail)),
                  const SizedBox(height: 8),
                  _Legend(p.line, context.tr('ثبت‌نشده', 'Not logged'), context.n(t.unset)),
                ]),
              ),
            ]),
          ),
        ],
        const SizedBox(height: RpSpace.s3),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('مقایسه‌ی عادت‌ها (۳۰ روز اخیر)', 'Habit comparison (last 30 days)'), style: rpText(RpType.body, weight: 600, color: p.text)),
            const SizedBox(height: RpSpace.s2),
            if (habits.isEmpty)
              Text(context.tr('هنوز عادتی اضافه نکردی.', "You haven't added any habits yet."), style: rpText(RpType.body, weight: 500, color: p.muted))
            else
              for (final h in habits)
                Builder(builder: (_) {
                  final v = habitCompletionPct(st.cast<String, dynamic>(), h, now);
                  return v == null
                      ? Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text('${h['name']}', style: rpText(RpType.body, weight: 500, color: p.text))), Text(context.tr('داده کافی نیست', 'Not enough data'), style: rpText(RpType.caption, weight: 500, color: p.muted))]))
                      : RpHBar(label: '${h['name']}', value: v, color: p.primary);
                }),
          ]),
        ),
        const SizedBox(height: RpSpace.s3),
        AppCard(child: Text(report ?? insufficient, key: const ValueKey('an-weekly'), style: rpText(RpType.body, weight: 500, color: report == null ? p.muted : p.text, height: 1.9))),
        const SizedBox(height: RpSpace.s3),
        RpCollapsible(
          key: const ValueKey('an-method'),
          icon: LucideIcons.info,
          title: context.tr('این اعداد چطور محاسبه می‌شوند؟', 'How are these numbers calculated?'),
          child: Text(
            context.tr(
                'فقط از ثبت‌های واقعیِ خودت. تکمیل = موفق ÷ عادت‌های سررسید. روزِ گذشته‌ای که ثبت نکرده‌ای «ثبت‌نشده» حساب می‌شود؛ امروز فقط وقتی ثبت کرده‌ای شمرده می‌شود و روزهای آینده هرگز. اگر چیزی برای شمارش نباشد، عددی ساخته نمی‌شود و «داده کافی نیست» می‌بینی.',
                'Only from your real entries. Completion = successes ÷ habits due. A past day you did not log counts as “not logged”; today counts only once logged and future days never. If there is nothing to count, no number is made up.'),
            style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.8),
          ),
        ),
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
