// یادداشت‌های ژورنال + یادآورِ یادداشت/کتاب (پرو). قواعد همان نسخه‌ی HTML.
import 'dart:math';

import 'actions.dart';
import 'notifier.dart';

String jrnlUid(int nowMs) => 'j_${nowMs.toRadixString(36)}${List.generate(5, (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[Random().nextInt(36)]).join()}';

/// نوبتِ بعدیِ یادآورِ تکرارشونده (daily/weekly/monthly)؛ اگر برنامه مدتی بسته بوده تا اولین نوبتِ آینده جلو می‌رود.
int? nextRepeat(int at, String? mode, int nowMs) {
  DateTime step(DateTime d) => switch (mode) {
        'daily' => DateTime(d.year, d.month, d.day + 1, d.hour, d.minute, d.second, d.millisecond),
        'weekly' => DateTime(d.year, d.month, d.day + 7, d.hour, d.minute, d.second, d.millisecond),
        _ => DateTime(d.year, d.month + 1, d.day, d.hour, d.minute, d.second, d.millisecond),
      };
  if (mode != 'daily' && mode != 'weekly' && mode != 'monthly') return null;
  var d = step(DateTime.fromMillisecondsSinceEpoch(at));
  while (d.millisecondsSinceEpoch <= nowMs) {
    d = step(d);
  }
  return d.millisecondsSinceEpoch;
}

extension JournalOps on AppActions {
  List<Map> get _journal {
    final s = store.state;
    if (s['journal'] is! List) s['journal'] = [];
    return (s['journal'] as List).cast<Map>();
  }

  bool addJournal(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    _journal.add({'id': jrnlUid(now), 'text': t, 'createdAt': now});
    store.save();
    return true;
  }

  bool editJournal(String id, String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    final e = _journal.where((x) => x['id'] == id).firstOrNull;
    if (e == null) return true;
    e['text'] = t;
    e['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    store.save();
    return true;
  }

  void deleteJournal(String id, {Notifier? notifier}) {
    notifier?.cancel('journal-$id');
    store.state['journal'] = _journal.where((e) => e['id'] != id).toList();
    store.save();
  }

  Map? _remindItem(String kind, String id) {
    final l = store.state[kind == 'journal' ? 'journal' : 'books'];
    return l is List ? l.whereType<Map>().where((x) => x['id'] == id).firstOrNull : null;
  }

  /// false اگر زمان گذشته باشد یا پرو نباشد
  bool setItemReminder(String kind, String id, int at, String repeat, {Notifier? notifier}) {
    if (!isProUser || at < DateTime.now().millisecondsSinceEpoch) return false;
    final it = _remindItem(kind, id);
    if (it == null) return false;
    it['remindAt'] = at;
    it['remindRepeat'] = repeat;
    it.remove('remindFired');
    store.save();
    final fa = store.state['lang'] != 'en';
    final title = kind == 'journal' ? (fa ? '📓 یادآوری یادداشت' : '📓 Journal reminder') : (fa ? '📚 یادآوری کتاب' : '📚 Book reminder');
    final body = kind == 'journal' ? ('${it['text'] ?? ''}'.length > 80 ? '${it['text']}'.substring(0, 80) : '${it['text'] ?? ''}') : '${it['title'] ?? ''}';
    notifier?.scheduleOnce('$kind-$id', title, body, at);
    return true;
  }

  void clearItemReminder(String kind, String id, {Notifier? notifier}) {
    if (!isProUser) return;
    final it = _remindItem(kind, id);
    if (it == null) return;
    it.remove('remindAt');
    it.remove('remindRepeat');
    it.remove('remindFired');
    store.save();
    notifier?.cancel('$kind-$id');
  }

  bool get isProUser => store.state['isPremium'] == true;
}
