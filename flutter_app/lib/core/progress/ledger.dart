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
