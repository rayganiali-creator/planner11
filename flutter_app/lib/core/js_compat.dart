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
  if (v is List) return jsToNumber(jsString(v)); // Number([]) = 0 ، Number([5]) = 5 ، Number([1,2]) = NaN
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

/// `JSON.stringify(v, null, indent)` مطابق JS: عددِ کامل بدونِ «.0»، کلیدها به ترتیب درج،
/// `{}` و `[]` تک‌خطی، فرار کاراکترها مثل موتور JS (بدونِ فرارِ غیر-ASCII).
String jsonStringify(Object? v, {int indent = 0}) {
  final b = StringBuffer();
  _stringify(b, v, indent, 0);
  return b.toString();
}

void _stringify(StringBuffer b, Object? v, int indent, int depth) {
  if (v == null) {
    b.write('null');
  } else if (v is bool) {
    b.write(v ? 'true' : 'false');
  } else if (v is num) {
    b.write((v is double && (v.isNaN || v.isInfinite)) ? 'null' : jsString(v));
  } else if (v is String) {
    _quote(b, v);
  } else if (v is List) {
    if (v.isEmpty) {
      b.write('[]');
      return;
    }
    b.write('[');
    for (int i = 0; i < v.length; i++) {
      if (i > 0) b.write(',');
      if (indent > 0) b..write('\n')..write(' ' * (indent * (depth + 1)));
      _stringify(b, v[i], indent, depth + 1);
    }
    if (indent > 0) b..write('\n')..write(' ' * (indent * depth));
    b.write(']');
  } else if (v is Map) {
    final keys = v.keys.toList();
    if (keys.isEmpty) {
      b.write('{}');
      return;
    }
    b.write('{');
    for (int i = 0; i < keys.length; i++) {
      if (i > 0) b.write(',');
      if (indent > 0) b..write('\n')..write(' ' * (indent * (depth + 1)));
      _quote(b, '${keys[i]}');
      b.write(indent > 0 ? ': ' : ':');
      _stringify(b, v[keys[i]], indent, depth + 1);
    }
    if (indent > 0) b..write('\n')..write(' ' * (indent * depth));
    b.write('}');
  } else {
    b.write('null');
  }
}

void _quote(StringBuffer b, String s) {
  b.write('"');
  final u = s.codeUnits;
  for (int i = 0; i < u.length; i++) {
    final c = u[i];
    switch (c) {
      case 0x22: b.write('\\"'); break;
      case 0x5C: b.write('\\\\'); break;
      case 0x08: b.write('\\b'); break;
      case 0x0C: b.write('\\f'); break;
      case 0x0A: b.write('\\n'); break;
      case 0x0D: b.write('\\r'); break;
      case 0x09: b.write('\\t'); break;
      default:
        if (c < 0x20) {
          b.write('\\u${c.toRadixString(16).padLeft(4, '0')}');
        } else if (c >= 0xD800 && c <= 0xDBFF && i + 1 < u.length && u[i + 1] >= 0xDC00 && u[i + 1] <= 0xDFFF) {
          b..writeCharCode(c)..writeCharCode(u[++i]); // جفتِ جانشین سالم
        } else if (c >= 0xD800 && c <= 0xDFFF) {
          b.write('\\u${c.toRadixString(16).padLeft(4, '0')}'); // جانشینِ تنها (well-formed JSON.stringify)
        } else {
          b.writeCharCode(c);
        }
    }
  }
  b.write('"');
}
