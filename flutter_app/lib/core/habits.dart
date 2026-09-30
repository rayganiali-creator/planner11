// پورت منطقِ عادت‌ها، امتیاز، سطح و streak از www/index.html.
// هر تابع با خروجی طلایی JS سنجیده می‌شود (test/habits_test.dart).
//
// `state` همان سند JSON است (Map). «امروز» همیشه پارامتر است، نه ساعت سیستم، تا تست‌پذیر باشد.
import 'doc.dart';
import 'calendar.dart';
import 'js_compat.dart';


const int coinMaxPerOp = 50; // سقف دریافت/کسر سکه در هر عملیات

// ---------------------------------------------------------------- سطح‌ها
class LevelDef {
  final int num;
  final int minPoints;
  final String labelFa, labelEn, icon;
  final bool isCapstone;
  const LevelDef(this.num, this.minPoints, this.labelFa, this.labelEn, {this.icon = '', this.isCapstone = false});
  Map<String, dynamic> toJson() => {'num': num, 'minPoints': minPoints, 'labelFa': labelFa, 'labelEn': labelEn, 'icon': icon, 'isCapstone': isCapstone};
}

const List<List<LevelDef>> habitLevelStages = [
  [
    LevelDef(1, 250, 'سطح ۱', 'Level 1'),
    LevelDef(2, 500, 'سطح ۲', 'Level 2'),
    LevelDef(3, 750, 'سطح ۳', 'Level 3'),
    LevelDef(4, 1000, 'سطح ۴', 'Level 4'),
    LevelDef(5, 1500, 'سطح ۵', 'Level 5'),
    LevelDef(6, 2000, 'استادی', 'Master', icon: '🏆', isCapstone: true),
  ],
  [
    LevelDef(7, 2500, 'سطح ۷', 'Level 7'),
    LevelDef(8, 3000, 'سطح ۸', 'Level 8'),
    LevelDef(9, 3500, 'سطح ۹', 'Level 9'),
    LevelDef(10, 4000, 'سطح ۱۰', 'Level 10'),
    LevelDef(11, 4500, 'سطح ۱۱', 'Level 11'),
    LevelDef(12, 5000, 'استاد اعظم', 'Grand Master', icon: '👑', isCapstone: true),
  ],
];

List<LevelDef> get levelThresholds => habitLevelStages[0];

int habitUnlockedStageCount(Map? h) {
  if (h == null) return 1;
  final v = h['unlockedStage'];
  return jsTruthy(v) ? jsToNumber(v).toInt() : 1;
}

List<LevelDef> habitActiveThresholds(Map? h) {
  final n = habitUnlockedStageCount(h);
  final take = n < habitLevelStages.length ? n : habitLevelStages.length;
  return [for (final s in habitLevelStages.take(take < 0 ? 0 : take)) ...s];
}

List<LevelDef> habitCurrentStageThresholds(Map? h) {
  final n = habitUnlockedStageCount(h);
  final k = n < habitLevelStages.length ? n : habitLevelStages.length;
  return (k - 1 >= 0 && k - 1 < habitLevelStages.length) ? habitLevelStages[k - 1] : habitLevelStages[0];
}

const LevelDef _beginner = LevelDef(0, 0, 'شروع', 'Beginner');

LevelDef getLevelFromPoints(num points, [List<LevelDef>? thresholds]) {
  final list = thresholds ?? levelThresholds;
  for (int i = list.length - 1; i >= 0; i--) {
    if (points >= list[i].minPoints) return list[i];
  }
  return _beginner;
}

int getLevelNum(num points, [List<LevelDef>? thresholds]) => getLevelFromPoints(points, thresholds).num;

// ---------------------------------------------------------------- عادت در یک روز
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

// ---------------------------------------------------------------- امتیاز
num getHabitRewardPoints(Map? h) {
  final rp = h == null ? null : h['rewardPoints'];
  final v = (rp is num && rp > 0) ? rp : 10;
  return v < coinMaxPerOp ? v : coinMaxPerOp;
}

num getRecordPoints(Object? value, Map h) {
  final status = getStatusFromRecord(value, h);
  final reward = getHabitRewardPoints(h);
  if (status == 'success') return reward;
  if (status == 'fail') {
    final half = jsRound(reward / 2);
    return -(half > 1 ? half : 1);
  }
  return 0;
}

Map<String, num> computeAllHabitPoints(Doc state) {
  final habitMap = <dynamic, Map>{for (final h in _habits(state)) h['id']: h};
  final totals = <String, num>{};
  final recs = state['records'];
  if (recs is Map) {
    for (final iso in recs.keys) {
      final rec = recs[iso];
      if (rec is! Map) continue; // روزِ خراب، نه خطا
      for (final hid in rec.keys) {
        final h = habitMap[hid];
        if (h != null) totals['$hid'] = (totals['$hid'] ?? 0) + getRecordPoints(rec[hid], h);
      }
    }
  }
  return totals;
}

num computeHabitPoints(Doc state, String hid) => computeAllHabitPoints(state)[hid] ?? 0;

num computeTotalPoints(Doc state) => computeAllHabitPoints(state).values.fold<num>(0, (a, b) => a + b);

// ---------------------------------------------------------------- سکه
int getAccountLevelFromCoins(num? coins) {
  final c = (coins == null || coins.isNaN) ? 0 : coins;
  return (c < 0 ? 0 : c) ~/ 1000;
}

Map _scores(Doc state) {
  final s = state['scores'];
  if (s is Map) return s;
  final m = <String, dynamic>{};
  state['scores'] = m;
  return m;
}

int _safeCoins(num? amount) {
  final a = jsRound(amount ?? 0);
  return a < 0 ? 0 : (a > coinMaxPerOp ? coinMaxPerOp : a);
}

/// هر دریافت سکه در کل برنامه فقط از همین‌جا می‌گذرد (سقف ۵۰ در هر عملیات).
int addCoins(Doc state, num? amount) {
  final safe = _safeCoins(amount);
  final sc = _scores(state);
  sc['coins'] = ((sc['coins'] is num ? sc['coins'] : 0) as num) + safe;
  return safe;
}

int removeCoins(Doc state, num? amount) {
  final safe = _safeCoins(amount);
  final sc = _scores(state);
  final cur = (sc['coins'] is num ? sc['coins'] : 0) as num;
  sc['coins'] = (cur - safe) < 0 ? 0 : cur - safe;
  return safe;
}

void syncCoinsFromPoints(Doc state, num totalPoints) {
  final sc = _scores(state);
  if (!sc.containsKey('lastPoints') || sc['lastPoints'] == null) sc['lastPoints'] = totalPoints;
  final delta = totalPoints - (sc['lastPoints'] as num);
  if (delta > 0) addCoins(state, delta);
  sc['lastPoints'] = totalPoints;
}

// ---------------------------------------------------------------- streak / رکورد
/// روزِ شروعِ هفته بر اساس state.weekStart
DateTime getWeekStart(Doc state, DateTime d) {
  final ws = state['weekStart'];
  final offset = jsTruthy(ws) ? jsToNumber(ws).toInt() : 0;
  final diff = (jsWeekday(d) - offset + 7) % 7;
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

// ---------------------------------------------------------------- سری‌ها و آمار (برای نمودارها)
typedef Series = ({List<String> labels, List<int?> values});

/// `str.slice(0, 3)`: اگر رشته کوتاه‌تر بود خطا نمی‌دهد.
String _slice3(String s) => s.length <= 3 ? s : s.substring(0, 3);

int _lenOfGregorianMonth(int y, int m) => DateTime(y, m + 1, 0).day;

({int jy, int jm}) _jalaliNow(DateTime today) {
  final j = toJalaali(today.year, today.month, today.day);
  return (jy: j.jy, jm: j.jm);
}

DateTime _dayOf(Doc state, int y, int m, int d) {
  if (state['calendarType'] == 'jalali') {
    final g = toGregorian(y, m, d);
    return DateTime(g.gy, g.gm, g.gd);
  }
  return DateTime(y, m, d);
}

Series collectSeries(Doc state, String range, DateTime todayIn) {
  final labels = <String>[], values = <int?>[];
  final today = startOfDay(todayIn);
  final fa = state['lang'] == 'fa';
  final jalali = state['calendarType'] == 'jalali';
  int pct(int s, int t) => jsRound(s / t * 100);
  if (range == 'week') {
    final s = getWeekStart(state, today);
    final wds = fa ? persianWeekdaysShort : enWeekdaysShort;
    for (int i = 0; i < 7; i++) {
      final d = addDays(s, i);
      labels.add(wds[i]);
      if (d.isAfter(today)) {
        values.add(null);
        continue;
      }
      final st = dayStatsAll(state, dateToISO(d));
      values.add(st.total > 0 ? pct(st.success, st.total) : null);
    }
  } else if (range == 'month') {
    late int jy, jm, len;
    if (jalali) {
      final j = _jalaliNow(today);
      jy = j.jy;
      jm = j.jm;
      len = jalaaliMonthLength(jy, jm);
    } else {
      jy = today.year;
      jm = today.month;
      len = _lenOfGregorianMonth(jy, jm);
    }
    for (int dn = 1; dn <= len; dn++) {
      final d = _dayOf(state, jy, jm, dn);
      labels.add(fa ? toPersianDigits(dn) : '$dn');
      if (d.isAfter(today)) {
        values.add(null);
        continue;
      }
      final st = dayStatsAll(state, dateToISO(d));
      values.add(st.total > 0 ? pct(st.success, st.total) : null);
    }
  } else {
    final months = fa ? persianMonths : enMonths;
    final year = jalali ? _jalaliNow(today).jy : today.year;
    for (int jm = 1; jm <= 12; jm++) {
      labels.add(_slice3(months[jm - 1]));
      int sS = 0, fS = 0;
      final len = jalali ? jalaaliMonthLength(year, jm) : _lenOfGregorianMonth(year, jm);
      for (int dn = 1; dn <= len; dn++) {
        final d = _dayOf(state, year, jm, dn);
        if (d.isAfter(today)) continue;
        final st = dayStatsAll(state, dateToISO(d));
        sS += st.success;
        fS += st.fail;
      }
      final tot = sS + fS;
      values.add(tot > 0 ? pct(sS, tot) : null);
    }
  }
  return (labels: labels, values: values);
}

({int success, int fail}) getTotalStats(Doc state, String range, DateTime todayIn) {
  int sS = 0, fS = 0;
  final today = startOfDay(todayIn);
  final jalali = state['calendarType'] == 'jalali';
  void add(DateTime d) {
    if (d.isAfter(today)) return;
    final st = dayStatsAll(state, dateToISO(d));
    sS += st.success;
    fS += st.fail;
  }

  if (range == 'week') {
    final s = getWeekStart(state, today);
    for (int i = 0; i < 7; i++) {
      add(addDays(s, i));
    }
  } else if (range == 'month') {
    final jy = jalali ? _jalaliNow(today).jy : today.year;
    final jm = jalali ? _jalaliNow(today).jm : today.month;
    final len = jalali ? jalaaliMonthLength(jy, jm) : _lenOfGregorianMonth(jy, jm);
    for (int dn = 1; dn <= len; dn++) {
      add(_dayOf(state, jy, jm, dn));
    }
  } else {
    final year = jalali ? _jalaliNow(today).jy : today.year;
    for (int jm = 1; jm <= 12; jm++) {
      final len = jalali ? jalaaliMonthLength(year, jm) : _lenOfGregorianMonth(year, jm);
      for (int dn = 1; dn <= len; dn++) {
        add(_dayOf(state, year, jm, dn));
      }
    }
  }
  return (success: sS, fail: fS);
}
