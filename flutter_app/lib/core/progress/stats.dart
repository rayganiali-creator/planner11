// آمارِ واقعی از داده‌ی برنامه؛ هر آمار یک فرمولِ مشخص دارد و بدونِ داده‌ی کافی null برمی‌گرداند (UI: «داده کافی برای محاسبه وجود ندارد»).
// همه‌ی فرمول‌ها همین‌جاست (statFormulas) و در رابط هم نمایش داده می‌شود.
import 'dart:math' as math;

import '../analytics.dart';
import '../calendar.dart';
import '../doc.dart';
import '../habits.dart';
import '../js_compat.dart';
import 'config.dart';

const Map<String, (String, String)> statFormulas = {
  'consistency': ('عادت‌های انجام‌شده ÷ کلِ عادت‌های برنامه‌ریزی‌شده × ۱۰۰ (۳۰ روزِ اخیر)', 'Completed planned habit occurrences ÷ total planned × 100 (last 30 days)'),
  'productivity': ('کارهای معتبرِ انجام‌شده ÷ کارهای برنامه‌ریزی‌شده × ۱۰۰ (۳۰ روزِ اخیر)', 'Completed valid tasks ÷ planned tasks × 100 (last 30 days)'),
  'focus': ('۵۰٪ جلسه‌های تمرکز (نسبت به ۲۰ جلسه) + ۵۰٪ دقیقه‌های تمرکز (نسبت به ۵۰۰ دقیقه) در ۳۰ روز', '50% focus sessions (vs 20) + 50% focus minutes (vs 500) over 30 days'),
  'reading': ('۶۰٪ روزهای مطالعه (نسبت به ۱۲ روز) + ۴۰٪ کتابِ تمام‌شده (حداقل ۱) در ۳۰ روز', '60% reading days (vs 12) + 40% completed books (min 1) over 30 days'),
  'discipline': ('۵۰٪ استمرار + ۳۰٪ استریک (نسبت به ۳۰ روز) + ۲۰٪ پایداریِ تکمیل (روزهای حفظ‌شده ÷ روزهای برنامه‌ریزی‌شده)', '50% consistency + 30% streak (vs 30 days) + 20% completion reliability'),
};

// ---------------------------------------------------------------- روزِ «حفظ‌شده» و استریک
/// null = روزِ بدونِ برنامه (خنثی)؛ true = حفظ شد؛ false = حفظ نشد
bool? keptDay(Doc st, String iso, DateTime today) {
  final s = dayStatsAll(st, iso);
  if (s.total == 0) return null;
  return s.success / s.total >= StatConfig.keepThreshold;
}

/// روزهای پیاپیِ حفظ‌شدنِ برنامه تا امروز. امروزِ هنوز ناتمام استریک را نمی‌شکند؛ روزِ بدونِ برنامه خنثی است.
int keptStreak(Doc st, DateTime todayIn) {
  final today = startOfDay(todayIn);
  final first = _firstPlanDate(st);
  if (first == null) return 0;
  int n = 0;
  var d = today;
  int guard = 0;
  while (!d.isBefore(first) && guard++ < 40000) {
    final k = keptDay(st, dateToISO(d), today);
    if (k == true) {
      n++;
    } else if (k == false) {
      if (d == today) {
        d = addDays(d, -1);
        continue;
      }
      break;
    }
    d = addDays(d, -1);
  }
  return n;
}

DateTime? _firstPlanDate(Doc st) {
  String? best;
  for (final h in (st['habits'] is List ? st['habits'] as List : const [])) {
    if (h is Map && h['createdAt'] is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(h['createdAt'])) {
      if (best == null || (h['createdAt'] as String).compareTo(best) < 0) best = h['createdAt'] as String;
    }
  }
  return best == null ? null : isoToDate(best);
}

typedef Runs = ({int bestKept, int bestPerfect});

/// بلندترین دنباله‌ی «حفظ‌شده» و «کاملِ ۱۰۰٪» در کلِ تاریخچه
Runs bestRuns(Doc st, DateTime todayIn) {
  final today = startOfDay(todayIn);
  final first = _firstPlanDate(st);
  if (first == null) return (bestKept: 0, bestPerfect: 0);
  int kept = 0, perfect = 0, bk = 0, bp = 0;
  var d = first;
  while (!d.isAfter(today)) {
    final s = dayStatsAll(st, dateToISO(d));
    if (s.total > 0) {
      final isToday = d == today;
      if (s.success / s.total >= StatConfig.keepThreshold) {
        kept++;
      } else if (!isToday) {
        kept = 0;
      }
      if (s.success == s.total) {
        perfect++;
      } else if (!isToday) {
        perfect = 0;
      }
      bk = math.max(bk, kept);
      bp = math.max(bp, perfect);
    }
    d = addDays(d, 1);
  }
  return (bestKept: bk, bestPerfect: bp);
}

// ---------------------------------------------------------------- آمارها
typedef StatValue = ({int? value, int? previous, int? change, String? note});

StatValue _pack(int? cur, int? prev) => (value: cur, previous: prev, change: (cur != null && prev != null) ? cur - prev : null, note: null);

/// برای هر بازه (offset=0 فعلی، 1 قبلی) روزهایی را برمی‌گرداند
({DateTime from, DateTime to}) windowOf(DateTime todayIn, int days, int offset) {
  final today = startOfDay(todayIn);
  final to = addDays(today, -days * offset);
  return (from: addDays(to, -(days - 1)), to: to);
}

Tally _tallyRange(Doc st, DateTime from, DateTime to, DateTime today) {
  int due = 0, s = 0, f = 0, u = 0;
  var d = from;
  while (!d.isAfter(to)) {
    final t = tallyDay(st, d, today);
    due += t.due;
    s += t.success;
    f += t.fail;
    u += t.unset;
    d = addDays(d, 1);
  }
  return (due: due, success: s, fail: f, unset: u);
}

int? consistencyIn(Doc st, DateTime from, DateTime to, DateTime today) {
  final t = _tallyRange(st, from, to, today);
  if (t.due < StatConfig.minPlannedHabits) return null;
  return jsRound(t.success / t.due * 100);
}

String _day(int ms) => dateToISO(DateTime.fromMillisecondsSinceEpoch(ms));

List<Map> _list(Object? v) => v is List ? [for (final e in v) if (e is Map) e] : <Map>[];

int? productivityIn(Doc st, DateTime from, DateTime to) {
  final f = dateToISO(from), t = dateToISO(to);
  final done = <String>{};
  final planned = <String>{};
  for (final e in _list(st['todoLog'])) {
    if (!isValidTodoLog(e)) continue;
    final iso = _day((e['at'] as num).toInt());
    if (iso.compareTo(f) >= 0 && iso.compareTo(t) <= 0) {
      done.add('${e['todoId']}');
      planned.add('${e['todoId']}');
    }
  }
  for (final td in _list(st['todos'])) {
    if (td['createdAt'] is num) {
      final iso = _day((td['createdAt'] as num).toInt());
      if (iso.compareTo(f) >= 0 && iso.compareTo(t) <= 0 && '${td['title'] ?? ''}'.trim().length >= XpGuards.todoMinTitleLen) planned.add('${td['id']}');
    }
  }
  if (planned.length < StatConfig.minPlannedTasks) return null;
  return jsRound(done.length / planned.length * 100);
}

bool isValidTodoLog(Map e) {
  if (e['at'] is! num) return false;
  if ('${e['title'] ?? ''}'.trim().length < XpGuards.todoMinTitleLen) return false;
  if (e['backfilled'] == true) return true;
  final c = e['createdAt'];
  return c is num && (e['at'] as num) - c >= XpGuards.todoMinAgeMs;
}

bool isValidPomodoro(Map e) => e['at'] is num && e['minutes'] is num && (e['minutes'] as num) >= XpGuards.pomodoroMinMinutes;

({int sessions, int minutes}) _focusIn(Doc st, DateTime from, DateTime to) {
  final f = dateToISO(from), t = dateToISO(to);
  int s = 0, m = 0;
  for (final e in _list((st['pomodoro'] is Map ? (st['pomodoro'] as Map)['log'] : null))) {
    if (!isValidPomodoro(e)) continue;
    final iso = _day((e['at'] as num).toInt());
    if (iso.compareTo(f) >= 0 && iso.compareTo(t) <= 0) {
      s++;
      m += (e['minutes'] as num).toInt();
    }
  }
  return (sessions: s, minutes: m);
}

int? focusIn(Doc st, DateTime from, DateTime to) {
  final x = _focusIn(st, from, to);
  if (x.sessions < StatConfig.minFocusSessions) return null;
  final v = 0.5 * math.min(1, x.sessions / StatConfig.focusTargetSessions) + 0.5 * math.min(1, x.minutes / StatConfig.focusTargetMinutes);
  return jsRound(v * 100);
}

/// روزهای مطالعه‌ی واقعی (صفحه‌ی تازه‌ی ثبت‌شده) به‌صورتِ ISO → صفحات
Map<String, int> readingDays(Doc st) {
  final out = <String, int>{};
  for (final b in _list(st['books'])) {
    var high = 0;
    final hist = _list(b['history'])..sort((a, c) => ((a['date'] as num?) ?? 0).compareTo((c['date'] as num?) ?? 0));
    for (final h in hist) {
      final total = (h['pagesRead'] as num?)?.toInt() ?? 0;
      if (h['date'] is! num) continue;
      if (total > high) {
        final iso = _day((h['date'] as num).toInt());
        out['${b['id']}|$iso'] = (out['${b['id']}|$iso'] ?? 0) + (total - high);
        high = total;
      }
    }
  }
  return out;
}

int? readingIn(Doc st, DateTime from, DateTime to) {
  final f = dateToISO(from), t = dateToISO(to);
  final days = <String>{};
  readingDays(st).forEach((k, _) {
    final iso = k.split('|').last;
    if (iso.compareTo(f) >= 0 && iso.compareTo(t) <= 0) days.add(iso);
  });
  if (days.length < StatConfig.minReadingDays) return null;
  int books = 0;
  for (final b in _list(st['books'])) {
    if (b['completed'] == true && b['completedAt'] is num) {
      final iso = _day((b['completedAt'] as num).toInt());
      if (iso.compareTo(f) >= 0 && iso.compareTo(t) <= 0) books++;
    }
  }
  final v = 0.6 * math.min(1, days.length / StatConfig.readingTargetDays) + 0.4 * math.min(1, books / 1);
  return jsRound(v * 100);
}

/// پایداریِ تکمیل: روزهای حفظ‌شده ÷ روزهای دارای برنامه (در بازه)
int? reliabilityIn(Doc st, DateTime from, DateTime to, DateTime today) {
  int planned = 0, kept = 0;
  var d = from;
  while (!d.isAfter(to)) {
    final t = tallyDay(st, d, today);
    if (t.due > 0) {
      planned++;
      if (t.success / t.due >= StatConfig.keepThreshold) kept++;
    }
    d = addDays(d, 1);
  }
  if (planned < 3) return null;
  return jsRound(kept / planned * 100);
}

int? disciplineIn(Doc st, DateTime from, DateTime to, DateTime today, {int? streakOverride}) {
  final c = consistencyIn(st, from, to, today);
  final r = reliabilityIn(st, from, to, today);
  if (c == null || r == null) return null;
  final sk = streakOverride ?? keptStreak(st, to);
  return jsRound(0.5 * c + 0.3 * (math.min(1, sk / 30) * 100) + 0.2 * r);
}

class UserStats {
  final StatValue consistency, productivity, focus, reading, discipline;
  const UserStats(this.consistency, this.productivity, this.focus, this.reading, this.discipline);
  bool get hasAny => [consistency, productivity, focus, reading, discipline].any((s) => s.value != null);
}

UserStats computeStats(Doc st, DateTime todayIn) {
  final today = startOfDay(todayIn);
  final w0 = windowOf(today, StatConfig.windowDays, 0), w1 = windowOf(today, StatConfig.windowDays, 1);
  StatValue two(int? Function(DateTime, DateTime) f) => _pack(f(w0.from, w0.to), f(w1.from, w1.to));
  return UserStats(
    two((a, b) => consistencyIn(st, a, b, today)),
    two((a, b) => productivityIn(st, a, b)),
    two((a, b) => focusIn(st, a, b)),
    two((a, b) => readingIn(st, a, b)),
    two((a, b) => disciplineIn(st, a, b, today, streakOverride: b == w0.to ? null : keptStreak(st, b))),
  );
}
