// سیستمِ پیشرفتِ جدید در برنامه: اتصال به عملیات، پروفایل، صفحه‌ی پیشرفت، مجموعه‌ی نشان‌ها، انیمیشن‌ها، Free/Pro، Backup.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
export 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/backup.dart';
import 'package:routine_planner/core/progress/engine.dart';
import 'package:routine_planner/core/progress/ledger.dart';
import 'package:routine_planner/core/state_model.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/data/pomodoro_ops.dart';
import 'package:routine_planner/data/todo_ops.dart';
import 'package:routine_planner/ui/widgets.dart';

final base = DateTime(2026, 9, 30, 14);

Future<(AppStore, AppActions, NavController)> boot(WidgetTester tester, {AppView view = AppView.dashboard, bool pro = false, Size size = const Size(1080, 2400), void Function(AppStore, AppActions)? prep, String lang = 'fa', bool dismiss = true}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final dir = Directory.systemTemp.createTempSync('rp_pg');
  addTearDown(() => dir.deleteSync(recursive: true));
  final store = AppStore('${dir.path}/s.json')..load();
  store.state['isPremium'] = pro;
  store.state['lang'] = lang;
  final a = AppActions(store, ToastBus(), clock: () => base);
  prep?.call(store, a);
  a.renderAll(); // مثل main: مهاجرتِ اولیه
  final nav = NavController()..go(view);
  await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: a.toasts, actions: a));
  await tester.pump(const Duration(milliseconds: 700));
  // دستاوردهایی که با داده‌ی آماده باز شدند (انیمیشنِ ظریف) را مثلِ کاربر می‌بندیم
  for (int i = 0; dismiss && i < 12 && find.byKey(const ValueKey('reveal-ok')).evaluate().isNotEmpty; i++) {
    await tester.tap(find.byKey(const ValueKey('reveal-ok')).last);
    await tester.pump(const Duration(milliseconds: 800));
  }
  return (store, a, nav);
}

Future<void> drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpWidget(const SizedBox());
}

String iso(int ago) => base.subtract(Duration(days: ago)).toIso8601String().substring(0, 10);

String addHabit(AppActions a, String name) => a.saveHabit(HabitForm(a.todayISO)..name = name)!;

Future<void> tapT(WidgetTester tester, String text) async {
  final any = find.text(text);
  if (any.evaluate().isEmpty) await tester.scrollUntilVisible(any, 300, scrollable: find.byType(Scrollable).first);
  final f = any.first;
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 150));
  final w = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  for (int i = 0; i < 4 && (tester.getCenter(f).dx < 8 || tester.getCenter(f).dx > w - 8); i++) {
    // ردیفِ افقیِ چیپ‌ها: به سمتِ مورد بکش
    final rows = find.ancestor(of: f, matching: find.byType(SingleChildScrollView));
    if (rows.evaluate().isEmpty) break;
    final row = rows.first;
    await tester.drag(row, Offset(tester.getCenter(f).dx < 8 ? 160 : -160, 0));
    await tester.pump(const Duration(milliseconds: 200));
  }
  final chip = find.ancestor(of: f, matching: find.byType(ChoiceChip));
  await tester.tap(chip.evaluate().isNotEmpty ? chip.first : f);
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> vis(WidgetTester tester, Finder f) async {
  if (f.evaluate().isNotEmpty) return;
  try {
    await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first, maxScrolls: 40);
  } catch (_) {
    await tester.scrollUntilVisible(f, -300, scrollable: find.byType(Scrollable).first, maxScrolls: 80);
  }
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await vis(tester, f);
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -140)); // از زیرِ نوارِ شناور بالا بیاید
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tapAt(tester.getTopLeft(f) + const Offset(60, 24)); // سرِ کارتِ بسته
  await tester.pump(const Duration(milliseconds: 450));
}

void main() {
  group('اتصال به عملیاتِ واقعی', () {
    test('کار: انجام +XP؛ Undo برمی‌گرداند؛ انجامِ دوباره فقط یک XP؛ کارِ آنی XP ندارد', () {
      final dir = Directory.systemTemp.createTempSync('rp_t');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = AppStore('${dir.path}/s.json')..load();
      var t = DateTime.now();
      final a = AppActions(store, ToastBus(), clock: () => t);
      a.renderAll();
      final todo = a.addTodo('خرید نان و میوه')!;
      final id = todo['id'] as String;
      a.toggleTodo(id); // فوراً
      expect(totalXp(store.state), 0, reason: 'کمتر از یک دقیقه پس از ساخت');
      a.toggleTodo(id); // Undo
      t = t.add(const Duration(minutes: 5));
      a.toggleTodo(id);
      expect(totalXp(store.state), 8);
      a.toggleTodo(id); // Undo
      expect(totalXp(store.state), 0);
      for (int i = 0; i < 4; i++) {
        a.toggleTodo(id);
        a.toggleTodo(id);
      }
      a.toggleTodo(id);
      expect(totalXp(store.state), 8, reason: 'Complete → Undo → Complete: فقط یک رویدادِ معتبر');
      a.deleteTodo(id); // حذفِ کارِ انجام‌شده XP را نمی‌سوزاند
      expect(totalXp(store.state), 8);
      final again = AppStore('${dir.path}/s.json')..load(); // Restart
      expect(totalXp(again.state), 8);
    });

    test('کارِ مهم: ۱۲ XP به‌جای ۸', () {
      final dir = Directory.systemTemp.createTempSync('rp_th');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = AppStore('${dir.path}/s.json')..load();
      var t = DateTime.now();
      final a = AppActions(store, ToastBus(), clock: () => t);
      a.renderAll();
      final todo = a.addTodo('گزارشِ مالیِ مهم')!;
      expect(a.saveTodoEdit(todo['id'] as String, title: 'گزارشِ مالیِ مهم', repeatMode: 'none', repeatDays: const [], subs: const [], high: true), isTrue);
      t = t.add(const Duration(minutes: 3));
      a.toggleTodo(todo['id'] as String);
      expect(totalXp(store.state), 12);
    });

    test('پومودورو: فقط پایانِ واقعیِ فاز جلسه می‌سازد؛ Skip/Start-Stop نه', () {
      final dir = Directory.systemTemp.createTempSync('rp_p');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = AppStore('${dir.path}/s.json')..load();
      var t = DateTime(2026, 9, 30, 10);
      final a = AppActions(store, ToastBus(), clock: () => t);
      a.renderAll();
      for (int i = 0; i < 5; i++) {
        a.pomoStart();
        a.pomoPause();
      }
      a.pomoSkip();
      expect(totalXp(store.state), 0);
      a.pomoSetPhase('focus');
      a.pomoStart();
      t = t.add(const Duration(minutes: 26));
      expect(a.pomoTick(), true);
      expect(totalXp(store.state), 10);
      expect(validEvents(store.state, type: 'pomodoro').length, 1);
    });

    test('مهاجرت: کاربرِ قدیمی؛ سکه به XP تبدیل نمی‌شود، تاریخچه‌ی واقعی می‌ماند، آواتار/انبار نمایش داده نمی‌شود', () {
      final st = defaultState();
      st['scores'] = {'points': 500, 'coins': 3450, 'level': 4, 'streak': 3, 'lastPoints': 500};
      st['avatar'] = {'gender': 'male', 'owned': {'x': true}, 'equipped': {'male': {}, 'female': {}}};
      st['habits'] = [
        {'id': 'h', 'name': 'ورزش', 'type': 'binary', 'createdAt': iso(10), 'permanent': true, 'scheduleMode': 'daily', 'rewardPoints': 30}
      ];
      st['records'] = {for (int i = 1; i <= 5; i++) iso(i): {'h': 'success'}};
      final d = syncProgress(st, base);
      expect(d.migrated, true);
      final xp = totalXp(st);
      expect(xp, lessThan(3450), reason: 'سکه تبدیل نشده');
      expect(validEvents(st, type: 'habit').length, 5);
      expect(validEvents(st, type: 'habit').first['amount'], 15, reason: 'امتیازِ پاداشِ بالا = عادتِ مهم');
      expect((progressOf(st)['legacy'] as Map)['coins'], 3450); // فقط ثبتِ اطلاعاتی
      expect(st['avatar'], isNotNull, reason: 'داده‌ی قدیمی حذف نمی‌شود، فقط نمایش داده نمی‌شود');
      expect(pendingAnnouncements(st).isEmpty, true);
      final before = totalXp(st);
      syncProgress(st, base);
      expect(totalXp(st), before);
    });
  });

  group('Backup / Restore', () {
    test('Export → حذفِ داده → Import: XP/سطح/نشان/عنوان/ویژه/فصل/آمار همه برمی‌گردند', () {
      final st = defaultState();
      st['isPremium'] = true;
      st['habits'] = [
        {'id': 'h', 'name': 'ورزش', 'type': 'binary', 'createdAt': iso(40), 'permanent': true, 'scheduleMode': 'daily'}
      ];
      st['records'] = {for (int i = 0; i <= 12; i++) iso(i): {'h': 'success'}};
      syncProgress(st, base);
      startSeason(st, base, 30);
      expect(setActiveTitle(st, 'routine_builder'), true);
      expect(toggleFeatured(st, 'first_habit'), true);
      syncProgress(st, base);
      final xp = totalXp(st);
      final prog = jsonEncode(st['progress']);
      final snapBefore = snapshotOf(st, base);
      final text = backupToJson(createBackupMap(st, exportedAtUtc: DateTime.utc(2026, 9, 30)));
      // حذفِ همه‌ی داده
      final fresh = defaultState();
      expect(totalXp(fresh), 0);
      final v = rpValidateBackup(jsonDecode(text));
      expect(v.ok, true);
      applyBackupToState(fresh, v.next);
      syncProgress(fresh, base); // پس از Restore
      expect(totalXp(fresh), xp);
      expect(jsonEncode(fresh['progress']), prog, reason: 'وضعیتِ پیشرفت دقیقاً بازسازی می‌شود');
      final s2 = snapshotOf(fresh, base);
      expect([s2.level, s2.badgeCount, s2.title?.id, s2.featured.join(','), s2.streak], [snapBefore.level, snapBefore.badgeCount, snapBefore.title?.id, snapBefore.featured.join(','), snapBefore.streak]);
      expect(((fresh['progress'] as Map)['season'] as Map)['days'], 30);
      expect(pendingAnnouncements(fresh).isEmpty, true, reason: 'بازیابی انیمیشنِ جعلی نمی‌سازد');
    });
  });

  group('رابط کاربری', () {
    testWidgets('ویرایشِ نامِ کاربر: مداد، ذخیره، خالی = «کاربر»، ماندگاری', (tester) async {
      final (store, _, _) = await boot(tester);
      expect(find.byKey(const ValueKey('profile-name')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('profile-name-edit')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byKey(const ValueKey('name-field')), '  سارا   احمدی ');
      await tester.tap(find.byKey(const ValueKey('name-save')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(store.state['profileName'], 'سارا احمدی');
      expect(find.text('سارا احمدی'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('profile-name-edit')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byKey(const ValueKey('name-field')), '   ');
      await tester.tap(find.byKey(const ValueKey('name-save')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(store.state['profileName'], 'کاربر');
      await drain(tester);
    });

    testWidgets('پروفایلِ خانه: سطح، رتبه، XP، استریک و نشان‌ها؛ بدونِ سکه/آواتار', (tester) async {
      final (store, a, _) = await boot(tester);
      expect(find.byKey(const ValueKey('profile-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-level')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('profile-level'))).data, 'سطح ۱');
      expect(tester.widget<Text>(find.byKey(const ValueKey('xp-line'))).data, '۰ / ۱۰۰ XP');
      expect(find.text('نوآموز'), findsWidgets);
      expect(find.textContaining('سکه'), findsNothing);
      expect(find.textContaining('آواتار'), findsNothing);
      final hid = addHabit(a, 'ورزش');
      a.setBinary(a.todayISO, hid, 'success');
      await tester.pump(const Duration(milliseconds: 300));
      expect(totalXp(store.state), 10, reason: 'یک عادت = ۱۰ XP (بونوسِ روزانه حداقل دو عادت می‌خواهد)');
      expect(tester.widget<Text>(find.byKey(const ValueKey('xp-line'))).data, '۱۰ / ۱۰۰ XP');
      await drain(tester);
    });

    testWidgets('انیمیشنِ دستاورد: «اولین عادت» ظریف نمایش داده می‌شود و پس از تأیید دوباره نمی‌آید', (tester) async {
      final (store, a, _) = await boot(tester);
      final hid = addHabit(a, 'مطالعه');
      a.setBinary(a.todayISO, hid, 'success');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('reveal-title')), findsOneWidget);
      expect(find.byKey(const ValueKey('reveal-name')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('reveal-name'))).data, 'اولین عادت');
      await tester.tap(find.byKey(const ValueKey('reveal-ok')).last);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('reveal-title')), findsNothing);
      expect(pendingAnnouncements(store.state).isEmpty, true);
      // Undo و انجامِ دوباره: نشان هرگز دوباره اعلام نمی‌شود
      a.setBinary(a.todayISO, hid, 'success');
      a.setBinary(a.todayISO, hid, 'success');
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('reveal-title')), findsNothing);
      await drain(tester);
    });

    testWidgets('انیمیشنِ سطح بالا رفتن (چندمرحله‌ای) با XPِ واقعی', (tester) async {
      final (store, a, _) = await boot(tester);
      final log = <dynamic>[];
      store.state['pomodoro'] = {'log': log};
      final t0 = base.millisecondsSinceEpoch;
      for (int d = 0; d < 6; d++) {
        for (int k = 0; k < 12; k++) {
          log.add({'id': 'p${d}_$k', 'at': t0 - d * 86400000 + k, 'minutes': 60});
        }
      }
      a.afterChange();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('reveal-level')), findsOneWidget);
      final lv = int.parse(tester.widget<Text>(find.byKey(const ValueKey('reveal-level'))).data!.replaceAllMapped(RegExp('[۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) - 0x06F0}'));
      expect(lv, greaterThan(2), reason: 'چند سطح پشتِ هم');
      await tester.tap(find.byKey(const ValueKey('reveal-ok')).last);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 700)); // نشانِ سطح ۱۰ و … پشتِ سرش می‌آید یا نه
      for (int i = 0; i < 6 && find.byKey(const ValueKey('reveal-ok')).evaluate().isNotEmpty; i++) {
        await tester.tap(find.byKey(const ValueKey('reveal-ok')).last);
        await tester.pump(const Duration(milliseconds: 700));
      }
      expect(pendingAnnouncements(store.state).isEmpty, true);
      await drain(tester);
    });

    testWidgets('مجموعه‌ی نشان‌ها: شمارنده، فیلترِ دسته، جزئیات، پیشرفت، ویژه کردن؛ فیلترِ پیشرفته فقط پرو', (tester) async {
      final (store, a, _) = await boot(tester, view: AppView.badges, prep: (s, a) {
        final hid = addHabit(a, 'ورزش');
        (s.state['habits'] as List).single['createdAt'] = iso(20);
        s.state['records'] = {for (int i = 0; i < 5; i++) iso(i): {hid: 'success'}};
      });
      expect(find.byKey(const ValueKey('badge-count')), findsOneWidget);
      expect(find.byKey(const ValueKey('badge-grid')), findsOneWidget);
      expect(find.byKey(const ValueKey('badge-first_habit')), findsOneWidget);
      // فیلترِ دسته
      await tapT(tester, 'تمرکز');
      expect(find.byKey(const ValueKey('badge-first_habit')), findsNothing);
      expect(find.byKey(const ValueKey('badge-focus_1')), findsOneWidget);
      await tapT(tester, 'همه');
      // فیلترِ پیشرفته برای Free: توستِ محدودیت، بدونِ تغییر
      await tapT(tester, 'بازشده');
      expect(find.byKey(const ValueKey('badge-focus_1')), findsOneWidget);
      // جزئیات: نزدیک به باز شدن (۵ از ۷)
      await vis(tester, find.byKey(const ValueKey('badge-cons_7')));
      await Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey('badge-cons_7'))), alignment: 0.5);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.byKey(const ValueKey('badge-cons_7')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('badge-name')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('badge-progress'))).data, contains('۵'));
      expect(find.textContaining('۲ روز باقی مانده'), findsOneWidget);
      await tester.tapAt(const Offset(180, 30)); // دیوارِ مودال
      await tester.pump(const Duration(seconds: 1));
      // نشانِ بازشده: تاریخ دریافت و ویژه کردن
      await Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey('badge-first_habit'))), alignment: 0.5);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.byKey(const ValueKey('badge-first_habit')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('badge-date')), findsOneWidget);
      tester.widget<RpButton>(find.widgetWithText(RpButton, 'افزودن به نشان‌های ویژه')).onTap!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(progressOf(store.state)['featured'], ['first_habit']);
      await drain(tester);
      // پرو: فیلترِ پیشرفته کار می‌کند
      final (_, _, _) = await boot(tester, view: AppView.badges, pro: true);
      await tapT(tester, 'بازشده');
      expect(find.byKey(const ValueKey('badge-focus_1')), findsNothing);
      await drain(tester);
    });

    testWidgets('صفحه‌ی پیشرفت: آمارِ بدونِ داده «داده کافی…»؛ با داده مقدار و (پرو) تغییر؛ Timeline و عنوان‌ها', (tester) async {
      final (_, _, _) = await boot(tester, view: AppView.progress);
      expect(find.byKey(const ValueKey('level-card')), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('stat-consistency-empty')), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('داده کافی برای محاسبه وجود ندارد.'), findsWidgets);
      expect(find.byKey(const ValueKey('stat-consistency')), findsNothing, reason: 'هرگز عددِ ساختگی نشان نده');
      await drain(tester);
      final (store2, _, _) = await boot(tester, view: AppView.progress, pro: true, prep: (s, a) {
        s.state['uiOpen'] = {'progTimeline': true, 'progTitles': true};
        final hid = addHabit(a, 'ورزش');
        (s.state['habits'] as List).single['createdAt'] = iso(80);
        s.state['records'] = {for (int i = 0; i < 60; i++) if (i % 5 != 0 || i > 29) iso(i): {hid: 'success'}};
      });
      await vis(tester, find.byKey(const ValueKey('stat-consistency')));
      expect(find.byKey(const ValueKey('stat-consistency')), findsOneWidget);
      await vis(tester, find.byKey(const ValueKey('stat-consistency-change')));
      expect(find.byKey(const ValueKey('stat-consistency-change')), findsOneWidget);
      await vis(tester, find.byKey(const ValueKey('stat-productivity-empty')));
      expect(find.byKey(const ValueKey('stat-productivity-empty')), findsOneWidget);
      // مسیر و عنوان‌ها (بخش‌ها با uiOpen باز شده‌اند)
      await vis(tester, find.text('شروع مسیر'));
      expect(find.text('شروع مسیر'), findsOneWidget);
      expect(find.text('اولین عادت'), findsWidgets);
      await vis(tester, find.byKey(const ValueKey('title-routine_builder')));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('title-routine_builder')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('title-routine_builder')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(progressOf(store2.state)['activeTitle'], 'routine_builder', reason: 'استمرار ۷ روزه باز شده');
      await drain(tester);
    });

    testWidgets('Free/Pro: آمارِ پیشرفته، تاریخچه و فصل برای Free یادداشتِ پرو؛ برای Pro بدونِ قفل', (tester) async {
      Future<void> bootP(bool pro) => boot(tester, view: AppView.progress, pro: pro, prep: (s, a) {
            s.state['uiOpen'] = {'progSeason': true, 'progHistory': true};
            final hid = addHabit(a, 'ورزش');
            (s.state['habits'] as List).single['createdAt'] = iso(80);
            s.state['records'] = {for (int i = 0; i < 60; i++) if (i % 3 != 0) iso(i): {hid: 'success'}};
          }).then((_) {});
      await bootP(false);
      
      
      await vis(tester, find.byKey(const ValueKey('pro-notice-advancedStats')));
      expect(find.byKey(const ValueKey('pro-notice-advancedStats')), findsOneWidget);
      await vis(tester, find.byKey(const ValueKey('pro-notice-seasons')));
      expect(find.byKey(const ValueKey('pro-notice-seasons')), findsOneWidget);
      await vis(tester, find.byKey(const ValueKey('pro-notice-progressHistory')));
      expect(find.byKey(const ValueKey('pro-notice-progressHistory')), findsOneWidget);
      await vis(tester, find.byKey(const ValueKey('stat-consistency')));
      expect(find.byKey(const ValueKey('stat-consistency')), findsOneWidget, reason: 'آمارِ پایه رایگان است');
      expect(find.byKey(const ValueKey('stat-consistency-change')), findsNothing);
      await drain(tester);
      await bootP(true);
      
      await vis(tester, find.byKey(const ValueKey('season-30')));
      expect(find.byKey(const ValueKey('season-30')), findsOneWidget);
      expect(find.byKey(const ValueKey('pro-notice-seasons')), findsNothing);
      await Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey('season-30'))), alignment: 0.5);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.byKey(const ValueKey('season-30')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('season-xp')), findsOneWidget);
      await drain(tester);
    });

    for (final lang in ['fa', 'en']) {
      testWidgets('صفحه‌ی باریک ۳۲۰dp و فونت بزرگ بدونِ سرریز — $lang', (tester) async {
        for (final v in [AppView.dashboard, AppView.progress, AppView.badges]) {
          final (store, _, nav) = await boot(tester, view: v, size: const Size(960, 2400), lang: lang, pro: true, prep: (s, a) {
            s.state['fontSize'] = 'large';
            final hid = addHabit(a, 'ورزش با نامی بسیار طولانی برای آزمونِ سرریزِ متن');
            s.state['records'] = {for (int i = 0; i < 9; i++) iso(i): {hid: 'success'}};
            (s.state['habits'] as List).single['createdAt'] = iso(20);
          });
          final ex0 = tester.takeException();
          if (ex0 != null) fail('${v.name}/$lang: ${ex0 is FlutterError ? ex0.toStringDeep() : ex0}');
          nav.go(v);
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull);
          expect(store.state['progress'], isNotNull);
          await drain(tester);
        }
      });
    }
  });
}
