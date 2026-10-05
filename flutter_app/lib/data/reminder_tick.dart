// یادآورهای درون‌برنامه‌ای وقتی برنامه باز است (rpReminderTick در HTML: checkDueTodos، checkHabitReminders، rpItemRemindersTick)
import '../core/calendar.dart';
import '../core/habits.dart';
import 'actions.dart';
import 'journal_ops.dart';
import 'notifier.dart';

String _pad2(int n) => n.toString().padLeft(2, '0');

extension ReminderTick on AppActions {
  /// هر ۱۵ ثانیه. اعلان سیستمی را `Notifier` جدا ثبت کرده؛ اینجا فقط توست/علامت‌گذاری است.
  void reminderTick({Notifier? notifier}) {
    final now = clock();
    final nowMs = now.millisecondsSinceEpoch;
    final s = store.state;
    final fa = s['lang'] != 'en';
    var changed = false;

    for (final t in (s['todos'] as List? ?? const []).whereType<Map>()) {
      if (t['done'] == true || t['notified'] == true || t['dueAt'] is! num) continue;
      if ((t['dueAt'] as num) <= nowMs) {
        t['notified'] = true;
        changed = true;
        toasts.show('⏰ ${t['title']}', ms: 4000);
      }
    }

    final hm = '${_pad2(now.hour)}:${_pad2(now.minute)}';
    final iso = dateToISO(startOfDay(now));
    for (final h in (s['habits'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
      if (h['reminderEnabled'] != true || h['reminderTime'] == null || h['reminderTime'] == '') continue;
      if (h['lastReminderDate'] == iso || h['reminderTime'] != hm) continue;
      h['lastReminderDate'] = iso;
      changed = true;
      if (!habitAppliesOnISO(h, iso)) continue;
      if (habitSuccessOnISO(s, h, iso) == true) continue;
      toasts.show('⏰ ${fa ? 'وقتشه: ' : 'Time for: '}${h['name']}', ms: 4000);
    }

    void fire(String listKey, String kind, String icon, String Function(Map) textOf) {
      for (final it in (s[listKey] as List? ?? const []).whereType<Map>()) {
        final at = it['remindAt'];
        if (at is! num || at > nowMs || it['remindFired'] == true) continue;
        final txt = textOf(it);
        toasts.show('$icon ${fa ? 'یادآوری: ' : 'Reminder: '}${txt.length > 40 ? txt.substring(0, 40) : txt}', ms: 6000);
        final next = nextRepeat(at.toInt(), it['remindRepeat'] as String?, nowMs);
        if (next != null) {
          it['remindAt'] = next;
          it.remove('remindFired');
          notifier?.scheduleOnce('$kind-${it['id']}', icon, textOf(it), next);
        } else {
          it['remindFired'] = true;
        }
        changed = true;
      }
    }

    fire('journal', 'journal', '📓', (j) => '${j['text'] ?? ''}');
    fire('books', 'book', '📚', (b) => '${b['title'] ?? ''}');
    if (changed) store.save();
  }
}
