// «تحلیل هوشمند» (پرو): امتیاز و داوری، تمرکزِ امروز، عادت‌های در خطر، بینش‌ها و بخش‌های کشوییِ جزئیات
// (روند، روزهای هفته، رتبه‌ها، محرک/مشوق، علت‌ها، ژورنال رفتاری). محاسبه: core/smart.dart (با JS سنجیده شده) + core/smart_extras.dart.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../onboarding/onboarding.dart';

import '../../app/i18n.dart';
import '../../core/date_fmt.dart';
import '../../core/calendar.dart';
import '../../core/pro_features.dart';
import '../../ui/pro_widgets.dart';
import '../../core/smart.dart';
import '../../core/smart_extras.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/charts.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';

class SmartScreen extends StatefulWidget {
  const SmartScreen({super.key});
  @override
  State<SmartScreen> createState() => _SmartScreenState();
}

class _SmartScreenState extends State<SmartScreen> {
  String range = 'month';
  String? journalReason;
  final note = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final a = context.read<AppActions>();
    final p = context.rp;
    final fa = context.isFa;
    final st = store.state;
    String N(Object n) => fa ? toPersianDigits(n) : '$n';
    final pct = fa ? '٪' : '%';
    if (st['isPremium'] != true) {
      return ListView(padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)), children: [
        Row(children: [Expanded(child: Text(context.tr('تحلیل هوشمند', 'Smart Analysis'), style: rpText(RpType.titleL, weight: 800, color: p.text))), const HelpButton('smart')]),
        const SizedBox(height: RpSpace.s3),
        const ProNotice(ProFeature.smartAnalysis),
      ]);
    }
    final now = a.today;
    final cur = saCompute(st, saPeriod(range, 0, now)), prev = saCompute(st, saPeriod(range, 1, now));
    final status = smartStatus(cur);
    final show = status != SmartStatus.insufficient;
    String pc(double? x) => (!show || x == null) ? '—' : '${N(jsR(x * 100))}$pct';
    Widget delta(double? x, double? y) {
      if (x == null || y == null) return Text('—', style: rpText(RpType.caption, weight: 700, color: p.muted));
      final d = jsR((x - y) * 100);
      return Text('${d > 0 ? '▲ ' : d < 0 ? '▼ ' : ''}${N(d.abs())}$pct', style: rpText(RpType.caption, weight: 800, color: d > 0 ? p.okInk : d < 0 ? p.badInk : p.muted));
    }

    Widget kpi(String ico, String label, String val, Widget d, [String? hint]) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(RpRadius.md), border: Border.all(color: p.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text(ico), const Spacer(), d]),
              Text(val, style: rpText(RpType.title, weight: 800, color: p.text)),
              Text(label, style: rpText(RpType.caption, weight: 700, color: p.muted)),
              if (hint != null) Text(hint, style: rpText(9, weight: 500, color: p.muted, height: 1.3)),
            ]),
          ),
        );
    double? perfectRate(SaResult r) => r.dueDays > 0 ? r.perfect / r.dueDays : null;

    // روند (سال = میانگینِ هر ماه)
    List<String> labels;
    List<int?> values;
    final jal = isJalali(st);
    if (range == 'year') {
      final b = <String, ({String lab, double s, int n})>{};
      for (final x in cur.series) {
        if (x.rate == null) continue;
        final ps = x.iso.split('-').map(int.parse).toList();
        final j = toJalaali(ps[0], ps[1], ps[2]);
        final key = jal ? '${j.jy}-${j.jm}' : '${ps[0]}-${ps[1]}';
        final lab = jal ? (fa ? persianMonths[j.jm - 1] : jalaliMonthsEn[j.jm - 1].substring(0, 3)) : (fa ? persianMonths[ps[1] - 1] : enMonths[ps[1] - 1]);
        final o = b[key];
        b[key] = (lab: lab, s: (o?.s ?? 0) + x.rate!, n: (o?.n ?? 0) + 1);
      }
      labels = [for (final e in b.values) e.lab];
      values = [for (final e in b.values) jsR(e.s / e.n * 100)];
    } else {
      labels = [
        for (final x in cur.series)
          () {
            final ps = x.iso.split('-').map(int.parse).toList();
            final j = toJalaali(ps[0], ps[1], ps[2]);
            final s = jal ? '${j.jm}/${j.jd}' : '${ps[1]}/${ps[2]}';
            return fa ? toPersianDigits(s) : s;
          }()
      ];
      values = [for (final x in cur.series) x.rate == null ? null : jsR(x.rate! * 100)];
    }

    // رتبه‌ی عادت‌ها
    final habits = [
      for (final h in cur.byHabit.values)
        (name: h.name, r: h.s / (h.s + h.f < 1 ? 1 : h.s + h.f), best: h.best, p: prev.byHabit[h.id] != null && prev.byHabit[h.id]!.s + prev.byHabit[h.id]!.f > 0 ? prev.byHabit[h.id]!.s / (prev.byHabit[h.id]!.s + prev.byHabit[h.id]!.f) : null),
    ]..sort((x, y) => y.r.compareTo(x.r));
    final impacts = [
      for (final e in cur.trig.values)
        if (e.s + e.f >= 1) (name: e.name, type: e.type, n: e.s + e.f, lift: cur.rate == null ? 0.0 : e.s / (e.s + e.f) - cur.rate!),
    ]..sort((x, y) => x.lift.compareTo(y.lift));
    final maxLift = [0.05, ...impacts.map((x) => x.lift.abs())].reduce((x, y) => x > y ? x : y);
    final pairs = <({String t, String r, int n, int fails, double share})>[];
    for (final e in cur.trig.values) {
      e.reasons.forEach((r, n) => pairs.add((t: e.name, r: r, n: n, fails: e.f, share: n / (e.f < 1 ? 1 : e.f))));
    }
    pairs.sort((x, y) => y.n != x.n ? y.n.compareTo(x.n) : y.share.compareTo(x.share));
    final findings = smartFindings(st, cur, prev, now, fa);
    final reasonsAll = <String>{};
    final rs = st['reasons'] is Map ? st['reasons'] as Map : const {};
    for (final v in rs.values) {
      if (v is! Map) continue;
      for (final e in v.values) {
        if (e is Map && e['reason'] is String && e['reason'] != '' && e['reason'] != '(بدون دلیل)') reasonsAll.add(e['reason']);
      }
    }
    final reasonsList = <String>{...cur.failReasons.keys, ...reasonsAll}.toList();
    if (journalReason == null || !reasonsList.contains(journalReason)) journalReason = reasonsList.isEmpty ? null : reasonsList.first;
    final bj = st['behaviorJournal'] is Map ? st['behaviorJournal'] as Map : const {};
    final journal = journalReason == null ? <Map>[] : ((bj[journalReason] as List?) ?? const []).cast<Map>().reversed.toList();
    final wdNames = fa ? saWdFa : saWdEn.map((e) => e.substring(0, 3)).toList();

    final bestWd = () {
      int bi = -1;
      double br = -1;
      for (int i = 0; i < 7; i++) {
        final w = cur.byWeekday[i];
        final n = w[0] + w[1];
        if (n >= 2 && w[0] / n > br) {
          br = w[0] / n;
          bi = i;
        }
      }
      return bi < 0 ? null : '${fa ? saWdFa[bi] : saWdEn[bi]} · ${N(jsR(br * 100))}$pct';
    }();
    String? sumFor(String ico, String title) {
      if (ico == '📈') return cur.rate == null ? null : '${N(jsR(cur.rate! * 100))}$pct';
      if (ico == '🗓️') return bestWd;
      if (ico == '🏅' && habits.isNotEmpty && !title.contains('پیروزی') && !title.contains('succeeded')) return habits.first.name;
      if (ico == '⚡') return impacts.isEmpty ? null : N(impacts.length);
      if (ico == '📓') return reasonsList.isEmpty ? null : N(reasonsList.length);
      return null;
    }

    Widget section(String ico, String title, String sub, Widget child) => Padding(
          padding: const EdgeInsets.only(top: RpSpace.s3),
          child: RpCollapsible(
            key: ValueKey('smart-$ico-$title'),
            persistKey: 'smart$ico',
            title: '$ico $title',
            summary: sumFor(ico, title),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sub, style: rpText(RpType.caption, weight: 500, color: p.muted)),
              const SizedBox(height: RpSpace.s2),
              child,
            ]),
          ),
        );
    Widget empty(String t) => Text(t, style: rpText(RpType.label, weight: 500, color: p.muted));

    final score = show ? smartScore(cur) : null;
    final iso = dateToISO(startOfDay(now));
    final focus = focusHabitToday(st, cur, iso);
    final risk = atRiskHabits(cur, prev);
    Widget insightCard(SmartFinding x) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: x.level == 'good' ? p.okSoft : x.level == 'bad' ? p.badSoft : p.goldSoft, borderRadius: BorderRadius.circular(RpRadius.md)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(x.ico, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(x.text, style: rpText(RpType.body, weight: 500, color: p.text, height: 1.7)), if (x.hint != null) Text(x.hint!, style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.7))])),
          ]),
        );
    final scoreColor = score == null ? p.muted : (score >= 65 ? p.okInk : score >= 40 ? p.goldInk : p.badInk);

    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Row(children: [Expanded(child: Text(context.tr('تحلیل هوشمند', 'Smart Analysis'), style: rpText(RpType.titleL, weight: 700, color: p.text))), const HelpButton('smart')]),
        const SizedBox(height: RpSpace.s2),
        Wrap(spacing: 8, children: [
          for (final r in const [('week', '۷ روز اخیر', 'Last 7 days'), ('month', '۳۰ روز اخیر', 'Last 30 days'), ('year', '۳۶۵ روز اخیر', 'Last 365 days')])
            ChoiceChip(key: ValueKey('range-${r.$1}'), label: Text(fa ? r.$2 : r.$3), selected: range == r.$1, onSelected: (_) => setState(() => range = r.$1)),
        ]),
        const SizedBox(height: RpSpace.s3),
        if (status == SmartStatus.insufficient)
          Container(
            key: const ValueKey('smart-insufficient'),
            margin: const EdgeInsets.only(bottom: RpSpace.s3),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(RpRadius.md)),
            child: Text(context.tr('داده کافی برای تحلیل وجود ندارد. (حداقل ۵ ثبتِ نتیجه در ۳ روزِ مختلف لازم است؛ فعلاً ${N(cur.succ + cur.fail)} ثبت در ${N(cur.activeDays)} روز.)', 'Not enough data to analyze. (At least 5 logged outcomes on 3 different days are needed; so far ${cur.succ + cur.fail} in ${cur.activeDays} days.)'), style: rpText(RpType.body, weight: 500, color: p.muted, height: 1.7)),
          )
        else if (status == SmartStatus.limited)
          Padding(padding: const EdgeInsets.only(bottom: RpSpace.s3), child: Text(context.tr('داده هنوز محدود است؛ نتیجه‌ها قطعی نیستند.', 'Data is still limited; results are not conclusive.'), key: const ValueKey('smart-limited'), style: rpText(RpType.label, weight: 500, color: p.muted))),
        // امتیاز و داوری
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              RpRing(value: (score ?? 0) / 100, size: 84, center: Text(score == null ? '—' : N(score), key: const ValueKey('smart-score'), style: rpText(RpType.title, weight: 900, color: scoreColor))),
              const SizedBox(width: RpSpace.s4),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.tr('امتیاز رفتار', 'Behavior score'), style: rpText(RpType.caption, weight: 700, color: p.muted)),
                  Text(score == null ? context.tr('چند روز ثبت بیشتر لازم است.', 'A few more days of data are needed.') : smartVerdict(score, fa), style: rpText(RpType.bodyL, weight: 800, color: p.text, height: 1.5)),
                  const SizedBox(height: 2),
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [Text(context.tr('نسبت به بازه‌ی قبل', 'vs. previous'), style: rpText(RpType.caption, weight: 500, color: p.muted)), delta(cur.rate, prev.rate)]),
                ]),
              ),
            ]),
            const SizedBox(height: RpSpace.s3),
            IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              kpi('✅', context.tr('موفقیت', 'Success'), pc(cur.rate), delta(cur.rate, prev.rate)),
              const SizedBox(width: 6),
              kpi('🌟', context.tr('روز کامل', 'Perfect days'), show ? N(cur.perfect) : '—', delta(perfectRate(cur), perfectRate(prev))),
            ])),
            const SizedBox(height: 6),
            IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              kpi('🔁', context.tr('تاب‌آوری', 'Resilience'), pc(cur.recovery), delta(cur.recovery, prev.recovery), context.tr('برگشت پس از شکست', 'comeback after a miss')),
              const SizedBox(width: 6),
              kpi('📆', context.tr('ثبات', 'Consistency'), pc(cur.consistency), delta(cur.consistency, prev.consistency), context.tr('روزهای ثبت‌شده', 'days with entries')),
            ])),
          ]),
        ),
        const SizedBox(height: RpSpace.s3),
        // تمرکز امروز
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(LucideIcons.crosshair, size: 18, color: p.primary), const SizedBox(width: 8), Text(context.tr('تمرکزِ امروز', 'Today’s focus'), style: rpText(RpType.body, weight: 800, color: p.text))]),
            const SizedBox(height: 6),
            if (!show)
              Text(context.tr('داده کافی برای تحلیل وجود ندارد.', 'Not enough data to analyze.'), style: rpText(RpType.body, weight: 500, color: p.muted))
            else if (focus == null)
              Text(context.tr('همه‌ی عادت‌های سررسیدِ امروز ثبت شده‌اند 🎉', 'Everything due today is logged 🎉'), style: rpText(RpType.body, weight: 500, color: p.muted))
            else ...[
              Text('${focus['name']}', key: const ValueKey('smart-focus'), style: rpText(RpType.bodyL, weight: 600, color: p.text)),
              const SizedBox(height: 2),
              Builder(builder: (_) {
                final fd = focusDetail(st, cur, focus, cur.series.first.iso, cur.series.last.iso, fa);
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(fd.ratePct == null ? context.tr('برای این عادت هنوز داده‌ی کافی نیست.', 'Not enough data for this habit yet.') : context.tr('نرخ موفقیت: ${N(fd.ratePct!)}$pct از ${N(fd.n)} ثبت', 'Success rate: ${fd.ratePct}% of ${fd.n} entries'), style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.7)),
                  if (fd.topReason != null) Text(context.tr('پرتکرارترین علتِ شکست: «${fd.topReason}»', 'Most frequent failure reason: “${fd.topReason}”'), style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.7)),
                  if (fd.hint != null) Text(fd.hint!, style: rpText(RpType.label, weight: 500, color: p.text, height: 1.7)),
                ]);
              }),
            ],
          ]),
        ),
        if (risk.isNotEmpty) ...[
          const SizedBox(height: RpSpace.s3),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(LucideIcons.triangleAlert, size: 18, color: p.badInk), const SizedBox(width: 8), Text(context.tr('عادت‌های در خطر', 'Habits at risk'), style: rpText(RpType.body, weight: 800, color: p.text))]),
              const SizedBox(height: 6),
              for (final r in risk)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(child: Text(r.name, style: rpText(RpType.body, weight: 700, color: p.text))),
                    Text('${N(jsR(r.before * 100))}$pct ← ${N(jsR(r.now * 100))}$pct', style: rpText(RpType.caption, weight: 800, color: p.badInk)),
                  ]),
                ),
            ]),
          ),
        ],
        const SizedBox(height: RpSpace.s3),
        // بینش‌ها: ۳ مورد برتر، بقیه کشویی
        Text(context.tr('بینش‌ها', 'Insights'), style: rpText(RpType.body, weight: 600, color: p.text)),
        const SizedBox(height: RpSpace.s2),
        if (!show)
          empty(context.tr('داده کافی برای تحلیل وجود ندارد.', 'Not enough data to analyze.'))
        else if (findings.isEmpty)
          empty(context.tr('الگوی معناداری در داده‌های این بازه پیدا نشد.', 'No meaningful pattern was found in this period’s data.'))
        else ...[
          for (final x in findings.take(3)) insightCard(x),
          if (findings.length > 3)
            RpCollapsible(key: const ValueKey('smart-more-insights'), persistKey: 'smartMore', title: context.tr('بینش‌های بیشتر', 'More insights'), summary: N(findings.length - 3), card: false, child: Column(children: [for (final x in findings.skip(3)) insightCard(x)])),
        ],
        section('📈', range == 'year' ? context.tr('روند ماهانه', 'Monthly trend') : range == 'month' ? context.tr('روند ۳۰ روز اخیر', 'Last 30 days') : context.tr('روند هفته', 'This week'),
            range == 'year' ? context.tr('میانگین نرخ موفقیت در هر ماه', 'Average success rate per month') : context.tr('نرخ موفقیت هر روز', 'Daily success rate'),
            cur.series.any((x) => x.rate != null) ? Directionality(textDirection: TextDirection.ltr, child: RpBarChart(labels: labels, values: values, color: p.primary, height: 150)) : empty(context.tr('در این بازه ثبتی وجود ندارد.', 'No entries in this period.'))),
        section('🗓️', context.tr('نقشه‌ی روزهای هفته', 'Weekday heatmap'), context.tr('درصد موفقیت هر روز هفته', 'Success % by weekday'),
            Row(children: [
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Builder(builder: (_) {
                    final w = cur.byWeekday[i];
                    final n = w[0] + w[1];
                    final r = n > 0 ? w[0] / n : null;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: r == null ? p.surface2 : Color.lerp(p.badSoft, p.okSoft, r), borderRadius: BorderRadius.circular(RpRadius.xs)),
                      child: Column(children: [
                        Text(r == null ? '—' : N(jsR(r * 100)), style: rpText(RpType.label, weight: 800, color: p.text)),
                        Text(wdNames[i].length > 3 ? wdNames[i].substring(0, 2) : wdNames[i], style: rpText(9, weight: 600, color: p.muted)),
                      ]),
                    );
                  }),
                ),
            ])),
        section('🏅', context.tr('رتبه‌بندی عادت‌ها', 'Habit ranking'), context.tr('موفقیت و تغییر نسبت به بازه‌ی قبل', 'Success and change vs. previous period'),
            habits.isEmpty
                ? empty(context.tr('داده‌ای نیست.', 'No data.'))
                : Column(children: [
                    for (int i = 0; i < habits.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Text('${N(i + 1)}. ', style: rpText(RpType.label, weight: 800, color: p.muted)), Expanded(child: Text(habits[i].name, style: rpText(RpType.body, weight: 700, color: p.text))), delta(habits[i].r, habits[i].p)]),
                          RpProgressBar(value: habits[i].r, colors: [p.primary, p.primary2]),
                          Text('${pc(habits[i].r)} · ${context.tr('بهترین زنجیره: ${N(habits[i].best)} روز', 'best streak: ${habits[i].best} days')}', style: rpText(RpType.caption, weight: 500, color: p.muted)),
                        ]),
                      ),
                  ])),
        section('⚡', context.tr('اثر محرک‌ها و مشوق‌ها', 'Trigger & incentive impact'), context.tr('تفاوت نرخ موفقیت نسبت به حالت معمول', 'Change in success vs. your usual rate'),
            impacts.isEmpty
                ? empty(context.tr('در این بازه محرک یا مشوقی همراه با نتیجه‌ی ثبت‌شده نیست.', 'No triggers with recorded outcomes in this period.'))
                : Column(children: [
                    for (final x in impacts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          SizedBox(width: 110, child: Text('${x.type == 'incentive' ? '✨ ' : '⚡ '}${x.name}${x.n < 3 ? ' (${context.tr('داده‌ی کم', 'low data')})' : ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: rpText(RpType.caption, weight: 600, color: p.text))),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Stack(alignment: Alignment.center, children: [
                                Container(height: 10, decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(5))),
                                Align(
                                  alignment: x.lift >= 0 ? Alignment.centerRight : Alignment.centerLeft,
                                  child: FractionallySizedBox(widthFactor: (x.lift.abs() / maxLift * .5).clamp(0.0, 0.5), child: Container(height: 10, decoration: BoxDecoration(color: x.lift >= 0 ? p.okInk : p.badInk, borderRadius: BorderRadius.circular(5)))),
                                ),
                              ]),
                            ),
                          ),
                          SizedBox(width: 48, child: Text('${x.lift >= 0 ? '+' : '−'}${N(jsR(x.lift.abs() * 100))}$pct', textAlign: TextAlign.end, style: rpText(RpType.caption, weight: 800, color: x.lift >= 0 ? p.okInk : p.badInk))),
                        ]),
                      ),
                  ])),
        section('🏅', context.tr('علت‌های پیروزی', 'Why you succeeded'), context.tr('وقتی موفق شدی، بیشتر چه دلیلی ثبت کردی', 'The reasons you recorded on successful days'), () {
          final wr = cur.winReasons.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
          final tot = wr.fold<int>(0, (s, x) => s + x.value);
          if (wr.isEmpty) return empty(context.tr('هنگام ثبتِ موفقیت، دلیلش را هم بنویس تا اینجا ببینی چه چیزی برایت جواب می‌دهد.', 'Add a reason when you mark a success to see what works for you.'));
          return Column(children: [
            for (int i = 0; i < wr.length && i < 6; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text('${N(i + 1)}. ${wr[i].key}', style: rpText(RpType.body, weight: 700, color: p.text))), Text('${N(jsR(wr[i].value / (tot < 1 ? 1 : tot) * 100))}$pct', style: rpText(RpType.caption, weight: 800, color: p.okInk))]),
                  RpProgressBar(value: wr[i].value / (tot < 1 ? 1 : tot), colors: [p.ok, p.okSoft]),
                  Text(context.tr('${N(wr[i].value)} بار از ${N(tot)} موفقیتِ دلیل‌دار', '${wr[i].value} of $tot successes with a reason'), style: rpText(RpType.caption, weight: 500, color: p.muted)),
                ]),
              ),
          ]);
        }()),
        section('🔗', context.tr('محرک‌ها و علت شکست', 'Triggers & failure reasons'), context.tr('وقتی هر محرک بوده، بیشتر چه علتی ثبت شده', 'When each trigger was present, which reason was recorded'),
            pairs.isEmpty
                ? empty(context.tr('برای این تحلیل باید هنگام شکست، هم محرک و هم علت را ثبت کنید.', 'Record both a trigger and a reason on a missed day to see links here.'))
                : Column(children: [
                    for (final x in pairs.take(6))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('⚡ ${x.t}  ${fa ? '⟵' : '⟶'}  🧱 ${x.r}', style: rpText(RpType.body, weight: 700, color: p.text)),
                          RpProgressBar(value: x.share.clamp(0.0, 1.0), colors: [p.bad, p.badSoft]),
                          Text(context.tr('از ${N(x.fails)} شکستِ همراه با «${x.t}»، ${N(x.n)} بار (${N(jsR(x.share * 100))}٪) علتش «${x.r}» بوده.', 'Of ${x.fails} misses with “${x.t}”, ${x.n} (${jsR(x.share * 100)}%) were due to “${x.r}”.'), style: rpText(RpType.caption, weight: 500, color: p.muted, height: 1.6)),
                        ]),
                      ),
                  ])),
        section('📓', context.tr('ژورنال رفتاری', 'Behavioral journal'), context.tr('یادداشت عمیق درباره‌ی علت‌ها', 'Reflect deeply on reasons'),
            reasonsList.isEmpty
                ? empty(context.tr('هنوز دلیلی ثبت نشده.', 'No reasons recorded yet.'))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    DropdownButton<String>(isExpanded: true, value: journalReason, items: [for (final r in reasonsList) DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))], onChanged: (v) => setState(() => journalReason = v)),
                    TextField(controller: note, maxLines: 3, decoration: InputDecoration(hintText: context.tr('چه چیزی واقعاً باعث این شد؟ دفعه‌ی بعد چه می‌کنم؟', 'What really caused this? What will I do next time?'))),
                    const SizedBox(height: 6),
                    RpButton(context.tr('ثبت یادداشت', 'Save note'), small: true, onTap: () {
                      final t = note.text.trim();
                      if (t.isEmpty || journalReason == null) return;
                      if (st['behaviorJournal'] is! Map) st['behaviorJournal'] = <String, dynamic>{};
                      final m = st['behaviorJournal'] as Map;
                      (m[journalReason] is List ? m[journalReason] as List : (m[journalReason] = <Map>[])).add({'text': t, 'at': DateTime.now().millisecondsSinceEpoch});
                      store.save();
                      note.clear();
                      a.toasts.show(context.tr('📓 یادداشت ثبت شد', '📓 Note saved'), ms: 1800);
                    }),
                    for (final j in journal)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${dateNumeric(DateTime.fromMillisecondsSinceEpoch((j['at'] as num).toInt()), jalali: jal, fa: fa)} — ${j['text']}', style: rpText(RpType.label, weight: 500, color: p.text, height: 1.7)),
                      ),
                  ])),
        Padding(
          padding: const EdgeInsets.only(top: RpSpace.s3),
          child: RpCollapsible(
            key: const ValueKey('smart-method'),
            icon: LucideIcons.info,
            title: context.tr('این تحلیل چطور کار می‌کند؟', 'How does this analysis work?'),
            child: Text(
              context.tr(
                  'فقط از ثبت‌های واقعیِ خودت و فقط وقتی داده کافی باشد (حداقل ۵ ثبت در ۳ روز؛ هر الگو کمینه‌ی داده‌ی خودش را دارد). بازه‌ها «روزهای اخیر» هستند (۷/۳۰/۳۶۵ روز تا امروز) و با بازه‌ی قبلیِ هم‌اندازه مقایسه می‌شوند. «موفقیت» = موفق ÷ ثبت‌شده‌ها؛ «ثبات» = روزهای دارای ثبت ÷ روزهای سررسید. ساعتِ ثبت ذخیره نمی‌شود، پس تحلیلِ ساعت‌محور ممکن نیست و ساخته نمی‌شود.',
                  'Only from your real entries and only with enough data (at least 5 entries over 3 days; each pattern has its own minimum). Periods are “recent days” (7/30/365 days up to today) compared with the equal previous period. “Success” = successes ÷ logged entries; “Consistency” = days with entries ÷ days due. The time of logging is not stored, so time-of-day analysis is not possible and is never faked.'),
              style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}

int jsR(num x) => (x + 0.5).floor();
