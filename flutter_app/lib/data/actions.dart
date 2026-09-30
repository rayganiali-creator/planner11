// عملیاتِ داده: هر تغییرِ کاربر از این‌جا می‌گذرد تا دقیقاً همان زنجیره‌ی نسخه‌ی HTML اجرا شود:
//   تغییر ← (checkLevelUp) ← renderAll (= مشتق‌سازیِ سکه/سطح حساب/streak) ← saveState
import '../app/toast.dart';
import '../core/calendar.dart';
import '../core/gameplay.dart';
import '../core/habits.dart';
import 'app_store.dart';
import 'media_store.dart';

typedef CapstoneHandler = void Function(String habitId, int level);

class AppActions {
  final AppStore store;
  final ToastBus toasts;
  CapstoneHandler? onCapstone;
  /// عکس/صدا؛ با حذفِ عادت/کتاب پاک می‌شوند (main آن را می‌گذارد)
  MediaStore? media;
  DateTime Function() clock;
  AppActions(this.store, this.toasts, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  DateTime get today => clock();
  String get todayISO => dateToISO(startOfDay(today));

  void _emit(Iterable<GameEvent> ev) {
    for (final e in ev) {
      if (e.kind == 'toast') {
        toasts.show(e.text!, cls: e.cls, ms: e.ms);
      } else if (e.kind == 'capstone') {
        onCapstone?.call(e.habitId!, e.level!);
      }
    }
  }

  /// renderAll(): مشتق‌سازی + ذخیره. برای باز شدنِ برنامه هم یک بار اجرا می‌شود.
  void renderAll() {
    _emit(applyDerived(store.state, today));
    store.save();
  }

  void _finish(RecordResult r) {
    if (!r.rendered) return;
    store.save(); // saveState() پیش از checkLevelUp
    _emit(r.events);
    renderAll();
  }

  void setBinary(String iso, String hid, String v) => _finish(setBinaryRecord(store.state, iso, hid, v));
  void setValue(String iso, String hid, Object? val) => _finish(setValueRecord(store.state, iso, hid, val));
  void clear(String iso, String hid) => _finish(clearRecord(store.state, iso, hid));

  /// «بله، ادامه بده» در پنجره‌ی سطح استادی
  void continueToNextStage(String habitId) {
    final habits = store.state['habits'];
    if (habits is! List) return;
    for (final h in habits) {
      if (h is Map && h['id'] == habitId) {
        h['unlockedStage'] = habitUnlockedStageCount(h) + 1;
        store.save();
        final next = habitCurrentStageThresholds(h);
        final fa = store.state['lang'] == 'fa';
        final cap = fa ? next.last.labelFa : next.last.labelEn;
        toasts.show(
          fa ? '🚀 مرحله‌ی جدید برای «${h['name']}» باز شد! تا $cap ادامه بده.' : '🚀 A new stage opened for "${h['name']}"! Keep going toward $cap.',
          cls: 'level-toast-up',
          ms: 4500,
        );
        return;
      }
    }
  }
}
