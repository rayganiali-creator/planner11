// پیکربندیِ مرکزیِ سیستمِ پیشرفت: همه‌ی عددها (XP، سقف‌ها، منحنیِ سطح، رتبه‌ها) فقط همین‌جاست.
// هیچ‌جای دیگرِ برنامه نباید نیازِ سطح/XP را hard-code کند.
import 'dart:math' as math;

// ---------------------------------------------------------------- XP منابع
class XpRules {
  static const int habit = 10, habitImportant = 15;
  static const int todo = 8, todoHigh = 12;
  static const int challengeMin = 25, challengeMax = 100;
  static const int libraryMin = 5, libraryMax = 15; // به‌ازای هر ۱۰ صفحه‌ی تازه ۱ امتیاز بیشتر
  static const int journal = 10;
  static const int dailyBonus = 10;
  /// Pomodoro: [حداقلِ دقیقه، XP] از کم به زیاد
  static const List<(int, int)> pomodoro = [(10, 10), (30, 12), (45, 15), (60, 20)];
  /// بونوسِ استمرار (فقط یک بار برای هر آستانه)
  static const Map<int, int> streakBonus = {7: 25, 30: 100, 100: 300};
}

// ---------------------------------------------------------------- ضدِ تقلب (قواعدِ اعتبارِ رویداد)
class XpGuards {
  /// فقط تاریخ‌های امروز و چند روز اخیر می‌توانند XPِ تازه بسازند (جلوگیری از تغییرِ تاریخ برای تولیدِ XP)
  static const int backfillDays = 3;
  /// کار باید دست‌کم این‌قدر پیش از انجام ساخته شده باشد (کارِ جعلیِ «بساز و تیک بزن» XP نمی‌دهد)
  static const int todoMinAgeMs = 60 * 1000;
  static const int todoMinTitleLen = 3;
  static const int challengeMinAgeMs = 60 * 60 * 1000;
  static const int pomodoroMinMinutes = 10;
  static const int journalMinLen = 20;
  static const int dailyBonusMinHabits = 2;
  static const double dailyBonusRatio = 0.8;
  /// سقفِ تعدادِ رویداد/XP در هر روز برای هر نوع
  static const Map<String, int> dailyEventCap = {'todo': 12, 'pomodoro': 12, 'journal': 1};
  static const Map<String, int> dailyXpCap = {'habit': 150, 'library': 30, 'challenge': 100};
}

// ---------------------------------------------------------------- سطح (۱ تا ۱۰۰)
const int maxLevel = 100;

/// XP لازم برای رفتن از سطحِ n به n+1
int xpToAdvance(int n) => (((100 + 2 * math.pow(n, 1.6)) / 10).round()) * 10;

/// مجموعِ XPِ لازم برای «رسیدن به» سطحِ n (سطح ۱ = ۰)
final List<int> levelFloor = (() {
  final l = <int>[0, 0];
  for (int n = 1; n < maxLevel; n++) {
    l.add(l.last + xpToAdvance(n));
  }
  return l; // اندیس n = حداقل XP برای سطح n
})();

typedef LevelInfo = ({int level, int into, int needed, double ratio, int toNext, bool maxed});

LevelInfo levelForXp(num xp) {
  final x = xp < 0 ? 0 : xp.floor();
  int lv = 1;
  for (int n = maxLevel; n >= 1; n--) {
    if (x >= levelFloor[n]) {
      lv = n;
      break;
    }
  }
  if (lv >= maxLevel) return (level: maxLevel, into: x - levelFloor[maxLevel], needed: 0, ratio: 1.0, toNext: 0, maxed: true);
  final need = levelFloor[lv + 1] - levelFloor[lv];
  final into = x - levelFloor[lv];
  return (level: lv, into: into, needed: need, ratio: into / need, toNext: need - into, maxed: false);
}

// ---------------------------------------------------------------- رتبه
class RankDef {
  final String id, nameEn, nameFa;
  final int fromLevel;
  const RankDef(this.id, this.nameEn, this.nameFa, this.fromLevel);
}

const List<RankDef> ranks = [
  RankDef('beginner', 'Beginner', 'نوآموز', 1),
  RankDef('initiate', 'Initiate', 'آغازگر', 5),
  RankDef('focused', 'Focused', 'متمرکز', 12),
  RankDef('consistent', 'Consistent', 'مستمر', 22),
  RankDef('disciplined', 'Disciplined', 'منضبط', 35),
  RankDef('dedicated', 'Dedicated', 'متعهد', 48),
  RankDef('elite', 'Elite', 'برجسته', 62),
  RankDef('master', 'Master', 'استاد', 78),
  RankDef('grandmaster', 'Grandmaster', 'استاد اعظم', 92),
];

RankDef rankForLevel(int level) {
  var r = ranks.first;
  for (final x in ranks) {
    if (level >= x.fromLevel) r = x;
  }
  return r;
}

// ---------------------------------------------------------------- آمار
class StatConfig {
  static const int windowDays = 30, longWindowDays = 90;
  static const double keepThreshold = 0.8; // روزی «حفظ‌شده» است که ≥ این نسبتِ عادت‌های سررسید انجام شده باشد
  static const int minPlannedHabits = 7; // کمتر از این → داده‌ی کافی نیست
  static const int minPlannedTasks = 5;
  static const int focusTargetSessions = 20, focusTargetMinutes = 500;
  static const int readingTargetDays = 12;
  static const int minFocusSessions = 3, minReadingDays = 2;
}

const int maxFeaturedBadges = 6; // یک نشانِ ویژه برای هر دسته (۶ دسته)
