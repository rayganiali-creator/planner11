// پورت منطقِ عادت‌ها و streak از www/index.html. (سکه/امتیاز/سطحِ عادت حذف شد؛ پیشرفت در core/progress است.)
// هر تابع با خروجی طلایی JS سنجیده می‌شود (test/habits_test.dart).
//
// `state` همان سند JSON است (Map). «امروز» همیشه پارامتر است، نه ساعت سیستم، تا تست‌پذیر باشد.
import 'doc.dart';
import 'calendar.dart';
import 'js_compat.dart';


bool habitAppliesOnISO(Map h, String iso) {
  final created = h['createdAt'];
  if (created is String && iso.compareTo(created) < 0) return false; // iso < h.createdAt
  if (h['permanent'] == false) {
    final end = h['endDate'];
    if (end is String && iso.compareTo(end) > 0) return false; // iso > h.endDate
  }
  final ad = h['activeDays'];
  if (h['scheduleMode'] == 'custom' && ad is List && ad.isNotEmpty) {
    final persianIdx = jsWeekdayToPersianIndex(jsWeekday(isoToDate(iso)));
    return ad.contains(persianIdx);
  }
  return true;
}

List<Map> applicableHabitsForISO(Doc state, String iso) =>
    [for (final h in _habits(state)) if (habitAppliesOnISO(h, iso)) h];

List<Map> _habits(Doc state) {
  final v = state['habits'];
  return v is List ? [for (final e in v) if (e is Map) e] : <Map>[];
}

Map _recordsOf(Doc state, String iso) {
  final r = state['records'];
  if (r is Map) {
    final d = r[iso];
    if (jsTruthy(d) && d is Map) return d;
  }
  return const {};
}

/// برای رکوردِ عددی/زمانی: مقدار و هدفِ لحظه‌ی ثبت. null = نامعتبر (NaN).
({double value, double target})? _valueAndTarget(Object? raw, Map h, String targetKey, num defaultTarget) {
  double value;
  Object? target;
  if (raw is Map) {
    value = jsParseFloat(raw['value']);
    target = raw.containsKey('targetAtTime') ? raw['targetAtTime'] : jsOr(h[targetKey], defaultTarget);
  } else if (raw is List) {
    value = double.nan; // raw.value روی آرایه undefined است
    target = jsOr(h[targetKey], defaultTarget);
  } else {
    value = jsParseFloat(raw);
    target = jsOr(h[targetKey], defaultTarget);
  }
  if (value.isNaN) return null;
  return (value: value, target: jsToNumber(target));
}

/// true / false / null (ثبت نشده یا نامعتبر)
bool? habitSuccessOnISO(Doc state, Map h, String iso) {
  final rec = _recordsOf(state, iso);
  final id = h['id'];
  if (!rec.containsKey(id)) return null;
  final raw = rec[id];
  final direction = jsOr(h['direction'], 'more');
  final type = h['type'];
  if (type == 'binary') return raw == 'success';
  if (type == 'numeric' || type == 'timer') {
    final vt = type == 'numeric'
        ? _valueAndTarget(raw, h, 'numericTarget', 1)
        : _valueAndTarget(raw, h, 'timerTarget', 30);
    if (vt == null) return null;
    return direction == 'less' ? vt.value <= vt.target : vt.value >= vt.target;
  }
  return null;
}

typedef DayStats = ({int total, int success, int fail, int unset});

DayStats dayStats(Doc state, String iso, [bool Function(Map h)? filter]) {
  var app = applicableHabitsForISO(state, iso);
  if (filter != null) app = app.where(filter).toList();
  int s = 0, f = 0;
  for (final h in app) {
    final r = habitSuccessOnISO(state, h, iso);
    if (r == true) {
      s++;
    } else if (r == false) {
      f++;
    }
  }
  return (total: app.length, success: s, fail: f, unset: app.length - s - f);
}

DayStats dayStatsAll(Doc state, String iso) => dayStats(state, iso);

/// 'success' | 'fail' | null
String? getStatusFromRecord(Object? value, Map h) {
  final type = h['type'];
  final direction = jsOr(h['direction'], 'more');
  if (type == 'binary') {
    if (value == 'success') return 'success';
    if (value == 'fail') return 'fail';
    return null;
  }
  if (type == 'numeric' || type == 'timer') {
    final vt = type == 'numeric'
        ? _valueAndTarget(value, h, 'numericTarget', 1)
        : _valueAndTarget(value, h, 'timerTarget', 30);
    if (vt == null) return null;
    final ok = direction == 'less' ? vt.value <= vt.target : vt.value >= vt.target;
    return ok ? 'success' : 'fail';
  }
  return null;
}

// ---------------------------------------------------------------- streak / رکورد
/// روزِ شروعِ هفته بر اساس state.weekStart: ۰ = شنبه، ۱ = یکشنبه (همان تعریفِ تنظیمات و تقویم).
/// تفاوتِ آگاهانه با HTML: آنجا getWeekStart اندیسِ JS (۰=یکشنبه) را با weekStartِ فارسی ترکیب می‌کرد و
/// «هفته‌ی جاری» در تحلیل یک روز جابه‌جا شروع می‌شد.
DateTime getWeekStart(Doc state, DateTime d) {
  final ws = state['weekStart'];
  final offset = jsTruthy(ws) ? jsToNumber(ws).toInt() : 0;
  final diff = (jsWeekdayToPersianIndex(jsWeekday(d)) - offset + 7) % 7;
  return addDays(d, -diff);
}

// تفاوت آگاهانه با JS: حلقه‌ی بی‌نهایت (وقتی عادتی createdAt ندارد) → سقف ۴۰٬۰۰۰ روز.
const int _streakGuard = 40000;

int computeStreak(Doc state, DateTime today) {
  int streak = 0;
  var d = startOfDay(today);
  final todayISO = dateToISO(d);
  int guard = 0;
  while (guard++ < _streakGuard) {
    final iso = dateToISO(d);
    final s = dayStatsAll(state, iso);
    if (s.total == 0 || s.fail > 0) break;
    if (s.success == s.total) {
      streak++;
      d = addDays(d, -1);
      continue;
    }
    if (iso == todayISO) {
      d = addDays(d, -1);
      continue;
    }
    break;
  }
  return streak;
}

int computePermanentStreak(Doc state, DateTime today) {
  int streak = 0;
  var d = startOfDay(today);
  final todayISO = dateToISO(d);
  int guard = 0;
  while (guard++ < _streakGuard) {
    final iso = dateToISO(d);
    final s = dayStats(state, iso, (h) => h['permanent'] != false);
    if (s.total == 0 || s.fail > 0) break;
    if (s.success == s.total) {
      streak++;
      d = addDays(d, -1);
      continue;
    }
    if (iso == todayISO) {
      d = addDays(d, -1);
      continue;
    }
    break;
  }
  return streak;
}

int computeHabitStreak(Doc state, Map h, DateTime today) {
  int streak = 0;
  var d = startOfDay(today);
  final todayISO = dateToISO(d);
  int guard = 0;
  while (guard++ < 20000) {
    final iso = dateToISO(d);
    final created = h['createdAt'];
    if (created is String && iso.compareTo(created) < 0) break;
    if (!habitAppliesOnISO(h, iso)) {
      d = addDays(d, -1);
      continue;
    }
    final r = habitSuccessOnISO(state, h, iso);
    if (r == true) {
      streak++;
      d = addDays(d, -1);
      continue;
    }
    if (r == null && iso == todayISO) {
      d = addDays(d, -1);
      continue;
    }
    break;
  }
  return streak;
}

/// عددی/زمانی: بهترین مقدار (برای «کمتر بهتر است» کمترین). دوتایی: بیشترین پیاپیِ موفق.
/// مقدارِ بازگشتی: null (عددی بدون داده) یا num.
num? computeHabitBestRecord(Doc state, Map h) {
  final recs = state['records'];
  final id = h['id'];
  final dates = <String>[];
  if (recs is Map) {
    for (final e in recs.entries) {
      final day = e.value;
      if (jsTruthy(day) && day is Map && day.containsKey(id)) dates.add(e.key as String);
    }
  }
  dates.sort();
  if (h['type'] == 'numeric' || h['type'] == 'timer') {
    final lessIsBetter = h['direction'] == 'less';
    double? best;
    for (final iso in dates) {
      final raw = (recs as Map)[iso][id];
      final val = (raw is Map) ? jsParseFloat(raw['value']) : (raw is List ? double.nan : jsParseFloat(raw));
      if (val.isNaN) continue;
      if (best == null) {
        best = val;
      } else if (lessIsBetter ? val < best : val > best) {
        best = val;
      }
    }
    return best;
  }
  int best = 0, current = 0;
  String? prevIso;
  for (final iso in dates) {
    if (!habitAppliesOnISO(h, iso)) continue;
    final success = habitSuccessOnISO(state, h, iso) == true;
    if (success) {
      current = (prevIso != null && isoAddDays(prevIso, 1) == iso) ? current + 1 : 1;
      if (current > best) best = current;
      prevIso = iso;
    } else {
      current = 0;
      prevIso = null;
    }
  }
  return best;
}

