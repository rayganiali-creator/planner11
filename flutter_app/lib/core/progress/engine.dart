// موتورِ پیشرفت: دفترِ XP را با دادهٔ واقعی همگام می‌کند (idempotent)، سطح/رتبه/نشان‌ها را می‌سازد و تغییرات را برمی‌گرداند.
// هر تغییرِ داده → syncProgress. اجرای مکرر (Refresh/Restart) همیشه همان نتیجه را می‌دهد.
import '../calendar.dart';
import '../doc.dart';
import '../habits.dart';
import 'achievements.dart';
import 'config.dart';
import 'ledger.dart';
import 'sources.dart';
import 'stats.dart';

class ProgressDelta {
  final int xpBefore, xpAfter, levelBefore, levelAfter;
  final List<String> newBadges;
  final bool migrated;
  const ProgressDelta(this.xpBefore, this.xpAfter, this.levelBefore, this.levelAfter, this.newBadges, this.migrated);
  int get xpGained => xpAfter - xpBefore;
  bool get levelUp => levelAfter > levelBefore;
}

class ProgressSnapshot {
  final int xp, level, into, needed, toNext, streak, badgeCount, totalBadges;
  final double ratio;
  final bool maxed;
  final RankDef rank;
  final TitleDef? title;
  final List<String> featured;
  const ProgressSnapshot(this.xp, this.level, this.into, this.needed, this.toNext, this.ratio, this.maxed, this.rank, this.title, this.streak, this.badgeCount, this.totalBadges, this.featured);
}

/// رخدادهایی که هنوز به کاربر نمایش داده نشده‌اند (برای انیمیشنِ Level-up / Badge)
class Pending {
  final int? level;
  final List<String> badges;
  const Pending(this.level, this.badges);
  bool get isEmpty => level == null && badges.isEmpty;
}

String _isoOf(DateTime d) => dateToISO(startOfDay(d));

/// قلبِ سیستم. [now] ساعتِ مطمئنِ برنامه.
ProgressDelta syncProgress(Doc st, DateTime now) {
  final p = progressOf(st);
  final migrating = p['startedAt'] == null;
  final nowMs = now.millisecondsSinceEpoch;
  final today = startOfDay(now);
  final todayIso = dateToISO(today);
  final windowStart = dateToISO(addDays(today, -XpGuards.backfillDays));
  final events = (p['events'] as Map).cast<String, dynamic>();
  final xpBefore = totalXp(st), levelBefore = levelForXp(xpBefore).level;

  if (migrating) {
    p['startedAt'] = nowMs;
    final sc = st['scores'];
    p['legacy'] = {'migratedAt': nowMs, 'note': 'Coin/Avatar/Inventory are no longer used; Coin is NOT converted to XP.', if (sc is Map) 'coins': sc['coins'], if (sc is Map) 'level': sc['level']};
    _backfillTodoLog(st);
    _legacyHabitFlags(st);
  }

  // ---- ۱) کاندیدها ← رویدادها (با سقف‌های روزانه، قطعی)
  final cands = collectCandidates(st, now);
  final byId = {for (final c in cands) c['id'] as String: c};
  int tsOf(Map c) => ((events[c['id']] as Map?)?['ts'] as num?)?.toInt() ?? (c['ts'] as num).toInt();
  cands.sort((a, b) {
    final r = tsOf(a).compareTo(tsOf(b));
    return r != 0 ? r : (a['id'] as String).compareTo(b['id'] as String);
  });
  final cnt = <String, int>{}, xps = <String, int>{};
  final allowed = <String>{};
  for (final c in cands) {
    final id = c['id'] as String, type = c['type'] as String, date = c['date'] as String;
    final key = '$type|$date';
    final capN = XpGuards.dailyEventCap[type], capX = XpGuards.dailyXpCap[type];
    final amount = (c['amount'] as num).toInt();
    final existing = events[id];
    if (capN != null && (cnt[key] ?? 0) >= capN) continue;
    if (capX != null && (xps[key] ?? 0) + amount > capX && (xps[key] ?? 0) > 0) continue;
    if (existing == null) {
      // تاریخِ قدیمی نمی‌تواند XPِ تازه بسازد (جز مهاجرتِ اولیه)
      if (!migrating && (type == 'habit' || type == 'daily') && date.compareTo(windowStart) < 0) continue;
      events[id] = c;
    } else if (existing is Map) {
      existing.remove('revoked'); // همان رویداد دوباره معتبر شد؛ رویدادِ تازه ساخته نمی‌شود
    }
    allowed.add(id);
    cnt[key] = (cnt[key] ?? 0) + 1;
    xps[key] = (xps[key] ?? 0) + ((events[id] as Map)['amount'] as num).toInt();
  }
  // ---- ۲) ابطالِ رویدادهای قابل‌ابطال که دیگر معتبر نیستند (فقط وقتی منبعشان هنوز هست)
  final habitIds = {for (final h in (st['habits'] is List ? st['habits'] as List : const [])) if (h is Map) h['id']};
  for (final e in events.values) {
    if (e is! Map || allowed.contains(e['id']) || e['revoked'] == true) continue;
    final t = e['type'];
    if (!revocableTypes.contains(t)) continue;
    bool relevant = true;
    if (t == 'habit') relevant = habitIds.contains(e['sourceId']);
    if (t == 'daily') relevant = applicableCount(st, '${e['date']}') > 0;
    if (t == 'todo') relevant = byId[e['id']] == null; // از todoLog برداشته شد (Undo) یا نامعتبر شد
    if (relevant) e['revoked'] = true;
  }

  // ---- ۳) سطح، دستاوردها، تاریخِ سطح‌ها
  final xpAfter = totalXp(st);
  final lv = levelForXp(xpAfter).level;
  final levelDates = (p['levelDates'] is Map ? p['levelDates'] as Map : (p['levelDates'] = <String, dynamic>{})).cast<String, dynamic>();
  for (int n = 2; n <= lv; n++) {
    levelDates.putIfAbsent('$n', () => nowMs);
  }
  final ctx = MetricCtx(st, now, lv);
  final unlocked = (p['unlocked'] as Map).cast<String, dynamic>();
  final isPro = st['isPremium'] == true;
  final newly = <String>[];
  for (final a in achievementStatuses(st, ctx)) {
    if (a.unlocked && !unlocked.containsKey(a.def.id) && !(a.def.pro && !isPro)) {
      unlocked[a.def.id] = {'at': nowMs, 'date': todayIso, if (migrating) 'backfilled': true};
      newly.add(a.def.id);
    }
  }
  if (migrating) {
    p['announced'] = {'level': lv, 'badges': unlocked.keys.toList()};
    newly.clear();
  }
  _season(st, p, now);
  return ProgressDelta(xpBefore, xpAfter, levelBefore, lv, newly, migrating);
}

/// تعدادِ عادت‌های سررسیدِ یک روز (برای تشخیصِ اینکه منبعِ بونوسِ روزانه هنوز هست)
int applicableCount(Doc st, String iso) => dayStatsAll(st, iso).total;

void _backfillTodoLog(Doc st) {
  final log = st['todoLog'] is List ? st['todoLog'] as List : (st['todoLog'] = <dynamic>[]);
  final have = {for (final e in log) if (e is Map) e['todoId']};
  for (final t in (st['todos'] is List ? st['todos'] as List : const [])) {
    if (t is Map && t['done'] == true && (t['repeatMode'] == null || t['repeatMode'] == 'none') && !have.contains(t['id'])) {
      final at = (t['createdAt'] as num?)?.toInt();
      if (at == null) continue;
      log.add({'id': 'bf_${t['id']}', 'todoId': t['id'], 'title': t['title'], 'at': at, 'createdAt': at, 'backfilled': true});
    }
  }
}

/// عادت‌های قدیمیِ «امتیاز پاداشِ» بالاتر از پیش‌فرض ← «مهم»
void _legacyHabitFlags(Doc st) {
  for (final h in (st['habits'] is List ? st['habits'] as List : const [])) {
    if (h is Map && !h.containsKey('important')) h['important'] = (h['rewardPoints'] is num && (h['rewardPoints'] as num) > 10);
  }
}

// ---------------------------------------------------------------- فصل (Season) — پرو
void _season(Doc st, Map<String, dynamic> p, DateTime now) {
  final cur = p['season'];
  if (cur is! Map) return;
  final today = _isoOf(now);
  if (today.compareTo('${cur['end']}') > 0) {
    final xp = xpBetween(st, '${cur['start']}', '${cur['end']}');
    (p['seasons'] as List).add({'id': cur['id'], 'name': cur['name'], 'start': cur['start'], 'end': cur['end'], 'days': cur['days'], 'xp': xp, 'closedAt': now.millisecondsSinceEpoch});
    p['season'] = null;
    // آرشیف ساخته شد؛ XP/Level/Rank/Badge/Title دائمی‌اند و هرگز حذف نمی‌شوند
  }
}

/// آغازِ فصل (فقط پرو). برمی‌گرداند false اگر فصلِ فعالی هست یا پرو نیست.
bool startSeason(Doc st, DateTime now, int days) {
  if (st['isPremium'] != true || ![30, 60, 90].contains(days)) return false;
  final p = progressOf(st);
  if (p['season'] is Map) return false;
  final n = (p['seasons'] as List).length + 1;
  final start = startOfDay(now);
  p['season'] = {'id': 's${n.toString().padLeft(2, '0')}', 'name': 'Season ${n.toString().padLeft(2, '0')}', 'theme': 'consistency', 'days': days, 'start': dateToISO(start), 'end': dateToISO(addDays(start, days - 1))};
  return true;
}

// ---------------------------------------------------------------- نمایش
ProgressSnapshot snapshotOf(Doc st, DateTime now) {
  final p = progressOf(st);
  final xp = totalXp(st);
  final li = levelForXp(xp);
  final un = p['unlocked'] as Map;
  final title = titleById('${p['activeTitle']}');
  final okTitle = title != null && un.containsKey(title.achId) ? title : null;
  final featured = [for (final f in (p['featured'] as List)) if (un.containsKey('$f')) '$f'];
  return ProgressSnapshot(xp, li.level, li.into, li.needed, li.toNext, li.ratio, li.maxed, rankForLevel(li.level), okTitle, keptStreak(st, now), un.length, achievementCatalog.length, featured);
}

Pending pendingAnnouncements(Doc st) {
  final p = progressOf(st);
  if (p['startedAt'] == null) return const Pending(null, []);
  final ann = p['announced'] as Map;
  final lv = levelForXp(totalXp(st)).level;
  final seenLv = (ann['level'] as num?)?.toInt() ?? 1;
  final seen = {for (final b in (ann['badges'] is List ? ann['badges'] as List : const [])) '$b'};
  return Pending(lv > seenLv ? lv : null, [for (final id in (p['unlocked'] as Map).keys) if (!seen.contains(id)) '$id']);
}

void markAnnounced(Doc st) {
  final p = progressOf(st);
  p['announced'] = {'level': levelForXp(totalXp(st)).level, 'badges': (p['unlocked'] as Map).keys.toList()};
}

// ---------------------------------------------------------------- انتخابِ کاربر
bool setActiveTitle(Doc st, String? id) {
  final p = progressOf(st);
  if (id == null) {
    p['activeTitle'] = null;
    return true;
  }
  final t = titleById(id);
  if (t == null || !(p['unlocked'] as Map).containsKey(t.achId)) return false;
  p['activeTitle'] = id;
  return true;
}

/// نشانِ ویژه: یک نشان برای هر دسته (۶ جایگاهِ صفحه‌ی خانه)؛ فقط نشانِ بازشده. نشانِ تازه جای نشانِ هم‌دسته را می‌گیرد.
bool toggleFeatured(Doc st, String achId) {
  final p = progressOf(st);
  final f = (p['featured'] as List).map((e) => '$e').toList();
  if (f.contains(achId)) {
    f.remove(achId);
  } else {
    final a = achById(achId);
    if (a == null || !(p['unlocked'] as Map).containsKey(achId)) return false;
    f.removeWhere((x) => achById(x)?.cat == a.cat);
    f.add(achId);
  }
  p['featured'] = f;
  return true;
}
