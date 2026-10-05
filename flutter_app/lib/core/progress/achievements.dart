// کاتالوگِ دستاوردها/نشان‌ها/عنوان‌ها/نقاطِ عطف. همه‌چیز داده‌محور است: افزودنِ دستاوردِ تازه = افزودنِ یک خط به [achievementCatalog].
// Achievement = کاری که واقعاً انجام شده؛ Badge = نمایشِ بصریِ همان؛ Title/Milestone روی همین‌ها سوار می‌شوند.
import 'dart:math' as math;

import '../calendar.dart';
import '../doc.dart';
import 'config.dart';
import 'ledger.dart';
import 'stats.dart';

enum BadgeTier { bronze, silver, gold, platinum, legendary }

enum BadgeRarity { common, uncommon, rare, epic, legendary }

class BadgeCategory {
  final String id, nameFa, nameEn;
  final bool pro;
  const BadgeCategory(this.id, this.nameFa, this.nameEn, {this.pro = false});
}

const List<BadgeCategory> badgeCategories = [
  BadgeCategory('consistency', 'استمرار', 'Consistency'),
  BadgeCategory('productivity', 'بهره‌وری', 'Productivity'),
  BadgeCategory('focus', 'تمرکز', 'Focus'),
  BadgeCategory('reading', 'مطالعه', 'Reading'),
  BadgeCategory('challenges', 'چالش‌ها', 'Challenges'),
  BadgeCategory('discipline', 'انضباط', 'Discipline'),
  BadgeCategory('mastery', 'تسلط', 'Mastery'),
  BadgeCategory('reflection', 'مرور', 'Reflection'),
  BadgeCategory('season', 'فصل', 'Season', pro: true),
];

class AchDef {
  final String id, cat, metric, nameFa, nameEn, descFa, descEn;
  final num target;
  final BadgeTier tier;
  final String? titleId;
  final bool pro; // نشانِ فصلی (پرو)؛ دستاوردهای هسته هرگز Paywall نمی‌شوند
  const AchDef(this.id, this.cat, this.tier, this.metric, this.target, this.nameFa, this.nameEn, this.descFa, this.descEn, {this.titleId, this.pro = false});
  BadgeRarity get rarity => BadgeRarity.values[tier.index];
  /// واحدِ نمایشِ پیشرفت (مثلاً «روز»)
  String unitFa() => switch (metric) { 'keptRun' || 'perfectRun' || 'journalDays' || 'deepFocusDays' => 'روز', 'level' => 'سطح', 'consistency30' || 'discipline90' => '٪', 'focusSessions' => 'جلسه', _ => '' };
  String unitEn() => switch (metric) { 'keptRun' || 'perfectRun' || 'journalDays' || 'deepFocusDays' => 'days', 'level' => 'level', 'consistency30' || 'discipline90' => '%', 'focusSessions' => 'sessions', _ => '' };
}

const _b = BadgeTier.bronze, _s = BadgeTier.silver, _g = BadgeTier.gold, _p = BadgeTier.platinum, _l = BadgeTier.legendary;

const List<AchDef> achievementCatalog = [
  // استمرار
  AchDef('first_habit', 'consistency', _b, 'habitCompletions', 1, 'اولین عادت', 'First Habit', 'برای اولین بار یک عادتِ برنامه‌ریزی‌شده را انجام بده.', 'Complete a planned habit for the first time.'),
  AchDef('cons_7', 'consistency', _s, 'keptRun', 7, 'استمرارِ ۷ روزه', '7-Day Consistency', '۷ روزِ متوالی برنامه‌ی عادت‌هایت را حفظ کن.', 'Keep your habit plan for 7 days in a row.', titleId: 'routine_builder'),
  AchDef('cons_30', 'consistency', _g, 'keptRun', 30, 'استمرارِ ۳۰ روزه', '30-Day Consistency', '۳۰ روزِ متوالی برنامه‌ی عادت‌هایت را حفظ کن.', 'Keep your habit plan for 30 days in a row.', titleId: 'the_consistent'),
  AchDef('cons_100', 'consistency', _p, 'keptRun', 100, 'استمرارِ ۱۰۰ روزه', '100-Day Consistency', '۱۰۰ روزِ متوالی برنامه‌ی عادت‌هایت را حفظ کن.', 'Keep your habit plan for 100 days in a row.', titleId: 'veteran_100'),
  AchDef('cons_365', 'consistency', _l, 'keptRun', 365, 'استمرارِ ۳۶۵ روزه', '365-Day Consistency', 'یک سالِ کامل بدونِ وقفه در برنامه بمان.', 'Stay on plan for a full year.', titleId: 'master_consistency'),
  // بهره‌وری
  AchDef('task_1', 'productivity', _b, 'tasks', 1, 'اولین کار', 'First Task', 'اولین کارت را تمام کن.', 'Finish your first task.'),
  AchDef('task_10', 'productivity', _s, 'tasks', 10, '۱۰ کار', '10 Tasks', '۱۰ کار را تمام کن.', 'Finish 10 tasks.'),
  AchDef('task_100', 'productivity', _g, 'tasks', 100, '۱۰۰ کار', '100 Tasks', '۱۰۰ کار را تمام کن.', 'Finish 100 tasks.', titleId: 'the_finisher'),
  AchDef('task_500', 'productivity', _p, 'tasks', 500, '۵۰۰ کار', '500 Tasks', '۵۰۰ کار را تمام کن.', 'Finish 500 tasks.'),
  AchDef('task_1000', 'productivity', _l, 'tasks', 1000, '۱۰۰۰ کار', '1000 Tasks', '۱۰۰۰ کار را تمام کن.', 'Finish 1000 tasks.'),
  // تمرکز
  AchDef('focus_1', 'focus', _b, 'focusSessions', 1, 'اولین پومودورو', 'First Pomodoro', 'اولین جلسه‌ی تمرکز را کامل کن.', 'Complete your first focus session.'),
  AchDef('focus_10', 'focus', _s, 'focusSessions', 10, '۱۰ جلسه‌ی تمرکز', '10 Focus Sessions', '۱۰ جلسه‌ی تمرکز را کامل کن.', 'Complete 10 focus sessions.', titleId: 'focused_mind'),
  AchDef('focus_100', 'focus', _g, 'focusSessions', 100, '۱۰۰ جلسه‌ی تمرکز', '100 Focus Sessions', '۱۰۰ جلسه‌ی تمرکز را کامل کن.', 'Complete 100 focus sessions.'),
  AchDef('deep_focus', 'focus', _p, 'deepFocusDays', 1, 'تمرکزِ عمیق', 'Deep Focus', 'در یک روز ۴ جلسه‌ی تمرکز و دست‌کم ۱۰۰ دقیقه تمرکز داشته باش.', 'In one day: 4 focus sessions and at least 100 focus minutes.', titleId: 'deep_focus'),
  // مطالعه
  AchDef('book_1', 'reading', _b, 'books', 1, 'اولین کتاب', 'First Book', 'اولین کتابت را تمام کن.', 'Finish your first book.'),
  AchDef('book_5', 'reading', _s, 'books', 5, '۵ کتاب', '5 Books', '۵ کتاب را تمام کن.', 'Finish 5 books.', titleId: 'bookworm'),
  AchDef('book_10', 'reading', _g, 'books', 10, '۱۰ کتاب', '10 Books', '۱۰ کتاب را تمام کن.', 'Finish 10 books.'),
  AchDef('book_25', 'reading', _p, 'books', 25, '۲۵ کتاب', '25 Books', '۲۵ کتاب را تمام کن.', 'Finish 25 books.'),
  AchDef('book_100', 'reading', _l, 'books', 100, '۱۰۰ کتاب', '100 Books', '۱۰۰ کتاب را تمام کن.', 'Finish 100 books.'),
  // چالش‌ها
  AchDef('chal_1', 'challenges', _b, 'challenges', 1, 'اولین چالش', 'First Challenge', 'اولین چالشت را با موفقیت تمام کن.', 'Succeed in your first challenge.'),
  AchDef('chal_5', 'challenges', _s, 'challenges', 5, '۵ چالش', '5 Challenges', '۵ چالش را با موفقیت تمام کن.', 'Succeed in 5 challenges.'),
  AchDef('chal_25', 'challenges', _g, 'challenges', 25, '۲۵ چالش', '25 Challenges', '۲۵ چالش را با موفقیت تمام کن.', 'Succeed in 25 challenges.'),
  AchDef('chal_master', 'challenges', _p, 'challenges', 50, 'استادِ چالش', 'Challenge Master', '۵۰ چالش را با موفقیت تمام کن.', 'Succeed in 50 challenges.', titleId: 'challenge_master'),
  // انضباط
  AchDef('perfect_week', 'discipline', _s, 'perfectRun', 7, 'هفته‌ی بی‌نقص', 'Perfect Week', '۷ روزِ متوالی همه‌ی عادت‌های سررسید را انجام بده.', 'Complete every due habit for 7 days in a row.'),
  AchDef('perfect_month', 'discipline', _g, 'perfectRun', 30, 'ماهِ بی‌نقص', 'Perfect Month', '۳۰ روزِ متوالی همه‌ی عادت‌های سررسید را انجام بده.', 'Complete every due habit for 30 days in a row.'),
  AchDef('high_consistency', 'discipline', _g, 'consistency30', 85, 'استمرارِ بالا', 'High Consistency', 'در ۳۰ روزِ اخیر دست‌کم ۸۵٪ برنامه‌ات را انجام بده.', 'Complete at least 85% of your plan over the last 30 days.', titleId: 'the_disciplined'),
  AchDef('long_discipline', 'discipline', _p, 'discipline90', 80, 'انضباطِ بلندمدت', 'Long-Term Discipline', 'امتیازِ انضباطِ ۹۰ روزه‌ات را به ۸۰ برسان.', 'Reach a 90-day discipline score of 80.'),
  // تسلط
  AchDef('level_10', 'mastery', _b, 'level', 10, 'سطح ۱۰', 'Level 10', 'به سطح ۱۰ برس.', 'Reach level 10.'),
  AchDef('level_25', 'mastery', _s, 'level', 25, 'سطح ۲۵', 'Level 25', 'به سطح ۲۵ برس.', 'Reach level 25.'),
  AchDef('level_50', 'mastery', _g, 'level', 50, 'سطح ۵۰', 'Level 50', 'به سطح ۵۰ برس.', 'Reach level 50.'),
  AchDef('level_75', 'mastery', _p, 'level', 75, 'سطح ۷۵', 'Level 75', 'به سطح ۷۵ برس.', 'Reach level 75.'),
  AchDef('level_100', 'mastery', _l, 'level', 100, 'سطح ۱۰۰', 'Level 100', 'به سطح ۱۰۰ برس.', 'Reach level 100.'),
  // مرور
  AchDef('review_1', 'reflection', _b, 'journalDays', 1, 'اولین مرور', 'First Review', 'اولین مرورِ روزانه‌ات را بنویس.', 'Write your first daily review.'),
  AchDef('review_7', 'reflection', _s, 'journalDays', 7, '۷ روز مرور', '7 Review Days', 'در ۷ روزِ مختلف مرورِ روزانه بنویس.', 'Write daily reviews on 7 different days.'),
  AchDef('review_30', 'reflection', _g, 'journalDays', 30, '۳۰ روز مرور', '30 Review Days', 'در ۳۰ روزِ مختلف مرورِ روزانه بنویس.', 'Write daily reviews on 30 different days.'),
  // فصل (پرو)
  AchDef('season_1', 'season', _g, 'seasonsDone', 1, 'اولین فصل', 'First Season', 'یک فصلِ کامل را به پایان برسان.', 'Finish a full season.', pro: true),
  AchDef('season_3', 'season', _p, 'seasonsDone', 3, 'سه فصل', 'Three Seasons', 'سه فصلِ کامل را به پایان برسان.', 'Finish three full seasons.', pro: true),
];

AchDef? achById(String id) {
  for (final a in achievementCatalog) {
    if (a.id == id) return a;
  }
  return null;
}

// ---------------------------------------------------------------- عنوان‌ها
class TitleDef {
  final String id, nameFa, nameEn, achId;
  const TitleDef(this.id, this.nameFa, this.nameEn, this.achId);
}

const List<TitleDef> titleCatalog = [
  TitleDef('routine_builder', 'سازنده‌ی روتین', 'Routine Builder', 'cons_7'),
  TitleDef('the_consistent', 'مستمر', 'The Consistent', 'cons_30'),
  TitleDef('veteran_100', 'کهنه‌کارِ ۱۰۰ روز', '100-Day Veteran', 'cons_100'),
  TitleDef('master_consistency', 'استادِ استمرار', 'Master of Consistency', 'cons_365'),
  TitleDef('the_finisher', 'تمام‌کننده', 'The Finisher', 'task_100'),
  TitleDef('focused_mind', 'ذهنِ متمرکز', 'Focused Mind', 'focus_10'),
  TitleDef('deep_focus', 'تمرکزِ عمیق', 'Deep Focus', 'deep_focus'),
  TitleDef('bookworm', 'کتاب‌خوان', 'Bookworm', 'book_5'),
  TitleDef('challenge_master', 'استادِ چالش', 'Challenge Master', 'chal_master'),
  TitleDef('the_disciplined', 'منضبط', 'The Disciplined', 'high_consistency'),
];

TitleDef? titleById(String? id) {
  for (final t in titleCatalog) {
    if (t.id == id) return t;
  }
  return null;
}

// ---------------------------------------------------------------- نقاطِ عطف (مسیرِ زندگیِ کاربر)
class MilestoneDef {
  final String id, kind, ref, nameFa, nameEn;
  const MilestoneDef(this.id, this.kind, this.ref, this.nameFa, this.nameEn);
}

const List<MilestoneDef> milestoneCatalog = [
  MilestoneDef('start', 'start', '', 'شروع مسیر', 'Journey begins'),
  MilestoneDef('m_habit', 'ach', 'first_habit', 'اولین عادت', 'First habit'),
  MilestoneDef('m_week', 'ach', 'cons_7', 'اولین هفته‌ی موفق', 'First successful week'),
  MilestoneDef('m_book', 'ach', 'book_1', 'اولین کتاب', 'First book'),
  MilestoneDef('m_chal', 'ach', 'chal_1', 'اولین چالش', 'First challenge'),
  MilestoneDef('m_l10', 'ach', 'level_10', 'سطح ۱۰', 'Level 10'),
  MilestoneDef('m_30', 'ach', 'cons_30', '۳۰ روز استمرار', '30-day streak'),
  MilestoneDef('m_l25', 'ach', 'level_25', 'سطح ۲۵', 'Level 25'),
  MilestoneDef('m_100', 'ach', 'cons_100', '۱۰۰ روز استمرار', '100-day streak'),
  MilestoneDef('m_l50', 'ach', 'level_50', 'سطح ۵۰', 'Level 50'),
  MilestoneDef('m_365', 'ach', 'cons_365', 'یک سال استمرار', 'One-year streak'),
  MilestoneDef('m_l100', 'ach', 'level_100', 'سطح ۱۰۰', 'Level 100'),
];

// ---------------------------------------------------------------- متریک‌ها
class MetricCtx {
  final Doc st;
  final DateTime today;
  final int level;
  final Map<String, num> _c = {};
  MetricCtx(this.st, DateTime now, this.level) : today = startOfDay(now);

  num get(String key) => _c.putIfAbsent(key, () => _compute(key));

  Iterable<Map> _ev(String type) => validEvents(st, type: type);

  num _compute(String k) {
    switch (k) {
      case 'habitCompletions':
        return _ev('habit').length;
      case 'tasks':
        return _ev('todo').length;
      case 'focusSessions':
        return _ev('pomodoro').length;
      case 'challenges':
        return _ev('challenge').length;
      case 'journalDays':
        return _ev('journal').length;
      case 'books':
        return (st['books'] is List ? st['books'] as List : const []).where((b) => b is Map && b['completed'] == true).length;
      case 'level':
        return level;
      case 'keptRun':
        return math.max(keptStreak(st, today), bestRuns(st, today).bestKept);
      case 'perfectRun':
        return bestRuns(st, today).bestPerfect;
      case 'consistency30':
        final w = windowOf(today, StatConfig.windowDays, 0);
        return consistencyIn(st, w.from, w.to, today) ?? 0;
      case 'discipline90':
        final w = windowOf(today, StatConfig.longWindowDays, 0);
        final c = consistencyIn(st, w.from, w.to, today);
        return c == null ? 0 : (disciplineIn(st, w.from, w.to, today) ?? 0);
      case 'deepFocusDays':
        final byDay = <String, ({int s, int m})>{};
        for (final e in _ev('pomodoro')) {
          final d = '${e['date']}';
          final cur = byDay[d] ?? (s: 0, m: 0);
          byDay[d] = (s: cur.s + 1, m: cur.m + (((e['minutes'] ?? 0) as num).toInt()));
        }
        return byDay.values.where((x) => x.s >= 4 && x.m >= 100).length;
      case 'seasonsDone':
        return (progressOf(st)['seasons'] as List).length;
    }
    return 0;
  }
}

enum AchState { locked, near, unlocked }

class AchStatus {
  final AchDef def;
  final num value;
  final bool unlocked;
  final int? unlockedAt;
  const AchStatus(this.def, this.value, this.unlocked, this.unlockedAt);
  num get shown => unlocked ? def.target : math.min(value, def.target);
  double get ratio => (shown / def.target).clamp(0, 1).toDouble();
  num get remaining => math.max(0, def.target - value);
  AchState get state => unlocked ? AchState.unlocked : (ratio >= 0.5 ? AchState.near : AchState.locked);
}

/// وضعیتِ همه‌ی دستاوردها (بدونِ نوشتن). unlockedمانده‌ها از state['progress']['unlocked'] خوانده می‌شوند.
List<AchStatus> achievementStatuses(Doc st, MetricCtx ctx) {
  final un = progressOf(st)['unlocked'] as Map;
  return [
    for (final a in achievementCatalog)
      () {
        final rec = un[a.id];
        final v = ctx.get(a.metric);
        final isU = rec is Map || v >= a.target;
        return AchStatus(a, v, isU, rec is Map ? (rec['at'] as num?)?.toInt() : null);
      }()
  ];
}
