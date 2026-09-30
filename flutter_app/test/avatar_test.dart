// مقایسه‌ی پیکسلی: avCompose دارتی با خروجیِ واقعیِ JS (tools/avatar-compare/gen_js.py) روی ۴۰ پیکربندی.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/features/avatar/avatar_compose.dart';

Future<List<int>> _rgba(ui.Image im) async => (await im.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('آواتار دارت با JS پیکسل‌به‌پیکسل قابل‌مقایسه است', () async {
    final data = await AvData.load();
    final cases = (jsonDecode(File('test/golden/avatar/cases.json').readAsStringSync()) as List).cast<Map>();
    int worst = 0, exact = 0;
    final report = <String>[];
    for (int n = 0; n < cases.length; n++) {
      final c = cases[n];
      final eq = {for (final e in (c['equipped'] as Map).entries) e.key as String: e.value as String};
      final mine = await avCompose(data, c['gender'], eq, c['cond'], mode: c['mode']);
      expect(mine, isNotNull, reason: 'case $n');
      final ref = await (await ui.instantiateImageCodec(File('test/golden/avatar/$n.png').readAsBytesSync())).getNextFrame();
      expect([mine!.width, mine.height], [ref.image.width, ref.image.height]);
      final a = await _rgba(mine), b = await _rgba(ref.image);
      int diff = 0, maxd = 0;
      for (int i = 0; i < a.length; i += 4) {
        // آلفای صفر = پیکسل خالی؛ RGB آن بی‌معناست
        if (a[i + 3] == 0 && b[i + 3] == 0) continue;
        final d = [for (int k = 0; k < 4; k++) (a[i + k] - b[i + k]).abs()].reduce((x, y) => x > y ? x : y);
        if (d > 2) diff++;
        if (d > maxd) maxd = d;
      }
      if (diff == 0) exact++;
      if (diff > worst) worst = diff;
      if (diff > 0) report.add('case $n: $diff px differ (max channel diff $maxd) ${jsonEncode(c)}');
    }
    // ignore: avoid_print
    print('exact=$exact/${cases.length} worstDiffPixels=$worst\n${report.take(8).join('\n')}');
    expect(worst, lessThan(60), reason: report.join('\n'));
  });
}
