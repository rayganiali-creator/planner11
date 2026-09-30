// زبان: متن‌ها همان جفت‌های فارسی/انگلیسیِ نسخه‌ی HTML‌اند و «کپی» می‌شوند، نه بازنویسی.
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/calendar.dart';
import '../data/app_store.dart';

extension RpI18n on BuildContext {
  bool get isFa => select<AppStore, bool>((s) => s.state['lang'] != 'en');
  String tr(String fa, String en) => isFa ? fa : en;

  /// اعداد: در فارسی ارقام فارسی
  String n(Object v) => isFa ? toPersianDigits(v) : '$v';
}
