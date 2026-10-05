// هر آیتمِ آواتار روی هر جنسیتِ سازگار، پیکسل‌به‌پیکسل با خروجیِ واقعیِ JS (tools/avatar-compare/gen_all.py).
// تنها اختلاف مجاز: سایه‌ی حیوان (چند پیکسل با اختلافِ ناچیز).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/features/avatar/avatar_compose.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('همه‌ی آیتم‌ها × جنسیت‌ها با JS یکسان‌اند', () async {
    final data = await AvData.load();
    final cases = (jsonDecode(File('test/golden/avatar_all/cases.json').readAsStringSync()) as List).cast<Map>();
    expect(cases.length, greaterThan(250));
    final bad = <String>[];
    for (int n = 0; n < cases.length; n++) {
      final c = cases[n];
      final eq = {for (final e in (c['equipped'] as Map).entries) e.key as String: e.value as String};
      final mine = await avCompose(data, c['gender'], eq, 'ok');
      if (mine == null) {
        bad.add('${c['id']} ${c['gender']}: null');
        continue;
      }
      final ref = await (await ui.instantiateImageCodec(File('test/golden/avatar_all/$n.png').readAsBytesSync())).getNextFrame();
      final a = (await mine.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
      final b = (await ref.image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
      if (a.length != b.length) {
        bad.add('${c['id']} ${c['gender']}: size');
        continue;
      }
      int diff = 0;
      for (int i = 0; i < a.length; i += 4) {
        if (a[i + 3] == 0 && b[i + 3] == 0) continue;
        final d = [for (int k = 0; k < 4; k++) (a[i + k] - b[i + k]).abs()].reduce((x, y) => x > y ? x : y);
        if (d > 2) diff++;
      }
      final isPet = '${c['id']}'.startsWith('pets/') || '${c['id']}'.startsWith('petgear/');
      if (diff > (isPet ? 80 : 0)) bad.add('${c['id']} ${c['gender']}: $diff px');
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });
}
