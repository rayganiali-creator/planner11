// خواندن فایل‌های طلایی (JSON فشرده) که tools/html-harness/gen_golden.py از خودِ JS می‌سازد.
import 'dart:convert';
import 'dart:io';

Object? loadGolden(String name) {
  final bytes = File('test/golden/$name.json.gz').readAsBytesSync();
  return jsonDecode(utf8.decode(gzip.decode(bytes)));
}

/// مقایسه‌ی ساختاری: اعداد برابرِ عددی (۵ == ۵٫۰)، نگاشت‌ها بدونِ توجه به ترتیبِ کلید.
bool deepEq(Object? a, Object? b) {
  if (a is num && b is num) return a == b || (a.isNaN && b.isNaN);
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!deepEq(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !deepEq(a[k], b[k])) return false;
    }
    return true;
  }
  return a == b;
}

/// اولین تفاوتِ دو ساختار (برای پیامِ خطای خوانا).
String? firstDiff(Object? a, Object? b, [String path = '']) {
  if (a is Map && b is Map) {
    for (final k in {...a.keys, ...b.keys}) {
      if (!a.containsKey(k)) return '$path/$k: در Dart نیست، JS=${_short(b[k])}';
      if (!b.containsKey(k)) return '$path/$k: در JS نیست، Dart=${_short(a[k])}';
      final d = firstDiff(a[k], b[k], '$path/$k');
      if (d != null) return d;
    }
    return null;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return '$path: طول Dart=${a.length} JS=${b.length}';
    for (int i = 0; i < a.length; i++) {
      final d = firstDiff(a[i], b[i], '$path[$i]');
      if (d != null) return d;
    }
    return null;
  }
  return deepEq(a, b) ? null : '$path: Dart=${_short(a)} JS=${_short(b)}';
}

String _short(Object? v) {
  final s = jsonEncode(v);
  return s.length > 140 ? '${s.substring(0, 140)}…' : s;
}
