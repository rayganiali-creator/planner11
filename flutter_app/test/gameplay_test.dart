// تست تفاضلی گیم‌پلی: دنباله‌ی عملیات (ثبت/پاک/مشتق‌سازی) روی ۱۳۰ state و HP/حالِ آواتار.
// JS همان کدِ واقعیِ برنامه است (setBinaryRecord/… با renderDashboard) و toast/پنجره‌ها ضبط شده‌اند.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/gameplay.dart';

import 'golden_loader.dart';

Map<String, dynamic> _copy(Object? o) => jsonDecode(jsonEncode(o)) as Map<String, dynamic>;

void main() {
  final rows = (loadGolden('gameplay') as List).cast<Map<String, dynamic>>();
  final today = DateTime(2026, 9, 30, 10);

  test('همه‌ی ${rows.length} مورد با JS یکسان است (state و رویدادها)', () {
    final bad = <String>[];
    int events = 0;
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final a = r['args'] as List;
      final st = _copy(a[0]);
      final want = r['ok'] as Map<String, dynamic>;
      Object? got;
      if (r['fn'] == 'runOps') {
        final ev = <List<Object?>>[];
        for (final op in (a[1] as List)) {
          RecordResult? res;
          switch (op[0]) {
            case 'bin':
              res = setBinaryRecord(st, op[1], op[2], op[3]);
            case 'val':
              res = setValueRecord(st, op[1], op[2], op[3]);
            case 'clear':
              res = clearRecord(st, op[1], op[2]);
            case 'derive':
              ev.addAll(applyDerived(st, today).map((e) => e.toJson()));
          }
          if (res != null) {
            ev.addAll(res.events.map((e) => e.toJson()));
            if (res.rendered) ev.addAll(applyDerived(st, today).map((e) => e.toJson())); // renderAll()
          }
        }
        st.remove('clock'); // lastSeen به ساعتِ زنده وابسته است
        events += ev.length;
        got = {'state': st, 'events': ev};
      } else {
        final hp = computeAvatarHP(st, today);
        got = {'hp': hp, 'cond': [0, 6, 7, 12, 18, 19, 23].map((h) => avConditionOf(hp, h)).toList()};
      }
      final d = firstDiff(jsonDecode(jsonEncode(got)), want);
      if (d != null) {
        bad.add('#$i ${r['fn']}: $d');
        if (bad.length >= 8) break;
      }
    }
    // ignore: avoid_print
    print('رویدادهای مقایسه‌شده: $events');
    expect(bad, isEmpty, reason: bad.join('\n'));
  });
}
