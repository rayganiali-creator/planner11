// نوشتن اتمیک روی دیسک: یا فایل کاملِ جدید، یا فایلِ کاملِ قبلی — هرگز نیمه‌کاره.
//
// تفاوتِ آگاهانه با نسخه‌ی HTML که ایمنی را بیشتر می‌کند: در HTML اگر JSON ذخیره‌شده خراب باشد،
// برنامه با حسابِ خالی بالا می‌آید و اولین ذخیره روی داده‌ی خراب (ولی شاید قابل‌بازیابی) می‌نویسد.
// اینجا فایلِ خراب پیش از هر بازنویسی به `.corrupt-<زمان>` کنار گذاشته می‌شود.
import 'dart:convert';
import 'dart:io';

class AtomicFile {
  final File main;
  AtomicFile(String path) : main = File(path);

  File get _tmp => File('${main.path}.tmp');
  File get _bak => File('${main.path}.bak');

  /// متنِ سالم را برمی‌گرداند: اول فایل اصلی، اگر نبود/خراب بود نسخه‌ی پشتیبان.
  /// [isValid] تعیین می‌کند متن «سالم» است یا نه (مثلاً JSON معتبر باشد).
  ({String? text, bool recovered, String? quarantinedAs}) read({required bool Function(String) isValid}) {
    String? quarantined;
    for (final (f, isBackup) in [(main, false), (_bak, true)]) {
      if (!f.existsSync()) continue;
      String? t;
      try {
        t = f.readAsStringSync(encoding: utf8);
      } catch (_) {
        t = null;
      }
      if (t != null && t.isNotEmpty && isValid(t)) {
        return (text: t, recovered: isBackup, quarantinedAs: quarantined);
      }
      // خراب: کنار بگذار تا حذف/بازنویسی نشود
      try {
        final q = '${f.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}';
        f.renameSync(q);
        quarantined ??= q;
      } catch (_) {}
    }
    return (text: null, recovered: false, quarantinedAs: quarantined);
  }

  /// بنویس؛ در خطا false (مثلاً فضای گوشی پر است) و فایلِ قبلی دست‌نخورده می‌ماند.
  bool write(String text) {
    try {
      main.parent.createSync(recursive: true);
      _tmp.writeAsStringSync(text, encoding: utf8, flush: true);
      if (main.existsSync()) {
        try {
          main.copySync(_bak.path);
        } catch (_) {}
      }
      _tmp.renameSync(main.path); // در یک پارتیشن اتمیک است
      return true;
    } catch (_) {
      try {
        if (_tmp.existsSync()) _tmp.deleteSync();
      } catch (_) {}
      return false;
    }
  }
}
