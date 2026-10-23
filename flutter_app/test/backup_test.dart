// تست تفاضلی پشتیبان‌گیری: اعتبارسنجی، بازیابی، ساخت JSON (مقایسه‌ی متن به متن با JS) و رمزنگاری
// (فایلِ رمزشده‌ی JS را Dart باز می‌کند؛ بالعکس با tool/verify_dart_crypto.py).
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/backup.dart';
import 'package:routine_planner/core/state_model.dart';

import 'golden_loader.dart';

Map<String, dynamic> _copy(Object? o) => jsonDecode(jsonEncode(o)) as Map<String, dynamic>;

// تفاوتِ آگاهانه با نسخه‌ی HTML: سیستمِ آواتار/سکه/سطحِ عادت حذف شد (این کلیدها دیگر ساخته/اعتبارسنجی نمی‌شوند) و
// سیستمِ پیشرفت دو کلیدِ تازه دارد (progress, todoLog). برای مقایسه با JS این کلیدها از هر دو طرف کنار گذاشته می‌شوند.
const _legacyKeys = {'avatar', 'levelToastSent', 'levelReachedColor', 'masteryColor', 'progress', 'todoLog'};
Object? _strip(Object? o) {
  if (o is Map) {
    return {for (final e in o.entries) if (!_legacyKeys.contains(e.key)) e.key: _strip(e.value)};
  }
  if (o is List) return [for (final e in o) if (!(e is String && _legacyKeys.contains(e))) _strip(e)];
  return o;
}

void main() {
  group('اعتبارسنجی و بازیابی', () {
    final rows = (loadGolden('backup_validate') as List).cast<Map<String, dynamic>>();
    test('همه‌ی ${rows.length} مورد با JS یکسان است', () {
      int bad = 0;
      final msgs = <String>[];
      for (final r in rows) {
        final fn = r['fn'] as String;
        final a = r['args'] as List;
        Object? got;
        if (fn == 'validateBackup') {
          final v = rpValidateBackup(a[0]);
          got = v.ok ? {'ok': true, 'next': v.next, 'skipped': v.skipped, 'version': v.version} : {'ok': false};
        } else {
          final st = _copy(a[0]);
          final v = rpValidateBackup(a[1]);
          if (!v.ok) {
            got = {'ok': false};
          } else {
            applyBackupToState(st, v.next);
            got = {'ok': true, 'state': st, 'skipped': v.skipped, 'version': v.version};
          }
        }
        final d = firstDiff(_strip(jsonDecode(jsonEncode(got))), _strip(r['ok']));
        if (d != null) {
          bad++;
          if (msgs.length < 8) msgs.add('$fn: $d');
        }
      }
      expect(bad, 0, reason: msgs.join('\n'));
    });
  });

  group('ساخت JSON', () {
    final rows = (loadGolden('backup_create') as List).cast<Map<String, dynamic>>();
    test('متنِ JSON همه‌ی ${rows.length} مورد حرف‌به‌حرف با JS یکی است', () {
      int bad = 0;
      final msgs = <String>[];
      for (final r in rows) {
        final st = _copy(r['state']);
        final got = jsonEncode(_strip(jsonDecode(backupToJson(createBackupMap(st, exportedAtUtc: DateTime.parse(r['now'] as String))))));
        final want = jsonEncode(_strip(jsonDecode(r['ok'] as String)));
        if (got != want) {
          bad++;
          if (msgs.length < 4) {
            int i = 0;
            while (i < got.length && i < want.length && got[i] == want[i]) {
              i++;
            }
            msgs.add('اولین تفاوت @$i\n  Dart: …${got.substring((i - 40).clamp(0, got.length), (i + 60).clamp(0, got.length))}\n  JS:   …${want.substring((i - 40).clamp(0, want.length), (i + 60).clamp(0, want.length))}');
          }
        }
      }
      expect(bad, 0, reason: msgs.join('\n'));
    });
  });

  group('رمزنگاری', () {
    final rows = (loadGolden('backup_crypto') as List).cast<Map<String, dynamic>>();
    test('فایل‌های رمزشده‌ی JS در Dart باز می‌شوند (و رمز غلط/دست‌کاری رد می‌شود)', () async {
      int bad = 0;
      final msgs = <String>[];
      // موازی در Isolateها (هر مشتق‌سازی حدود ۱ ثانیه است)
      for (int i = 0; i < rows.length; i += 8) {
        final chunk = rows.skip(i).take(8).toList();
        final outs = await Future.wait(chunk.map((r) => Isolate.run(() => rpDecryptBackup(jsonDecode(r['env'] as String) as Map, r['pass'] as String))));
        for (int j = 0; j < chunk.length; j++) {
          if (outs[j] != chunk[j]['expect']) {
            bad++;
            if (msgs.length < 5) msgs.add('#${i + j} expect=${(chunk[j]['expect'] as String?)?.length} got=${outs[j]?.length}');
          }
        }
      }
      expect(bad, 0, reason: msgs.join('\n'));
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('Dart رمز می‌کند و برای تأییدِ JS فایل می‌نویسد (tool/verify_dart_crypto.py)', () async {
      final plains = ['{}', 'روتین پلنر — یادداشتِ خصوصی 🔒 «نقل» "q" \\ \n\t', '{"k":"${'متن ' * 4000}"}', '😀' * 300];
      final passes = ['abcdef', 'رمزِ فارسی ۱۲۳۴۵۶', 'p@ss w0rd', '😀🔑'];
      final out = <Map<String, String>>[];
      for (int i = 0; i < plains.length; i++) {
        final env = await Isolate.run(() => rpEncryptBackup(plains[i], passes[i]));
        out.add({'plain': plains[i], 'pass': passes[i], 'env': env});
        // خودِ Dart هم باید باز کند
        expect(await rpDecryptBackup(jsonDecode(env) as Map, passes[i]), plains[i]);
        expect(await rpDecryptBackup(jsonDecode(env) as Map, '${passes[i]}!'), isNull);
      }
      Directory('build').createSync(recursive: true);
      File('build/dart_crypto_out.json').writeAsStringSync(jsonEncode(out));
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  test('هر نمایه‌ی بارگذاری پس از بازیابی دوباره قابل ذخیره/خواندن است (round trip)', () {
    final l = loadStateFromRaw(jsonEncode({'habits': [{'id': 'h', 'type': 'binary', 'createdAt': '2026-01-01'}], 'records': {}, 'scores': {'coins': 12}}), nowMs: 1790762400000);
    final m = createBackupMap(l.state, exportedAtUtc: DateTime.utc(2026, 9, 30, 8));
    final v = rpValidateBackup(jsonDecode(backupToJson(m)));
    expect(v.ok, isTrue);
    final st2 = defaultState();
    applyBackupToState(st2, v.next);
    expect((st2['habits'] as List).length, 1);
    expect((st2['scores'] as Map)['coins'], 12);
  });
}
