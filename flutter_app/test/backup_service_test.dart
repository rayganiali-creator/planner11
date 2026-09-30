import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/backup.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/backup_service.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/data/media_store.dart';
import 'package:routine_planner/data/native_api.dart';

class _N implements NativeApi {
  @override
  Future<void> connect() async {}
  @override
  Future<Map> purchase(String p) async => {};
  @override
  Future<void> consume(String t) async {}
  @override
  Future<List<Map>> getPurchasedProducts() async => [];
  @override
  Future<String> saveToDownloads({required String fileName, required String mimeType, required String base64Data}) async => 'x';
}

void main() {
  handoffTests();
  late Directory dir;
  late AppStore store;
  late AppActions a;
  late MediaStore media;
  late BackupService svc;
  late ToastBus toasts;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('rp_bs');
    store = AppStore('${dir.path}/s.json')..load();
    toasts = ToastBus();
    a = AppActions(store, toasts);
    media = MediaStore('${dir.path}/media');
    svc = BackupService(a, media, _N(), toasts);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('رفت‌وبرگشتِ کامل: ساخت ← ورود روی برنامه‌ی دیگر، همه‌ی داده برابر', () async {
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
    final hid = (store.state['habits'] as List).first['id'] as String;
    a.setBinary(a.todayISO, hid, 'success');
    a.addJournalForTest('یادداشت');
    final json = await svcJson(svc);
    // برنامه‌ی دوم (خالی)
    final dir2 = Directory.systemTemp.createTempSync('rp_bs2');
    addTearDown(() => dir2.deleteSync(recursive: true));
    final s2 = AppStore('${dir2.path}/s.json')..load();
    final a2 = AppActions(s2, ToastBus());
    final svc2 = BackupService(a2, MediaStore('${dir2.path}/media'), _N(), ToastBus());
    expect(await svc2.importFromText(json), isTrue);
    expect((s2.state['habits'] as List).single['name'], 'ورزش');
    expect(((s2.state['records'] as Map)[a.todayISO] as Map)[hid], 'success');
    expect((s2.state['journal'] as List).single['text'], 'یادداشت');
  });

  test('رمزدار: رمز درست، رمز غلط (بدون تغییر)، JSON خراب، فایلِ بی‌ربط', () async {
    a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
    final plain = await svcJson(svc);
    final enc = await rpEncryptBackup(plain, 'secret');
    store.state['profileName'] = 'قبل';
    expect(await svc.importFromText(enc, ask: () async => (plain: false, pass: 'wrong')), isFalse);
    expect(store.state['profileName'], 'قبل'); // دست‌نخورده
    expect(await svc.importFromText('{not json'), isFalse);
    expect(await svc.importFromText('{"hello":1}'), isFalse);
    expect(store.state['profileName'], 'قبل');
    store.state['habits'] = [];
    expect(await svc.importFromText(enc, ask: () async => (plain: false, pass: 'secret')), isTrue);
    expect((store.state['habits'] as List).length, 1);
    // انصراف در پرسشِ رمز
    expect(await svc.importFromText(enc, ask: () async => null), isFalse);
  });

  test('CSV: BOM، CRLF، نقل‌قول، ستون‌ها', () {
    expect(svc.buildCsv(), '');
    a.saveHabit(HabitForm(a.todayISO)..name = 'خواندن, "کتاب"');
    final hid = (store.state['habits'] as List).first['id'] as String;
    a.setBinary('2026-09-30', hid, 'success');
    a.setBinary('2026-09-29', hid, 'fail');
    final csv = svc.buildCsv();
    expect(csv.startsWith('﻿'), isTrue);
    final lines = csv.substring(1).split('\r\n');
    expect(lines[0], 'تاریخ,تاریخ شمسی,عادت,وضعیت,مقدار ثبت‌شده');
    expect(lines[1], '2026-09-29,1405/07/07,"خواندن, ""کتاب""",ناموفق,');
    expect(lines[2], '2026-09-30,1405/07/08,"خواندن, ""کتاب""",موفق,');
  });
}

Future<String> svcJson(BackupService s) async {
  // مسیرِ عمومیِ ساخت بدون پنجره‌ی رمز
  return s.debugJson();
}

extension on AppActions {
  void addJournalForTest(String t) {
    (store.state['journal'] as List).add({'id': 'j1', 'text': t, 'createdAt': 1});
    store.save();
  }
}

void handoffTests() {
  test('انتقال از نسخه‌ی HTML: وارد می‌شود، تغییر نام می‌دهد، دوباره وارد نمی‌شود، خرابی دست‌نخورده می‌ماند', () async {
    final dir = Directory.systemTemp.createTempSync('rp_ho');
    addTearDown(() => dir.deleteSync(recursive: true));
    // «نسخه‌ی HTML» یک پشتیبان ساخته است
    final src = AppStore('${dir.path}/src.json')..load();
    final sa = AppActions(src, ToastBus());
    sa.saveHabit(HabitForm(sa.todayISO)..name = 'قدیمی');
    src.state['profileName'] = 'علی';
    final json = await BackupService(sa, MediaStore('${dir.path}/m0'), _N(), ToastBus()).debugJson();
    final app = Directory('${dir.path}/app')..createSync();
    File('${app.path}/rp_handoff.json').writeAsStringSync(json);
    final store = AppStore('${app.path}/state.json')..load();
    final a = AppActions(store, ToastBus())..renderAll(); // مثل main: state.json پیش از انتقال ساخته می‌شود
    final svc = BackupService(a, MediaStore('${app.path}/media'), _N(), ToastBus());
    expect(await svc.importHandoff(app.path), isTrue);
    expect(store.state['profileName'], 'علی');
    expect((store.state['habits'] as List).single['name'], 'قدیمی');
    expect(File('${app.path}/rp_handoff.json').existsSync(), isFalse);
    expect(File('${app.path}/rp_handoff.imported.json').existsSync(), isTrue); // کپیِ کامل می‌ماند
    expect(await svc.importHandoff(app.path), isFalse); // دوباره نه
    // فایلِ خراب: داده‌ی فعلی دست‌نخورده و فایل سر جایش (برای تلاشِ بعد)
    File('${app.path}/rp_handoff.json').writeAsStringSync('{broken');
    expect(await svc.importHandoff(app.path), isFalse);
    expect(store.state['profileName'], 'علی');
    expect(File('${app.path}/rp_handoff.json').existsSync(), isTrue);
  });
}
