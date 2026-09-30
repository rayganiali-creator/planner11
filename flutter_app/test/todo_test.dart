import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/notifier.dart';
import 'package:routine_planner/data/todo_ops.dart';

class _Rec implements Notifier {
  @override
  Future<void> resyncAll(dynamic state, DateTime now) async {}
  final calls = <String>[];
  @override
  Future<void> scheduleOnce(String id, String title, String body, int atMs) async => calls.add('sched $id $body');
  @override
  Future<void> cancel(String id) async => calls.add('cancel $id');
}

void main() {
  test('تکرار و زمان بعدی', () {
    // جمعه ۲۰۲۶-۰۹-۱۱ ساعت ۱۰ — شاخص فارسیِ جمعه = ۶
    final now = DateTime(2026, 9, 11, 10, 0);
    final due = DateTime(2026, 1, 1, 8, 30).millisecondsSinceEpoch;
    expect(computeNextTodoOccurrence({'dueAt': due, 'repeatMode': 'daily'}, now), DateTime(2026, 9, 12, 8, 30).millisecondsSinceEpoch);
    expect(computeNextTodoOccurrence({'dueAt': due, 'repeatMode': 'none'}, now), isNull); // گذشته
    expect(computeNextTodoOccurrence({'dueAt': now.millisecondsSinceEpoch + 5000, 'repeatMode': 'none'}, now), now.millisecondsSinceEpoch + 5000);
    // فقط دوشنبه (شاخص فارسی ۲: شنبه=۰) → دوشنبه ۲۰۲۶-۰۹-۱۴
    expect(computeNextTodoOccurrence({'dueAt': due, 'repeatMode': 'custom', 'repeatDays': [2]}, now), DateTime(2026, 9, 14, 8, 30).millisecondsSinceEpoch);
    expect(todoAppliesOn({'repeatMode': 'custom', 'repeatDays': [6]}, now), isTrue);
    expect(todoAppliesOn({'repeatMode': 'custom', 'repeatDays': [3]}, now), isFalse);
    expect(computeNextTodoOccurrence({'dueAt': null, 'repeatMode': 'daily'}, now), isNull);
  });

  test('افزودن/ریستِ روزانه/ویرایش/حذف با اعلان', () async {
    final dir = Directory.systemTemp.createTempSync('rp_t');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus());
    final n = _Rec();
    expect(a.addTodo('  ', notifier: n), isNull);
    final t = a.addTodo('  خرید ', dueAt: DateTime.now().millisecondsSinceEpoch + 3600000, repeatMode: 'daily', notifier: n)!;
    expect(t['title'], 'خرید');
    a.toggleTodo(t['id'], notifier: n);
    expect(t['done'], isTrue);
    a.resetRepeatingTodosIfNeeded();
    expect(t['done'], isFalse); // تکراری: امروز برای بار اول ریست می‌شود
    expect(t['lastActiveResetDate'], a.todayISO);
    a.toggleTodo(t['id'], notifier: n);
    a.resetRepeatingTodosIfNeeded();
    expect(t['done'], isTrue); // همان روز دوباره ریست نمی‌شود
    // رایگان: custom رد می‌شود
    expect(a.saveTodoEdit(t['id'], title: 'x', repeatMode: 'custom', repeatDays: [1], subs: [], notifier: n), isTrue);
    expect(t['repeatMode'], 'none'); // قبلاً custom نبود → none (مثل JS)
    expect(a.saveTodoEdit(t['id'], title: ' ', repeatMode: 'none', repeatDays: [], subs: []), isFalse);
    a.deleteTodo(t['id'], notifier: n);
    expect(store.state['todos'], isEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(n.calls.where((c) => c.startsWith('sched')).length, greaterThanOrEqualTo(1));
    expect(n.calls.any((c) => c == 'cancel todo-${t['id']}'), isTrue);
  });

  testWidgets('صفحه‌ی کارها: افزودن، انجام، و شمارنده', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_t2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    final nav = NavController()..go(AppView.todo);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField).first, 'کار آزمایشی');
    await tester.tap(find.text('افزودن'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('کار آزمایشی'), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.circle));
    await tester.pump(const Duration(milliseconds: 300));
    expect((store.state['todos'] as List).first['done'], isTrue);
    await tester.pump(const Duration(seconds: 5)); // پایانِ تایمرِ toast
    await tester.pumpWidget(const SizedBox());
  });
}
