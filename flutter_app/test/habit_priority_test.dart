// اولویتِ سه‌سطحیِ عادت (طلایی/نقره‌ای/برنزی) و جابه‌جاییِ ترتیبِ عادت‌ها با کشیدن.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/ui/priority_dot.dart';

import 'progress_ui_test.dart';

void main() {
  test('نگاشتِ مقدارهای قدیمی به سه سطح', () {
    expect(habitPriorityOf('gold'), HabitPriority.gold);
    expect(habitPriorityOf('red'), HabitPriority.gold);
    expect(habitPriorityOf('yellow'), HabitPriority.silver);
    expect(habitPriorityOf(null), HabitPriority.silver);
    expect(habitPriorityOf('green'), HabitPriority.bronze);
    expect(habitPriorityOf('bronze'), HabitPriority.bronze);
    expect(HabitForm.from({'name': 'x', 'createdAt': '2026-01-01', 'priority': 'red'}).priority, 'gold');
    expect(HabitForm('2026-01-01').priority, 'silver');
  });

  testWidgets('کارتِ عادت نقطه‌ی اولویت دارد؛ فرم سه گزینه و ذخیره‌ی انتخاب', (tester) async {
    final (store, a, _) = await boot(tester, view: AppView.habits, prep: (s, a) {
      a.saveHabit(HabitForm(a.todayISO)..name = 'الف'..priority = 'gold');
      a.saveHabit(HabitForm(a.todayISO)..name = 'ب'..priority = 'bronze');
    });
    expect(find.byKey(const ValueKey('prio-gold')), findsOneWidget);
    expect(find.byKey(const ValueKey('prio-bronze')), findsOneWidget);
    expect(find.byKey(const ValueKey('habit-list')), findsOneWidget);
    expect((store.state['habits'] as List).map((h) => (h as Map)['priority']).toList(), ['gold', 'bronze']);
    await drain(tester);
  });

  testWidgets('کشیدن: ترتیبِ عادت‌ها عوض و ذخیره می‌شود', (tester) async {
    final (store, a, _) = await boot(tester, view: AppView.habits, prep: (s, a) {
      for (final n in ['الف', 'ب', 'ج']) {
        a.saveHabit(HabitForm(a.todayISO)..name = n);
      }
    });
    List<String> names() => [for (final h in store.state['habits'] as List) '${(h as Map)['name']}'];
    expect(names(), ['الف', 'ب', 'ج']);
    // با دستگیره‌ی عادتِ اول به پایین بکشیم
    final id = ((store.state['habits'] as List).first as Map)['id'];
    final grip = find.byKey(ValueKey('drag-$id'));
    expect(grip, findsOneWidget);
    await tester.timedDrag(grip, const Offset(0, 330), const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(names().first, isNot('الف'));
    expect(names().toSet(), {'الف', 'ب', 'ج'});
    // منطقِ خالص
    expect(a.reorderHabit(0, 2), isTrue);
    expect(a.reorderHabit(1, 1), isFalse);
    await drain(tester);
  });
}
