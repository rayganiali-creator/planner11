import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/journal_ops.dart';
import 'package:routine_planner/data/notifier.dart';

class _Rec implements Notifier {
  @override
  Future<void> resyncAll(dynamic state, DateTime now) async {}
  final calls = <String>[];
  @override
  Future<void> scheduleOnce(String id, String title, String body, int atMs) async => calls.add('sched $id');
  @override
  Future<void> cancel(String id) async => calls.add('cancel $id');
}

void main() {
  test('نوبتِ بعدیِ تکرار', () {
    final at = DateTime(2026, 1, 31, 9, 0).millisecondsSinceEpoch;
    final now = DateTime(2026, 1, 31, 10, 0).millisecondsSinceEpoch;
    expect(nextRepeat(at, 'daily', now), DateTime(2026, 2, 1, 9, 0).millisecondsSinceEpoch);
    expect(nextRepeat(at, 'weekly', now), DateTime(2026, 2, 7, 9, 0).millisecondsSinceEpoch);
    // مثل JS setMonth: ۳۱ ژانویه + ۱ ماه = ۳ مارس
    expect(nextRepeat(at, 'monthly', now), DateTime(2026, 3, 3, 9, 0).millisecondsSinceEpoch);
    expect(nextRepeat(at, 'none', now), isNull);
    // برنامه مدتی بسته بوده: تا اولین نوبتِ آینده
    final later = DateTime(2026, 2, 10, 12, 0).millisecondsSinceEpoch;
    expect(nextRepeat(at, 'daily', later), DateTime(2026, 2, 11, 9, 0).millisecondsSinceEpoch);
  });

  test('ژورنال: افزودن/ویرایش/حذف و یادآوری (پرو)', () {
    final dir = Directory.systemTemp.createTempSync('rp_j');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus());
    final n = _Rec();
    expect(a.addJournal('  '), isFalse);
    expect(a.addJournal(' سلام '), isTrue);
    final e = (store.state['journal'] as List).single as Map;
    expect(e['text'], 'سلام');
    expect(a.editJournal(e['id'], ''), isFalse);
    expect(a.editJournal(e['id'], 'تغییر'), isTrue);
    expect(e.containsKey('updatedAt'), isTrue);
    final future = DateTime.now().millisecondsSinceEpoch + 3600000;
    expect(a.setItemReminder('journal', e['id'], future, 'daily', notifier: n), isFalse); // رایگان
    store.state['isPremium'] = true;
    expect(a.setItemReminder('journal', e['id'], DateTime.now().millisecondsSinceEpoch - 5, 'none', notifier: n), isFalse); // گذشته
    expect(a.setItemReminder('journal', e['id'], future, 'daily', notifier: n), isTrue);
    expect(e['remindRepeat'], 'daily');
    a.clearItemReminder('journal', e['id'], notifier: n);
    expect(e.containsKey('remindAt'), isFalse);
    a.deleteJournal(e['id'], notifier: n);
    expect(store.state['journal'], isEmpty);
    expect(n.calls, contains('sched journal-${e['id']}'));
    expect(n.calls, contains('cancel journal-${e['id']}'));
  });

  testWidgets('صفحه‌ی ژورنال: ثبت، جست‌وجو', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_j2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    a.addJournal('یادداشت اول');
    a.addJournal('چیز دیگر');
    final nav = NavController()..go(AppView.journal);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('یادداشت اول'), findsOneWidget);
    expect(find.text('چیز دیگر'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'دیگر');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('یادداشت اول'), findsNothing);
    expect(find.text('چیز دیگر'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
