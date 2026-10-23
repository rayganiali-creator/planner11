// دفترِ XP و وضعیتِ پیشرفت داخلِ state['progress'] (Local-First؛ همراهِ Backup/Restore ذخیره می‌شود).
// هر XP یک «رویداد» با شناسه‌ی یکتا و قطعی است؛ ثبتِ دوباره‌ی همان شناسه هرگز XP اضافه نمی‌دهد.
import '../doc.dart';

const int progressVersion = 1;

/// رویدادِ XP: {id,type,sourceId,amount,ts,date,meta,revoked?}
Map<String, dynamic> newEvent(String id, String type, String sourceId, int amount, int ts, String date, [Map<String, dynamic>? meta]) =>
    {'id': id, 'type': type, 'sourceId': sourceId, 'amount': amount, 'ts': ts, 'date': date, if (meta != null && meta.isNotEmpty) 'meta': meta};

Map<String, dynamic> freshProgress() => {
      'v': progressVersion,
      'startedAt': null,
      'events': <String, dynamic>{},
      'unlocked': <String, dynamic>{}, // achievementId → {at, date, backfilled?}
      'activeTitle': null,
      'featured': <dynamic>[],
      'season': null, // فصلِ جاری (پرو)
      'seasons': <dynamic>[], // آرشیفِ فصل‌ها
      'announced': <String, dynamic>{'level': 1, 'badges': <dynamic>[]},
      'legacy': null,
    };

/// state['progress'] را سالم برمی‌گرداند (فیلدهای خراب ترمیم می‌شوند؛ چیزی حذف نمی‌شود).
Map<String, dynamic> progressOf(Doc st) {
  var p = st['progress'];
  if (p is! Map) {
    p = freshProgress();
    st['progress'] = p;
  }
  final m = p as Map<String, dynamic>;
  final base = freshProgress();
  for (final e in base.entries) {
    if (!m.containsKey(e.key)) m[e.key] = e.value;
  }
  if (m['events'] is! Map) m['events'] = <String, dynamic>{};
  if (m['unlocked'] is! Map) m['unlocked'] = <String, dynamic>{};
  if (m['featured'] is! List) m['featured'] = <dynamic>[];
  if (m['seasons'] is! List) m['seasons'] = <dynamic>[];
  if (m['announced'] is! Map) m['announced'] = <String, dynamic>{'level': 1, 'badges': <dynamic>[]};
  return m;
}

bool hasProgress(Doc st) => st['progress'] is Map && (st['progress'] as Map)['startedAt'] != null;

Map<String, dynamic> eventsOf(Doc st) => (progressOf(st)['events'] as Map).cast<String, dynamic>();

int totalXp(Doc st) {
  int s = 0;
  for (final e in eventsOf(st).values) {
    if (e is Map && e['revoked'] != true) s += ((e['amount'] as num?) ?? 0).toInt();
  }
  return s;
}

/// مجموعِ XP در بازه‌ی تاریخی [fromIso, toIso] (شاملِ هر دو سر)
int xpBetween(Doc st, String fromIso, String toIso) {
  int s = 0;
  for (final e in eventsOf(st).values) {
    if (e is! Map || e['revoked'] == true) continue;
    final d = '${e['date']}';
    if (d.compareTo(fromIso) >= 0 && d.compareTo(toIso) <= 0) s += ((e['amount'] as num?) ?? 0).toInt();
  }
  return s;
}

Iterable<Map> validEvents(Doc st, {String? type}) sync* {
  for (final e in eventsOf(st).values) {
    if (e is Map && e['revoked'] != true && (type == null || e['type'] == type)) yield e;
  }
}

/// ورودیِ نامطمئن (فایل پشتیبانِ دست‌کاری‌شده / ذخیره‌ی خراب): هر فیلدِ نادرست حذف یا ترمیم می‌شود تا هیچ‌جای برنامه
/// با cast/نوعِ غلط نیفتد. true = چیزی تغییر کرد. ورودیِ سالم دست‌نخورده می‌ماند.
bool sanitizeProgress(Map p) {
  bool changed = false;
  void drop(Map m, Object k) {
    m.remove(k);
    changed = true;
  }

  num? numOrNull(Object? v) => v is num && v.isFinite ? v : null;

  final ev = p['events'];
  if (ev is Map) {
    for (final k in ev.keys.toList()) {
      final e = ev[k];
      if (e is! Map || e['amount'] is! num || !(e['amount'] as num).isFinite || e['date'] is! String || e['type'] is! String || e['sourceId'] is! String || numOrNull(e['ts']) == null) {
        drop(ev, k);
        continue;
      }
      if (e['revoked'] != null && e['revoked'] is! bool) {
        e['revoked'] = e['revoked'] == true;
        changed = true;
      }
      if (e['meta'] != null && e['meta'] is! Map) {
        e.remove('meta');
        changed = true;
      }
    }
  }
  final un = p['unlocked'];
  if (un is Map) {
    for (final k in un.keys.toList()) {
      final r = un[k];
      if (r is! Map || numOrNull(r['at']) == null) drop(un, k);
    }
  }
  if (p['featured'] is List) {
    final f = (p['featured'] as List);
    final clean = <dynamic>[for (final x in f) if (x is String) x];
    if (clean.length != f.length) {
      p['featured'] = clean;
      changed = true;
    }
  }
  final an = p['announced'];
  if (an is Map) {
    if (an['level'] is! num) {
      an['level'] = 1;
      changed = true;
    }
    final b = an['badges'];
    if (b is! List || b.any((x) => x is! String)) {
      an['badges'] = <dynamic>[if (b is List) ...b.whereType<String>()];
      changed = true;
    }
  }
  final ss = p['seasons'];
  if (ss is List && ss.any((x) => x is! Map)) {
    p['seasons'] = <dynamic>[for (final x in ss) if (x is Map) x];
    changed = true;
  }
  final se = p['season'];
  if (se != null && (se is! Map || se['start'] is! String || se['end'] is! String || se['days'] is! num || se['id'] is! String || se['name'] is! String)) {
    p['season'] = null;
    changed = true;
  }
  final ld = p['levelDates'];
  if (ld != null) {
    if (ld is! Map) {
      p.remove('levelDates');
      changed = true;
    } else {
      for (final k in ld.keys.toList()) {
        if (ld[k] is! num) drop(ld, k);
      }
    }
  }
  if (p['activeTitle'] != null && p['activeTitle'] is! String) {
    p['activeTitle'] = null;
    changed = true;
  }
  if (p['startedAt'] != null && numOrNull(p['startedAt']) == null) {
    p['startedAt'] = null;
    changed = true;
  }
  if (p['legacy'] != null && p['legacy'] is! Map) {
    p['legacy'] = null;
    changed = true;
  }
  return changed;
}

/// داده‌ی خامِ کاربر که موتورِ پیشرفت می‌خواند (تمرکز، کارها، کتاب‌ها): ورودیِ ناقص/خراب حذف یا ترمیم می‌شود.
bool sanitizeProgressInputs(Doc st) {
  bool ch = false;
  bool isN(Object? v) => v is num && v.isFinite;
  // پومودورو
  final pom = st['pomodoro'];
  if (pom is Map && pom['log'] != null) {
    final log = pom['log'];
    if (log is! List) {
      pom['log'] = <dynamic>[];
      ch = true;
    } else if (log.any((e) => e is! Map || !isN(e['at']) || !isN(e['minutes']))) {
      pom['log'] = <dynamic>[for (final e in log) if (e is Map && isN(e['at']) && isN(e['minutes'])) e];
      ch = true;
    }
  }
  // لاگِ کارها
  final tl = st['todoLog'];
  if (tl is List && tl.any((e) => e is! Map || !isN(e['at']) || e['title'] != null && e['title'] is! String)) {
    st['todoLog'] = <dynamic>[for (final e in tl) if (e is Map && isN(e['at']) && (e['title'] == null || e['title'] is String)) e];
    ch = true;
  }
  for (final e in (st['todoLog'] is List ? st['todoLog'] as List : const [])) {
    if (e is Map && e['createdAt'] != null && !isN(e['createdAt'])) {
      e.remove('createdAt');
      ch = true;
    }
  }
  // کارها
  for (final t in (st['todos'] is List ? st['todos'] as List : const [])) {
    if (t is Map) {
      if (t['createdAt'] != null && !isN(t['createdAt'])) {
        t.remove('createdAt');
        ch = true;
      }
      if (t['title'] != null && t['title'] is! String) {
        t['title'] = '${t['title']}';
        ch = true;
      }
    }
  }
  // کتاب‌ها
  for (final b in (st['books'] is List ? st['books'] as List : const [])) {
    if (b is! Map) continue;
    if (b['completedAt'] != null && !isN(b['completedAt'])) {
      b.remove('completedAt');
      ch = true;
    }
    final h = b['history'];
    if (h != null && h is! List) {
      b['history'] = <dynamic>[];
      ch = true;
    } else if (h is List && h.any((x) => x is! Map || !isN(x['date']) || (x['pagesRead'] != null && !isN(x['pagesRead'])))) {
      b['history'] = <dynamic>[for (final x in h) if (x is Map && isN(x['date']) && (x['pagesRead'] == null || isN(x['pagesRead']))) x];
      ch = true;
    }
  }
  // عادت‌ها: تاریخِ ساخت باید «YYYY-MM-DD» باشد
  final re = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  for (final h in (st['habits'] is List ? st['habits'] as List : const [])) {
    if (h is Map && h['createdAt'] != null && !(h['createdAt'] is String && re.hasMatch(h['createdAt'] as String))) {
      h.remove('createdAt');
      ch = true;
    }
  }
  // چالش‌ها
  for (final c in (st['challenges'] is List ? st['challenges'] as List : const [])) {
    if (c is Map) {
      for (final k in const ['completedAt', 'createdAt', 'deadlineAt', 'targetCount', 'progressCount']) {
        if (c[k] != null && !isN(c[k])) {
          c.remove(k);
          ch = true;
        }
      }
    }
  }
  return ch;
}
