// خواندن فایل‌های طلایی (JSON فشرده) که tools/html-harness/gen_golden.py از خودِ JS می‌سازد.
import 'dart:convert';
import 'dart:io';

Object? loadGolden(String name) {
  final bytes = File('test/golden/$name.json.gz').readAsBytesSync();
  return jsonDecode(utf8.decode(gzip.decode(bytes)));
}
