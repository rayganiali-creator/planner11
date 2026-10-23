// افزوده‌های «تحلیل هوشمند» روی موتورِ saCompute (که با JS سنجیده شده): امتیازِ کلی، عادت‌های در خطر، تمرکزِ امروز.
import 'calendar.dart';
import 'doc.dart';
import 'habits.dart';
import 'smart.dart';

/// امتیازِ ۰..۱۰۰: ۵۵٪ نرخ موفقیت + ۲۰٪ ثبات + ۱۵٪ تاب‌آوری + ۱۰٪ روزهای کامل (مؤلفه‌ی نامعلوم = نرخ موفقیت). null = داده‌ی کافی نیست.
int? smartScore(SaResult r) {
  final rate = r.rate;
  if (rate == null) return null;
  final perfect = r.dueDays > 0 ? r.perfect / r.dueDays : rate;
  final v = 0.55 * rate + 0.20 * (r.consistency ?? rate) + 0.15 * (r.recovery ?? rate) + 0.10 * perfect;
  return (v.clamp(0.0, 1.0) * 100).round();
}

/// 0 = ضعیف … 3 = عالی
int smartTier(int score) => score >= 85 ? 3 : score >= 65 ? 2 : score >= 40 ? 1 : 0;

String smartVerdict(int score, bool fa) => switch (smartTier(score)) {
      3 => fa ? 'عالی؛ ثباتت مثال‌زدنی است.' : 'Excellent — remarkably consistent.',
      2 => fa ? 'خوب؛ مسیر درستی هستی.' : 'Good — you are on the right track.',
      1 => fa ? 'در حال شکل‌گیری؛ کمی ثبات لازم است.' : 'Taking shape — a little more consistency needed.',
      _ => fa ? 'شروعِ دوباره؛ یک قدمِ کوچک کافی است.' : 'A fresh start — one small step is enough.',
    };

typedef RiskHabit = ({String id, String name, double now, double before});

/// عادت‌هایی که نرخ موفقیتشان نسبت به بازه‌ی قبل ≥۱۵ واحد افت کرده (حداقل ۴ ثبت در هر بازه)
List<RiskHabit> atRiskHabits(SaResult cur, SaResult prev) {
  final out = <RiskHabit>[];
  for (final h in cur.byHabit.values) {
    final p = prev.byHabit[h.id];
    if (p == null || p.s + p.f < 4 || h.s + h.f < 4) continue;
    final n = h.s / (h.s + h.f), b = p.s / (p.s + p.f);
    if (b - n >= 0.15) out.add((id: h.id, name: h.name, now: n, before: b));
  }
  out.sort((a, b) => (b.before - b.now).compareTo(a.before - a.now));
  return out;
}

/// «امروز روی چه چیزی تمرکز کنم؟»: ضعیف‌ترین عادتِ سررسیدِ امروز که هنوز ثبت نشده (null = همه ثبت شده/عادتی نیست)
Map? focusHabitToday(Doc st, SaResult cur, String iso) {
  final rec = (st['records'] is Map ? (st['records'] as Map)[iso] : null);
  final day = rec is Map ? rec : const {};
  final pending = [for (final h in applicableHabitsForISO(st, iso)) if (day[h['id']] == null) h];
  if (pending.isEmpty) return null;
  double rateOf(Map h) {
    final x = cur.byHabit[h['id']];
    return x == null || x.s + x.f == 0 ? 0.5 : x.s / (x.s + x.f);
  }

  pending.sort((a, b) => rateOf(a).compareTo(rateOf(b)));
  return pending.first;
}

// ---------------------------------------------------------------- یافته‌های هوشمند (فقط الگوهای واقعیِ داده؛ بدون توصیه‌ی عمومی/تصادفی)
enum SmartStatus { insufficient, limited, ok }

/// کمینه داده: کمتر از ۵ ثبتِ نتیجه یا کمتر از ۳ روزِ فعال ⇒ هیچ نتیجه‌ای نمی‌دهیم.
SmartStatus smartStatus(SaResult r) {
  final n = r.succ + r.fail;
  if (n < 5 || r.activeDays < 3) return SmartStatus.insufficient;
  return n < 15 ? SmartStatus.limited : SmartStatus.ok;
}

typedef SmartFinding = ({String level, String ico, String text, String? hint, double w});

int _p(double x) => (x * 100 + 0.5).floor();

List<SmartFinding> smartFindings(Doc st, SaResult cur, SaResult prev, DateTime today, bool fa) {
  if (smartStatus(cur) == SmartStatus.insufficient) return const [];
  final out = <SmartFinding>[];
  String N(Object n) => fa ? toPersianDigits(n) : '$n';
  final pc = fa ? '٪' : '%';
  void add(String level, String ico, String text, double w, [String? hint]) => out.add((level: level, ico: ico, text: text, hint: hint, w: w));
  final rate = cur.rate!;
  final wdNames = fa ? saWdFa : saWdEn;

  // ۱) نسبت به بازه‌ی قبل (هر دو بازه حداقل ۵ ثبت)
  if (prev.rate != null && prev.succ + prev.fail >= 5) {
    final d = rate - prev.rate!;
    if (d.abs() >= 0.08) {
      add(d > 0 ? 'good' : 'warn', d > 0 ? '📈' : '📉', fa ? 'نرخ موفقیت نسبت به بازه‌ی قبل ${N(_p(d.abs()))}$pc ${d > 0 ? 'بهتر' : 'کمتر'} شده (${N(_p(prev.rate!))}$pc ← ${N(_p(rate))}$pc).' : 'Success rate is ${_p(d.abs())}% ${d > 0 ? 'higher' : 'lower'} than the previous period (${_p(prev.rate!)}% → ${_p(rate)}%).', 0.35 + d.abs() * 2);
    }
  }

  // ۲) روندِ داخلِ همین بازه: نیمه‌ی اول در برابر نیمه‌ی دوم (هر نیمه ≥۳ روزِ دارای داده)
  final days = [for (final x in cur.series) if (x.rate != null) x.rate!];
  if (days.length >= 6) {
    final h = days.length ~/ 2;
    double mean(Iterable<double> l) => l.reduce((a, b) => a + b) / l.length;
    final a = mean(days.take(h)), b = mean(days.skip(days.length - h));
    final d = b - a;
    if (d.abs() >= 0.15) {
      add(d > 0 ? 'good' : 'warn', d > 0 ? '🚀' : '⚠️', fa ? 'در همین بازه روندت ${d > 0 ? 'صعودی' : 'نزولی'} است: نیمه‌ی اول ${N(_p(a))}$pc، نیمه‌ی دوم ${N(_p(b))}$pc.' : 'Within this period your trend is ${d > 0 ? 'rising' : 'falling'}: first half ${_p(a)}%, second half ${_p(b)}%.', 0.4 + d.abs());
    }
  }

  // ۳) روزهای هفته (هر روز ≥۳ ثبت)
  final tot = cur.succ + cur.fail;
  final avgFail = cur.fail / (tot < 1 ? 1 : tot);
  int worst = -1, best = -1;
  double worstR = 0, bestR = -1;
  int withData = 0;
  for (int i = 0; i < 7; i++) {
    final w = cur.byWeekday[i];
    final n = w[0] + w[1];
    if (n < 3) continue;
    withData++;
    final fr = w[1] / n;
    if (fr > worstR) {
      worstR = fr;
      worst = i;
    }
    if (1 - fr > bestR) {
      bestR = 1 - fr;
      best = i;
    }
  }
  if (withData >= 2) {
    if (worst >= 0 && worstR >= (avgFail * 1.4 > 0.35 ? avgFail * 1.4 : 0.35)) {
      add('warn', '📅', fa ? 'سخت‌ترین روزِ هفته «${wdNames[worst]}» است؛ ${N(_p(worstR))}$pc ثبت‌ها ناموفق (${N(cur.byWeekday[worst][0] + cur.byWeekday[worst][1])} ثبت).' : 'Hardest weekday: ${wdNames[worst]} (${_p(worstR)}% misses over ${cur.byWeekday[worst][0] + cur.byWeekday[worst][1]} entries).', worstR);
    }
    if (best >= 0 && best != worst && bestR - rate >= 0.15) {
      add('good', '🌟', fa ? 'بهترین روزِ هفته «${wdNames[best]}» است؛ ${N(_p(bestR))}$pc موفق (میانگین ${N(_p(rate))}$pc).' : 'Best weekday: ${wdNames[best]} (${_p(bestR)}% vs ${_p(rate)}% overall).', bestR - rate + 0.1);
    }
  }

  // ۴) شکستِ پشت‌سرهمِ یک عادت و ۵) ضعیف‌ترین عادت
  final start = isoToDate(_isoOf(today, -(saDaysOfSeries(cur) - 1)));
  for (final h in [for (final e in (st['habits'] is List ? st['habits'] as List : const [])) if (e is Map) e]) {
    int run = 0;
    for (var d = start; !d.isAfter(today); d = addDays(d, 1)) {
      final iso = dateToISO(d);
      if (!habitAppliesOnISO(h, iso)) continue;
      final r = habitSuccessOnISO(st, h, iso);
      if (r == null) continue;
      run = r ? 0 : run + 1;
    }
    if (run >= 3) {
      add('bad', '🧱', fa ? '«${h['name']}» ${N(run)} بار پشت‌سرهم ناموفق ثبت شده.' : '“${h['name']}” was logged as failed $run times in a row.', 0.6 + run / 20);
    }
  }
  final weakest = cur.byHabit.values.where((x) => x.s + x.f >= 5 && x.s / (x.s + x.f) < 0.5).toList()..sort((a, b) => (a.s / (a.s + a.f)).compareTo(b.s / (b.s + b.f)));
  if (weakest.isNotEmpty) {
    final x = weakest.first;
    add('warn', '🎯', fa ? '«${x.name}» کمترین موفقیت را دارد (${N(_p(x.s / (x.s + x.f)))}$pc از ${N(x.s + x.f)} ثبت).' : '“${x.name}” has the lowest success (${_p(x.s / (x.s + x.f))}% of ${x.s + x.f} entries).', 0.5 - x.s / (x.s + x.f) + 0.15);
  }

  // ۶) استریک (از دادهٔ واقعی)
  final streak = computeStreak(st, today);
  if (streak >= 3) {
    add('good', '🔥', fa ? 'استریکِ فعلی ${N(streak)} روز است؛ در این روزها همه‌ی عادت‌های سررسید موفق بوده‌اند.' : 'Current streak is $streak days — every due habit succeeded on each of them.', streak >= 7 ? 0.7 : 0.3);
  }

  // ۷) محرک/مشوق (هر مورد ≥۳ ثبت)
  final trigs = cur.trig.values.where((e) => e.s + e.f >= 3).map((e) => (e: e, lift: e.s / (e.s + e.f) - rate)).toList();
  final bad = trigs.where((x) => x.e.type == 'trigger' && x.lift <= -0.15).toList()..sort((a, b) => a.lift.compareTo(b.lift));
  if (bad.isNotEmpty) {
    final x = bad.first;
    add('bad', '⚡', fa ? 'محرک «${x.e.name}» نرخ موفقیت را ${N(_p(-x.lift))}$pc پایین می‌آورد (${N(x.e.s + x.e.f)} مورد).' : '“${x.e.name}” lowers success by ${_p(-x.lift)}% (${x.e.s + x.e.f} cases).', -x.lift + 0.1);
  }
  final good = trigs.where((x) => x.e.type == 'incentive' && x.lift >= 0.10).toList()..sort((a, b) => b.lift.compareTo(a.lift));
  if (good.isNotEmpty) {
    final x = good.first;
    add('good', '✨', fa ? 'مشوق «${x.e.name}» موفقیت را ${N(_p(x.lift))}$pc بالا می‌برد (${N(x.e.s + x.e.f)} مورد).' : '“${x.e.name}” raises success by ${_p(x.lift)}% (${x.e.s + x.e.f} cases).', x.lift);
  }

  // ۸) مانعِ اصلی (≥۳ علت ثبت‌شده و سهمِ ≥۴۰٪)؛ پیشنهاد فقط اگر علت با یک قاعده بخواند
  final fr = cur.failReasons.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final frTot = fr.fold<int>(0, (a, x) => a + x.value);
  if (fr.isNotEmpty && frTot >= 3 && fr.first.value / frTot >= 0.4) {
    final share = fr.first.value / frTot;
    add('bad', '🧩', fa ? 'مانع اصلی: «${fr.first.key}» — ${N(_p(share))}$pc علت‌های شکست (${N(fr.first.value)} از ${N(frTot)}).' : 'Main obstacle: “${fr.first.key}” — ${_p(share)}% of failure reasons (${fr.first.value} of $frTot).', share + 0.2, saSuggestionOrNull(fr.first.key, fa));
  }

  // ۹) تاب‌آوری (≥۳ شکستِ دارای روزِ بعد)
  if (cur.recovery != null && cur.recN >= 3) {
    if (cur.recovery! < 0.5) {
      add('warn', '🔁', fa ? 'بعد از یک شکست، فقط ${N(_p(cur.recovery!))}$pc مواقع روز بعد برگشته‌ای (${N(cur.recN)} مورد).' : 'After a miss you came back the next day only ${_p(cur.recovery!)}% of the time (${cur.recN} cases).', 0.5 - cur.recovery! + 0.15);
    } else if (cur.recovery! >= 0.75) {
      add('good', '💪', fa ? 'تاب‌آوریِ خوب: بعد از شکست، ${N(_p(cur.recovery!))}$pc مواقع روز بعد برگشته‌ای (${N(cur.recN)} مورد).' : 'Good resilience: ${_p(cur.recovery!)}% next-day comebacks after a miss (${cur.recN} cases).', 0.1);
    }
  }

  // ۱۰) جمعه در برابر بقیه (جمعه ≥۳ ثبت و بقیه ≥۶)
  final fri = cur.byWeekday[6];
  final wk = cur.byWeekday.sublist(0, 6).fold<List<int>>([0, 0], (a, w) => [a[0] + w[0], a[1] + w[1]]);
  if (fri[0] + fri[1] >= 3 && wk[0] + wk[1] >= 6) {
    final d = fri[0] / (fri[0] + fri[1]) - wk[0] / (wk[0] + wk[1]);
    if (d <= -0.15) add('warn', '🌙', fa ? 'جمعه‌ها ${N(_p(-d))}$pc کمتر از بقیه‌ی روزها موفق هستی.' : 'On Fridays you succeed ${_p(-d)}% less than on other days.', -d);
  }

  // ۱۱) چالش‌ها: موفق/ناموفقِ ثبت‌شده در همین بازه (واقعی)
  final from = start.millisecondsSinceEpoch, to = addDays(today, 1).millisecondsSinceEpoch;
  int cs = 0, cf = 0;
  for (final c in (st['challenges'] is List ? st['challenges'] as List : const [])) {
    if (c is! Map || c['completedAt'] is! num) continue;
    final t = (c['completedAt'] as num).toInt();
    if (t < from || t >= to) continue;
    if (c['status'] == 'success') cs++;
    if (c['status'] == 'failed') cf++;
  }
  if (cs + cf > 0) {
    add(cf > cs ? 'warn' : 'good', '🏆', fa ? 'در این بازه ${N(cs)} چالش موفق و ${N(cf)} چالش ناموفق ثبت شده است.' : 'In this period: $cs successful and $cf failed challenges.', 0.45);
  }

  out.sort((a, b) => b.w.compareTo(a.w));
  return out;
}

String _isoOf(DateTime d, int offsetDays) => dateToISO(addDays(startOfDay(d), offsetDays));

/// طولِ بازه‌ی تحلیل از روی سریِ خودِ SaResult
int saDaysOfSeries(SaResult r) => r.series.length;

/// جزئیاتِ «تمرکزِ امروز» برای یک عادت: نرخِ موفقیت (اگر ≥۳ ثبت)، پرتکرارترین علتِ شکستِ همین عادت و پیشنهادِ مرتبط (در صورت وجود)
({int? ratePct, int n, String? topReason, String? hint}) focusDetail(Doc st, SaResult cur, Map h, String from, String to, bool fa) {
  final x = cur.byHabit['${h['id']}'];
  final n = x == null ? 0 : x.s + x.f;
  final ratePct = (x != null && n >= 3) ? _p(x.s / n) : null;
  final rs = st['reasons'] is Map ? (st['reasons'] as Map)['${h['id']}'] : null;
  final counts = <String, int>{};
  if (rs is Map) {
    rs.forEach((iso, e) {
      if ('$iso'.compareTo(from) < 0 || '$iso'.compareTo(to) > 0 || e is! Map || e['status'] != 'fail') return;
      final r = e['reason'];
      if (r is String && r.isNotEmpty && r != '(بدون دلیل)') counts[r] = (counts[r] ?? 0) + 1;
    });
  }
  String? top;
  if (counts.isNotEmpty) top = (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  return (ratePct: ratePct, n: n, topReason: top, hint: top == null ? null : saSuggestionOrNull(top, fa));
}
