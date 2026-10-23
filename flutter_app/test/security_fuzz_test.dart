// «حمله»ی خودکار به داده: فایل/ذخیره‌ی خراب و دست‌کاری‌شده نباید برنامه را بیندازد؛ هیچ مسیری نباید Pro رایگان بدهد.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/backup.dart';
import 'package:routine_planner/core/pro.dart';
import 'package:routine_planner/core/progress/engine.dart';
import 'package:routine_planner/core/progress/stats.dart';
import 'package:routine_planner/core/state_model.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/challenge_ops.dart';
import 'package:routine_planner/data/habit_ops.dart';
import 'package:routine_planner/data/media_store.dart';
import 'package:routine_planner/features/settings/settings_screen.dart' show AppVersion;

import 'progress_ui_test.dart';

final _now = DateTime(2026, 9, 30, 14);

Map<String, dynamic> _richState() {
  final dir = Directory.systemTemp.createTempSync('rp_fz');
  final store = AppStore('${dir.path}/s.json')..load();
  final a = AppActions(store, ToastBus(), clock: () => _now);
  final h1 = a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش')!;
  final h2 = a.saveHabit(HabitForm(a.todayISO)..name = 'مطالعه'..type = 'number')!;
  for (final h in store.state['habits'] as List) {
    (h as Map)['createdAt'] = '2026-09-01';
  }
  store.state['records'] = {for (int i = 0; i < 20; i++) '2026-09-${(29 - i).toString().padLeft(2, '0')}': {h1: 'success', h2: 5}};
  store.state['todos'] = [{'id': 't1', 'title': 'کار نمونه', 'done': true, 'createdAt': 1790000000000, 'priority': 'high'}];
  store.state['journal'] = [{'id': 'j1', 'date': '2026-09-29', 'text': 'یادداشتی بلند برای تست امنیت و پایداری'}];
  store.state['books'] = [{'id': 'b1', 'title': 'کتاب', 'totalPages': 100, 'currentPage': 40, 'completed': false}];
  a.joinPreset('seven_days_no_social', notifier: null);
  a.renderAll();
  final m = jsonDecode(jsonEncode(store.state)) as Map<String, dynamic>;
  dir.deleteSync(recursive: true);
  return m;
}

final _junk = <Object?>[null, '', 'x', '😈' * 50, 'A' * 5000, -1, 0, 1e308, -1e308, 9007199254740993, true, false, '@[]', '@{}', '@[null]', '@[[[]]]', '@{"a": {"b": []}}', '2026-13-45', '../../etc/passwd', '<script>alert(1)</script>', '\u0000\u202E'];

Object? _pick(Random r) {
  final v = _junk[r.nextInt(_junk.length)];
  // ساختارها را تازه و «dynamic» بسازیم تا نوعِ استاتیکِ لیترال‌ها جلوی تزریق را نگیرد
  return v is String && v.startsWith('@') ? jsonDecode(v.substring(1).replaceAll("'", '"')) : (v is double && (v.isNaN || v.isInfinite) ? 1e308 : v);
}

void _mutate(Object? node, Random r, int depth) {
  if (node is Map && node.isNotEmpty) {
    final keys = node.keys.toList();
    final k = keys[r.nextInt(keys.length)];
    if (depth > 0 && (node[k] is List || node[k] is Map) && r.nextInt(3) != 0) {
      _mutate(node[k], r, depth - 1);
      return;
    }
    r.nextInt(5) == 0 ? node.remove(k) : node[k] = _pick(r);
  } else if (node is List && node.isNotEmpty) {
    final i = r.nextInt(node.length);
    if (depth > 0 && (node[i] is Map || node[i] is List) && r.nextInt(3) != 0) {
      _mutate(node[i], r, depth - 1);
      return;
    }
    r.nextInt(5) == 0 ? node.removeAt(i) : node[i] = _pick(r);
  }
}

String _enc(Object? o) => jsonEncode(o, toEncodable: (v) => '$v');

void main() {
  _versionMain();
  final base = _richState();

  test('فازِ منطق: ۱۵٬۰۰۰ ذخیره‌ی دست‌کاری‌شده → بارگذاری، همگام‌سازی پیشرفت، آمار، بدون استثنا', () {
    final r = Random(1337);
    final fails = <String>[];
    for (int i = 0; i < 15000; i++) {
      final m = jsonDecode(_enc(base)) as Map<String, dynamic>;
      final n = 1 + r.nextInt(4);
      for (int k = 0; k < n; k++) {
        _mutate(m, r, 3);
      }
      final text = _enc(m);
      try {
        final l = loadStateFromRaw(text, nowMs: _now.millisecondsSinceEpoch);
        syncProgress(l.state, _now);
        snapshotOf(l.state, _now);
        computeStats(l.state, _now);
        jsonEncode(l.state, toEncodable: (v) => '$v');
        final p = l.state['isPremium'];
        if (p == true && l.state['proCache'] == null && l.state['__rpOwnerMark'] == null) fails.add('#$i isPremium بدون مدرک');
      } catch (e, st) {
        fails.add('#$i $e\n${st.toString().split('\n').take(9).join('\n')}\n$text'.substring(0, 1500));
        if (fails.length >= 5) break;
      }
    }
    expect(fails, isEmpty, reason: fails.join('\n----\n'));
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('فازِ رابط: ۳۰ ذخیره‌ی دست‌کاری‌شده در همه‌ی صفحه‌های اصلی بدون استثنا', (tester) async {
    final r = Random(99);
    FlutterErrorDetails? first;
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (d) => first ??= d;
    addTearDown(() => FlutterError.onError = oldHandler);
    for (int i = 0; i < int.parse(Platform.environment['FUZZ_UI'] ?? '30'); i++) {
      final m = jsonDecode(_enc(base)) as Map<String, dynamic>;
      for (int k = 0; k < 3; k++) {
        _mutate(m, r, 3);
      }
      for (final v in [AppView.dashboard, AppView.habits, AppView.progress, AppView.badges, AppView.analytics, AppView.todo, AppView.month]) {
        final dir = Directory.systemTemp.createTempSync('rp_fzui');
        File('${dir.path}/s.json').writeAsStringSync(_enc(m));
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3;
        final store = AppStore('${dir.path}/s.json')..load();
        final a = AppActions(store, ToastBus(), clock: () => _now);
        try {
          a.renderAll();
        } catch (e) {
          fail('renderAll #$i: $e');
        }
        final nav = NavController()..go(v);
        await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: a.toasts, actions: a));
        await tester.pump(const Duration(milliseconds: 500));
        final ex = tester.takeException();
        expect(ex, isNull, reason: 'view=$v mutation#$i: $ex\n${first?.stack.toString().split('\n').take(10).join('\n')}\n${_enc(m)}'.substring(0, 2500));
        await tester.pumpWidget(const SizedBox());
        dir.deleteSync(recursive: true);
      }
    }
    tester.view.reset();
  }, timeout: const Timeout(Duration(minutes: 5)));

  group('Pro: راه‌های دورزدن', () {
    Map<String, dynamic> st() => defaultState();
    final now = _now.millisecondsSinceEpoch;
    test('بازیابیِ پشتیبانِ مخرب نمی‌تواند Pro بدهد (isPremium / proCache / نشانه‌ی مالک)', () {
      final s = st();
      final evil = {
        'version': '3.0',
        'data': {
          'habits': [], 'records': {},
          'isPremium': true, '__rpOwnerMark': rpOwnerMarkValue,
          'proCache': {'isPro': true, 'expiresAt': null, 'purchases': [{'productId': 'premium_unlock', 'purchaseToken': 'x', 'purchaseTime': 1}], 'purchaseToken': 'x'},
        }
      };
      final v = rpValidateBackup(evil);
      expect(v.ok, isTrue);
      applyBackupToState(s, v.next);
      recomputeTrustedPremiumFlag(s, now);
      expect(s['isPremium'], false);
      expect(s.containsKey('__rpOwnerMark') && s['__rpOwnerMark'] == rpOwnerMarkValue, false);
    });

    test('ویرایشِ دستیِ proCache (بدون امضا/با امضای غلط) و پلنِ منقضی کار نمی‌کند', () {
      final s = st();
      s['proCache'] = {'isPro': true, 'expiresAt': now + 99999999, 'purchases': [{'productId': 'rp_pro_6m', 'purchaseToken': 'tok', 'purchaseTime': now}], 'purchaseToken': 'tok', 'sig': 'forged'};
      expect(recomputeTrustedPremiumFlag(s, now), false, reason: 'امضای غلط');
      final pc = {'isPro': true, 'expiresAt': now - 1000, 'purchases': [{'productId': 'rp_pro_1m', 'purchaseToken': 'tok', 'purchaseTime': now - 99999999}], 'purchaseToken': 'tok'};
      pc['sig'] = rpSig(pc);
      s['proCache'] = pc;
      expect(recomputeTrustedPremiumFlag(s, now), false, reason: 'منقضی');
      final ok = {'isPro': true, 'expiresAt': now + 100000, 'purchases': [{'productId': 'rp_pro_1m', 'purchaseToken': 'tok', 'purchaseTime': now}], 'purchaseToken': 'tok'};
      ok['sig'] = rpSig(ok);
      s['proCache'] = ok;
      expect(recomputeTrustedPremiumFlag(s, now), true, reason: 'خریدِ معتبر باید کار کند');
      (ok['purchases'] as List).first['productId'] = 'rp_pro_6m'; // ارتقای دستیِ پلن بدونِ امضای دوباره
      expect(recomputeTrustedPremiumFlag(s, now), false);
    });

    test('ساعت: عقب‌کشیدنِ ساعتِ گوشی پلنِ منقضی را زنده نمی‌کند', () {
      final c = TrustedClock();
      final t1 = c.now(dateNow: now + 86400000 * 40, perfNow: 0, lastSeen: null);
      final t2 = c.now(dateNow: now, perfNow: 1000, lastSeen: t1); // کاربر ساعت را ۴۰ روز عقب برد
      expect(t2, greaterThanOrEqualTo(t1));
    });
  });

  group('پشتیبان: ورودی مخرب', () {
    test('رمزنگاری: رمز غلط، دست‌کاریِ متن/برچسب، پاکتِ ناقص، تکرارِ غول‌آسا → null و بدون استثنا/قفل', () async {
      final enc = jsonDecode(await rpEncryptBackup('{"data":{}}', 'درست-123', iterations: 1000)) as Map;
      expect(await rpDecryptBackup(enc, 'غلط'), isNull);
      final tam = Map.of(enc);
      final raw = base64.decode(enc['data'] as String).toList();
      raw[3] ^= 1;
      tam['data'] = base64.encode(raw);
      expect(await rpDecryptBackup(tam, 'درست-123'), isNull);
      final tag = base64.decode(enc['data'] as String).toList();
      tag[tag.length - 1] ^= 1;
      expect(await rpDecryptBackup({...enc, 'data': base64.encode(tag)}, 'درست-123'), isNull);
      for (final bad in [<String, dynamic>{}, {'kdf': 5}, {'kdf': {'salt': 1}, 'iv': 2, 'data': 3}, {...enc, 'iv': 'نامعتبر!!'}, {...enc, 'data': ''}]) {
        expect(await rpDecryptBackup(bad, 'x'), isNull);
      }
      final sw = Stopwatch()..start();
      await rpDecryptBackup({...enc, 'kdf': {...(enc['kdf'] as Map), 'iterations': 999999999999}}, 'x');
      expect(sw.elapsed.inSeconds, lessThan(60), reason: 'تکرارِ KDF باید سقف داشته باشد');
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('JSONِ خیلی تودرتو یا حجیم → خطای قابل‌گرفتن، نه کرش', () {
      final deep = '[' * 200000;
      Object? err;
      try {
        jsonDecode(deep);
      } catch (e) {
        err = e;
      }
      expect(err, isNotNull);
      expect(rpValidateBackup(jsonDecode('{"data":{"habits":[],"records":{}},"version":"3.0"}')).ok, isTrue);
    });

    test('کلیدهای خطرناک/ناشناخته در پشتیبان نادیده گرفته می‌شوند', () {
      final v = rpValidateBackup({'data': {'habits': [], 'records': {}, '__proto__': {'x': 1}, 'constructor': 1, 'isPremium': true, 'avatar': {}}});
      expect(v.next.keys.toSet().intersection({'__proto__', 'constructor', 'isPremium', 'avatar'}), isEmpty);
    });
  });

  test('رسانه: مسیرِ مخرب در ownerId از پوشه‌ی برنامه بیرون نمی‌رود', () async {
    final dir = Directory.systemTemp.createTempSync('rp_media');
    final outside = Directory('${dir.path}/outside')..createSync();
    final ms = MediaStore('${dir.path}/media');
    final id = await ms.addPhoto(PhotoKind.habit, '../../outside/../../x', 'data:image/png;base64,iVBORw0KGgo=');
    expect(id, isNotNull);
    expect(outside.listSync(), isEmpty);
    for (final f in Directory(dir.path).listSync(recursive: true).whereType<File>()) {
      expect(f.path.startsWith('${dir.path}/media/'), isTrue, reason: f.path);
    }
    dir.deleteSync(recursive: true);
  });
}

void _versionMain() {
  test('نسخه‌ی نمایشی در تنظیمات با pubspec یکی است', () {
    final m = RegExp(r'^version:\s*(\S+)\+(\d+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!;
    expect('${AppVersion.name}+${AppVersion.code}', '${m.group(1)}+${m.group(2)}');
  });
}
