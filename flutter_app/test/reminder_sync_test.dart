import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/doc.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/data/local_notifier.dart';
import 'package:routine_planner/data/notifier.dart';
import 'package:routine_planner/data/todo_ops.dart';

class _Rec implements Notifier {
  int resyncs = 0;
  @override
  Future<void> resyncAll(Doc state, DateTime now) async => resyncs++;
  @override
  Future<void> scheduleOnce(String id, String title, String body, int atMs) async {}
  @override
  Future<void> cancel(String id) async {}
}

void main() {
  test('همگام‌سازی فقط وقتی فهرستِ یادآورها عوض شود، تأخیری و یک‌بار', () async {
    final dir = Directory.systemTemp.createTempSync('rp_rs');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus());
    final n = _Rec();
    final sync = ReminderSync(store, n);
    addTearDown(sync.dispose);
    // تغییرِ بی‌ربط (امتیاز) ← همگام‌سازی نه
    (store.state['scores'] as Map)['coins'] = 5;
    store.save();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(n.resyncs, 0);
    // عادتِ یادآوردار ← یک‌بار (با چند ذخیره‌ی پشت‌سرهم)
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش'..reminderEnabled = true..reminderTime = '07:30');
    a.addTodo('کار');
    store.save();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(n.resyncs, 1);
    // همان وضعیت، ذخیره‌ی دوباره ← نه
    store.save();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(n.resyncs, 1);
    // تغییرِ ساعتِ یادآوری ← دوباره
    (store.state['habits'] as List).first['reminderTime'] = '08:00';
    store.save();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(n.resyncs, 2);
  });
}
