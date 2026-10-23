// تست تفاضلی منطق عادت/امتیاز/سطح/streak/سری‌ها: خروجی Dart باید با خروجی طلایی JS یکی باشد.
// اجرا با همان منطقه‌ی زمانی‌ای که golden با آن ساخته شده:  TZ=Europe/Berlin flutter test
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/calendar.dart';
import 'package:routine_planner/core/habits.dart';
import 'package:routine_planner/core/smart.dart';

import 'golden_loader.dart';

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
      case 'computeStreak':
        return computeStreak(st, now);
      case 'computePermanentStreak':
        return computePermanentStreak(st, now);
      case 'computeHabitStreak_id':
        return computeHabitStreak(st, findHabit(st, a[0]), now);
      case 'computeHabitBestRecord_id':
        return computeHabitBestRecord(st, findHabit(st, a[0]));
      case 'smart':
        {
          final st2 = Map<String, dynamic>.from(st);
          final rg = a[0] as String;
          final fa = a[1] == 'fa';
          final cur = saCompute(st2, saPeriod(rg, 0, now)), prev = saCompute(st2, saPeriod(rg, 1, now));
          Map pack(SaResult r) => {
                'succ': r.succ, 'fail': r.fail, 'rate': r.rate, 'perfect': r.perfect, 'zero': r.zero, 'activeDays': r.activeDays, 'dueDays': r.dueDays,
                'recovery': r.recovery, 'recN': r.recN, 'consistency': r.consistency, 'byWeekday': r.byWeekday,
                'byHabit': {for (final e in r.byHabit.entries) e.key: {'s': e.value.s, 'f': e.value.f, 'best': e.value.best, 'name': e.value.name}},
                'trig': {for (final e in r.trig.entries) e.key: {'name': e.value.name, 'type': e.value.type, 's': e.value.s, 'f': e.value.f, 'reasons': e.value.reasons}},
                'failReasons': r.failReasons, 'winReasons': r.winReasons,
                'series': [for (final x in r.series) {'iso': x.iso, 'rate': x.rate}],
              };
          return {
            'cur': pack(cur),
            'prev': pack(prev),
            'insights': [for (final x in saInsights(cur, prev, fa)) {'level': x.level, 'ico': x.ico, 't': x.t, 's': x.s, 'w': x.w}],
          };
        }
      case 'getWeekStart_iso':
        return dateToISO(getWeekStart(st, startOfDay(now)));
    }
    throw UnimplementedError(fn);
  }

  test('همه‌ی ${cases.length} مورد با خروجی JS یکسان است', () {
    final counts = <String, int>{};
    final bad = <String, int>{};
    final msgs = <String>[];
    for (final c in cases) {
      final fn = c['fn'] as String;
      // این سه تابعِ JS (باگ‌دار: امروز شمرده نمی‌شد، برچسب‌های هفته/ماه، میانگینِ ناهمگن) عمداً با core/analytics.dart جایگزین شدند؛ تستشان در analytics_core_test است
      if (const {'habitProgressPct_id', 'collectSeries', 'getTotalStats', 'getWeekStart_iso', 'computeAllHabitPoints', 'computeTotalPoints', 'getRecordPoints_id', 'getHabitRewardPoints_id', 'level_habit', 'level_base', 'stageCount_id', 'getAccountLevelFromCoins', 'coinOps'}.contains(fn)) continue; // سکه/سطحِ عادت حذف شد // getWeekStart: شروعِ هفته‌ی فارسی (اصلاحِ باگِ HTML)
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
      if (fn == 'smart') {
        // تفاوتِ آگاهانه با JS: «امروزِ بی‌ثبت» روزِ سررسید حساب نمی‌شود (dueDays/perfect/zero/consistency)؛ بقیه‌ی فیلدها باید یکی باشند.
        for (final side in [got, want]) {
          for (final k in ['cur', 'prev']) {
            for (final f in ['dueDays', 'perfect', 'zero', 'consistency']) {
              ((side as Map)[k] as Map).remove(f);
            }
          }
        }
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
