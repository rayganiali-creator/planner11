// برنامه‌ریز یادآوری‌ها: «چه اعلان‌هایی، با چه شناسه و زمانی، ثبت/لغو شوند».
// پورت منطقِ nativeScheduleOnce / nativeScheduleDailyHabit / nativeScheduleChallengeNotifications /
// nativeResyncAllReminders از www/index.html. خودِ ثبت در اندروید (flutter_local_notifications)
// در لایه‌ی platform است؛ این‌جا فقط فهرستِ عملیات تولید می‌شود تا با JS مقایسه‌پذیر باشد.
import 'calendar.dart';
import 'doc.dart';
import 'habits.dart';
import 'js_compat.dart';

class ReminderOp {
  final String kind; // 'cancel' | 'schedule'
  final int id;
  final String? title, body;
  final num? atMs;
  const ReminderOp.cancel(this.id)
      : kind = 'cancel',
        title = null,
        body = null,
        atMs = null;
  const ReminderOp.schedule(this.id, String this.title, String this.body, num this.atMs) : kind = 'schedule';
  List<Object?> toJson() => kind == 'cancel' ? ['cancel', id] : ['schedule', id, title, body, atMs];
}

/// شناسه‌ی عددیِ ۳۱ بیتی از روی رشته (هش Java-style در حسابِ int32 جاوااسکریپت).
int rpNumericId(String str) {
  int h = 0;
  for (final c in str.codeUnits) {
    h = ((h << 5).toSigned(32) - h + c).toSigned(32);
  }
  final r = h.abs() % 2147483647;
  return r == 0 ? 1 : r;
}

/// یک‌بارِ دقیق: همیشه اول لغو، و فقط اگر زمان در آینده باشد ثبت.
List<ReminderOp> planScheduleOnce(String idStr, String title, String body, num whenMs, num nowMs) {
  final id = rpNumericId(idStr);
  return [ReminderOp.cancel(id), if (whenMs > nowMs) ReminderOp.schedule(id, title, body, whenMs)];
}

List<ReminderOp> planCancel(String idStr) => [ReminderOp.cancel(rpNumericId(idStr))];

/// امروز اگر ساعت نگذشته، وگرنه فردا.
int rpNextHabitOccurrence(int hh, int mm, DateTime now) {
  var next = DateTime(now.year, now.month, now.day, hh, mm);
  if (!next.isAfter(now)) next = DateTime(next.year, next.month, next.day + 1, next.hour, next.minute);
  return next.millisecondsSinceEpoch;
}

/// ۱۴ نوبتِ بعدیِ یادآوریِ روزانه‌ی عادت، فقط در روزهایی که خودِ عادت فعال است.
/// (رفتارِ فعلیِ JS عیناً: فاصله‌ها ۲۴ ساعت خام‌اند، نه «همان ساعتِ روز بعد».)
List<ReminderOp> planDailyHabit(Doc state, String habitId, String title, String body, int hh, int mm, DateTime now) {
  Map? h;
  for (final x in (state['habits'] is List ? state['habits'] as List : const [])) {
    if (x is Map && x['id'] == habitId) {
      h = x;
      break;
    }
  }
  final first = rpNextHabitOccurrence(hh, mm, now);
  final out = <ReminderOp>[];
  for (int i = 0; i < 14; i++) {
    final at = first + i * 86400000;
    final iso = dateToISO(DateTime.fromMillisecondsSinceEpoch(at));
    final applies = h == null || habitAppliesOnISO(h, iso);
    out.addAll(planScheduleOnce('habit-$habitId-d$i', title, body, applies ? at : 0, now.millisecondsSinceEpoch));
  }
  return out;
}

const int challengeMaxReminderSlots = 60;

List<ReminderOp> planChallenge(Doc state, Map ch, DateTime now) {
  final kind = ch['kind'];
  if (!(kind == 'timed' || kind == 'both')) return [];
  if (!jsTruthy(ch['deadlineAt'])) return [];
  final fa = state['lang'] == 'fa';
  final name = jsString(ch['name']);
  final id = jsString(ch['id']);
  final nowMs = now.millisecondsSinceEpoch;
  final deadline = jsToNumber(ch['deadlineAt']);
  final out = <ReminderOp>[
    ...planScheduleOnce(
      'challenge-deadline-$id',
      fa ? '⏰ مهلت چالش تموم شد' : '⏰ Challenge deadline reached',
      fa ? 'زمان چالش «$name» تموم شد! انجامش دادی؟' : 'Time is up for "$name"! Did you do it?',
      deadline,
      nowMs,
    )
  ];
  if (jsTruthy(ch['reminderIntervalHours'])) {
    final intervalMs = jsToNumber(ch['reminderIntervalHours']) * 3600000;
    num t = nowMs + intervalMs;
    int idx = 0;
    while (t < deadline && idx < challengeMaxReminderSlots) {
      out.addAll(planScheduleOnce(
        'challenge-reminder-$id-r$idx',
        fa ? '🔥 یادآوری چالش' : '🔥 Challenge reminder',
        fa ? 'یادت نره: «$name»' : "Don't forget: $name",
        t,
        nowMs,
      ));
      t += intervalMs;
      idx++;
    }
  }
  return out;
}

List<ReminderOp> planCancelChallenge(String chId) =>
    [...planCancel('challenge-deadline-$chId'), for (int i = 0; i < challengeMaxReminderSlots; i++) ...planCancel('challenge-reminder-$chId-r$i')];

bool todoAppliesToday(Map t, DateTime now) {
  final m = t['repeatMode'];
  if (!jsTruthy(m) || m == 'none') return true;
  if (m == 'daily') return true;
  if (m == 'custom') {
    final rd = t['repeatDays'];
    return rd is List && rd.contains(jsWeekdayToPersianIndex(jsWeekday(now)));
  }
  return true;
}

/// برای کارِ بدونِ تکرار: همان dueAt اگر در آینده باشد؛ برای تکرارشونده: نزدیک‌ترین زمانِ آینده‌ی مجاز.
num? computeNextTodoOccurrence(Map t, DateTime now) {
  if (!jsTruthy(t['dueAt'])) return null;
  final due = jsToNumber(t['dueAt']);
  final nowMs = now.millisecondsSinceEpoch;
  final m = t['repeatMode'];
  if (!jsTruthy(m) || m == 'none') return due > nowMs ? due : null;
  final d = DateTime.fromMillisecondsSinceEpoch(due.toInt());
  for (int i = 0; i < 8; i++) {
    final cand = DateTime(now.year, now.month, now.day + i, d.hour, d.minute);
    if (cand.millisecondsSinceEpoch <= nowMs) continue;
    if (m == 'daily') return cand.millisecondsSinceEpoch;
    if (m == 'custom') {
      final rd = t['repeatDays'];
      if (rd is List && rd.contains(jsWeekdayToPersianIndex(jsWeekday(cand)))) return cand.millisecondsSinceEpoch;
    }
  }
  return null;
}

String _slice(String s, int n) => s.length <= n ? s : s.substring(0, n);

/// معادلِ nativeResyncAllReminders: هر بار برنامه باز شود «زمانِ بعدی» همه‌ی یادآوری‌ها تازه ثبت می‌شود.
List<ReminderOp> planResyncAll(Doc state, DateTime now) {
  final fa = state['lang'] == 'fa';
  final nowMs = now.millisecondsSinceEpoch;
  final out = <ReminderOp>[];
  List list(String k) => state[k] is List ? state[k] as List : const [];
  for (final t in list('todos')) {
    if (t is! Map) continue;
    final next = computeNextTodoOccurrence(t, now);
    if (!jsTruthy(t['done']) && next != null) {
      out.addAll(planScheduleOnce('todo-${jsString(t['id'])}', fa ? '⏰ وقت انجام کار رسید' : '⏰ Task is due', jsString(t['title']), next, nowMs));
    }
  }
  for (final h in list('habits')) {
    if (h is! Map) continue;
    if (jsTruthy(h['reminderEnabled']) && jsTruthy(h['reminderTime'])) {
      final parts = jsString(h['reminderTime']).split(':');
      // رفتارِ فعلیِ JS: `parseInt(...) || 8` — ساعتِ «۰۰» هم به ۸ تبدیل می‌شود (ثبت شده؛ اصلاح نشده)
      final hh = jsParseInt10(parts[0]) ?? 0;
      final mm = jsParseInt10(parts.length > 1 ? parts[1] : null) ?? 0;
      out.addAll(planDailyHabit(state, jsString(h['id']), fa ? '⏰ یادآوری عادت' : '⏰ Habit Reminder',
          (fa ? 'وقتشه: ' : 'Time for: ') + jsString(h['name']), hh == 0 ? 8 : hh, mm, now));
    }
  }
  for (final j in list('journal')) {
    if (j is! Map) continue;
    final r = j['remindAt'];
    if (jsTruthy(r) && jsToNumber(r) > nowMs) {
      out.addAll(planScheduleOnce('journal-${jsString(j['id'])}', fa ? '📓 یادآوری یادداشت' : '📓 Journal reminder',
          _slice(jsString(jsOr(j['text'], '')), 80), jsToNumber(r), nowMs));
    }
  }
  for (final b in list('books')) {
    if (b is! Map) continue;
    final r = b['remindAt'];
    if (jsTruthy(r) && jsToNumber(r) > nowMs) {
      out.addAll(planScheduleOnce('book-${jsString(b['id'])}', fa ? '📚 یادآوری کتاب' : '📚 Book reminder', jsString(jsOr(b['title'], '')), jsToNumber(r), nowMs));
    }
  }
  for (final c in list('challenges')) {
    if (c is! Map) continue;
    if (c['status'] == 'active' && (c['kind'] == 'timed' || c['kind'] == 'both') && jsToNumber(c['deadlineAt']) > nowMs) {
      out.addAll(planChallenge(state, c, now));
    }
  }
  return out;
}
