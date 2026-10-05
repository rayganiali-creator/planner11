// لیست کارها: همان قواعدِ نسخه‌ی HTML (تکرار، ریستِ روزانه، زمانِ بعدیِ یادآوری، زیرتسک).
import 'dart:math';

import '../core/calendar.dart';
import 'actions.dart';
import 'notifier.dart';

const int freeSubtaskLimit = 3;

String _rand(int n) => List.generate(n, (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[Random().nextInt(36)]).join();
String todoUid(int nowMs) => 'td_${nowMs.toRadixString(36)}${_rand(5)}';
String subUid(int nowMs) => 's${nowMs.toRadixString(36)}${_rand(3)}';

bool todoAppliesOn(Map t, DateTime d) {
  final m = t['repeatMode'];
  if (m == null || m == 'none' || m == 'daily') return true;
  if (m == 'custom') {
    final idx = jsWeekdayToPersianIndex(jsWeekday(d));
    final days = t['repeatDays'];
    return days is List && days.contains(idx);
  }
  return true;
}

/// زمانِ بعدیِ یادآوری؛ null اگر نباشد
int? computeNextTodoOccurrence(Map t, DateTime now) {
  final due = t['dueAt'];
  if (due is! num || due == 0) return null;
  final nowMs = now.millisecondsSinceEpoch;
  final m = t['repeatMode'];
  if (m == null || m == 'none') return due > nowMs ? due.toInt() : null;
  final dd = DateTime.fromMillisecondsSinceEpoch(due.toInt());
  for (int i = 0; i < 8; i++) {
    final cand = DateTime(now.year, now.month, now.day + i, dd.hour, dd.minute);
    if (cand.millisecondsSinceEpoch <= nowMs) continue;
    if (m == 'daily') return cand.millisecondsSinceEpoch;
    if (m == 'custom') {
      final idx = jsWeekdayToPersianIndex(jsWeekday(cand));
      final days = t['repeatDays'];
      if (days is List && days.contains(idx)) return cand.millisecondsSinceEpoch;
    }
  }
  return null;
}

extension TodoOps on AppActions {
  List<Map> get _todos {
    final s = store.state;
    if (s['todos'] is! List) s['todos'] = [];
    return (s['todos'] as List).cast<Map>();
  }

  bool get isPro => store.state['isPremium'] == true;

  String _dueTitle() => store.state['lang'] == 'en' ? '⏰ Task is due' : '⏰ وقت انجام کار رسید';

  Future<void> _schedule(Map t, Notifier n) async {
    final id = 'todo-${t['id']}';
    // وضعیت را همین لحظه می‌خوانیم، نه بعد از await (کاربر ممکن است بین این دو، کار را انجام بدهد)
    final next = t['done'] != true ? computeNextTodoOccurrence(t, today) : null;
    final title = _dueTitle(), body = '${t['title']}';
    await n.cancel(id);
    if (next != null) await n.scheduleOnce(id, title, body, next);
  }

  /// برمی‌گرداند کارِ تازه یا null (عنوان خالی)
  Map? addTodo(String title, {int? dueAt, String repeatMode = 'none', List<int> repeatDays = const [], Notifier? notifier}) {
    if (title.trim().isEmpty) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final t = <String, dynamic>{
      'id': todoUid(now),
      'title': title.trim(),
      'done': false,
      'createdAt': now,
      'dueAt': dueAt,
      'notified': false,
      'repeatMode': repeatMode,
      'repeatDays': repeatMode == 'custom' ? [...repeatDays] : <int>[],
      'lastActiveResetDate': null,
    };
    _todos.add(t);
    store.save();
    if (dueAt != null && notifier != null) _schedule(t, notifier);
    return t;
  }

  void toggleTodo(String id, {Notifier? notifier}) {
    final t = _todos.where((x) => x['id'] == id).firstOrNull;
    if (t == null) return;
    t['done'] = !(t['done'] == true);
    final log = _todoLog;
    if (t['done'] == true) {
      notifier?.cancel('todo-$id');
      // رویدادِ انجام: منبعِ XP. شناسه‌ی یکتا؛ Undo همین ورودی را برمی‌دارد (بازگرداندنِ XP)
      final now = clock().millisecondsSinceEpoch;
      log.add({'id': 'tl_${now.toRadixString(36)}${_rand(4)}', 'todoId': id, 'title': t['title'], 'at': now, 'createdAt': t['createdAt'], if (t['priority'] == 'high') 'priority': 'high'});
      if (log.length > 5000) log.removeRange(0, log.length - 5000);
    } else {
      final i = log.lastIndexWhere((e) => e is Map && e['todoId'] == id);
      if (i >= 0) log.removeAt(i);
    }
    store.save();
    afterChange();
  }

  List get _todoLog {
    final s = store.state;
    if (s['todoLog'] is! List) s['todoLog'] = <dynamic>[];
    return s['todoLog'] as List;
  }

  void toggleSubtask(String tid, String sid) {
    final t = _todos.where((x) => x['id'] == tid).firstOrNull;
    final s = (t?['subtasks'] as List?)?.cast<Map>().where((x) => x['id'] == sid).firstOrNull;
    if (s == null) return;
    s['done'] = !(s['done'] == true);
    store.save();
  }

  void deleteTodo(String id, {Notifier? notifier}) {
    notifier?.cancel('todo-$id');
    store.state['todos'] = _todos.where((t) => t['id'] != id).toList();
    store.save();
  }

  void clearDoneTodos() {
    store.state['todos'] = _todos.where((t) => t['done'] != true).toList();
    store.save();
  }

  /// ویرایش؛ false اگر عنوان خالی باشد
  bool saveTodoEdit(String id, {required String title, int? dueAt, required String repeatMode, required List<int> repeatDays, required List<Map> subs, bool? high, Notifier? notifier}) {
    final t = _todos.where((x) => x['id'] == id).firstOrNull;
    if (t == null) return false;
    final nt = title.trim();
    if (nt.isEmpty) return false;
    t['title'] = nt;
    t['dueAt'] = dueAt;
    t['repeatMode'] = (repeatMode == 'custom' && !isPro) ? (t['repeatMode'] == 'custom' ? 'custom' : 'none') : repeatMode;
    if (high != null) {
      if (high) {
        t['priority'] = 'high';
      } else {
        t.remove('priority');
      }
    }
    t['subtasks'] = subs;
    t['repeatDays'] = repeatMode == 'custom' ? [...repeatDays] : <int>[];
    store.save();
    if (notifier != null) _schedule(t, notifier);
    return true;
  }

  /// هر روز برای کارهای تکرارشونده: «انجام‌شده»ی دیروز پاک می‌شود
  void resetRepeatingTodosIfNeeded() {
    final iso = todayISO;
    bool changed = false;
    for (final t in _todos) {
      final m = t['repeatMode'];
      if (m == null || m == 'none') continue;
      if (t['lastActiveResetDate'] != iso) {
        if (t['done'] == true) t['done'] = false;
        t['lastActiveResetDate'] = iso;
        changed = true;
      }
    }
    if (changed) store.save();
  }
}

