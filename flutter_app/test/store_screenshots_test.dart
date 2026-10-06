// تولید اسکرین‌شات‌های فروشگاه از خودِ برنامه (فقط با STORE_SHOTS=1):
//   STORE_SHOTS=1 flutter test --update-goldens test/store_screenshots_test.dart
// نکته: اسکرین‌شات‌های فعلی با افزودنِ موقتِ 'NotoColorEmoji' به kFontFallback (lib/ui/tokens.dart) ساخته شده‌اند تا ایموجی‌ها در تست دیده شوند؛ آن تغییر در برنامه‌ی منتشرشده نیست.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/features/challenges/challenges_sheet.dart';
import 'package:routine_planner/core/progress/engine.dart' show toggleFeatured;
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/challenge_ops.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/data/todo_ops.dart';

import 'progress_ui_test.dart';

Future<void> _loadFonts() async {
  final man = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final f in man) {
    final loader = FontLoader(f['family'] as String);
    for (final x in (f['fonts'] as List)) {
      loader.addFont(rootBundle.load(x['asset'] as String));
    }
    await loader.load();
  }
  final emoji = FontLoader('NotoColorEmoji')..addFont(Future.value(ByteData.sublistView(File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf').readAsBytesSync())));
  await emoji.load();
}

void _seed(AppStore s, AppActions a) {
  final st = s.state;
  st['profileName'] = 'سارا';
  final names = ['ورزش صبحگاهی', 'مطالعه ۲۰ دقیقه', 'نوشیدن ۸ لیوان آب', 'مدیتیشن'];
  final ids = [for (final n in names) a.saveHabit(HabitForm(a.todayISO)..name = n)!];
  for (final h in st['habits'] as List) {
    (h as Map)['createdAt'] = '2026-08-20';
  }
  final recs = <String, dynamic>{};
  for (int i = 0; i < 40; i++) {
    final d = base.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
    recs[d] = {for (int k = 0; k < ids.length; k++) ids[k]: (i < 16 || (i + k) % 7 != 0) ? 'success' : 'fail'};
  }
  st['records'] = recs;
  final bms = base.millisecondsSinceEpoch;
  st['todoLog'] = [for (int i = 0; i < 64; i++) {'id': 'tl$i', 'todoId': 'x$i', 'title': 'کارِ شماره ${i + 1}', 'at': bms - i * 86400000 ~/ 3, 'createdAt': bms - i * 86400000 ~/ 3 - 600000}];
  final pm = (st['pomodoro'] is Map ? st['pomodoro'] as Map : (st['pomodoro'] = <String, dynamic>{}));
  pm['log'] = [for (int i = 0; i < 58; i++) {'id': 'pl$i', 'at': bms - (i ~/ 4) * 86400000 - (i % 4) * 3600000, 'minutes': 25}];
  st['books'] = [
    {'id': 'b1', 'title': 'عادت‌های اتمی', 'author': 'جیمز کلییر', 'totalPages': 320, 'pagesRead': 214, 'completed': false, 'history': [{'date': bms - 86400000, 'pagesRead': 214, 'delta': 30}]},
    for (int i = 0; i < 6; i++) {'id': 'bd$i', 'title': 'کتابِ ${i + 1}', 'author': '—', 'totalPages': 200, 'pagesRead': 200, 'completed': true, 'completedAt': bms - (i + 2) * 86400000 * 3, 'history': []},
  ];
  st['journal'] = [
    {'id': 'j1', 'text': 'امروز سه‌تا کارِ مهم را تمام کردم و حس خیلی خوبی دارم.', 'createdAt': bms - 3600000},
    {'id': 'j2', 'text': 'تمرکزم بعد از پومودورو بهتر شد؛ فردا هم ادامه می‌دهم.', 'createdAt': bms - 90000000},
  ];
  st['challenges'] = [];
  a.addTodo('مرور برنامه‌ی هفته');
  a.addTodo('خرید کتاب جدید');
  a.addTodo('تماس با مادر');
  (st['todos'] as List).add({'id': 'dn1', 'title': 'گزارش پروژه را بفرست', 'done': true, 'createdAt': bms - 86400000, 'dueAt': null, 'repeatMode': 'none', 'repeatDays': <int>[], 'notified': false});
  a.joinPreset('preset_workout10', notifier: null);
  a.renderAll();
  for (final id in ['cons_14', 'focus_100', 'task_50']) {
    toggleFeatured(st, id);
  }
  s.save();
}

void main() {
  final on = Platform.environment['STORE_SHOTS'] == '1';
  Future<void> shot(WidgetTester tester, String name, AppView v, {String theme = 'light', String accent = 'emerald', Future<void> Function(WidgetTester)? after}) async {
    final (_, _, _) = await boot(tester, view: v, size: const Size(1080, 2160), prep: (s, a) {
      s.state['theme'] = theme;
      s.state['accentTheme'] = accent;
      _seed(s, a);
    });
    for (int i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 150));
    }
    if (after != null) await after(tester);
    for (int i = 0; i < 6 && find.byKey(const ValueKey('reveal-ok')).evaluate().isNotEmpty; i++) {
      await tester.tap(find.byKey(const ValueKey('reveal-ok')).last);
      await tester.pump(const Duration(milliseconds: 800));
    }
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('/tmp/shots/$name.png'));
    await drain(tester);
  }

  setUpAll(() async {
    if (on) await _loadFonts();
  });

  for (final c in [
    ('01-home', AppView.dashboard, 'light', 'emerald'),
    ('02-habits', AppView.habits, 'light', 'emerald'),
    ('03-progress', AppView.progress, 'light', 'emerald'),
    ('04-badges', AppView.badges, 'light', 'emerald'),
    ('05-todo', AppView.todo, 'light', 'royal'),
    ('06-calendar', AppView.month, 'light', 'lagoon'),
    ('07-pomodoro', AppView.pomodoro, 'dark', 'royal'),
    ('08-badges-dark', AppView.badges, 'dark', 'coral'),
  ]) {
    testWidgets('shot ${c.$1}', skip: !on, (tester) async => shot(tester, c.$1, c.$2, theme: c.$3, accent: c.$4));
  }
  testWidgets('shot 09-challenges', skip: !on, (tester) async {
    await shot(tester, '09-challenges', AppView.dashboard, after: (t) async {
      showChallenges(t.element(find.byType(Scaffold).first), tab: 'active');
      await t.pump(const Duration(milliseconds: 700));
      await t.pump(const Duration(milliseconds: 700));
    });
  });
}
