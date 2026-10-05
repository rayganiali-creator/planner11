// تحلیلِ پایه: فقط از دادهٔ واقعیِ ذخیره‌شده (records + عادت‌های فعلی) محاسبه می‌شود؛ هیچ عددِ تقریبی/ساختگی نمی‌سازد.
//
// تعاریف (همه‌جا یکسان):
//  • «عادتِ سررسید» در یک روز: عادتی که در همان روز طبق createdAt/endDate/روزهای فعال فعال است (habitAppliesOnISO).
//  • یک روز-عادت «شمرده می‌شود» اگر روز گذشته باشد (ثبت‌نشده = ناموفق/جاافتاده) یا «امروز» باشد و نتیجه‌اش ثبت شده باشد؛
//    امروزِ ثبت‌نشده هنوز نه موفقیت است نه شکست و در هیچ درصدی نمی‌آید. روزهای آینده هرگز شمرده نمی‌شوند.
//  • تکمیل (Completion) = موفق ÷ شمرده‌شده. اگر شمرده‌شده صفر باشد مقدار null است (UI باید «داده کافی نیست» بنویسد).
//  • حذفِ عادت: رکوردها و ردپایش پاک می‌شود (deleteHabit) پس در آمار نیست. ویرایشِ برنامه/تاریخِ پایان به گذشته هم اعمال می‌شود؛
//    هدفِ عددی/زمانی با targetAtTime روی رکوردهای قبلی قفل است.
//  • تاریخ‌ها: رشته‌ی ISO محلیِ روز؛ پیمایش با DateTime(y,m,d±n) (بی‌تأثیر از DST و منطقه‌ی زمانی).
import 'calendar.dart';
import 'doc.dart';
import 'habits.dart';
import 'js_compat.dart';

bool _isJalali(Doc st) => st['calendarType'] != 'gregorian';

typedef Tally = ({int due, int success, int fail, int unset});

/// یک روز-عادت شمرده می‌شود؟ (ثبت‌شده یا روزِ گذشته)
bool _counts(DateTime d, DateTime today, bool recorded) => !d.isAfter(today) && (d.isBefore(today) || recorded);

Tally tallyDay(Doc st, DateTime day, DateTime todayIn) {
  final today = startOfDay(todayIn);
  final d = startOfDay(day);
  if (d.isAfter(today)) return (due: 0, success: 0, fail: 0, unset: 0);
  final iso = dateToISO(d);
  int due = 0, s = 0, f = 0;
  for (final h in applicableHabitsForISO(st, iso)) {
    final r = habitSuccessOnISO(st, h, iso);
    if (!_counts(d, today, r != null)) continue;
    due++;
    if (r == true) {
      s++;
    } else if (r == false) {
      f++;
    }
  }
  return (due: due, success: s, fail: f, unset: due - s - f);
}

Tally _sum(Iterable<Tally> l) => l.fold((due: 0, success: 0, fail: 0, unset: 0), (a, b) => (due: a.due + b.due, success: a.success + b.success, fail: a.fail + b.fail, unset: a.unset + b.unset));

int? completionPct(Tally t) => t.due == 0 ? null : jsRound(t.success / t.due * 100);

typedef DayPoint = ({DateTime date, String label, Tally tally, int? pct, bool future});

class RangeReport {
  final String range;
  final List<DayPoint> days; // هفته: ۷، ماه: طولِ ماه، سال: ۱۲ ماه (هر نقطه = یک ماه)
  final Tally total;
  const RangeReport(this.range, this.days, this.total);
  int? get completion => completionPct(total);
  /// روزهایی/نقطه‌هایی که واقعاً داده دارند
  int get pointsWithData => days.where((d) => d.pct != null).length;
}

String _short3(String s) => s.length <= 3 ? s : s.substring(0, 3);

RangeReport buildRangeReport(Doc st, String range, DateTime todayIn) {
  final today = startOfDay(todayIn);
  final fa = st['lang'] != 'en';
  final jal = _isJalali(st);
  final days = <DayPoint>[];
  DayPoint day(DateTime d, String label) {
    final t = tallyDay(st, d, today);
    return (date: d, label: label, tally: t, pct: completionPct(t), future: d.isAfter(today));
  }

  if (range == 'week') {
    final s = getWeekStart(st, today);
    for (int i = 0; i < 7; i++) {
      final d = addDays(s, i);
      // برچسب از «روزِ واقعیِ هفته» می‌آید (نه از اندیس): با شروعِ هفته از یکشنبه هم درست است
      final names = fa ? persianWeekdaysShort : enWeekdaysShort;
      days.add(day(d, names[jsWeekdayToPersianIndex(jsWeekday(d))]));
    }
  } else if (range == 'month') {
    final y = jal ? toJalaali(today.year, today.month, today.day).jy : today.year;
    final m = jal ? toJalaali(today.year, today.month, today.day).jm : today.month;
    final len = jal ? jalaaliMonthLength(y, m) : DateTime(y, m + 1, 0).day;
    for (int dn = 1; dn <= len; dn++) {
      final d = jal ? (() { final g = toGregorian(y, m, dn); return DateTime(g.gy, g.gm, g.gd); })() : DateTime(y, m, dn);
      days.add(day(d, fa ? toPersianDigits(dn) : '$dn'));
    }
  } else {
    final y = jal ? toJalaali(today.year, today.month, today.day).jy : today.year;
    for (int m = 1; m <= 12; m++) {
      final len = jal ? jalaaliMonthLength(y, m) : DateTime(y, m + 1, 0).day;
      final tallies = <Tally>[];
      DateTime? first;
      for (int dn = 1; dn <= len; dn++) {
        final d = jal ? (() { final g = toGregorian(y, m, dn); return DateTime(g.gy, g.gm, g.gd); })() : DateTime(y, m, dn);
        first ??= d;
        tallies.add(tallyDay(st, d, today));
      }
      final t = _sum(tallies);
      final name = jal ? (fa ? persianMonths[m - 1] : jalaliMonthsEn[m - 1]) : (fa ? gregorianMonthShortFa(m) : enMonths[m - 1]);
      days.add((date: first!, label: _short3(name), tally: t, pct: completionPct(t), future: first.isAfter(today)));
    }
  }
  return RangeReport(range, days, _sum(days.map((d) => d.tally)));
}

String gregorianMonthShortFa(int m) => const ['ژان', 'فور', 'مار', 'آور', 'مه', 'ژوئ', 'ژوئ', 'اوت', 'سپت', 'اکت', 'نوا', 'دسا'][m - 1];

/// تکمیلِ یک عادت: دائمی = ۳۰ روزِ اخیر (از آخرین «شروع یا ۲۹ روز پیش»)، مدت‌دار = از شروع تا امروز/پایان. null = داده کافی نیست.
int? habitCompletionPct(Doc st, Map h, DateTime todayIn, {int windowDays = 30}) {
  final today = startOfDay(todayIn);
  final created = h['createdAt'];
  if (created is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(created)) return null;
  var d = isoToDate(created);
  final permanent = h['permanent'] != false;
  final ws = addDays(today, -(windowDays - 1));
  if (permanent && d.isBefore(ws)) d = ws;
  int due = 0, s = 0;
  while (!d.isAfter(today)) {
    final iso = dateToISO(d);
    if (habitAppliesOnISO(h, iso)) {
      final r = habitSuccessOnISO(st, h, iso);
      if (_counts(d, today, r != null)) {
        due++;
        if (r == true) s++;
      }
    }
    d = addDays(d, 1);
  }
  return due == 0 ? null : jsRound(s / due * 100);
}

/// تعدادِ روز-عادت‌های ثبت‌شده در کل (برای تصمیمِ «داده کافی هست؟»)
int recordedHabitDays(Doc st) {
  int n = 0;
  final recs = st['records'];
  if (recs is! Map) return 0;
  final ids = {for (final h in (st['habits'] is List ? st['habits'] as List : const [])) if (h is Map) h['id']};
  for (final day in recs.values) {
    if (day is Map) n += day.keys.where(ids.contains).length;
  }
  return n;
}
