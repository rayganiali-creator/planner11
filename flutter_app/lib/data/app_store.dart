// AppStore: معادلِ `state` سراسری + saveState() در نسخه‌ی HTML.
// state همان سند JSON (Map) است؛ هر تغییر با save() ذخیره و به شنونده‌ها اعلام می‌شود.
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/doc.dart';
import '../core/js_compat.dart';
import '../core/pro.dart';
import '../core/state_model.dart';
import 'atomic_file.dart';

typedef NowMs = int Function();

class AppStore extends ChangeNotifier {
  final AtomicFile _file;
  final NowMs _now;
  final TrustedClock clock = TrustedClock();
  Doc state = defaultState();

  /// هر ذخیره این شماره را بالا می‌برد؛ صفحه‌ها فقط وقتی دوباره ساخته می‌شوند که عوض شده باشد.
  int dataVersion = 0;

  /// آخرین ذخیره‌ی ناموفق (برای نمایش پیامِ «حافظه پر است»).
  bool lastSaveFailed = false;

  /// نتیجه‌ی بارگذاری برای رابط کاربری (بازیابی از پشتیبان/فایل خراب).
  bool recoveredFromBackup = false;
  String? quarantinedCorruptFile;

  AppStore(String path, {NowMs? nowMs})
      : _file = AtomicFile(path),
        _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  Stopwatch? _perf;

  /// «الان»ِ ساعتِ مطمئن (هرگز عقب‌تر از lastSeen نمی‌رود).
  num rpNow() {
    _perf ??= Stopwatch()..start();
    final c = state['clock'];
    return clock.now(dateNow: _now(), perfNow: _perf!.elapsedMicroseconds / 1000, lastSeen: c is Map ? c['lastSeen'] : null);
  }

  /// بارگذاری از دیسک. هرگز استثنا نمی‌دهد؛ در بدترین حالت با حسابِ تازه بالا می‌آید
  /// (و فایلِ خراب، در صورت وجود، کنار گذاشته می‌شود نه پاک).
  void load() {
    final r = _file.read(isValid: (t) {
      try {
        jsonDecode(t);
        return true;
      } catch (_) {
        return false;
      }
    });
    recoveredFromBackup = r.recovered;
    quarantinedCorruptFile = r.quarantinedAs;
    final loaded = loadStateFromRaw(r.text, nowMs: _now());
    state = loaded.state;
    // همان کاری که JS می‌کند: اگر نرمال‌سازی چیزی را تعمیر کرد، همان‌جا بنویس تا دفعه‌ی بعد سالم بالا بیاید
    if (loaded.repaired && r.text != null) _file.write(jsonStringify(state));
    notifyListeners();
  }

  /// معادلِ saveState(): false یعنی روی دیسک ننشست (مثلاً حافظه پر است).
  bool save() {
    dataVersion++;
    final c = state['clock'];
    if (c is Map) {
      final n = rpNow();
      final ls = jsToNumber(jsOr(c['lastSeen'], 0));
      c['lastSeen'] = (ls.isNaN ? 0 : (ls > n ? ls : n)).toInt();
    }
    final ok = _file.write(jsonStringify(state));
    lastSaveFailed = !ok;
    notifyListeners();
    return ok;
  }

  /// جایگزینیِ یک‌جای کلِ state (بازیابیِ پشتیبان).
  void replaceWith(Doc s) {
    state = s;
    save();
  }
}
