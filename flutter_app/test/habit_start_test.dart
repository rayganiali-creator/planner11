import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/habits.dart';
import 'package:routine_planner/data/habit_ops.dart';

void main() {
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
