// ثبتِ عادت: setBinaryRecord / setValueRecord / clearRecord (پورتِ عین‌به‌عینِ نسخه‌ی HTML) و قفلِ هدفِ رکوردهای قبلی.
// سکه، سطحِ عادت، HP و آواتار حذف شده‌اند؛ XP/سطح/نشان‌ها از دادهٔ واقعی در core/progress ساخته می‌شود.
import 'doc.dart';
import 'js_compat.dart';

/// نتیجه‌ی یک ثبت. [rendered] = آیا در JS بعدِ آن renderAll() (یعنی مشتق‌سازیِ سکه/سطح/streak + ذخیره)
/// اجرا می‌شود؟ وقتی عادت وجود ندارد JS زودتر برمی‌گردد و هیچ‌چیز همگام نمی‌شود؛ پس فراخواننده فقط
/// در صورت true باید applyDerived را صدا بزند.
typedef RecordResult = ({bool rendered});

const RecordResult _noop = (rendered: false);

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
    return (rendered: true);
  }
  day[hid] = v;
  return (rendered: true);
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
  return (rendered: true);
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
    return (rendered: true);
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
