import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/format.dart';

import 'golden_loader.dart';

void main() {
  final rows = (loadGolden('format') as List).cast<Map<String, dynamic>>();
  test('ساعتِ هدر: همه‌ی ${rows.length} مورد با JS یکی است', () {
    final bad = <String>[];
    for (final r in rows) {
      final n = (r['now'] as List).cast<int>();
      final got = clockText(DateTime(n[0], n[1], n[2], n[3], n[4]), fa: (r['args'] as List)[0] == 'fa');
      if (got != r['ok']) bad.add('$n ${(r['args'] as List)[0]}: Dart="$got" JS="${r['ok']}"');
    }
    expect(bad, isEmpty, reason: bad.take(6).join('\n'));
  });
}
