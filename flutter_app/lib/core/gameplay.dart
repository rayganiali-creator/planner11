// قلبِ «بازی‌وار»: ثبتِ عادت، ارتقای سطح، مشتق‌سازیِ امتیاز/سکه/سطح حساب/streak و HP آواتار.
// پورتِ عین‌به‌عینِ setBinaryRecord / setValueRecord / clearRecord / checkLevelUp / renderDashboard (بخشِ state)
// / announceAccountLevelUpIfNeeded / computeAvatarHP. خروجیِ ناخالص (toast و پنجره) به‌صورت «رویداد» برمی‌گردد
// تا رابط کاربری نشانش بدهد؛ منطق از رابط جداست و با JS سنجیده می‌شود (test/gameplay_test.dart).
import 'calendar.dart';
import 'doc.dart';
import 'habits.dart';
import 'js_compat.dart';

class GameEvent {
  /// 'toast' | 'capstone'
  final String kind;
  final String? cls; // level-toast-up | level-toast-mastery
  final String? text;
  final String? habitId;
  final int? level;
  final int ms; // مدتِ نمایشِ toast
  const GameEvent.toast(this.cls, String this.text, {this.level, this.ms = 3500})
      : kind = 'toast',
        habitId = null;
  const GameEvent.capstone(String this.habitId, int this.level)
      : kind = 'capstone',
        cls = null,
        text = null,
        ms = 0;
  List<Object?> toJson() => kind == 'toast' ? ['toast', cls, text, ms] : ['capstone', habitId, level];
}

/// نتیجه‌ی یک ثبت. [rendered] = آیا در JS بعدِ آن renderAll() (یعنی مشتق‌سازیِ سکه/سطح/streak + ذخیره)
/// اجرا می‌شود؟ وقتی عادت وجود ندارد JS زودتر برمی‌گردد و هیچ‌چیز همگام نمی‌شود؛ پس فراخواننده فقط
/// در صورت true باید applyDerived را صدا بزند.
typedef RecordResult = ({bool rendered, List<GameEvent> events});

const RecordResult _noop = (rendered: false, events: <GameEvent>[]);

bool _fa(Doc s) => s['lang'] == 'fa';

Map _map(Doc s, String k) {
  final v = s[k];
  if (v is Map) return v;
  final m = <String, dynamic>{};
  s[k] = m;
  return m;
}

Map? _habit(Doc s, String hid) {
  for (final h in (s['habits'] is List ? s['habits'] as List : const [])) {
    if (h is Map && h['id'] == hid) return h;
  }
  return null;
}

// ---------------------------------------------------------------- ارتقای سطحِ هر عادت
List<GameEvent> checkLevelUp(Doc state, String hid) {
  final h = _habit(state, hid);
  if (h == null) return const [];
  final points = computeHabitPoints(state, hid);
  final thresholds = habitActiveThresholds(h);
  final cur = getLevelFromPoints(points, thresholds);
  final prev = getLevelFromPoints(points - coinMaxPerOp, thresholds);
  if (cur.num <= prev.num) return const [];
  final key = '${hid}_level_${cur.num}';
  final sent = _map(state, 'levelToastSent');
  if (jsTruthy(sent[key])) return const [];
  sent[key] = true;
  final fa = _fa(state);
  final name = jsString(h['name']);
  if (cur.isCapstone) {
    final hasNext = habitUnlockedStageCount(h) < habitLevelStages.length;
    if (hasNext) return [GameEvent.capstone(hid, cur.num)];
    final icon = cur.icon.isEmpty ? '🏆' : cur.icon;
    return [
      GameEvent.toast(
        'level-toast-mastery',
        fa ? '🎉$icon تبریک! شما عادت «$name» را در بالاترین سطح فعلی به اتمام رساندید! 🎉' : '🎉$icon Congratulations! You reached the highest current level for "$name"! 🎉',
        level: cur.num,
        ms: 5000,
      )
    ];
  }
  final label = fa ? cur.labelFa : cur.labelEn;
  return [
    GameEvent.toast(
      'level-toast-up',
      fa ? '🎉 تبریک! شما به $label در عادت «$name» رسیدید! 🎉' : '🎉 Congratulations! You reached $label for "$name"! 🎉',
      level: cur.num,
      ms: 4000,
    )
  ];
}

// ---------------------------------------------------------------- ثبت
void _dropEmptyDay(Doc s, String iso) {
  final recs = _map(s, 'records');
  final d = recs[iso];
  if (d is Map && d.isEmpty) recs.remove(iso);
}

void _dropReason(Doc s, String hid, String iso) {
  final reasons = _map(s, 'reasons');
  final r = reasons[hid];
  if (jsTruthy(r) && r is Map && r.containsKey(iso) && jsTruthy(r[iso])) {
    r.remove(iso);
    if (r.isEmpty) reasons.remove(hid);
  }
}

/// دوباره زدنِ همان مقدار = برداشتنِ ثبت (و حذفِ دلیلِ همان روز). `recompute` را خودِ ذخیره‌ی بعدی انجام می‌دهد.
RecordResult setBinaryRecord(Doc state, String iso, String hid, String v) {
  final h = _habit(state, hid);
  if (h == null) return _noop;
  final recs = _map(state, 'records');
  if (recs[iso] is! Map || !jsTruthy(recs[iso])) recs[iso] = <String, dynamic>{};
  final day = recs[iso] as Map;
  if (day[hid] == v) {
    day.remove(hid);
    _dropEmptyDay(state, iso);
    _dropReason(state, hid, iso);
    return (rendered: true, events: const <GameEvent>[]);
  }
  day[hid] = v;
  return (rendered: true, events: checkLevelUp(state, hid));
}

RecordResult setValueRecord(Doc state, String iso, String hid, Object? val) {
  final h = _habit(state, hid);
  if (h == null) return _noop;
  final recs = _map(state, 'records');
  if (recs[iso] is! Map || !jsTruthy(recs[iso])) recs[iso] = <String, dynamic>{};
  Object? target;
  bool hasTarget = true;
  if (h['type'] == 'numeric') {
    target = jsOr(h['numericTarget'], 1);
  } else if (h['type'] == 'timer') {
    target = jsOr(h['timerTarget'], 30);
  } else {
    hasTarget = false;
  }
  (recs[iso] as Map)[hid] = {'value': jsString(val), if (hasTarget) 'targetAtTime': target};
  return (rendered: true, events: checkLevelUp(state, hid));
}

RecordResult clearRecord(Doc state, String iso, String hid) {
  final h = _habit(state, hid);
  if (h == null) return _noop;
  final recs = _map(state, 'records');
  final day = recs[iso];
  if (jsTruthy(day) && day is Map) {
    day.remove(hid);
    _dropEmptyDay(state, iso);
    _dropReason(state, hid, iso);
    return (rendered: true, events: const <GameEvent>[]);
  }
  return _noop; // روزی ثبت نشده: JS هیچ کاری نمی‌کند (renderAll هم نه)
}

/// پیش از تغییرِ هدفِ عددی/زمانیِ یک عادت: هدفِ فعلی روی رکوردهای قبلی «قفل» می‌شود.
void freezeHabitRecordTargets(Doc state, Map h) {
  if (h['type'] != 'numeric' && h['type'] != 'timer') return;
  final cur = h['type'] == 'numeric' ? jsOr(h['numericTarget'], 1) : jsOr(h['timerTarget'], 30);
  final recs = state['records'];
  if (recs is! Map) return;
  for (final iso in recs.keys) {
    final rec = recs[iso];
    if (rec is! Map) continue;
    final id = h['id'];
    if (!rec.containsKey(id)) continue;
    final raw = rec[id];
    if (raw is Map) {
      if (!raw.containsKey('targetAtTime')) raw['targetAtTime'] = cur;
    } else if (raw is! List) {
      rec[id] = {'value': jsString(raw), 'targetAtTime': cur};
    }
  }
}

// ---------------------------------------------------------------- مشتق‌سازی (بخشِ state از renderDashboard)
/// امتیاز کل ← سکه (سقف ۵۰ در هر همگام‌سازی) ← سطح حساب (هر ۱۰۰۰ سکه = یک سطح) ← streak.
/// JS این کار را در هر renderAll انجام می‌دهد و بعدش saveState() می‌زند؛ پس «هر تغییرِ داده» باید از اینجا بگذرد.
List<GameEvent> applyDerived(Doc state, DateTime today) {
  final scores = _map(state, 'scores');
  final total = computeTotalPoints(state);
  scores['points'] = total;
  syncCoinsFromPoints(state, total);
  final coins = jsOr(scores['coins'], 0);
  final level = getAccountLevelFromCoins(coins is num ? coins : jsToNumber(coins));
  final events = <GameEvent>[];
  // announceAccountLevelUpIfNeeded
  if (!jsTruthy(scores['accountLevelToastSent'])) scores['accountLevelToastSent'] = <String, dynamic>{};
  final sent = scores['accountLevelToastSent'] as Map;
  if (level > 0 && !jsTruthy(sent['$level'])) {
    sent['$level'] = true;
    final fa = _fa(state);
    events.add(GameEvent.toast('level-toast-up', fa ? '🎉 تبریک! به سطح ${toPersianDigits(level)} حساب رسیدید!' : '🎉 Congratulations! You reached account level $level!', level: level, ms: 4500));
  }
  scores['level'] = level;
  scores['streak'] = computeStreak(state, today);
  return events;
}

// ---------------------------------------------------------------- HP و حالِ آواتار
/// HP = موفقیت‌ها ÷ عادت‌های سررسیدِ ۳ روزِ کامل + موفقیت‌های امروز (امروزِ انجام‌نشده شکست نیست).
int computeAvatarHP(Doc state, DateTime todayIn) {
  final today = startOfDay(todayIn);
  int due = 0, ok = 0;
  final habits = [for (final h in (state['habits'] is List ? state['habits'] as List : const [])) if (h is Map) h];
  for (int i = 1; i <= 3; i++) {
    final iso = dateToISO(addDays(today, -i));
    for (final h in habits) {
      if (!habitAppliesOnISO(h, iso)) continue;
      due++;
      if (habitSuccessOnISO(state, h, iso) == true) ok++;
    }
  }
  final isoToday = dateToISO(today);
  for (final h in habits) {
    if (!habitAppliesOnISO(h, isoToday)) continue;
    if (habitSuccessOnISO(state, h, isoToday) == true) {
      due++;
      ok++;
    }
  }
  return due > 0 ? jsRound(100 * ok / due) : 100;
}

/// ۰ تا ۷ صبح: آواتار می‌خوابد. ۷ تا ۱۹: روز.
bool isNightSleep(int hour) => hour >= 0 && hour < 7;
bool isDay(int hour) => hour >= 7 && hour < 19;

/// 'ok' | 'tired' | 'hurt' | 'sick' | 'asleep'
String avConditionOf(int hp, int hour) {
  if (isNightSleep(hour)) return 'asleep';
  if (hp >= 70) return 'ok';
  if (hp >= 40) return 'tired';
  if (hp >= 15) return 'hurt';
  return 'sick';
}

/// چشمِ بسته فقط در خواب یا مریضیِ شدید
bool avCondEyesClosed(String c) => c == 'asleep' || c == 'sick';
