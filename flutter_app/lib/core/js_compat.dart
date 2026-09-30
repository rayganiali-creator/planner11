// کمک‌های «هم‌رفتاری با JS». داده‌ی ذخیره‌شده از JS آمده و نوع‌هایش شل است؛ برای اینکه
// نتیجه‌ی محاسبه‌ها با نسخه‌ی فعلی یکی بماند، همان قواعد تبدیلِ JS اینجا بازسازی شده است.
import 'dart:math' as math;

/// `String(v)` در JS (برای انواعی که از JSON می‌آیند).
String jsString(Object? v) {
  if (v == null) return 'null';
  if (v is bool) return v ? 'true' : 'false';
  if (v is int) return v.toString();
  if (v is double) {
    if (v.isNaN) return 'NaN';
    if (v.isInfinite) return v.isNegative ? '-Infinity' : 'Infinity';
    if (v == v.truncateToDouble() && v.abs() < 1e21) return v.toInt().toString();
    return v.toString();
  }
  if (v is String) return v;
  if (v is List) return v.map((e) => (e == null) ? '' : jsString(e)).join(',');
  return '[object Object]';
}

final RegExp _floatPrefix = RegExp(r'^[+-]?(?:Infinity|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)');

/// `parseFloat(v)`: بلندترین پیشوندِ عددی؛ وگرنه NaN.
double jsParseFloat(Object? v) {
  final s = jsString(v).trimLeft();
  final m = _floatPrefix.firstMatch(s);
  if (m == null) return double.nan;
  final t = m[0]!;
  if (t.endsWith('Infinity')) return t.startsWith('-') ? double.negativeInfinity : double.infinity;
  return double.parse(t);
}

/// `Number(v)` در JS (برای مقایسه‌هایی مثل `value <= target`).
double jsToNumber(Object? v) {
  if (v == null) return 0;
  if (v is bool) return v ? 1 : 0;
  if (v is num) return v.toDouble();
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return 0;
    if (t == 'Infinity' || t == '+Infinity') return double.infinity;
    if (t == '-Infinity') return double.negativeInfinity;
    return double.tryParse(t) ?? double.nan;
  }
  return double.nan;
}

/// درستیِ JS (truthy).
bool jsTruthy(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return !(v == 0 || v.isNaN);
  if (v is String) return v.isNotEmpty;
  return true; // شیء/آرایه
}

/// `a || b`
Object? jsOr(Object? a, Object? b) => jsTruthy(a) ? a : b;

/// `Math.round`: نیمه به سمت +∞ (برخلاف `num.round` که از صفر دور می‌شود).
int jsRound(num x) => (x + 0.5).floor();

num jsMin(num a, num b) => math.min(a, b);
