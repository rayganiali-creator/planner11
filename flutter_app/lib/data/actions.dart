// عملیاتِ داده: هر تغییرِ کاربر از این‌جا می‌گذرد؛ بعد از هر تغییر سیستمِ پیشرفت (XP/سطح/نشان‌ها) با دادهٔ واقعی همگام می‌شود.
//   تغییر ← ذخیره ← syncProgress (idempotent) ← ذخیره
import 'package:flutter/foundation.dart';

import '../app/toast.dart';
import '../core/calendar.dart';
import '../core/gameplay.dart';
import '../core/progress/engine.dart';
import 'app_store.dart';
import 'media_store.dart';

class AppActions {
  final AppStore store;
  final ToastBus toasts;
  /// عکس/صدا؛ با حذفِ عادت/کتاب پاک می‌شوند (main آن را می‌گذارد)
  MediaStore? media;
  DateTime Function() clock;
  AppActions(this.store, this.toasts, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  /// هر بار سطح بالا رفت یا نشانی باز شد یکی زیاد می‌شود (برای انیمیشن‌های Level-up / Badge)
  final ValueNotifier<int> progressTick = ValueNotifier<int>(0);
  ProgressDelta? lastDelta;

  DateTime get today => clock();
  String get todayISO => dateToISO(startOfDay(today));

  /// همگام‌سازیِ پیشرفت با دادهٔ واقعی + ذخیره؛ برای باز شدنِ برنامه هم یک بار اجرا می‌شود.
  void renderAll() {
    final d = syncProgress(store.state, today);
    lastDelta = d;
    store.save();
    if (d.levelUp || d.newBadges.isNotEmpty) progressTick.value++;
  }

  /// پس از هر تغییری که XP/دستاورد را می‌تواند عوض کند (کار، پومودورو، کتاب، چالش، یادداشت)
  void afterChange() => renderAll();

  void _finish(RecordResult r) {
    if (!r.rendered) return;
    store.save();
    renderAll();
  }

  void setBinary(String iso, String hid, String v) => _finish(setBinaryRecord(store.state, iso, hid, v));
  void setValue(String iso, String hid, Object? val) => _finish(setValueRecord(store.state, iso, hid, val));
  void clear(String iso, String hid) => _finish(clearRecord(store.state, iso, hid));
}
