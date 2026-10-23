// پورت عین‌به‌عینِ بخش «PERSIAN CALENDAR HELPERS» از www/index.html.
// هر تابع با خروجی طلایی گرفته‌شده از خودِ JS سنجیده می‌شود (test/calendar_test.dart).
//
// نکته‌ی دقیق: در JS از `~~(a / b)` استفاده شده (کوتاه‌کردن به سمت صفر)؛ معادلش در Dart
// همان `~/` است، و `mod` آنجا «باقی‌مانده‌ی بریده» است (علامتِ مقسوم) نه `%` اقلیدسی.

int _div(int a, int b) => a ~/ b;
int _mod(int a, int b) => a - (a ~/ b) * b;

const List<int> _jBreaks = [
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, 1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178
];

typedef JalCal = ({int leap, int gy, int march});
typedef GDate = ({int gy, int gm, int gd});
typedef JDate = ({int jy, int jm, int jd});

JalCal jalCal(int jy) {
  final bl = _jBreaks.length;
  final gy = jy + 621;
  int leapJ = -14;
  int jp = _jBreaks[0];
  int jump = 0;
  for (int i = 1; i < bl; i++) {
    final jm = _jBreaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ = leapJ + _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
    jp = jm;
  }
  int n = jy - jp;
  leapJ = leapJ + _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
  if (_mod(jump, 33) == 4 && jump - n == 4) leapJ += 1;
  final leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150;
  final march = 20 + leapJ - leapG;
  if (jump - n < 6) n = n - jump + _div(jump, 33) * 33;
  int leap = _mod(_mod(n + 1, 33) - 1, 4);
  if (leap == -1) leap = 4;
  return (leap: leap, gy: gy, march: march);
}

int g2d(int gy, int gm, int gd) {
  final d = _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) + _div(153 * _mod(gm + 9, 12) + 2, 5) + gd - 34840408;
  return d - _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) + 752;
}

int j2d(int jy, int jm, int jd) {
  final r = jalCal(jy);
  return g2d(r.gy, 3, r.march) + (jm - 1) * 31 - _div(jm, 7) * (jm - 7) + jd - 1;
}

GDate d2g(int jdn) {
  int j = 4 * jdn + 139361631;
  j = j + _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
  final i = _div(_mod(j, 1461), 4) * 5 + 308;
  return (
    gy: _div(j, 1461) - 100100 + _div(8 - _mod(_div(i, 153), 12) - 1, 6),
    gm: _mod(_div(i, 153), 12) + 1,
    gd: _div(_mod(i, 153), 5) + 1,
  );
}

JDate d2j(int jdn) {
  final gy = d2g(jdn).gy;
  int jy = gy - 621;
  final r = jalCal(jy);
  final jdn1f = g2d(gy, 3, r.march);
  int k = jdn - jdn1f;
  if (k >= 0) {
    if (k <= 185) return (jy: jy, jm: 1 + _div(k, 31), jd: _mod(k, 31) + 1);
    k -= 186;
  } else {
    jy -= 1;
    k += 179;
    if (r.leap == 1) k += 1;
  }
  return (jy: jy, jm: 7 + _div(k, 30), jd: _mod(k, 30) + 1);
}

JDate toJalaali(int gy, int gm, int gd) => d2j(g2d(gy, gm, gd));

GDate toGregorian(int jy, int jm, int jd) => d2g(j2d(jy, jm, jd));

int jalaaliMonthLength(int jy, int jm) {
  if (jm <= 6) return 31;
  if (jm <= 11) return 30;
  return jalCal(jy).leap == 1 ? 30 : 29;
}

const List<String> jalaliMonthsEn = [
  'Farvardin', 'Ordibehesht', 'Khordad', 'Tir', 'Mordad', 'Shahrivar', 'Mehr', 'Aban', 'Azar', 'Dey', 'Bahman', 'Esfand'
];
const List<String> persianMonths = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
];
const List<String> persianWeekdays = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];
const List<String> persianWeekdaysShort = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
const List<String> persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
const List<String> enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const List<String> enWeekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const List<String> enWeekdaysShort = ['Sa', 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr'];

/// مثل `String(n).replace(/[0-9]/g, …)`؛ ورودی هر چیزی می‌تواند باشد.
String toPersianDigits(Object? n) =>
    '$n'.replaceAllMapped(RegExp('[0-9]'), (m) => persianDigits[int.parse(m[0]!)]);

String pad2(num n) => n < 10 ? '0$n' : '$n';

String dateToISO(DateTime d) => '${d.year}-${pad2(d.month)}-${pad2(d.day)}';

/// `isoToDate`: «YYYY-MM-DD» → تاریخ محلی (بدونِ ساعت).
DateTime isoToDate(String iso) {
  final p = iso.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// JS: Sunday=0 … Saturday=6 ← Dart: Monday=1 … Sunday=7
int jsWeekday(DateTime d) => d.weekday % 7;

/// شنبه=۰ … جمعه=۶
int jsWeekdayToPersianIndex(int jsDay) => (jsDay + 1) % 7;

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// `setDate(getDate()+n)`: سازنده‌ی DateTime روزِ سرریز را خودش نرمال می‌کند.
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

String isoAddDays(String iso, int n) => dateToISO(addDays(isoToDate(iso), n));
