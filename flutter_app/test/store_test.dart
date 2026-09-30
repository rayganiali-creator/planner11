// ذخیره‌سازی روی دیسک واقعی (پوشه‌ی موقت): نوشتن اتمیک، بازیابی از فایل خراب، رسانه، و چرخه‌ی کاملِ پشتیبان.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/backup.dart';
import 'package:routine_planner/core/state_model.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/atomic_file.dart';
import 'package:routine_planner/data/media_store.dart';

const _now = 1790762400000;

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('rp_store_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  group('AtomicFile', () {
    test('نوشتن و خواندن؛ نسخه‌ی قبلی به .bak می‌رود', () {
      final f = AtomicFile('${tmp.path}/s.json');
      expect(f.write('{"a":1}'), isTrue);
      expect(f.write('{"a":2}'), isTrue);
      expect(File('${tmp.path}/s.json').readAsStringSync(), '{"a":2}');
      expect(File('${tmp.path}/s.json.bak').readAsStringSync(), '{"a":1}');
      expect(File('${tmp.path}/s.json.tmp').existsSync(), isFalse);
    });

    test('فایلِ اصلیِ خراب → از .bak بازیابی و خرابه کنار گذاشته (نه پاک) می‌شود', () {
      final f = AtomicFile('${tmp.path}/s.json');
      f.write('{"a":1}');
      f.write('{"a":2}');
      File('${tmp.path}/s.json').writeAsStringSync('{"a":'); // نیمه‌کاره (مثلاً قطع برق)
      final r = f.read(isValid: (t) {
        try {
          jsonDecode(t);
          return true;
        } catch (_) {
          return false;
        }
      });
      expect(r.text, '{"a":1}');
      expect(r.recovered, isTrue);
      expect(r.quarantinedAs, isNotNull);
      expect(File(r.quarantinedAs!).readAsStringSync(), '{"a":', reason: 'داده‌ی خراب باید برای بازیابیِ دستی حفظ شود');
    });

    test('هر دو فایل خراب → null ولی هر دو کنار گذاشته می‌شوند', () {
      final f = AtomicFile('${tmp.path}/s.json');
      File('${tmp.path}/s.json').writeAsStringSync('xx');
      File('${tmp.path}/s.json.bak').writeAsStringSync('yy');
      final r = f.read(isValid: (_) => false);
      expect(r.text, isNull);
      expect(tmp.listSync().where((e) => e.path.contains('.corrupt-')).length, 2);
    });

    test('نوشتن در مسیرِ غیرممکن false می‌دهد و استثنا نمی‌اندازد', () {
      File('${tmp.path}/blocker').writeAsStringSync('x'); // فایل، نه پوشه
      expect(AtomicFile('${tmp.path}/blocker/s.json').write('{}'), isFalse);
    });
  });

  group('AppStore', () {
    test('نصب تازه: حالتِ پیش‌فرض، و save() سندِ سالم می‌نویسد', () {
      final s = AppStore('${tmp.path}/state.json', nowMs: () => _now)..load();
      expect(s.state['lang'], 'fa');
      expect(s.save(), isTrue);
      final back = jsonDecode(File('${tmp.path}/state.json').readAsStringSync()) as Map;
      expect(back['habits'], isEmpty);
      expect(s.dataVersion, 1);
    });

    test('داده‌ی کاربر بعد از خروج و ورودِ دوباره می‌ماند (و فیلدِ ناشناخته هم)', () {
      final a = AppStore('${tmp.path}/state.json', nowMs: () => _now)..load();
      a.state['habits'] = [{'id': 'h1', 'name': 'آب', 'type': 'binary', 'createdAt': '2026-09-01'}];
      a.state['records'] = {'2026-09-30': {'h1': 'success'}};
      a.state['future_field'] = {'x': [1, 2]};
      (a.state['scores'] as Map)['coins'] = 77;
      a.save();
      final b = AppStore('${tmp.path}/state.json', nowMs: () => _now)..load();
      expect((b.state['habits'] as List).single['name'], 'آب');
      expect(b.state['records'], {'2026-09-30': {'h1': 'success'}});
      expect(b.state['future_field'], {'x': [1, 2]});
      expect((b.state['scores'] as Map)['coins'], 77);
    });

    test('فایلِ خراب بدونِ نسخه‌ی پشتیبان: برنامه بالا می‌آید و خرابه نگه داشته می‌شود', () {
      File('${tmp.path}/state.json').writeAsStringSync('{"habits":[{"id":"h1","na');
      final s = AppStore('${tmp.path}/state.json', nowMs: () => _now)..load();
      expect(s.state['habits'], isEmpty);
      expect(s.quarantinedCorruptFile, isNotNull);
      s.save(); // نوشتنِ حسابِ خالی نباید داده‌ی خراب را نابود کند
      expect(File(s.quarantinedCorruptFile!).readAsStringSync(), startsWith('{"habits":[{"id":"h1"'));
    });

    test('lastSeen هرگز عقب نمی‌رود (ساعتِ مطمئن)', () {
      var t = _now;
      final s = AppStore('${tmp.path}/state.json', nowMs: () => t)..load();
      s.save();
      final first = (s.state['clock'] as Map)['lastSeen'] as int;
      t = _now - 86400000 * 5; // کاربر ساعت گوشی را ۵ روز عقب کشید
      s.save();
      expect((s.state['clock'] as Map)['lastSeen'], greaterThanOrEqualTo(first));
    });
  });

  group('MediaStore', () {
    final png = base64.encode(List<int>.generate(64, (i) => i));

    test('عکس: افزودن، فهرست به ترتیب، حذف', () async {
      final m = MediaStore('${tmp.path}/media');
      final a = await m.addPhoto(PhotoKind.habit, 'h/1', 'data:image/jpeg;base64,$png');
      final b = await m.addPhoto(PhotoKind.habit, 'h/1', 'data:image/jpeg;base64,$png');
      expect(a, isNotNull);
      var l = await m.photos(PhotoKind.habit, 'h/1');
      expect(l.length, 2);
      expect(l.first.id, a);
      expect(l.first.dataUrl, 'data:image/jpeg;base64,$png');
      await m.deletePhoto(PhotoKind.habit, 'h/1', a!);
      l = await m.photos(PhotoKind.habit, 'h/1');
      expect(l.single.id, b);
      expect(await m.addPhoto(PhotoKind.habit, 'h', 'not-a-data-url'), isNull);
    });

    test('شناسه‌ی مالک با نویسه‌های عجیب امن است (بدونِ خروج از پوشه)', () async {
      final m = MediaStore('${tmp.path}/media');
      await m.addPhoto(PhotoKind.book, '../../etc/passwd', 'data:image/png;base64,$png');
      expect(Directory('${tmp.path}/etc').existsSync(), isFalse);
      expect((await m.photos(PhotoKind.book, '../../etc/passwd')).length, 1);
    });

    test('صدا: ذخیره/ترتیب/حذف، و نوعِ webm حفظ می‌شود', () async {
      final m = MediaStore('${tmp.path}/media');
      await m.putVoice('b1', bytes: Uint8List.fromList([1, 2, 3]), type: 'audio/webm;codecs=opus', at: 200, ms: 1500);
      await m.putVoice('b1', bytes: Uint8List.fromList([4]), type: 'audio/webm', at: 100, ms: 10);
      final v = await m.voices('b1');
      expect(v.map((e) => e.at), [100, 200]);
      expect(v.last.type, 'audio/webm;codecs=opus');
      await m.deleteVoice('b1', v.first.id);
      expect((await m.voices('b1')).length, 1);
    });
  });

  test('چرخه‌ی کامل: state + عکس + صدا → فایل پشتیبان (رمزدار) → دستگاه خالی → بازیابی = همان', () async {
    // --- دستگاه مبدأ ---
    final a = AppStore('${tmp.path}/a/state.json', nowMs: () => _now)..load();
    final ma = MediaStore('${tmp.path}/a/media');
    a.state['habits'] = [{'id': 'h1', 'name': 'ورزش', 'type': 'binary', 'createdAt': '2026-09-01'}];
    a.state['books'] = [{'id': 'b1', 'title': 'کتاب', 'totalPages': 100, 'pagesRead': 10}];
    a.state['records'] = {'2026-09-29': {'h1': 'success'}};
    (a.state['scores'] as Map)['coins'] = 420;
    a.save();
    final pngB = 'data:image/png;base64,${base64.encode(List<int>.generate(200, (i) => i % 251))}';
    await ma.addPhoto(PhotoKind.habit, 'h1', pngB);
    await ma.addPhoto(PhotoKind.book, 'b1', pngB);
    final audio = Uint8List.fromList(List<int>.generate(3000, (i) => (i * 7) % 256));
    await ma.putVoice('b1', id: 'v1', bytes: audio, type: 'audio/webm;codecs=opus', at: 1700000000000, ms: 4200);

    final media = await ma.collectForBackup(a.state['books'] as List, a.state['habits'] as List);
    final plain = backupToJson(createBackupMap(a.state, exportedAtUtc: DateTime.utc(2026, 9, 30, 8), media: media));
    final enc = await rpEncryptBackup(plain, 'pw-123456', iterations: 2000); // تکرارِ کم فقط برای سرعتِ تست

    // --- دستگاه مقصد (خالی) ---
    final env = jsonDecode(enc) as Map;
    final dec = await rpDecryptBackup(env, 'pw-123456');
    expect(dec, isNotNull);
    final raw = jsonDecode(dec!);
    final v = rpValidateBackup(raw);
    expect(v.ok, isTrue);
    final b = AppStore('${tmp.path}/b/state.json', nowMs: () => _now)..load();
    applyBackupToState(b.state, v.next);
    b.save();
    final mb = MediaStore('${tmp.path}/b/media');
    await mb.restoreFromBackup((raw as Map)['data'] as Map);

    final b2 = AppStore('${tmp.path}/b/state.json', nowMs: () => _now)..load();
    expect((b2.state['habits'] as List).single['name'], 'ورزش');
    expect((b2.state['books'] as List).single['title'], 'کتاب');
    expect(b2.state['records'], {'2026-09-29': {'h1': 'success'}});
    expect((b2.state['scores'] as Map)['coins'], 420);
    expect((await mb.photos(PhotoKind.habit, 'h1')).single.dataUrl, pngB);
    expect((await mb.photos(PhotoKind.book, 'b1')).single.dataUrl, pngB);
    final vo = (await mb.voices('b1')).single;
    expect(vo.id, 'v1');
    expect(vo.bytes, audio, reason: 'بایت‌های صدا باید دقیقاً یکی باشد');
    expect(vo.type, 'audio/webm;codecs=opus');
    expect(vo.at, 1700000000000);
    expect(vo.ms, 4200);
    // بازیابیِ دوباره تکراری نمی‌سازد
    await mb.restoreFromBackup(raw['data'] as Map);
    expect((await mb.photos(PhotoKind.habit, 'h1')).length, 1);
    expect((await mb.voices('b1')).length, 1);
    expect(loadStateFromRaw(null, nowMs: 0).state['lang'], 'fa');
  });
}
