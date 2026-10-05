import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/reminder_tick.dart';

void main() {
  test('یادآور درون‌برنامه‌ای: کار سررسیده، عادت سرِ ساعت، یادداشت تکرارشونده', () {
    final dir = Directory.systemTemp.createTempSync('rp_tick');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final now = DateTime(2025, 3, 10, 8, 30, 5);
    final nowMs = now.millisecondsSinceEpoch;
    store.state['lang'] = 'en';
    store.state['todos'] = [
      {'id': 't1', 'title': 'Pay', 'dueAt': nowMs - 1000},
      {'id': 't2', 'title': 'Later', 'dueAt': nowMs + 100000},
    ];
    store.state['habits'] = [
      {'id': 'h1', 'name': 'Run', 'type': 'binary', 'reminderEnabled': true, 'reminderTime': '08:30', 'start': '2025-01-01', 'permanent': true},
    ];
    store.state['journal'] = [
      {'id': 'j1', 'text': 'note', 'remindAt': nowMs - 5000, 'remindRepeat': 'daily'},
      {'id': 'j2', 'text': 'once', 'remindAt': nowMs - 5000},
    ];
    final toasts = ToastBus();
    final a = AppActions(store, toasts, clock: () => now);
    a.reminderTick();
    expect((store.state['todos'] as List)[0]['notified'], true);
    expect((store.state['todos'] as List)[1]['notified'], isNull);
    expect((store.state['habits'] as List)[0]['lastReminderDate'], '2025-03-10');
    final j = store.state['journal'] as List;
    expect(j[0]['remindAt'], greaterThan(nowMs));
    expect(j[1]['remindFired'], true);
    // بار دوم چیزی تکرار نمی‌شود
    final before = [j[0]['remindAt'], j[1]['remindFired']];
    a.reminderTick();
    expect([j[0]['remindAt'], j[1]['remindFired']], before);
  });
}
