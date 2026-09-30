// «تحلیل رفتار هوشمند» (پرو): KPIها، روند، نقشه‌ی روزهای هفته، رتبه‌ی عادت‌ها، اثر محرک/مشوق، علت‌ها،
// الگوها و پیشنهادها، ژورنال رفتاری. محاسبه: core/smart.dart (با JS سنجیده شده).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../core/calendar.dart';
import '../../core/smart.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/charts.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';

class SmartCard extends StatefulWidget {
  const SmartCard({super.key});
  @override
  State<SmartCard> createState() => _SmartCardState();
}

class _SmartCardState extends State<SmartCard> {
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
      return AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('⭐ ${context.tr('تحلیل رفتار هوشمند — پرو', 'Smart behavior analytics — Pro')}', style: rpText(RpType.body, weight: 800, color: p.goldInk)),
          const SizedBox(height: 6),
          Text(context.tr('شاخص‌های کلیدی با مقایسه‌ی بازه‌ها، روند روزانه، نقشه‌ی روزهای هفته، رتبه‌بندی عادت‌ها، اثر هر محرک و مشوق، ارتباط محرک با علت شکست، الگوها و پیشنهادها و ژورنال رفتاری.',
              'Key metrics with period comparison, daily trend, weekday heatmap, habit ranking, trigger impact, trigger–reason links, patterns with suggestions, and a behavioral journal.'), style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.8)),
        ]),
      );
    }
    final now = a.today;
    final cur = saCompute(st, saPeriod(range, 0, now)), prev = saCompute(st, saPeriod(range, 1, now));
    String pc(double? x) => x == null ? '—' : '${N(jsR(x * 100))}$pct';
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
    final jal = st['calendarType'] == 'jalali';
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
    final insights = saInsights(cur, prev, fa);
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

    Widget section(String ico, String title, String sub, Widget child) => Padding(
          padding: const EdgeInsets.only(top: RpSpace.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$ico $title', style: rpText(RpType.body, weight: 800, color: p.text)),
            Text(sub, style: rpText(RpType.caption, weight: 500, color: p.muted)),
            const SizedBox(height: RpSpace.s2),
            child,
          ]),
        );
    Widget empty(String t) => Text(t, style: rpText(RpType.label, weight: 500, color: p.muted));

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🧠 ${context.tr('تحلیل رفتار هوشمند', 'Smart behavior analytics')}', style: rpText(RpType.bodyL, weight: 800, color: p.text)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final r in const [('week', 'هفتگی', 'Week'), ('month', 'ماهانه', 'Month'), ('year', 'سالانه', 'Year')])
            ChoiceChip(label: Text(fa ? r.$2 : r.$3), selected: range == r.$1, onSelected: (_) => setState(() => range = r.$1)),
        ]),
        const SizedBox(height: RpSpace.s3),
        Row(children: [
          kpi('✅', context.tr('نرخ موفقیت', 'Success rate'), pc(cur.rate), delta(cur.rate, prev.rate)),
          const SizedBox(width: 6),
          kpi('🌟', context.tr('روزهای کامل', 'Perfect days'), N(cur.perfect), delta(perfectRate(cur), perfectRate(prev))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          kpi('🔁', context.tr('تاب‌آوری', 'Resilience'), pc(cur.recovery), delta(cur.recovery, prev.recovery), context.tr('برگشت پس از شکست', 'comeback after a miss')),
          const SizedBox(width: 6),
          kpi('📆', context.tr('ثبات', 'Consistency'), pc(cur.consistency), delta(cur.consistency, prev.consistency), context.tr('روزهای ثبت‌شده', 'days with entries')),
        ]),
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
        section('💡', context.tr('الگوها و پیشنهادها', 'Patterns & suggestions'), context.tr('به ترتیب اهمیت', 'Sorted by importance'),
            insights.isEmpty
                ? empty(context.tr('برای کشف الگو، چند روز ثبت بیشتر لازم است.', 'A few more days of data are needed.'))
                : Column(children: [
                    for (final x in insights)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: x.level == 'good' ? p.okSoft : x.level == 'bad' ? p.badSoft : p.goldSoft, borderRadius: BorderRadius.circular(RpRadius.md)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(x.ico, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(x.t, style: rpText(RpType.body, weight: 800, color: p.text, height: 1.6)), Text(x.s, style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.7))])),
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
                        child: Text('${DateTime.fromMillisecondsSinceEpoch((j['at'] as num).toInt()).toString().substring(0, 10)} — ${j['text']}', style: rpText(RpType.label, weight: 500, color: p.text, height: 1.7)),
                      ),
                  ])),
      ]),
    );
  }
}

int jsR(num x) => (x + 0.5).floor();
