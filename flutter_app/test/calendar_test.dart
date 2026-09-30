// تست تفاضلی: خروجی Dart باید دقیقاً همان خروجیِ JS (golden/calendar.json) باشد.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/calendar.dart';

void main() {
  final rows = (jsonDecode(File('test/golden/calendar.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();

  Object? run(String fn, List a) {
    switch (fn) {
      case 'jalCal':
        final r = jalCal(a[0]);
        return {'leap': r.leap, 'gy': r.gy, 'march': r.march};
      case 'g2d':
        return g2d(a[0], a[1], a[2]);
      case 'j2d':
        return j2d(a[0], a[1], a[2]);
      case 'd2g':
        final r = d2g(a[0]);
        return {'gy': r.gy, 'gm': r.gm, 'gd': r.gd};
      case 'd2j':
        final r = d2j(a[0]);
        return {'jy': r.jy, 'jm': r.jm, 'jd': r.jd};
      case 'toJalaali':
        final r = toJalaali(a[0], a[1], a[2]);
        return {'jy': r.jy, 'jm': r.jm, 'jd': r.jd};
      case 'toGregorian':
        final r = toGregorian(a[0], a[1], a[2]);
        return {'gy': r.gy, 'gm': r.gm, 'gd': r.gd};
      case 'jalaaliMonthLength':
        return jalaaliMonthLength(a[0], a[1]);
      case 'toPersianDigits':
        return toPersianDigits(a[0]);
      case 'pad2':
        return pad2(a[0]);
      case 'dateToISO_ymd':
        return dateToISO(DateTime(a[0], a[1], a[2]));
      case 'isoToDate_ymd':
        final d = isoToDate(a[0]);
        return [d.year, d.month, d.day, jsWeekday(d)];
      case 'isoAddDays':
        return isoAddDays(a[0], a[1]);
      case 'jsWeekdayToPersianIndex':
        return jsWeekdayToPersianIndex(a[0]);
    }
    throw UnimplementedError(fn);
  }

  test('هیچ تابعِ بدون پورتی در golden نیست', () {
    final fns = rows.map((r) => r['fn']).toSet();
    for (final f in fns) {
      expect(() => run(f as String, rows.firstWhere((r) => r['fn'] == f)['args']), returnsNormally, reason: f);
    }
  });

  test('همه‌ی ${rows.length} مورد با خروجی JS یکسان است', () {
    int bad = 0;
    final msgs = <String>[];
    for (final r in rows) {
      final got = run(r['fn'], r['args']);
      final want = r['ok'];
      if (jsonEncode(got) != jsonEncode(want)) {
        bad++;
        if (msgs.length < 10) msgs.add('${r['fn']}(${r['args']}) → Dart=${jsonEncode(got)} JS=${jsonEncode(want)}');
      }
    }
    expect(bad, 0, reason: msgs.join('\n'));
  });
}
