// تست تفاضلی برنامه‌ریز یادآوری‌ها: فهرستِ فراخوانی‌های پلاگین اعلانِ JS در برابر خروجی Dart.
// ترتیب بینِ شناسه‌های مختلف در JS به‌خاطر async آزاد است؛ پس «به‌ازای هر شناسه» مقایسه می‌کنیم
// (برای هر شناسه ترتیب مهم است: اول لغو، بعد ثبت).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/reminders.dart';

import 'golden_loader.dart';

Map<String, List<Object?>> perId(Iterable<List<Object?>> ops) {
  final m = <String, List<Object?>>{};
  for (final o in ops) {
    (m['${o[1]}'] ??= []).add(o);
  }
  return m;
}

void main() {
  final rows = (loadGolden('reminders') as List).cast<Map<String, dynamic>>();

  test('همه‌ی ${rows.length} مورد با JS یکسان است', () {
    final counts = <String, int>{};
    final bad = <String, int>{};
    final msgs = <String>[];
    for (final r in rows) {
      final fn = r['fn'] as String;
      counts[fn] = (counts[fn] ?? 0) + 1;
      final n = (r['now'] as List).cast<int>();
      final now = DateTime(n[0], n[1], n[2], n[3], n[4]);
      final a = r['args'] as List;
      Object? got;
      Object? want = r['ok'];
      try {
        switch (fn) {
          case 'numericId':
            got = rpNumericId(a[0] as String);
          case 'nextHabitOccurrence':
            got = rpNextHabitOccurrence(a[0] as int, a[1] as int, now);
          case 'nextTodo':
            got = computeNextTodoOccurrence(a[0] as Map, now);
          case 'todoToday':
            got = todoAppliesToday(a[0] as Map, now);
          case 'planResync':
            got = perId(planResyncAll(jsonDecode(jsonEncode(a[0])) as Map<String, dynamic>, now).map((o) => o.toJson()));
            want = perId((want as List).cast<List<Object?>>());
          case 'planChallenge':
            got = perId(planChallenge(jsonDecode(jsonEncode(a[0])) as Map<String, dynamic>, a[1] as Map, now).map((o) => o.toJson()));
            want = perId((want as List).cast<List<Object?>>());
          case 'planDaily':
            final st = jsonDecode(jsonEncode(a[0])) as Map<String, dynamic>;
            got = perId(planDailyHabit(st, a[1] as String, 'T', 'B', a[2] as int, a[3] as int, now).map((o) => o.toJson()));
            want = perId((want as List).cast<List<Object?>>());
          case 'planCancelChallenge':
            got = perId(planCancelChallenge(a[0] as String).map((o) => o.toJson()));
            want = perId((want as List).cast<List<Object?>>());
          default:
            throw UnimplementedError(fn);
        }
      } catch (e, st) {
        got = 'EXCEPTION: $e\n$st';
      }
      final d = firstDiff(jsonDecode(jsonEncode(got)), jsonDecode(jsonEncode(want)));
      if (d != null) {
        bad[fn] = (bad[fn] ?? 0) + 1;
        if (msgs.length < 8) msgs.add('$fn @$n: $d');
      }
    }
    // ignore: avoid_print
    print('تعداد هر تابع: $counts');
    expect(bad, isEmpty, reason: '$bad\n${msgs.join('\n')}');
  });
}
