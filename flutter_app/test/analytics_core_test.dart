// تحلیلِ پایه و هوشمند: ۱۰ حالتِ خواسته‌شده با داده‌ی واقعی؛ هیچ‌جا عددِ ساختگی نباید تولید شود.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/analytics.dart';
import 'package:routine_planner/core/calendar.dart';
import 'package:routine_planner/core/habits.dart';
import 'package:routine_planner/core/smart.dart';
import 'package:routine_planner/core/smart_extras.dart';
import 'package:routine_planner/core/state_model.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';

Map<String, dynamic> habit(String id, String created, {bool permanent = true, String type = 'binary', Map<String, dynamic> extra = const {}}) =>
    {'id': id, 'name': 'عادت $id', 'type': type, 'direction': 'more', 'permanent': permanent, 'createdAt': created, 'priority': 'yellow', 'scheduleMode': 'daily', 'activeDays': <int>[], ...extra};

Map<String, dynamic> stateWith(List<Map<String, dynamic>> habits, Map<String, Map<String, dynamic>> records, {String cal = 'gregorian', String lang = 'fa'}) {
  final st = defaultState();
  st['calendarType'] = cal;
  st['lang'] = lang;
  st['habits'] = habits;
  st['records'] = {for (final e in records.entries) e.key: Map<String, dynamic>.from(e.value)};
  return st;
}

String iso(int y, int m, int d) => dateToISO(DateTime(y, m, d));

void main() {
  final today = DateTime(2026, 9, 30, 14, 30); // چهارشنبه

  test('Case 1: هیچ داده‌ای نیست ← هیچ عددی ساخته نمی‌شود', () {
    final st = stateWith([], {});
    for (final r in ['week', 'month', 'year']) {
      final rep = buildRangeReport(st, r, today);
      expect(rep.total.due, 0);
      expect(rep.completion, isNull);
      expect(rep.pointsWithData, 0);
    }
    expect(recordedHabitDays(st), 0);
    final cur = saCompute(st, saPeriod('month', 0, today));
    expect(smartStatus(cur), SmartStatus.insufficient);
    expect(smartFindings(st, cur, saCompute(st, saPeriod('month', 1, today)), today, true), isEmpty);
    // عادتِ تازه‌ساخته‌شده‌ی بدون ثبت: امروزِ ثبت‌نشده شمرده نمی‌شود ← null (نه ۰٪)
    final st2 = stateWith([habit('a', '2026-09-30')], {});
    expect(habitCompletionPct(st2, st2['habits'][0] as Map, today), isNull);
    expect(buildRangeReport(st2, 'week', today).completion, isNull);
    expect(computeStreak(st2, today), 0);
  });

  test('Case 2: یک عادت فقط در یک روز (امروز) انجام شده', () {
    for (final cal in ['gregorian', 'jalali']) {
      final st = stateWith([habit('a', '2026-09-30')], {'2026-09-30': {'a': 'success'}}, cal: cal);
      expect(tallyDay(st, today, today), (due: 1, success: 1, fail: 0, unset: 0));
      for (final r in ['week', 'month', 'year']) {
        final rep = buildRangeReport(st, r, today);
        expect(rep.total, (due: 1, success: 1, fail: 0, unset: 0), reason: '$cal $r');
        expect(rep.completion, 100);
        expect(rep.pointsWithData, 1);
      }
      expect(habitCompletionPct(st, st['habits'][0] as Map, today), 100);
      expect(computeStreak(st, today), 1);
      // یک ثبتِ تک‌روزه برای تحلیل هوشمند کافی نیست
      final cur = saCompute(st, saPeriod('week', 0, today));
      expect(smartStatus(cur), SmartStatus.insufficient);
      expect(smartFindings(st, cur, saCompute(st, saPeriod('week', 1, today)), today, true), isEmpty);
    }
  });

  test('Case 3: چند روزِ متوالی انجام شده', () {
    final recs = {for (int d = 24; d <= 30; d++) iso(2026, 9, d): {'a': 'success'}};
    final st = stateWith([habit('a', '2026-09-24')], recs);
    expect(computeStreak(st, today), 7);
    expect(computeHabitStreak(st, st['habits'][0] as Map, today), 7);
    expect(habitCompletionPct(st, st['habits'][0] as Map, today), 100);
    final month = buildRangeReport(st, 'month', today);
    expect(month.total, (due: 7, success: 7, fail: 0, unset: 0)); // پیش از ۲۴ام عادتی وجود نداشت
    expect(month.completion, 100);
    expect(month.pointsWithData, 7);
    expect(month.days.where((d) => d.future).length, 0); // ۳۰ سپتامبر آخرین روز است
  });

  test('Case 4: یک روز انجام نشده (شکست) و یک روزِ ثبت‌نشده', () {
    final recs = {
      for (int d = 24; d <= 30; d++) iso(2026, 9, d): {'a': d == 27 ? 'fail' : 'success'},
    }..remove('2026-09-26'); // ۲۶ام اصلاً ثبت نشده
    final st = stateWith([habit('a', '2026-09-24')], recs);
    final t = buildRangeReport(st, 'month', today).total;
    expect(t, (due: 7, success: 5, fail: 1, unset: 1)); // ثبت‌نشده = جاافتاده، نه موفق
    expect(buildRangeReport(st, 'month', today).completion, 71); // ۵ ÷ ۷
    expect(habitCompletionPct(st, st['habits'][0] as Map, today), 71);
    expect(computeStreak(st, today), 3); // ۲۸، ۲۹، ۳۰
    final cur = saCompute(st, saPeriod('month', 0, today));
    expect(cur.succ, 5);
    expect(cur.fail, 1);
    expect(cur.rate, closeTo(5 / 6, 1e-9)); // «موفقیت» فقط روی ثبت‌شده‌ها
    // نتیجه‌ی قطعیِ ساختگی نمی‌دهد: ۶ ثبت = «محدود»؛ یافته‌ها فقط واقعی‌اند (استریک ۳)
    expect(smartStatus(cur), SmartStatus.limited);
    final f = smartFindings(st, cur, saCompute(st, saPeriod('month', 1, today)), today, true);
    expect(f.every((x) => !x.text.contains('پشت‌سرهم ناموفق')), isTrue);
    expect(f.any((x) => x.text.contains('استریکِ فعلی')), isTrue);
  });

  test('Case 5: داده‌ی ماه قبل و ماه جاری قاطی نمی‌شوند (میلادی و جلالی)', () {
    final recs = <String, Map<String, dynamic>>{
      for (int d = 1; d <= 31; d++) iso(2026, 8, d): {'a': 'success'},
      for (int d = 1; d <= 15; d++) iso(2026, 9, d): {'a': 'success'},
      for (int d = 16; d <= 20; d++) iso(2026, 9, d): {'a': 'fail'},
    };
    final h = [habit('a', '2026-08-01')];
    final g = stateWith(h, recs);
    final sep = buildRangeReport(g, 'month', today);
    // امروز (۳۰ام) ثبت نشده ← شمرده نمی‌شود: ۲۹ روز، ۹ روزِ جاافتاده
    expect(sep.total, (due: 29, success: 15, fail: 5, unset: 9));
    expect(sep.completion, 52); // ۱۵ ÷ ۲۹
    final year = buildRangeReport(g, 'year', today);
    expect(year.total, (due: 60, success: 46, fail: 5, unset: 9));
    expect(year.days[7].pct, 100); // اوت
    expect(year.days[8].pct, 52); // سپتامبر
    expect(year.days[9].pct, isNull); // ماه‌های آینده داده ندارند
    // جلالی: ماهِ جلالیِ جاری از ۱ مهر ۱۴۰۵ (= ۲۳ سپتامبر ۲۰۲۶) تا امروز
    final j = stateWith(h, recs, cal: 'jalali');
    final mehr = buildRangeReport(j, 'month', today);
    final jt = toJalaali(2026, 9, 30);
    final first = toGregorian(jt.jy, jt.jm, 1);
    final days = today.difference(DateTime(first.gy, first.gm, first.gd)).inDays; // امروزِ ثبت‌نشده شمرده نمی‌شود
    expect(mehr.total.due, days);
    expect(mehr.total.success + mehr.total.fail + mehr.total.unset, days);
    // مهر شاملِ هیچ‌کدام از روزهای اوت نیست
    expect(mehr.total.success, lessThanOrEqualTo(days));
    expect(buildRangeReport(j, 'year', today).days.length, 12);
  });

  test('Case 6: عادتِ حذف‌شده از تحلیل بیرون می‌رود و عادتِ دیگر دست‌نخورده می‌ماند', () {
    final dir = Directory.systemTemp.createTempSync('rp_c6');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus(), clock: () => today);
    store.state['calendarType'] = 'gregorian';
    store.state['habits'] = [habit('a', '2026-09-28'), habit('b', '2026-09-28')];
    store.state['records'] = {
      '2026-09-29': {'a': 'success', 'b': 'fail'},
      '2026-09-30': {'a': 'success', 'b': 'success'},
    };
    final before = buildRangeReport(store.state, 'week', today).total;
    expect(before, (due: 6, success: 3, fail: 1, unset: 2)); // ۲۸ام: هیچ‌کدام ثبت نشده
    a.deleteHabit('a');
    final after = buildRangeReport(store.state, 'week', today).total;
    expect(after, (due: 3, success: 1, fail: 1, unset: 1));
    expect(recordedHabitDays(store.state), 2);
    expect((store.state['records'] as Map).values.every((d) => !(d as Map).containsKey('a')), isTrue);
    final cur = saCompute(store.state, saPeriod('week', 0, today));
    expect(cur.byHabit.keys, ['b']);
  });

  test('Case 7: عادتِ ویرایش‌شده — هدفِ قدیمی روی ثبت‌های گذشته قفل است', () {
    final dir = Directory.systemTemp.createTempSync('rp_c7');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus(), clock: () => today);
    store.state['calendarType'] = 'gregorian';
    store.state['habits'] = [habit('n', '2026-09-20', type: 'numeric', extra: {'numericTarget': 10, 'numericUnit': 'بار'})];
    store.state['records'] = {
      '2026-09-25': {'n': {'value': '12', 'targetAtTime': 10}},
    };
    expect(habitSuccessOnISO(store.state, store.state['habits'][0] as Map, '2026-09-25'), true);
    // ویرایش: هدف ۵۰ می‌شود
    final h = store.state['habits'][0] as Map;
    final f = HabitForm.from(h)..numericTarget = 50;
    a.saveHabit(f, editingId: 'n');
    expect(habitSuccessOnISO(store.state, store.state['habits'][0] as Map, '2026-09-25'), true, reason: 'ثبتِ قدیمی باید با هدفِ قدیمی بسنجیده شود');
    (store.state['records'] as Map)['2026-09-30'] = {'n': {'value': '12', 'targetAtTime': 50}};
    expect(habitSuccessOnISO(store.state, store.state['habits'][0] as Map, '2026-09-30'), false);
    // تغییرِ فقط نام: آمار تغییر نمی‌کند
    final before = buildRangeReport(store.state, 'month', today).total;
    a.saveHabit(HabitForm.from(store.state['habits'][0] as Map)..name = 'نام تازه', editingId: 'n');
    expect(buildRangeReport(store.state, 'month', today).total, before);
    expect((store.state['habits'] as List).single['createdAt'], '2026-09-20'); // createdAt حفظ می‌شود
    // تغییرِ برنامه به گذشته هم اعمال می‌شود (مستند): فقط روزهای فعال شمرده می‌شوند
    final f2 = HabitForm.from(store.state['habits'][0] as Map)
      ..scheduleMode = 'custom'
      ..activeDays = [0]; // فقط شنبه
    a.saveHabit(f2, editingId: 'n');
    final t = buildRangeReport(store.state, 'month', today).total;
    expect(t.due, lessThan(before.due));
  });

  test('Case 8: تاریخ/منطقه‌ی زمانی — شروع/پایانِ DST، ساعتِ روز و هم‌ارزی', () {
    // بهار (جلو رفتن ساعت ۲۹ مارس برلین) و پاییز (عقب رفتن ۲۵ اکتبر)
    for (final c in [
      (created: DateTime(2026, 3, 20), today: DateTime(2026, 3, 31, 9, 15), n: 12),
      (created: DateTime(2026, 10, 20), today: DateTime(2026, 10, 27, 23, 59, 59), n: 8),
    ]) {
      final recs = <String, Map<String, dynamic>>{};
      for (var d = c.created; !d.isAfter(c.today); d = addDays(d, 1)) {
        recs[dateToISO(d)] = {'a': 'success'};
      }
      final st = stateWith([habit('a', dateToISO(c.created))], recs);
      expect(habitCompletionPct(st, st['habits'][0] as Map, c.today), 100);
      expect(computeStreak(st, c.today), c.n, reason: 'هیچ روزی در گذار DST گم/تکراری نشود');
      final rep = buildRangeReport(st, 'year', c.today);
      expect(rep.total.due, c.n);
      expect(rep.total.success, c.n);
      // ساعتِ روز نباید نتیجه را عوض کند
      expect(tallyDay(st, DateTime(c.today.year, c.today.month, c.today.day, 0, 0, 1), c.today), tallyDay(st, DateTime(c.today.year, c.today.month, c.today.day, 23, 59, 59), c.today));
    }
    // رشته‌ی روز محلی است: ۲۳:۵۹ و ۰۰:۰۱ دو روزِ متفاوتِ شمارش
    expect(dateToISO(DateTime(2026, 9, 30, 23, 59)), '2026-09-30');
    expect(dateToISO(DateTime(2026, 10, 1, 0, 1)), '2026-10-01');
    // آینده هرگز شمرده نمی‌شود
    final st = stateWith([habit('a', '2026-09-01')], {'2026-10-05': {'a': 'success'}});
    expect(tallyDay(st, DateTime(2026, 10, 5), today).due, 0);
    expect(buildRangeReport(st, 'month', today).total.success, 0);
  });

  test('برچسب‌های هفته از روزِ واقعی می‌آیند (شروع هفته از یکشنبه هم درست است)', () {
    final st = stateWith([habit('a', '2026-09-01')], {}, lang: 'en');
    st['weekStart'] = 1; // یکشنبه
    final rep = buildRangeReport(st, 'week', today);
    expect(rep.days.first.label, 'Su');
    expect(rep.days.last.label, 'Sa');
    st['weekStart'] = 0;
    final w0 = buildRangeReport(st, 'week', today);
    expect(w0.days.first.label, 'Sa'); // ۰ = شنبه
    expect(w0.days.first.date, DateTime(2026, 9, 26)); // شنبه‌ی هفته‌ی ۳۰ سپتامبر ۲۰۲۶ (چهارشنبه)
    expect(dateToISO(getWeekStart(st, today)), '2026-09-26');
    st['weekStart'] = 1;
    expect(dateToISO(getWeekStart(st, today)), '2026-09-27'); // یکشنبه
    // سال: نامِ ماهِ جلالی در انگلیسی «Far…» است نه ماهِ میلادی
    final j = stateWith([habit('a', '2026-09-01')], {}, cal: 'jalali', lang: 'en');
    expect(buildRangeReport(j, 'year', today).days.first.label, 'Far');
  });

  group('Case 9/10: کاربر Free و Pro', () {
    Future<void> boot(WidgetTester tester, {required bool pro}) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final dir = Directory.systemTemp.createTempSync('rp_c9');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = AppStore('${dir.path}/s.json')..load();
      final now = DateTime(2026, 9, 30, 14, 30);
      final a = AppActions(store, ToastBus(), clock: () => now);
      store.state['isPremium'] = pro;
      store.state['calendarType'] = 'gregorian';
      a.saveHabit(HabitForm('2026-09-01')..name = 'ورزش');
      final hid = (store.state['habits'] as List).first['id'] as String;
      for (int d = 1; d <= 29; d++) {
        ((store.state['records'] as Map).putIfAbsent(iso(2026, 9, d), () => <String, dynamic>{}) as Map)[hid] = d % 4 == 0 ? 'fail' : 'success';
      }
      a.renderAll();
      final nav = NavController()..go(AppView.smart);
      await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: a.toasts, actions: a));
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('Free: قفل و توضیحِ Pro، بدون هیچ نتیجه‌ی تحلیلی', (tester) async {
      await boot(tester, pro: false);
      expect(find.byKey(const ValueKey('pro-notice-smartAnalysis')), findsOneWidget);
      expect(find.byKey(const ValueKey('pro-cta')), findsOneWidget);
      expect(find.byKey(const ValueKey('smart-score')), findsNothing);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Pro: امتیاز و تحلیل از دادهٔ واقعی، بدون هیچ پیام/قفل/CTA ی پرو', (tester) async {
      await boot(tester, pro: true);
      expect(find.byKey(const ValueKey('pro-notice-smartAnalysis')), findsNothing);
      expect(find.byKey(const ValueKey('pro-cta')), findsNothing);
      expect(find.byKey(const ValueKey('smart-score')), findsOneWidget);
      expect(find.byKey(const ValueKey('smart-insufficient')), findsNothing);
      expect(find.textContaining('از امکانات پرو'), findsNothing);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
