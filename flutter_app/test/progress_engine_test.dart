import 'dart:io';
// سیستمِ پیشرفتِ جدید: XP (بدونِ تقلب)، سطح، رتبه، دستاورد/نشان، استریک، فصل، مهاجرت.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/calendar.dart';
import 'package:routine_planner/core/gameplay.dart';
import 'package:routine_planner/core/progress/achievements.dart';
import 'package:routine_planner/core/progress/config.dart';
import 'package:routine_planner/core/progress/engine.dart';
import 'package:routine_planner/core/progress/ledger.dart';
import 'package:routine_planner/core/progress/stats.dart';
import 'package:routine_planner/core/state_model.dart';

final now = DateTime(2026, 9, 30, 14, 0);
String iso(int daysAgo) => dateToISO(addDays(now, -daysAgo));

Map<String, dynamic> habit(String id, {int created = 60, bool important = false}) => {
      'id': id, 'name': id, 'type': 'binary', 'createdAt': iso(created), 'permanent': true, 'scheduleMode': 'daily', 'important': important, 'rewardPoints': 10,
    };

Map<String, dynamic> fresh({int habits = 1}) {
  final st = defaultState();
  st['habits'] = [for (int i = 0; i < habits; i++) habit('h$i')];
  return st;
}

void done(Map<String, dynamic> st, int daysAgo, String hid) => setBinaryRecord(st, iso(daysAgo), hid, 'success');
void undo(Map<String, dynamic> st, int daysAgo, String hid) => setBinaryRecord(st, iso(daysAgo), hid, 'success'); // دوباره زدن = برداشتن

void main() {
  group('منحنیِ سطح و رتبه', () {
    test('۱ تا ۱۰۰، یکنواخت، بدونِ hard-code', () {
      expect(levelForXp(0).level, 1);
      expect(levelForXp(-5).level, 1);
      int prev = 0;
      for (int n = 1; n < maxLevel; n++) {
        expect(levelFloor[n + 1] - levelFloor[n], xpToAdvance(n));
        expect(xpToAdvance(n), greaterThanOrEqualTo(prev));
        prev = xpToAdvance(n);
        expect(levelForXp(levelFloor[n]).level, n);
        expect(levelForXp(levelFloor[n + 1] - 1).level, n);
      }
      expect(levelForXp(levelFloor[maxLevel]).level, maxLevel);
      final over = levelForXp(levelFloor[maxLevel] + 5000);
      expect((over.level, over.maxed, over.toNext), (maxLevel, true, 0));
      final a = levelForXp(levelFloor[27] + 100);
      expect((a.level, a.into, a.toNext), (27, 100, xpToAdvance(27) - 100));
    });
    test('رتبه با سطح هماهنگ و ۹ رتبه', () {
      expect(ranks.length, 9);
      expect(rankForLevel(1).id, 'beginner');
      expect(rankForLevel(100).id, 'grandmaster');
      for (int n = 2; n <= 100; n++) {
        expect(rankForLevel(n).fromLevel, greaterThanOrEqualTo(rankForLevel(n - 1).fromLevel));
      }
    });
  });

  group('XP و ضدِ تقلب', () {
    test('Complete → +10، Undo → بدونِ XP، Complete دوباره → فقط یک رویدادِ معتبر', () {
      final st = fresh();
      syncProgress(st, now); // مهاجرتِ اولیه
      done(st, 0, 'h0');
      syncProgress(st, now);
      expect(totalXp(st), 10);
      undo(st, 0, 'h0');
      syncProgress(st, now);
      expect(totalXp(st), 0, reason: 'Undo باید XP را برگرداند');
      for (int i = 0; i < 5; i++) {
        done(st, 0, 'h0');
        syncProgress(st, now);
        undo(st, 0, 'h0');
        syncProgress(st, now);
      }
      expect(totalXp(st), 0);
      done(st, 0, 'h0');
      syncProgress(st, now);
      expect(totalXp(st), 10);
      expect(eventsOf(st).length, 1, reason: 'همان شناسه؛ رویدادِ تکراری ساخته نمی‌شود');
      expect(eventsOf(st)['habit:h0:${iso(0)}']!['revoked'], isNull);
    });

    test('Refresh / Restart: XP ثابت (سریال‌سازی + چندین sync)', () {
      var st = fresh(habits: 3);
      syncProgress(st, now);
      for (final h in ['h0', 'h1', 'h2']) {
        done(st, 0, h);
        done(st, 1, h);
      }
      for (int i = 0; i < 4; i++) {
        syncProgress(st, now);
      }
      final xp = totalXp(st);
      expect(xp, greaterThan(0));
      for (int i = 0; i < 3; i++) {
        st = jsonDecode(jsonEncode(st)) as Map<String, dynamic>; // ذخیره/بازیابی
        syncProgress(st, now);
        syncProgress(st, now.add(const Duration(minutes: 5)));
        expect(totalXp(st), xp);
      }
    });

    test('عادتِ مهم ۱۵ و عادی ۱۰؛ سقفِ روزانه ۱۵۰', () {
      final st = fresh(habits: 0);
      st['habits'] = [habit('a'), habit('b', important: true)];
      syncProgress(st, now);
      done(st, 0, 'a');
      done(st, 0, 'b');
      syncProgress(st, now);
      expect(validEvents(st, type: 'habit').map((e) => e['amount']).toList()..sort(), [10, 15]);
      final many = fresh(habits: 40);
      syncProgress(many, now);
      for (int i = 0; i < 40; i++) {
        done(many, 0, 'h$i');
      }
      syncProgress(many, now);
      final habitXp = validEvents(many, type: 'habit').fold<int>(0, (a, e) => a + (e['amount'] as int));
      expect(habitXp, lessThanOrEqualTo(XpGuards.dailyXpCap['habit']!));
    });

    test('تغییرِ تاریخ: ثبتِ روزهای قدیمی بعد از شروع XP نمی‌سازد؛ مهاجرتِ اولیه تاریخچه‌ی واقعی را می‌شمارد', () {
      final st = fresh();
      syncProgress(st, now);
      for (int d = 10; d < 20; d++) {
        done(st, d, 'h0');
      }
      syncProgress(st, now);
      expect(validEvents(st, type: 'habit').where((e) => (e['date'] as String).compareTo(iso(3)) < 0), isEmpty);
      // تاریخچه‌ی واقعی قبل از نصبِ سیستمِ جدید
      final old = fresh();
      for (int d = 10; d < 15; d++) {
        done(old, d, 'h0');
      }
      final delta = syncProgress(old, now);
      expect(delta.migrated, true);
      expect(validEvents(old, type: 'habit').length, 5);
      expect(pendingAnnouncements(old).isEmpty, true, reason: 'مهاجرت نباید انیمیشنِ جعلی بسازد');
    });

    test('آینده هرگز XP نمی‌دهد', () {
      final st = fresh();
      syncProgress(st, now);
      setBinaryRecord(st, iso(-3), 'h0', 'success');
      syncProgress(st, now);
      expect(totalXp(st), 0);
    });

    test('حذفِ عادت XPِ کسب‌شده را نمی‌سوزاند، حذف و ساختنِ دوباره هم XP تازه نمی‌دهد', () {
      final st = fresh();
      syncProgress(st, now);
      done(st, 0, 'h0');
      syncProgress(st, now);
      expect(totalXp(st), 10);
      st['habits'] = [];
      (st['records'] as Map).clear();
      syncProgress(st, now);
      expect(totalXp(st), 10);
      st['habits'] = [habit('h0')]; // همان شناسه ولی بدونِ رکورد
      syncProgress(st, now);
      expect(totalXp(st), 0, reason: 'عادت هست ولی انجام نشده → XP برنمی‌گردد');
    });

    test('کارِ جعلی: ساخت و فوراً تیک نمی‌دهد؛ سقفِ روزانه؛ عنوانِ تکراری؛ Undo', () {
      final st = fresh(habits: 0);
      syncProgress(st, now);
      final t0 = now.millisecondsSinceEpoch;
      final log = <dynamic>[];
      st['todoLog'] = log;
      log.add({'id': 'a', 'todoId': 't1', 'title': 'خریدِ نان', 'at': t0, 'createdAt': t0 - 5000});
      syncProgress(st, now);
      expect(totalXp(st), 0, reason: 'کمتر از یک دقیقه پس از ساخت');
      log.clear();
      log.add({'id': 'a', 'todoId': 't1', 'title': 'خریدِ نان', 'at': t0, 'createdAt': t0 - 120000});
      syncProgress(st, now);
      expect(totalXp(st), XpRules.todo);
      log.clear(); // Undo: ورودی از لاگ حذف می‌شود
      syncProgress(st, now);
      expect(totalXp(st), 0);
      log.add({'id': 'b', 'todoId': 't1', 'title': 'خریدِ نان', 'at': t0 + 1000, 'createdAt': t0 - 120000});
      syncProgress(st, now);
      expect(totalXp(st), XpRules.todo, reason: 'Complete دوباره: یک XP، نه دو تا');
      for (int i = 0; i < 30; i++) {
        log.add({'id': 'x$i', 'todoId': 'x$i', 'title': 'کار شماره $i', 'at': t0 + 2000 + i, 'createdAt': t0 - 999999});
      }
      log.add({'id': 'dup', 'todoId': 'q', 'title': 'خریدِ نان', 'at': t0 + 9000, 'createdAt': t0 - 999999});
      syncProgress(st, now);
      expect(validEvents(st, type: 'todo').length, XpGuards.dailyEventCap['todo']);
      log.add({'id': 'short', 'todoId': 'z', 'title': 'ab', 'at': t0 + 9500, 'createdAt': t0 - 999999});
      final before = totalXp(st);
      syncProgress(st, now);
      expect(totalXp(st), before);
    });

    test('پومودورو: حداقلِ دقیقه، پله‌های XP و سقف؛ Start/Stop بدونِ جلسه XP ندارد', () {
      final st = fresh(habits: 0);
      syncProgress(st, now);
      final t0 = now.millisecondsSinceEpoch;
      st['pomodoro'] = {'log': [
        {'id': 'p1', 'at': t0, 'minutes': 3}, // کوتاه
        {'id': 'p2', 'at': t0 + 1, 'minutes': 25},
        {'id': 'p3', 'at': t0 + 2, 'minutes': 50},
        {'id': 'p4', 'at': t0 + 3, 'minutes': 90},
      ]};
      syncProgress(st, now);
      expect(totalXp(st), 10 + 15 + 20);
      syncProgress(st, now);
      expect(totalXp(st), 45);
    });

    test('مطالعه: فقط صفحه‌ی تازه (بیشینه‌ی قبلی)؛ بالا/پایین کردنِ مجموع تقلب نیست', () {
      final st = fresh(habits: 0);
      syncProgress(st, now);
      final t0 = now.millisecondsSinceEpoch;
      st['books'] = [
        {'id': 'b1', 'title': 'x', 'totalPages': 300, 'pagesRead': 120, 'completed': false, 'history': [
          {'date': t0, 'pagesRead': 50, 'delta': 50},
          {'date': t0 + 10, 'pagesRead': 0, 'delta': -50},
          {'date': t0 + 20, 'pagesRead': 50, 'delta': 50},
          {'date': t0 + 30, 'pagesRead': 120, 'delta': 70},
        ]}
      ];
      syncProgress(st, now);
      final ev = validEvents(st, type: 'library').single;
      expect(ev['meta']['pages'], 120);
      expect(ev['amount'], 5 + 12 > XpRules.libraryMax ? XpRules.libraryMax : 17);
    });

    test('چالش: دست‌کم یک ساعت؛ مدالِ قدیمی هم شمرده می‌شود؛ ساخت/حذف سودی ندارد', () {
      final st = fresh(habits: 0);
      syncProgress(st, now);
      final t0 = now.millisecondsSinceEpoch;
      st['challenges'] = [
        {'id': 'c1', 'status': 'success', 'createdAt': t0 - 1000, 'completedAt': t0}, // آنی
        {'id': 'c2', 'status': 'success', 'createdAt': t0 - 10 * 86400000, 'completedAt': t0},
      ];
      st['medals'] = [{'challengeId': 'old', 'at': t0 - 5000}];
      syncProgress(st, now);
      final ids = validEvents(st, type: 'challenge').map((e) => e['sourceId']).toSet();
      expect(ids, {'c2', 'old'});
      st['challenges'] = []; // حذف
      syncProgress(st, now);
      expect(validEvents(st, type: 'challenge').length, 2);
    });

    test('مرورِ روزانه: حداقل طول و فقط یک بار در روز', () {
      final st = fresh(habits: 0);
      syncProgress(st, now);
      final t0 = now.millisecondsSinceEpoch;
      st['journal'] = [
        {'id': 'j1', 'text': 'کوتاه', 'createdAt': t0},
        {'id': 'j2', 'text': 'امروز روز خوبی بود و کارهایم را انجام دادم', 'createdAt': t0},
        {'id': 'j3', 'text': 'یک یادداشتِ طولانیِ دیگر برای همین روز', 'createdAt': t0 + 10},
      ];
      syncProgress(st, now);
      expect(validEvents(st, type: 'journal').length, 1);
      expect(totalXp(st), XpRules.journal);
    });
  });

  group('استریک', () {
    test('استمرار، شکستن و شروعِ دوباره؛ XP حذف نمی‌شود', () {
      final st = fresh();
      for (int d = 1; d <= 7; d++) {
        done(st, d, 'h0');
      }
      syncProgress(st, now);
      expect(keptStreak(st, now), 7, reason: 'امروزِ ناتمام استریک را نمی‌شکند');
      expect(eventsOf(st).keys.any((k) => k == 'streak:7'), true);
      final xp = totalXp(st);
      // یک روز جا می‌افتد → شکست
      undo(st, 3, 'h0');
      syncProgress(st, now);
      expect(keptStreak(st, now), 2);
      expect(totalXp(st), greaterThanOrEqualTo(xp - XpRules.habit - XpRules.dailyBonus - 1), reason: 'بونوسِ استمرارِ قبلی نمی‌سوزد');
      expect(eventsOf(st)['streak:7']!['revoked'], isNull);
      done(st, 0, 'h0');
      syncProgress(st, now);
      expect(keptStreak(st, now), 3);
      expect(bestRuns(st, now).bestKept, 4);
    });
  });

  group('دستاوردها', () {
    test('اولین عادت: قفل → باز؛ تاریخِ دریافت؛ Undo بعدی نشان را نمی‌گیرد', () {
      final st = fresh();
      syncProgress(st, now);
      var s = achievementStatuses(st, MetricCtx(st, now, 1)).firstWhere((a) => a.def.id == 'first_habit');
      expect(s.state, AchState.locked);
      done(st, 0, 'h0');
      final d = syncProgress(st, now);
      expect(d.newBadges, contains('first_habit'));
      expect(pendingAnnouncements(st).badges, contains('first_habit'));
      markAnnounced(st);
      expect(pendingAnnouncements(st).isEmpty, true);
      final at = (progressOf(st)['unlocked'] as Map)['first_habit']['at'];
      undo(st, 0, 'h0');
      syncProgress(st, now.add(const Duration(days: 1)));
      s = achievementStatuses(st, MetricCtx(st, now, 1)).firstWhere((a) => a.def.id == 'first_habit');
      expect(s.unlocked, true);
      expect(s.unlockedAt, at);
    });

    test('پیشرفت و Near Unlock', () {
      final st = fresh();
      for (int d = 1; d <= 5; d++) {
        done(st, d, 'h0');
      }
      syncProgress(st, now);
      final c7 = achievementStatuses(st, MetricCtx(st, now, 1)).firstWhere((a) => a.def.id == 'cons_7');
      expect((c7.shown, c7.remaining, c7.state), (5, 2, AchState.near));
      expect(c7.ratio, closeTo(5 / 7, 1e-9));
    });

    test('کاتالوگ: شناسه‌ها یکتا، دقیقاً ۴۸ نشان (شیتِ ۶×۸) با تصویرِ متناظر', () {
      final ids = achievementCatalog.map((a) => a.id).toSet();
      expect(ids.length, achievementCatalog.length);
      expect(achievementCatalog.length, 48);
      for (int i = 0; i < 48; i++) {
        expect(badgeArt(achievementCatalog[i]), i + 1);
        expect(File('assets/badges/badge_${(i + 1).toString().padLeft(2, '0')}.png').existsSync(), true, reason: 'badge_${i + 1}');
        // آخرِ هر ردیف «تاج» (Legendary) است
        if ((i + 1) % 8 == 0) expect(achievementCatalog[i].tier, BadgeTier.legendary);
      }
      for (final c in ['consistency', 'productivity', 'focus', 'reading', 'discipline', 'mastery']) {
        expect(achievementCatalog.any((a) => a.cat == c), true, reason: c);
      }
      for (final a in achievementCatalog) {
        expect(badgeCategories.any((c) => c.id == a.cat), true);
        expect(a.target, greaterThan(0));
        if (a.titleId != null) expect(titleById(a.titleId), isNotNull);
      }
      for (final t in titleCatalog) {
        expect(achById(t.achId), isNotNull);
      }
      for (final m in milestoneCatalog.where((m) => m.kind == 'ach')) {
        expect(achById(m.ref), isNotNull);
      }
    });

    test('سطح ۱۰: نشانِ تسلط از XP واقعی؛ Level-up چندمرحله‌ای', () {
      final st = fresh(habits: 0);
      syncProgress(st, now);
      final t0 = now.millisecondsSinceEpoch;
      // XPِ واقعی از جلسه‌های تمرکز در روزهای مختلف (سقفِ روزانه رعایت می‌شود)
      final log = <dynamic>[];
      st['pomodoro'] = {'log': log};
      for (int d = 0; d < 60; d++) {
        for (int k = 0; k < 12; k++) {
          log.add({'id': 'p${d}_$k', 'at': t0 - d * 86400000 + k, 'minutes': 60});
        }
      }
      final delta = syncProgress(st, now);
      expect(totalXp(st), 60 * 12 * 20);
      final lv = levelForXp(totalXp(st)).level;
      expect(lv, greaterThan(10));
      expect(delta.levelAfter, lv);
      expect(progressOf(st)['unlocked'], contains('level_10'));
    });
  });

  group('فصل (پرو) و انتخاب‌های کاربر', () {
    test('فصل فقط پرو؛ XP فصل جدا؛ بایگانی و حذف نشدنِ دائمی‌ها', () {
      final st = fresh();
      expect(startSeason(st, now, 30), false);
      st['isPremium'] = true;
      syncProgress(st, now);
      expect(startSeason(st, now, 45), false);
      expect(startSeason(st, now, 30), true);
      expect(startSeason(st, now, 30), false);
      done(st, 0, 'h0');
      syncProgress(st, now);
      final p = progressOf(st);
      final inSeason = xpBetween(st, (p['season'] as Map)['start'], (p['season'] as Map)['end']);
      expect(inSeason, totalXp(st));
      final later = now.add(const Duration(days: 40));
      syncProgress(st, later);
      expect(progressOf(st)['season'], isNull);
      expect((progressOf(st)['seasons'] as List).single['xp'], inSeason);
      expect(totalXp(st), inSeason, reason: 'XP دائمی با پایانِ فصل حذف نمی‌شود');
      expect((progressOf(st)['unlocked'] as Map).containsKey('first_habit'), true);
    });

    test('عنوان و نشان‌های ویژه (حداکثر ۳، فقط باز‌شده‌ها)', () {
      final st = fresh();
      done(st, 0, 'h0');
      syncProgress(st, now);
      expect(setActiveTitle(st, 'the_consistent'), false);
      expect(toggleFeatured(st, 'cons_7'), false);
      expect(toggleFeatured(st, 'first_habit'), true);
      final un = progressOf(st)['unlocked'] as Map;
      for (final id in ['level_10', 'task_1', 'focus_1']) {
        un[id] = {'at': 1, 'date': iso(0)};
      }
      expect(toggleFeatured(st, 'task_1'), true);
      expect(toggleFeatured(st, 'focus_1'), true);
      expect(toggleFeatured(st, 'level_10'), false, reason: 'سقفِ ۳');
      un['cons_7'] = {'at': 1, 'date': iso(0)};
      expect(setActiveTitle(st, 'routine_builder'), true);
      expect(snapshotOf(st, now).title!.id, 'routine_builder');
      expect(toggleFeatured(st, 'first_habit'), true); // برداشتن
      expect(snapshotOf(st, now).featured.length, 2);
    });
  });

  group('آمار (داده‌ی واقعی، بدونِ عددِ ساختگی)', () {
    test('بدونِ داده: همه null؛ با داده: مقدار + دوره‌ی قبل + تغییر', () {
      final empty = fresh(habits: 0);
      final s0 = computeStats(empty, now);
      expect(s0.hasAny, false);
      expect(s0.consistency.value, isNull);
      final st = fresh();
      for (int d = 1; d <= 29; d++) {
        if (d % 5 != 0) done(st, d, 'h0'); // ۳۰ روزِ اخیر ≈ ۸۰٪
      }
      for (int d = 31; d <= 59; d++) {
        if (d % 2 == 0) done(st, d, 'h0'); // دوره‌ی قبل ≈ ۵۰٪
      }
      final s = computeStats(st, now);
      expect(s.consistency.value, isNotNull);
      expect(s.consistency.previous, isNotNull);
      expect(s.consistency.change, s.consistency.value! - s.consistency.previous!);
      expect(s.consistency.value!, greaterThan(s.consistency.previous!));
      expect(s.productivity.value, isNull);
      expect(s.focus.value, isNull);
      expect(s.reading.value, isNull);
      expect(s.discipline.value, isNotNull);
    });
  });
}
