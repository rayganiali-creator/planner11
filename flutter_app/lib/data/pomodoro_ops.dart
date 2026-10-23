// پومودورو: زمانِ «پایان» ذخیره می‌شود نه شمارنده؛ پس با بستنِ برنامه هم درست می‌ماند. قواعد = نسخه‌ی HTML.
import '../core/js_compat.dart';
import 'actions.dart';
import 'notifier.dart';

const pomoDefaults = {'focus': 25, 'short': 5, 'long': 15};
const pomoLabel = {'focus': ['تمرکز', 'Focus'], 'short': ['استراحت کوتاه', 'Short break'], 'long': ['استراحت بلند', 'Long break']};

extension PomodoroOps on AppActions {
  bool get _pro => store.state['isPremium'] == true;
  int get _nowMs => clock().millisecondsSinceEpoch;

  Map pomoState() {
    final s = store.state;
    if (s['pomodoro'] is! Map) s['pomodoro'] = <String, dynamic>{};
    final p = s['pomodoro'] as Map;
    if (p['settings'] is! Map) p['settings'] = Map<String, dynamic>.from(pomoDefaults);
    (p['settings'] as Map).remove('sound');
    if (!jsTruthy(p['phase'])) p['phase'] = 'focus';
    if (!p.containsKey('cycle')) p['cycle'] = 0;
    if (p['remainingMs'] == null) p['remainingMs'] = pomoDurationMs('${p['phase']}');
    return p;
  }

  int pomoMinutes(String phase) {
    final set = (store.state['pomodoro'] is Map ? (store.state['pomodoro'] as Map)['settings'] : null) as Map? ?? pomoDefaults;
    if (!_pro) return pomoDefaults[phase]!;
    final v = set[phase];
    return jsTruthy(v) ? (v as num).toInt() : pomoDefaults[phase]!;
  }

  int pomoDurationMs(String phase) => pomoMinutes(phase) * 60000;

  int pomoRemaining() {
    final p = pomoState();
    if (p['running'] == true) {
      final r = (p['endsAt'] as num) - _nowMs;
      return r < 0 ? 0 : r.toInt();
    }
    return (p['remainingMs'] as num).toInt();
  }

  void _notice(Notifier? n) {
    final p = pomoState();
    n?.cancel('pomodoro');
    if (p['running'] != true || n == null) return;
    final fa = store.state['lang'] != 'en';
    final ph = '${p['phase']}';
    final lbl = pomoLabel[ph]![fa ? 0 : 1];
    final next = ph == 'focus' ? (fa ? 'وقت استراحت است' : 'Time for a break') : (fa ? 'وقت تمرکز دوباره است' : 'Back to focus');
    n.scheduleOnce('pomodoro', fa ? '⏱️ $lbl تمام شد' : '⏱️ $lbl finished', next, (p['endsAt'] as num).toInt());
  }

  void pomoStart({Notifier? notifier}) {
    final p = pomoState();
    if (p['running'] == true) return;
    p['running'] = true;
    final rem = jsTruthy(p['remainingMs']) ? (p['remainingMs'] as num).toInt() : pomoDurationMs('${p['phase']}');
    p['endsAt'] = _nowMs + rem;
    store.save();
    _notice(notifier);
  }

  void pomoPause({Notifier? notifier}) {
    final p = pomoState();
    if (p['running'] != true) return;
    final r = (p['endsAt'] as num) - _nowMs;
    p['remainingMs'] = r < 0 ? 0 : r.toInt();
    p['running'] = false;
    p['endsAt'] = null;
    store.save();
    _notice(notifier);
  }

  void pomoSetPhase(String ph, {Notifier? notifier}) {
    final p = pomoState();
    p['running'] = false;
    p['endsAt'] = null;
    p['phase'] = ph;
    p['remainingMs'] = pomoDurationMs(ph);
    store.save();
    _notice(notifier);
  }

  /// فاز بعدی؛ در فازِ تمرکز شمارنده‌ی دور را یکی زیاد می‌کند (هر ۴ دور → استراحت بلند)
  String pomoNextPhase() {
    final p = pomoState();
    if (p['phase'] == 'focus') {
      p['cycle'] = (((p['cycle'] as num?) ?? 0).toInt()) + 1;
      return (p['cycle'] as int) % 4 == 0 ? 'long' : 'short';
    }
    return 'focus';
  }

  void pomoSkip({Notifier? notifier}) => pomoSetPhase(pomoNextPhase(), notifier: notifier);

  /// پایانِ فاز: برمی‌گرداند (تمام‌شده, بعدی)
  (String, String) pomoFinish() {
    final p = pomoState();
    final done = '${p['phase']}';
    if (done == 'focus') {
      // جلسه‌ی تمرکزِ کاملِ ثبت‌شده (فقط با پایانِ واقعیِ زمان؛ Skip/Start-Stop جلسه نمی‌سازد)
      final log = p['log'] is List ? p['log'] as List : (p['log'] = <dynamic>[]);
      final now = _nowMs;
      log.add({'id': 'pl_${now.toRadixString(36)}_${log.length}', 'at': now, 'minutes': pomoMinutes('focus')});
      if (log.length > 5000) log.removeRange(0, log.length - 5000);
    }
    final next = pomoNextPhase();
    p['running'] = false;
    p['endsAt'] = null;
    p['phase'] = next;
    p['remainingMs'] = pomoDurationMs(next);
    store.save();
    afterChange();
    final fa = store.state['lang'] != 'en';
    toasts.show(
      fa ? '⏱️ ${pomoLabel[done]![0]} تمام شد — نوبت ${pomoLabel[next]![0]}' : '⏱️ ${pomoLabel[done]![1]} done — next: ${pomoLabel[next]![1]}',
      ms: 4000,
      cls: 'toast-success',
    );
    return (done, next);
  }

  /// هر ۵۰۰ میلی‌ثانیه؛ true یعنی فازی تمام شد
  bool pomoTick() {
    final p = pomoState();
    if (p['running'] == true && _nowMs >= (p['endsAt'] as num)) {
      pomoFinish();
      return true;
    }
    return false;
  }

  void pomoSetMinutes(String key, int raw, int max) {
    if (!_pro) return;
    final v = raw.clamp(1, max);
    final p = pomoState();
    (p['settings'] as Map)[key] = v;
    if (p['running'] != true && p['phase'] == key) p['remainingMs'] = v * 60000;
    store.save();
  }
}
