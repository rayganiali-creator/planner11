import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/data/library_ops.dart';
import 'package:routine_planner/data/media_store.dart';

void main() {
  test('حذفِ عادت و کتاب، عکس و صدایشان را هم پاک می‌کند (بدون یتیم)', () async {
    final dir = Directory.systemTemp.createTempSync('rp_md');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final media = MediaStore('${dir.path}/media');
    final a = AppActions(store, ToastBus())..media = media;
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
    final hid = (store.state['habits'] as List).first['id'] as String;
    a.saveBook(title: 'کتاب', author: '', summary: '', totalPages: 10, reward: '', newId: 'bk1');
    const png = 'data:image/png;base64,iVBORw0KGgo=';
    await media.addPhoto(PhotoKind.habit, hid, png);
    await media.addPhoto(PhotoKind.book, 'bk1', png);
    await media.putVoice('bk1', bytes: Uint8List.fromList([1, 2, 3]), type: 'audio/webm', at: 1, ms: 1000);
    expect((await media.photos(PhotoKind.habit, hid)).length, 1);
    a.deleteHabit(hid);
    a.deleteBook('bk1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await media.photos(PhotoKind.habit, hid), isEmpty);
    expect(await media.photos(PhotoKind.book, 'bk1'), isEmpty);
    expect(await media.voices('bk1'), isEmpty);
  });

  testWidgets('کتابخانه: نوارِ عکسِ کارت (نگهدارِ 📕) و ویرایشگر با صدا/عکس', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_md2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final media = MediaStore('${dir.path}/media');
    final a = AppActions(store, toasts)..media = media;
    a.saveBook(title: 'شازده', author: '', summary: '', totalPages: 100, reward: '');
    final nav = NavController()..go(AppView.library);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a, media: media));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('شازده'), findsOneWidget);
    await tester.ensureVisible(find.text('✏️ ویرایش'));
    await tester.pump();
    await tester.tap(find.text('✏️ ویرایش'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    expect(find.text('یادداشت صوتی'), findsOneWidget);
    expect(find.text('هنوز یادداشت صوتی ثبت نشده.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });
}
