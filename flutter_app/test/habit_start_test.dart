import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/calendar.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/core/habits.dart';
import 'package:routine_planner/data/habit_ops.dart';

void main() {
  streakTests();
  test('تاریخ و ساعتِ شروعِ عادت ذخیره می‌شود و روزهای گذشته‌ی بعد از آن فعال‌اند', () {
    final f = HabitForm('2026-10-08')
      ..name = 'ورزش'
      ..createdAt = '2026-09-28'
      ..startTime = '07:30';
    final m = f.toMap();
    expect(m['createdAt'], '2026-09-28');
    expect(m['startTime'], '07:30');
    final back = HabitForm.from(m);
    expect(back.createdAt, '2026-09-28');
    expect(back.startTime, '07:30');
    expect(habitAppliesOnISO(m, '2026-09-27'), isFalse);
    expect(habitAppliesOnISO(m, '2026-09-28'), isTrue);
    expect(habitAppliesOnISO(m, '2026-10-01'), isTrue);
  });
  test('ساعتِ نامعتبر نادیده گرفته می‌شود', () {
    expect(HabitForm.from({'name': 'x', 'createdAt': '2026-10-01', 'startTime': 'abc'}).startTime, '');
  });
}

// ---- زنجیره‌ی عادتی که با شروعِ گذشته ثبت شده ----
// (در همان فایل نگه داشته می‌شود تا کنارِ تستِ تاریخِ شروع باشد)
void streakTests() {
  test('شروع ۴ روز پیش: زنجیره از روزِ شروع حساب می‌شود (نه ۰)', () {
    final dir = Directory.systemTemp.createTempSync('rp_st');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus());
    final start = isoAddDays(a.todayISO, -4);
    final id = a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش'..createdAt = start)!;
    final h = (store.state['habits'] as List).single as Map;
    expect(h['assumedTo'], isoAddDays(a.todayISO, -1));
    expect(computeHabitStreak(store.state, h, a.today), 4);
    a.setBinary(a.todayISO, id, 'success');
    expect(computeHabitStreak(store.state, h, a.today), 5);
  });
  test('«نشد» در روزِ فرضی، زنجیره را می‌شکند؛ شروعِ امروز = فرضی ندارد', () {
    final dir = Directory.systemTemp.createTempSync('rp_st2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus());
    final id = a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش'..createdAt = isoAddDays(a.todayISO, -4))!;
    final h = (store.state['habits'] as List).single as Map;
    a.setBinary(isoAddDays(a.todayISO, -2), id, 'fail');
    expect(computeHabitStreak(store.state, h, a.today), 1); // فقط دیروز
    final id2 = a.saveHabit(HabitForm(a.todayISO)..name = 'تازه')!;
    final h2 = (store.state['habits'] as List).cast<Map>().firstWhere((x) => x['id'] == id2);
    expect(h2.containsKey('assumedTo'), isFalse);
    expect(computeHabitStreak(store.state, h2, a.today), 0);
  });
}
