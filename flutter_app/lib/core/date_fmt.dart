// نمایشِ تاریخ در کل برنامه: «نوعِ تقویم» (calendarType: jalali پیش‌فرض / gregorian) تعیین می‌کند چه تاریخی نشان داده شود
// و «زبان» فقط نام‌ها و رقم‌ها را (فارسی: رقم فارسی). منطقِ تاریخ‌ها همان DateTime میلادی می‌ماند.
import 'calendar.dart';

const List<String> gregorianMonthsFa = ['ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن', 'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر'];
const List<String> _enMonthsFull = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/// پیش‌فرض جلالی؛ فقط وقتی کاربر صراحتاً میلادی انتخاب کرده میلادی است.
bool isJalali(Map st) => st['calendarType'] != 'gregorian';

String _n(Object v, bool fa) => fa ? toPersianDigits(v) : '$v';

String monthName(int y, int m, {required bool jalali, required bool fa, bool full = false}) {
  if (jalali) return fa ? persianMonths[m - 1] : jalaliMonthsEn[m - 1];
  return fa ? gregorianMonthsFa[m - 1] : (full ? _enMonthsFull[m - 1] : enMonths[m - 1]);
}

/// ({y,m,d}) در تقویمِ انتخاب‌شده
({int y, int m, int d}) ymd(DateTime d, bool jalali) {
  if (!jalali) return (y: d.year, m: d.month, d: d.day);
  final j = toJalaali(d.year, d.month, d.day);
  return (y: j.jy, m: j.jm, d: j.jd);
}

String weekdayName(DateTime d, {required bool fa}) => fa ? persianWeekdays[jsWeekdayToPersianIndex(jsWeekday(d))] : enWeekdays[jsWeekday(d)];

/// «۸ مهر ۱۴۰۴» / «Sep 30, 2025» ؛ [withYear] false = بدون سال؛ [weekday] = با نامِ روز
String dateLabel(DateTime d, {required bool jalali, required bool fa, bool withYear = true, bool weekday = false}) {
  final c = ymd(d, jalali);
  final mn = monthName(c.y, c.m, jalali: jalali, fa: fa);
  final body = (fa || jalali)
      ? '${_n(c.d, fa)} $mn${withYear ? ' ${_n(c.y, fa)}' : ''}'
      : '$mn ${c.d}${withYear ? ', ${c.y}' : ''}';
  return weekday ? '${weekdayName(d, fa: fa)}${fa ? '،' : ','} $body' : body;
}

String timeLabel(DateTime d, {required bool fa}) {
  final t = '${pad2(d.hour)}:${pad2(d.minute)}';
  return fa ? toPersianDigits(t) : t;
}

String dateTimeLabel(DateTime d, {required bool jalali, required bool fa, bool withYear = false, String sep = ' — '}) =>
    '${dateLabel(d, jalali: jalali, fa: fa, withYear: withYear)}$sep${timeLabel(d, fa: fa)}';

/// عددی «۱۴۰۴/۷/۸» یا «9/30/2025»
String dateNumeric(DateTime d, {required bool jalali, required bool fa}) {
  final c = ymd(d, jalali);
  return jalali || fa ? _n('${c.y}/${c.m}/${c.d}', fa) : '${c.m}/${c.d}/${c.y}';
}
