import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/library_ops.dart';

void main() {
  test('سطح کتابخوان', () {
    expect([0, 4, 5, 9, 10, 99, 100, 101].map(libraryLevelNum), [1, 1, 2, 2, 3, 20, 21, 21]);
    expect([0, 4, 5, 100].map(libraryBooksToNext), [5, 1, 5, 0]);
    expect([0, 2, 5, 100].map(libraryLevelPct), [0, 40, 0, 100]);
    expect(bookProgressPct({'totalPages': 0, 'pagesRead': 5}), 0);
    expect(bookProgressPct({'totalPages': 200, 'pagesRead': 50}), 25);
    expect(bookProgressPct({'totalPages': 100, 'pagesRead': 500}), 100);
  });

  test('کتاب: ذخیره، ثبت صفحه، اتمام = +سکه، ویرایش صفحات', () {
    final dir = Directory.systemTemp.createTempSync('rp_l');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final a = AppActions(store, ToastBus());
    expect(a.saveBook(title: ' ', author: '', summary: '', totalPages: 10, reward: ''), 'title');
    expect(a.saveBook(title: 'ا', author: '', summary: '', totalPages: 0, reward: ''), 'pages');
    expect(a.saveBook(title: ' کتاب ', author: 'x', summary: '', totalPages: 100, reward: 'شیرینی'), isNull);
    final b = a.books.single;
    expect(b['title'], 'کتاب');
    final id = b['id'] as String;
    expect(a.logPages(id).ok, isFalse);
    var r = a.logPages(id, justRead: 30);
    expect([r.ok, r.justCompleted, r.pct], [true, false, 30]);
    r = a.logPages(id, justRead: 10, totalSoFar: 50); // مجموع اولویت دارد
    expect(b['pagesRead'], 50);
    expect((b['history'] as List).last['delta'], 20);
    final before = (store.state['scores'] as Map)['coins'] ?? 0;
    r = a.logPages(id, totalSoFar: 999);
    expect(b['pagesRead'], 100);
    expect(r.justCompleted, isTrue);
    expect((store.state['scores'] as Map)['coins'] - before, 50);
    expect(a.logPages(id, totalSoFar: 100).justCompleted, isFalse); // دوباره سکه نمی‌دهد
    a.saveBook(editingId: id, title: 'کتاب', author: '', summary: '', totalPages: 300, reward: '');
    expect(b['completed'], isFalse); // صفحه‌ی کل بیشتر شد
    a.deleteBook(id);
    expect(a.books, isEmpty);
    // سقف رایگان
    for (int i = 0; i < 3; i++) {
      a.saveBook(title: 'b$i', author: '', summary: '', totalPages: 10, reward: '');
    }
    expect(a.canAddBook, isFalse);
    store.state['isPremium'] = true;
    expect(a.canAddBook, isTrue);
  });

  testWidgets('صفحه‌ی کتابخانه: نمایش و آمار', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_l2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    a.saveBook(title: 'شازده کوچولو', author: 'اگزوپری', summary: '', totalPages: 100, reward: '');
    final nav = NavController()..go(AppView.library);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('شازده کوچولو'), findsOneWidget);
    expect(find.text('سطح ۱'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
