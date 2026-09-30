// تحلیل رفتار هوشمند (پرو): پورتِ saPeriod / saCompute / saSuggestion / saInsights از www/index.html.
// مدل داده: reasons[habitId][iso] = {status, reason} ، triggers[habitId] = [{trigger, date, type}].
import 'calendar.dart';
import 'doc.dart';
import 'habits.dart';
import 'js_compat.dart';

const saDays = {'week': 7, 'month': 30, 'year': 365};
const saWdFa = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];
const saWdEn = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

typedef SaPeriod = ({String from, String to, DateTime start, int days});

SaPeriod saPeriod(String range, int offsetPeriods, DateTime todayIn) {
  final n = saDays[range]!;
  final today = startOfDay(todayIn);
  final end = addDays(today, -n * offsetPeriods);
  final start = addDays(end, -(n - 1));
  return (from: dateToISO(start), to: dateToISO(end), start: start, days: n);
}

class SaHabit {
  final String id, name;
  int s = 0, f = 0, run = 0, best = 0;
  SaHabit(this.id, this.name);
}

class SaTrig {
  final String name, type;
  int s = 0, f = 0;
  final Map<String, int> reasons = {};
  SaTrig(this.name, this.type);
}

class SaResult {
  int succ = 0, fail = 0, perfect = 0, zero = 0, activeDays = 0, dueDays = 0;
  final Map<String, SaHabit> byHabit = {};
  final List<List<int>> byWeekday = List.generate(7, (_) => [0, 0]); // [s, f]
  final Map<String, SaTrig> trig = {};
  final Map<String, int> failReasons = {}, winReasons = {};
  final List<({String iso, double? rate})> series = [];
  double? rate, recovery, consistency;
  int recN = 0;
}

SaResult saCompute(Doc state, SaPeriod per) {
  final r = SaResult();
  final habits = [for (final h in (state['habits'] is List ? state['habits'] as List : const [])) if (h is Map) h];
  final outcome = <String, bool>{};
  for (int i = 0; i < per.days; i++) {
    final d = DateTime(per.start.year, per.start.month, per.start.day + i, per.start.hour, per.start.minute);
    final iso = dateToISO(d);
    final wd = (jsWeekday(d) + 1) % 7;
    int ds = 0, df = 0, due = 0;
    for (final h in habits) {
      if (!habitAppliesOnISO(h, iso)) continue;
      due++;
      final res = habitSuccessOnISO(state, h, iso);
      if (res == null) continue;
      outcome['${h['id']}|$iso'] = res;
      final bh = r.byHabit.putIfAbsent('${h['id']}', () => SaHabit('${h['id']}', '${h['name']}'));
      if (res) {
        r.succ++;
        ds++;
        bh.s++;
        r.byWeekday[wd][0]++;
        bh.run++;
        if (bh.run > bh.best) bh.best = bh.run;
      } else {
        r.fail++;
        df++;
        bh.f++;
        r.byWeekday[wd][1]++;
        bh.run = 0;
      }
    }
    if (due > 0) {
      r.dueDays++;
      if (ds + df > 0) r.activeDays++;
      if (ds == due) r.perfect++;
      if (ds == 0) r.zero++;
    }
    r.series.add((iso: iso, rate: (ds + df) > 0 ? ds / (ds + df) : null));
  }
  // تاب‌آوری: بعد از یک شکست، روز بعد چند درصد مواقع موفق بوده؟
  int recN = 0, recOk = 0;
  for (final k in outcome.keys) {
    if (outcome[k] != false) continue;
    final sep = k.indexOf('|');
    final hid = k.substring(0, sep), iso = k.substring(sep + 1);
    final next = outcome['$hid|${dateToISO(addDays(isoToDate(iso), 1))}'];
    if (next == null) continue;
    recN++;
    if (next) recOk++;
  }
  final trigs = state['triggers'] is Map ? state['triggers'] as Map : const {};
  final reasons = state['reasons'] is Map ? state['reasons'] as Map : const {};
  for (final hid in trigs.keys) {
    final list = trigs[hid];
    if (list is! List) continue;
    for (final t in list) {
      if (t is! Map) continue;
      final date = t['date'];
      if (!jsTruthy(date) || '$date'.compareTo(per.from) < 0 || '$date'.compareTo(per.to) > 0) continue;
      final res = outcome['$hid|$date'];
      if (res == null) continue;
      final k = '${t['type']}|${t['trigger']}';
      final e = r.trig.putIfAbsent(k, () => SaTrig('${t['trigger']}', '${t['type']}'));
      if (res) {
        e.s++;
      } else {
        e.f++;
        final rs = reasons['$hid'] is Map ? (reasons['$hid'] as Map)['$date'] : null;
        if (rs is Map && rs['status'] == 'fail' && jsTruthy(rs['reason']) && rs['reason'] != '(بدون دلیل)') {
          e.reasons['${rs['reason']}'] = (e.reasons['${rs['reason']}'] ?? 0) + 1;
        }
      }
    }
  }
  for (final hid in reasons.keys) {
    final m = reasons[hid];
    if (m is! Map) continue;
    for (final iso in m.keys) {
      final e = m[iso];
      if ('$iso'.compareTo(per.from) < 0 || '$iso'.compareTo(per.to) > 0 || e is! Map || !jsTruthy(e['reason']) || e['reason'] == '(بدون دلیل)') continue;
      if (e['status'] == 'fail') {
        r.failReasons['${e['reason']}'] = (r.failReasons['${e['reason']}'] ?? 0) + 1;
      } else if (e['status'] == 'success') {
        r.winReasons['${e['reason']}'] = (r.winReasons['${e['reason']}'] ?? 0) + 1;
      }
    }
  }
  r.rate = (r.succ + r.fail) > 0 ? r.succ / (r.succ + r.fail) : null;
  r.recN = recN;
  r.recovery = recN >= 2 ? recOk / recN : null;
  r.consistency = r.dueDays > 0 ? r.activeDays / r.dueDays : null;
  return r;
}

String saSuggestion(String? reason, bool fa) {
  final r = reason ?? '';
  final rules = <(RegExp, String, String)>[
    (RegExp('خست|خواب|انرژی|tired|sleep', caseSensitive: false), 'زمان این عادت را به ساعتی ببرید که انرژی بیشتری دارید، یا نسخه‌ی کوتاه‌تری از آن تعریف کنید.', 'Move it to a higher-energy time of day, or define a shorter version.'),
    (RegExp('وقت|زمان|سر ?کار|مشغول|busy|time', caseSensitive: false), 'یک زمان ثابت در تقویم برایش رزرو کنید و یادآوری بگذارید.', 'Reserve a fixed slot for it and set a reminder.'),
    (RegExp('حوصله|انگیزه|تنبل|motivat|lazy', caseSensitive: false), 'هدف را کوچک کنید (مثلاً ۲ دقیقه) و بعد از انجام، به خودتان جایزه بدهید.', 'Shrink the goal (e.g. 2 minutes) and reward yourself afterwards.'),
    (RegExp('گوشی|موبایل|شبکه|اینستا|phone|social', caseSensitive: false), 'هنگام این عادت گوشی را در اتاق دیگری بگذارید یا حالت تمرکز را روشن کنید.', 'Keep the phone in another room or turn on focus mode.'),
    (RegExp('استرس|ناراحت|عصبی|stress|sad', caseSensitive: false), 'قبل از شروع، ۳ دقیقه تنفس آرام یا پیاده‌روی کوتاه را امتحان کنید.', 'Try 3 minutes of slow breathing or a short walk first.'),
    (RegExp('مهمان|بیرون|سفر|travel|guest', caseSensitive: false), 'برای روزهای خاص یک نسخه‌ی «حداقلی» از عادت داشته باشید تا زنجیره نشکند.', 'Keep a minimal version for unusual days so the chain doesn’t break.'),
  ];
  for (final x in rules) {
    if (x.$1.hasMatch(r)) return fa ? x.$2 : x.$3;
  }
  return fa ? 'برای این مانع یک برنامه‌ی «اگر… آنگاه…» بنویسید؛ مثلاً «اگر این اتفاق افتاد، آنگاه…».' : 'Write an “if… then…” plan for this obstacle.';
}

class SaInsight {
  final String level, ico, t, s;
  final double w;
  SaInsight(this.level, this.ico, this.t, this.s, this.w);
}

int _pct(double x) => jsRound(x * 100);

List<SaInsight> saInsights(SaResult cur, SaResult prev, bool fa) {
  final out = <SaInsight>[];
  if (cur.rate == null) return out;
  String N(Object n) => fa ? toPersianDigits(n) : '$n';
  void add(String level, String ico, String t, String sug, double w) => out.add(SaInsight(level, ico, t, sug, w));
  final tot = cur.succ + cur.fail;
  final avgFail = cur.fail / (tot < 1 ? 1 : tot);
  int worst = -1;
  double worstRate = 0, bestRate = -1;
  for (int i = 0; i < 7; i++) {
    final w = cur.byWeekday[i];
    final n = w[0] + w[1];
    if (n >= 3) {
      final fr = w[1] / n;
      if (fr > worstRate) {
        worstRate = fr;
        worst = i;
      }
      if (1 - fr > bestRate) bestRate = 1 - fr;
    }
  }
  final thr = avgFail * 1.4 > 0.35 ? avgFail * 1.4 : 0.35;
  if (worst >= 0 && worstRate >= thr) {
    add('warn', '📅', fa ? 'سخت‌ترین روز هفته «${saWdFa[worst]}» است؛ ${N(_pct(worstRate))}٪ ثبت‌ها ناموفق.' : 'Hardest day: ${saWdEn[worst]} (${_pct(worstRate)}% misses).',
        fa ? 'برای این روز نسخه‌ی سبک‌تر عادت‌ها یا یادآوری زودتر تنظیم کنید.' : 'Plan lighter versions or earlier reminders for that day.', worstRate);
  }
  final fr = cur.failReasons.entries.toList()..sort((a, b) => b.value.compareTo(a.value)); // پایدار، مثل JS
  final frTot = fr.fold<int>(0, (a, x) => a + x.value);
  if (fr.isNotEmpty && frTot >= 2) {
    final share = fr[0].value / frTot;
    add('bad', '🧱', fa ? 'مانع اصلی: «${fr[0].key}» — ${N(_pct(share))}٪ علت‌های شکست.' : 'Main obstacle: “${fr[0].key}” — ${_pct(share)}% of failure reasons.', saSuggestion(fr[0].key, fa), share + .2);
  }
  final trigs = [
    for (final e in cur.trig.values)
      if (e.s + e.f >= 2) (e: e, lift: e.s / (e.s + e.f) - cur.rate!),
  ];
  final bads = trigs.where((x) => x.e.type == 'trigger' && x.lift <= -0.15).toList()..sort((a, b) => a.lift.compareTo(b.lift));
  if (bads.isNotEmpty) {
    final b = bads.first;
    add('bad', '⚡', fa ? 'محرک «${b.e.name}» نرخ موفقیت را ${N(_pct(-b.lift))}٪ پایین می‌آورد (${N(b.e.s + b.e.f)} مورد).' : '“${b.e.name}” lowers success by ${_pct(-b.lift)}% (${b.e.s + b.e.f} cases).',
        fa ? 'از قبل برای روبه‌رو شدن با این محرک یک کار جایگزین مشخص آماده کنید.' : 'Prepare a specific replacement action for this trigger.', -b.lift + .1);
  }
  final goods = trigs.where((x) => x.e.type == 'incentive' && x.lift >= 0.1).toList()..sort((a, b) => b.lift.compareTo(a.lift));
  if (goods.isNotEmpty) {
    final g = goods.first;
    add('good', '✨', fa ? 'مشوق «${g.e.name}» موفقیت را ${N(_pct(g.lift))}٪ بالا می‌برد.' : '“${g.e.name}” raises success by ${_pct(g.lift)}%.',
        fa ? 'این مشوق را عمداً در برنامه‌ی روزانه‌تان بگنجانید.' : 'Build this incentive into your day on purpose.', g.lift);
  }
  if (cur.recovery != null) {
    final rc = cur.recovery!;
    if (rc < 0.5) {
      add('warn', '🔁', fa ? 'بعد از یک شکست، فقط ${N(_pct(rc))}٪ مواقع روز بعد به مسیر برمی‌گردید.' : 'After a miss you get back on track the next day only ${_pct(rc)}% of the time.',
          fa ? 'قانون «هرگز دو بار پشت‌سرهم نه» را امتحان کنید: روز بعد از شکست، حداقلی‌ترین نسخه را هم انجام دهید.' : 'Try “never miss twice”: after a miss, do even the tiniest version the next day.', .5 - rc + .15);
    } else if (rc >= 0.75) {
      add('good', '💪', fa ? 'تاب‌آوری عالی: بعد از شکست، ${N(_pct(rc))}٪ مواقع روز بعد برمی‌گردید.' : 'Great resilience: ${_pct(rc)}% next-day comebacks after a miss.',
          fa ? 'همین الگو را حفظ کنید؛ شکست‌های تک‌روزه شما را از مسیر خارج نمی‌کنند.' : 'Keep it up — single misses don’t derail you.', .1);
    }
  }
  final fri = cur.byWeekday[6];
  int ws = 0, wf = 0;
  for (int i = 0; i < 6; i++) {
    ws += cur.byWeekday[i][0];
    wf += cur.byWeekday[i][1];
  }
  if (fri[0] + fri[1] >= 3 && ws + wf >= 6) {
    final d = fri[0] / (fri[0] + fri[1]) - ws / (ws + wf);
    if (d <= -0.15) {
      add('warn', '🌙', fa ? 'آخر هفته (جمعه) ${N(_pct(-d))}٪ کمتر از روزهای کاری موفق هستید.' : 'Weekends are ${_pct(-d)}% less successful than weekdays.',
          fa ? 'برای جمعه‌ها ساعت مشخصی برای عادت‌ها تعیین کنید؛ نبودِ برنامه‌ی ثابت علت رایج است.' : 'Set fixed times on weekends; lack of routine is a common cause.', -d);
    }
  }
  if (prev.rate != null) {
    final d = cur.rate! - prev.rate!;
    if (d.abs() >= 0.05) {
      add(d > 0 ? 'good' : 'warn', d > 0 ? '📈' : '📉', fa ? 'نرخ موفقیت نسبت به بازه‌ی قبل ${N(_pct(d.abs()))}٪ ${d > 0 ? 'بهتر' : 'کمتر'} شده.' : 'Success is ${_pct(d.abs())}% ${d > 0 ? 'higher' : 'lower'} than last period.',
          d > 0 ? (fa ? 'روالی که ساخته‌اید جواب می‌دهد؛ ادامه دهید.' : 'Your routine is working — keep going.') : (fa ? 'یک عادت را موقتاً ساده‌تر کنید تا دوباره روی روال بیفتید.' : 'Simplify one habit for a while to regain momentum.'), d.abs());
    }
    final improvedL = <({String name, double d})>[];
    for (final h in cur.byHabit.values) {
      final p = prev.byHabit[h.id];
      if (p == null || p.s + p.f < 3 || h.s + h.f < 3) continue;
      improvedL.add((name: h.name, d: h.s / (h.s + h.f) - p.s / (p.s + p.f)));
    }
    improvedL.sort((a, b) => b.d.compareTo(a.d));
    if (improvedL.isNotEmpty && improvedL.first.d >= 0.15) {
      final im = improvedL.first;
      add('good', '🚀', fa ? 'بیشترین پیشرفت: «${im.name}» (+${N(_pct(im.d))}٪).' : 'Most improved: “${im.name}” (+${_pct(im.d)}%).',
          fa ? 'روشی که برای این عادت جواب داده را روی عادت‌های دیگر هم امتحان کنید.' : 'Apply what worked here to your other habits.', im.d * .8);
    }
  }
  final weakL = [for (final x in cur.byHabit.values) if (x.s + x.f >= 4) (h: x, r: x.s / (x.s + x.f))]..sort((a, b) => a.r.compareTo(b.r));
  if (weakL.isNotEmpty && weakL.first.r < 0.5) {
    final w = weakL.first;
    add('warn', '🎯', fa ? '«${w.h.name}» کمترین موفقیت را دارد (${N(_pct(w.r))}٪).' : '“${w.h.name}” has the lowest success (${_pct(w.r)}%).',
        fa ? 'تمرکز این بازه را روی همین عادت بگذارید یا هدفش را کوچک‌تر کنید.' : 'Focus on this habit next, or shrink its goal.', .5 - w.r);
  }
  // JS Array.sort پایدار است؛ Dart sort پایدار نیست ← کلید دوم: ترتیب درج
  final idx = {for (int i = 0; i < out.length; i++) out[i]: i};
  out.sort((a, b) => a.w != b.w ? b.w.compareTo(a.w) : idx[a]!.compareTo(idx[b]!));
  return out;
}
