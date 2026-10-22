// همگام‌سازیِ ویجت صفحه‌ی اصلی: با هر ذخیره‌ی state یک اسنپ‌شاتِ کوچک از «امروز»
// (عادت‌ها + وضعیت + پیشرفت + streak + تم) از کانالِ rp/native به نیتیو می‌رود تا
// ویجت‌ها (android/.../widget) بدون باز شدنِ برنامه تازه بمانند.
import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/calendar.dart';
import '../core/date_fmt.dart';
import '../core/habits.dart';
import '../ui/app_themes.dart';
import 'app_store.dart';

class WidgetSync {
  static const _c = MethodChannel('rp/native');

  /// ساختِ اسنپ‌شات از state فعلی؛ خالص و تست‌پذیر.
  static Map<String, Object?> buildSnapshot(AppStore store, DateTime now) {
    final st = store.state;
    final fa = st['lang'] != 'en';
    String n(Object v) => fa ? toPersianDigits(v) : '$v';
    final iso = dateToISO(now);
    final habits = applicableHabitsForISO(st, iso).toList()
      ..sort((a, b) => _timeOf(a).compareTo(_timeOf(b)));
    final stats = dayStats(st, iso);
    final done = stats.success;
    final total = stats.total;
    final pct = total == 0 ? 0 : (done * 100 / total).round();
    final streak = computeStreak(st, now);
    return <String, Object?>{
      'rtl': fa,
      'themeId': themeById(st['accentTheme']).id,
      'mode': themeMode(st),
      'title': fa ? 'روتین امروز' : "Today's routine",
      'dateLine': dateLabel(now, jalali: isJalali(st), fa: fa, withYear: false, weekday: true),
      'todayLabel': fa ? 'امروز' : 'Today',
      'emptyText': fa ? 'امروز عادتی نداری' : 'No habits for today',
      'progressText': fa ? '${n(done)} از ${n(total)} انجام شد' : '$done of $total done',
      'smallCountText': total == 0
          ? (fa ? 'امروز عادتی نداری' : 'No habits for today')
          : (fa ? '${n(done)} از ${n(total)} عادت' : '$done of $total habits'),
      'streakText': fa ? '${n(streak)} روز پیاپی' : '$streak-day streak',
      'streak': streak,
      'done': done,
      'total': total,
      'pct': pct,
      'habits': [
        for (var i = 0; i < habits.length; i++)
          <String, Object?>{
            'name': '${habits[i]['name'] ?? ''}',
            'time': fa ? toPersianDigits(_timeOf(habits[i])) : _timeOf(habits[i]),
            'status': switch (habitSuccessOnISO(st, habits[i], iso)) { true => 'success', false => 'fail', null => 'unset' },
            'colorIdx': i,
          },
      ],
    };
  }

  static String _timeOf(Map h) {
    final t = h['reminderTime'];
    return t is String && t.isNotEmpty ? t : '08:00';
  }

  /// ارسال به نیتیو؛ هر خطایی (مثلاً نبودِ پل در تست/وب) نادیده گرفته می‌شود.
  static Future<void> push(AppStore store) async {
    try {
      await _c.invokeMethod<void>('updateWidget', {'json': jsonEncode(buildSnapshot(store, DateTime.now()))});
    } catch (_) {
      // ویجت نباید هرگز جلوی کارِ برنامه را بگیرد.
    }
  }
}
