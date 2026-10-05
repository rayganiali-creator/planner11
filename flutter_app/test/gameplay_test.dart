// تست تفاضلیِ ثبتِ عادت: دنباله‌ی عملیات (ثبت/پاک) روی ۱۳۰ state؛ فقط «رکوردها/دلایل» با JS مقایسه می‌شود.
// (سکه/سطح/HP/آواتار عمداً حذف شده‌اند؛ آن بخش‌های JS دیگر مرجع نیستند.)
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/gameplay.dart';

import 'golden_loader.dart';

Map<String, dynamic> _copy(Object? o) => jsonDecode(jsonEncode(o)) as Map<String, dynamic>;

void main() {
  final rows = (loadGolden('gameplay') as List).cast<Map<String, dynamic>>();

  test('همه‌ی ${rows.length} مورد: رکوردها و دلایل با JS یکسان است', () {
    final bad = <String>[];
    int ops = 0;
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      if (r['fn'] != 'runOps') continue; // HP/حالِ آواتار حذف شده
      final a = r['args'] as List;
      final st = _copy(a[0]);
      for (final op in (a[1] as List)) {
        switch (op[0]) {
          case 'bin':
            setBinaryRecord(st, op[1], op[2], op[3]);
            ops++;
          case 'val':
            setValueRecord(st, op[1], op[2], op[3]);
            ops++;
          case 'clear':
            clearRecord(st, op[1], op[2]);
            ops++;
        }
      }
      Map pick(Map s) => {'records': s['records'], 'reasons': s['reasons']};
      final d = firstDiff(jsonDecode(jsonEncode(pick(st))), pick((r['ok'] as Map<String, dynamic>)['state'] as Map));
      if (d != null) {
        bad.add('#$i: $d');
        if (bad.length >= 8) break;
      }
    }
    // ignore: avoid_print
    print('عملیاتِ مقایسه‌شده: $ops');
    expect(bad, isEmpty, reason: bad.join('\n'));
  });
}
