// تست تفاضلی منطق عادت/امتیاز/سطح/streak/سری‌ها: خروجی Dart باید با خروجی طلایی JS یکی باشد.
// اجرا با همان منطقه‌ی زمانی‌ای که golden با آن ساخته شده:  TZ=Europe/Berlin flutter test
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/calendar.dart';
import 'package:routine_planner/core/habits.dart';

import 'golden_loader.dart';

Map lvl(LevelDef l) => {'num': l.num, 'minPoints': l.minPoints, 'labelFa': l.labelFa, 'labelEn': l.labelEn, 'icon': l.icon, 'isCapstone': l.isCapstone};

Map lvlFromJs(Map m) => {
      'num': m['num'], 'minPoints': m['minPoints'], 'labelFa': m['labelFa'], 'labelEn': m['labelEn'],
      'icon': m['icon'] ?? '', 'isCapstone': m['isCapstone'] ?? false,
    };

void main() {
  final raw = loadGolden('habits') as Map<String, dynamic>;
  final states = (raw['states'] as List).cast<Map<String, dynamic>>();
  final cases = (raw['cases'] as List).cast<Map<String, dynamic>>();

  test('منطقه‌ی زمانی اجرا با golden یکی است', () {
    final tz = Platform.environment['TZ'] ?? '';
    expect(tz, raw['tz'], reason: 'اجرا کنید: TZ=${raw['tz']} flutter test');
  });

  Map findHabit(Map<String, dynamic> st, String id) =>
      ((st['habits'] as List).firstWhere((h) => h['id'] == id)) as Map;

  Object? run(Map<String, dynamic> st, DateTime now, String fn, List a) {
    switch (fn) {
      case 'habitAppliesOnISO_id':
        return habitAppliesOnISO(findHabit(st, a[0]), a[1]);
      case 'applicableIds':
        return [for (final h in applicableHabitsForISO(st, a[0])) h['id']];
      case 'habitSuccessOnISO_id':
        return habitSuccessOnISO(st, findHabit(st, a[0]), a[1]);
      case 'dayStats_all':
        final r = dayStatsAll(st, a[0]);
        return {'total': r.total, 'success': r.success, 'fail': r.fail, 'unset': r.unset};
      case 'dayStats_perm':
        final r = dayStats(st, a[0], (h) => h['permanent'] != false);
        return {'total': r.total, 'success': r.success, 'fail': r.fail, 'unset': r.unset};
      case 'getStatusFromRecord_id':
        return getStatusFromRecord(a[0], findHabit(st, a[1]));
      case 'getRecordPoints_id':
        return getRecordPoints(a[0], findHabit(st, a[1]));
      case 'getHabitRewardPoints_id':
        return getHabitRewardPoints(findHabit(st, a[0]));
      case 'computeAllHabitPoints':
        return computeAllHabitPoints(st);
      case 'computeTotalPoints':
        return computeTotalPoints(st);
      case 'level_habit':
        return lvl(getLevelFromPoints(a[0], habitActiveThresholds(findHabit(st, a[1]))));
      case 'level_base':
        return lvl(getLevelFromPoints(a[0]));
      case 'stageCount_id':
        return habitUnlockedStageCount(findHabit(st, a[0]));
      case 'computeStreak':
        return computeStreak(st, now);
      case 'computePermanentStreak':
        return computePermanentStreak(st, now);
      case 'habitProgressPct_id':
        return habitProgressPct(st, findHabit(st, a[0]), now);
      case 'computeHabitStreak_id':
        return computeHabitStreak(st, findHabit(st, a[0]), now);
      case 'computeHabitBestRecord_id':
        return computeHabitBestRecord(st, findHabit(st, a[0]));
      case 'collectSeries':
        final s = collectSeries(st, a[0], now);
        return {'labels': s.labels, 'values': s.values};
      case 'getTotalStats':
        final t = getTotalStats(st, a[0], now);
        return {'success': t.success, 'fail': t.fail};
      case 'getWeekStart_iso':
        return dateToISO(getWeekStart(st, startOfDay(now)));
      case 'getAccountLevelFromCoins':
        final c = a[0];
        return getAccountLevelFromCoins(c is num ? c : (c == null ? null : double.nan));
      case 'coinOps':
        final out = <Object?>[];
        for (final op in a[0]) {
          final x = op[1] as num;
          if (op[0] == 'add') {
            out.add(addCoins(st, x));
          } else if (op[0] == 'remove') {
            out.add(removeCoins(st, x));
          } else {
            syncCoinsFromPoints(st, x);
            out.add(null);
          }
          final sc = st['scores'] as Map;
          out.add(sc['coins']);
          out.add(sc['lastPoints']);
        }
        return out;
    }
    throw UnimplementedError(fn);
  }

  test('همه‌ی ${cases.length} مورد با خروجی JS یکسان است', () {
    final counts = <String, int>{};
    final bad = <String, int>{};
    final msgs = <String>[];
    for (final c in cases) {
      final fn = c['fn'] as String;
      counts[fn] = (counts[fn] ?? 0) + 1;
      // هر مورد روی کپیِ تازه‌ی state (coinOps آن را تغییر می‌دهد)
      final st = jsonDecode(jsonEncode(states[c['s']])) as Map<String, dynamic>;
      final n = (c['now'] as List).cast<int>();
      final now = DateTime(n[0], n[1], n[2], n[3], n[4]);
      Object? got;
      try {
        got = run(st, now, fn, c['args']);
      } catch (e) {
        got = 'EXCEPTION: $e';
      }
      Object? want = c['ok'];
      if (fn.startsWith('level_')) {
        got = lvlFromJs(got as Map);
        want = lvlFromJs(want as Map);
      }
      if (!deepEq(got, want)) {
        bad[fn] = (bad[fn] ?? 0) + 1;
        if (msgs.length < 12) msgs.add('$fn(${jsonEncode(c['args'])}) @${c['now']} state#${c['s']}\n   Dart=${jsonEncode(got)}\n   JS  =${jsonEncode(want)}');
      }
    }
    // ignore: avoid_print
    print('تعداد هر تابع: $counts');
    expect(bad, isEmpty, reason: 'اختلاف‌ها: $bad\n${msgs.join('\n')}');
  });
}
