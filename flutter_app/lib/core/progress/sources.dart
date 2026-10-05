// منابعِ XP: از دادهٔ واقعیِ برنامه «رویدادِ کاندید» می‌سازد. شناسه‌ها قطعی‌اند (همان منبع = همان شناسه)،
// پس Complete→Undo→Complete، Refresh و Restart هرگز XP اضافه تولید نمی‌کنند.
import 'dart:math' as math;

import '../calendar.dart';
import '../doc.dart';
import '../habits.dart';
import 'config.dart';
import 'ledger.dart';
import 'stats.dart';

typedef Cand = Map<String, dynamic>;

const Set<String> revocableTypes = {'habit', 'daily', 'todo'};

List<Map> _list(Object? v) => v is List ? [for (final e in v) if (e is Map) e] : <Map>[];
int _ms(Object? v) => v is num ? v.toInt() : 0;
String _iso(int ms) => dateToISO(DateTime.fromMillisecondsSinceEpoch(ms));
int _noon(String iso) {
  final d = isoToDate(iso);
  return DateTime(d.year, d.month, d.day, 12).millisecondsSinceEpoch;
}

int pomodoroXp(int minutes) {
  int xp = 0;
  for (final (m, x) in XpRules.pomodoro) {
    if (minutes >= m) xp = x;
  }
  return xp;
}

int challengeXp(Map c) {
  final created = _ms(c['createdAt']), done = _ms(c['completedAt']);
  final days = created > 0 && done > created ? (done - created) ~/ 86400000 : 0;
  final byTime = 25 + 5 * days;
  final byTarget = c['targetCount'] is num ? 25 + 2 * (c['targetCount'] as num).toInt() : 25;
  return math.max(XpRules.challengeMin, math.min(XpRules.challengeMax, math.max(byTime, byTarget)));
}

/// همه‌ی رویدادهای معتبر در این لحظه (پیش از سقف‌های روزانه)
List<Cand> collectCandidates(Doc st, DateTime now) {
  final out = <Cand>[];
  final today = startOfDay(now);
  final todayIso = dateToISO(today);

  // ---- عادت‌ها + بونوسِ تکمیلِ روزانه (از رکوردها)
  final habits = {for (final h in _list(st['habits'])) h['id']: h};
  final recs = st['records'] is Map ? st['records'] as Map : const {};
  for (final iso in recs.keys.map((k) => '$k').toList()..sort()) {
    if (iso.compareTo(todayIso) > 0) continue; // آینده هرگز
    final day = recs[iso];
    if (day is! Map) continue;
    for (final hid in day.keys) {
      final h = habits[hid];
      if (h == null || !habitAppliesOnISO(h, iso)) continue;
      if (habitSuccessOnISO(st, h, iso) != true) continue;
      final important = h['important'] == true;
      out.add(newEvent('habit:$hid:$iso', 'habit', '$hid', important ? XpRules.habitImportant : XpRules.habit, iso == todayIso ? now.millisecondsSinceEpoch : _noon(iso), iso, important ? {'important': true} : null));
    }
    final s = dayStatsAll(st, iso);
    if (s.total >= XpGuards.dailyBonusMinHabits && s.success / s.total >= XpGuards.dailyBonusRatio) {
      out.add(newEvent('daily:$iso', 'daily', iso, XpRules.dailyBonus, iso == todayIso ? now.millisecondsSinceEpoch : _noon(iso), iso));
    }
  }

  // ---- کارها (از todoLog؛ بازنشانیِ روزانه‌ی کارهای تکرارشونده XP را از بین نمی‌برد)
  final seenTitleDay = <String>{};
  final todoLog = _list(st['todoLog'])..sort((a, b) => _ms(a['at']).compareTo(_ms(b['at'])));
  for (final e in todoLog) {
    if (!isValidTodoLog(e)) continue;
    final at = _ms(e['at']);
    final iso = _iso(at);
    final key = '$iso|${'${e['title']}'.trim().toLowerCase()}';
    if (!seenTitleDay.add(key)) continue; // یک عنوانِ یکسان در یک روز فقط یک بار
    out.add(newEvent('todo:${e['id']}', 'todo', '${e['todoId']}', e['priority'] == 'high' ? XpRules.todoHigh : XpRules.todo, at, iso));
  }

  // ---- چالش‌ها (موفق + دست‌کم یک ساعت از ساخت)؛ مدال‌های قدیمی هم اگر چالششان حذف شده
  final chIds = <String>{};
  for (final c in _list(st['challenges'])) {
    if (c['status'] != 'success' || c['completedAt'] is! num) continue;
    final created = _ms(c['createdAt']);
    if (created > 0 && _ms(c['completedAt']) - created < XpGuards.challengeMinAgeMs) continue;
    chIds.add('${c['id']}');
    out.add(newEvent('chal:${c['id']}', 'challenge', '${c['id']}', challengeXp(c), _ms(c['completedAt']), _iso(_ms(c['completedAt']))));
  }
  for (final m in _list(st['medals'])) {
    final id = '${m['challengeId']}';
    if (chIds.contains(id) || m['at'] is! num) continue;
    out.add(newEvent('chal:$id', 'challenge', id, XpRules.challengeMin, _ms(m['at']), _iso(_ms(m['at']))));
  }

  // ---- پومودورو (جلسه‌ی تمرکزِ کاملِ ثبت‌شده)
  final pom = st['pomodoro'] is Map ? _list((st['pomodoro'] as Map)['log']) : <Map>[];
  for (final e in pom) {
    if (!isValidPomodoro(e)) continue;
    final xp = pomodoroXp((e['minutes'] as num).toInt());
    if (xp <= 0) continue;
    out.add(newEvent('pomo:${e['id']}', 'pomodoro', '${e['id']}', xp, _ms(e['at']), _iso(_ms(e['at']))));
  }

  // ---- مطالعه‌ی واقعی (صفحه‌ی تازه نسبت به بیشینه‌ی قبلیِ همان کتاب)
  readingDays(st).forEach((k, pages) {
    final parts = k.split('|');
    final xp = math.min(XpRules.libraryMax, XpRules.libraryMin + pages ~/ 10);
    out.add(newEvent('lib:${parts[0]}:${parts[1]}', 'library', parts[0], xp, _noon(parts[1]), parts[1], {'pages': pages}));
  });

  // ---- مرورِ روزانه (یادداشتِ ژورنال با حداقل طول؛ هر روز یک بار)
  final jd = <String, int>{};
  for (final j in _list(st['journal'])) {
    final at = _ms(j['createdAt']);
    if (at == 0 || '${j['text'] ?? ''}'.trim().length < XpGuards.journalMinLen) continue;
    final iso = _iso(at);
    if (!jd.containsKey(iso) || at < jd[iso]!) jd[iso] = at;
  }
  jd.forEach((iso, at) => out.add(newEvent('journal:$iso', 'journal', iso, XpRules.journal, at, iso)));

  // ---- بونوسِ استمرار (یک بار برای هر آستانه)
  final ks = keptStreak(st, now);
  XpRules.streakBonus.forEach((n, xp) {
    if (ks >= n) out.add(newEvent('streak:$n', 'streak', '$n', xp, now.millisecondsSinceEpoch, todayIso));
  });
  return out;
}
