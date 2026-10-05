// افزوده‌های «تحلیل هوشمند» روی موتورِ saCompute (که با JS سنجیده شده): امتیازِ کلی، عادت‌های در خطر، تمرکزِ امروز.
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
