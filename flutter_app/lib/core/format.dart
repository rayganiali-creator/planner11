// قالب‌بندی متن‌ها: پورتِ عین‌به‌عینِ renderClock (هدر). با JS سنجیده می‌شود (test/format_test.dart).
import 'calendar.dart';
import 'date_fmt.dart' show gregorianMonthsFa;

/// فارسی: «شنبه، ۸ مهر — ۲۰:۳۷» ؛ انگلیسی: «Saturday, Sep 30 — 20:37»
String clockText(DateTime d, {required bool fa, bool? jalali}) {
  final t = '${pad2(d.hour)}:${pad2(d.minute)}';
  final jal = jalali ?? fa; // پیش‌فرضِ قدیم: فارسی=جلالی، انگلیسی=میلادی (با JS سنجیده می‌شود)
  if (jal) {
    final j = toJalaali(d.year, d.month, d.day);
    if (fa) {
      final wd = persianWeekdays[jsWeekdayToPersianIndex(jsWeekday(d))];
      return '$wd، ${toPersianDigits(j.jd)} ${persianMonths[j.jm - 1]} — ${toPersianDigits(t)}';
    }
    return '${enWeekdays[jsWeekday(d)]}, ${j.jd} ${jalaliMonthsEn[j.jm - 1]} — $t';
  }
  if (fa) {
    return '${persianWeekdays[jsWeekdayToPersianIndex(jsWeekday(d))]}، ${toPersianDigits(d.day)} ${gregorianMonthsFa[d.month - 1]} — ${toPersianDigits(t)}';
  }
  return '${enWeekdays[jsWeekday(d)]}, ${enMonths[d.month - 1]} ${d.day} — $t';
}
