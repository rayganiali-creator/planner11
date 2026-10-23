// دسترسیِ UI به دادهٔ پیشرفت: همه‌چیز از state واقعی محاسبه می‌شود و برای هر نسخه‌ی داده یک بار کش می‌شود.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../core/calendar.dart';
import '../../core/date_fmt.dart';
import '../../core/progress/achievements.dart';
import '../../core/progress/engine.dart';
import '../../core/progress/stats.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';

class ProgressData {
  final ProgressSnapshot snap;
  final List<AchStatus> statuses;
  final UserStats stats;
  final DateTime now;
  ProgressData(this.snap, this.statuses, this.stats, this.now);

  AchStatus? byId(String id) {
    for (final s in statuses) {
      if (s.def.id == id) return s;
    }
    return null;
  }

  List<AchStatus> get unlockedList => statuses.where((s) => s.unlocked).toList();

  /// آخرین دستاوردهای دریافت‌شده (جدید → قدیم)
  List<AchStatus> recent([int n = 5]) => (unlockedList..sort((a, b) => (b.unlockedAt ?? 0).compareTo(a.unlockedAt ?? 0))).take(n).toList();

  /// نزدیک‌ترین دستاوردهای قفل (بیشترین پیشرفت)
  List<AchStatus> nextUp([int n = 2]) => (statuses.where((s) => !s.unlocked && s.def.pro == false && s.ratio > 0).toList()..sort((a, b) => b.ratio.compareTo(a.ratio))).take(n).toList();
}

int _cacheVer = -1;
String _cacheKey = '';
ProgressData? _cache;

/// [watch] = true در build؛ false در کال‌بک‌ها
ProgressData progressDataOf(BuildContext context, {bool watch = true}) {
  final store = watch ? context.watch<AppStore>() : context.read<AppStore>();
  final a = context.read<AppActions>();
  final now = a.today;
  final key = '${dateToISO(startOfDay(now))}|${store.state['isPremium']}';
  if (_cache != null && _cacheVer == store.dataVersion && _cacheKey == key && identical(_cacheStore, store)) return _cache!;
  final snap = snapshotOf(store.state, now);
  final ctx = MetricCtx(store.state, now, snap.level);
  final d = ProgressData(snap, achievementStatuses(store.state, ctx), computeStats(store.state, now), now);
  _cache = d;
  _cacheVer = store.dataVersion;
  _cacheKey = key;
  _cacheStore = store;
  return d;
}

AppStore? _cacheStore;

String groupDigits(BuildContext context, int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(context.isFa ? '٬' : ',');
    b.write(s[i]);
  }
  return context.n((n < 0 ? '-' : '') + b.toString());
}

String achName(BuildContext c, AchDef d) => c.tr(d.nameFa, d.nameEn);
String achDesc(BuildContext c, AchDef d) => c.tr(d.descFa, d.descEn);
String catName(BuildContext c, String id) {
  final k = badgeCategories.firstWhere((x) => x.id == id);
  return c.tr(k.nameFa, k.nameEn);
}

String dateOfMs(BuildContext c, int ms) {
  final st = c.read<AppStore>().state;
  return dateLabel(DateTime.fromMillisecondsSinceEpoch(ms), jalali: isJalali(st), fa: c.isFa);
}
