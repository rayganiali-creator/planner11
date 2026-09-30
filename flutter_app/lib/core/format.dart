// قالب‌بندی متن‌ها: پورتِ عین‌به‌عینِ renderClock (هدر). با JS سنجیده می‌شود (test/format_test.dart).
import 'calendar.dart';

/// فارسی: «شنبه، ۸ مهر — ۲۰:۳۷» ؛ انگلیسی: «Saturday, Sep 30 — 20:37»
String clockText(DateTime d, {required bool fa}) {
  final t = '${pad2(d.hour)}:${pad2(d.minute)}';
  if (fa) {
    final j = toJalaali(d.year, d.month, d.day);
    final wd = persianWeekdays[jsWeekdayToPersianIndex(jsWeekday(d))];
    return '$wd، ${toPersianDigits(j.jd)} ${persianMonths[j.jm - 1]} — ${toPersianDigits(t)}';
  }
  return '${enWeekdays[jsWeekday(d)]}, ${enMonths[d.month - 1]} ${d.day} — $t';
}
