// زبان: متن‌ها همان جفت‌های فارسی/انگلیسیِ نسخه‌ی HTML‌اند و «کپی» می‌شوند، نه بازنویسی.
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/calendar.dart';
import '../data/app_store.dart';

extension RpI18n on BuildContext {
  /// در build (و LayoutBuilder): وابستگی ثبت می‌شود تا با عوض‌شدنِ زبان دوباره ساخته شود؛
  /// در کال‌بک‌ها (ضربه و …) Provider اجازه‌ی select نمی‌دهد و فقط خوانده می‌شود.
  bool get isFa {
    try {
      return select<AppStore, bool>((s) => s.state['lang'] != 'en');
    } on AssertionError {
      return read<AppStore>().state['lang'] != 'en';
    }
  }

  String tr(String fa, String en) => isFa ? fa : en;

  /// اعداد: در فارسی ارقام فارسی
  String n(Object v) => isFa ? toPersianDigits(v) : '$v';
}
