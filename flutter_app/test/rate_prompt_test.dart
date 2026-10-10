import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/ui/tokens.dart';
import 'package:routine_planner/features/rating/rate_prompt.dart';

Future<(AppStore, int, int)> _run(WidgetTester tester, {required bool rated, required String tap}) async {
  final dir = Directory.systemTemp.createTempSync('rp_rate');
  addTearDown(() => dir.deleteSync(recursive: true));
  final store = AppStore('${dir.path}/s.json')..load();
  if (rated) store.state['ratedBazaar'] = true;
  int exits = 0, opens = 0;
  await tester.pumpWidget(ChangeNotifierProvider<AppStore>.value(
    value: store,
    child: MaterialApp(theme: buildRpTheme(Brightness.light), home: Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => askReviewOrExit(c, open: () async { opens++; return true; }, exit: () => exits++), child: const Text('go'))))),
  ));
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  if (tap.isNotEmpty) {
    await tester.tap(find.textContaining(tap));
    await tester.pumpAndSettle();
  }
  return (store, exits, opens);
}

void main() {
  testWidgets('قبلاً نظر داده: مستقیم خارج می‌شود و پرسشی نیست', (tester) async {
    final r = await _run(tester, rated: true, tap: '');
    expect(r.$2, 1);
    expect(find.textContaining('ثبت نظر'), findsNothing);
  });
  testWidgets('ثبت نظر: بازار باز می‌شود، پرچم ذخیره و برنامه بسته نمی‌شود', (tester) async {
    final r = await _run(tester, rated: false, tap: 'حتماً');
    expect(r.$3, 1);
    expect(r.$2, 0);
    expect(r.$1.state['ratedBazaar'], true);
  });
  testWidgets('«فعلاً نه»: خروج، و پرچم ذخیره نمی‌شود (دفعه‌ی بعد دوباره می‌پرسد)', (tester) async {
    final r = await _run(tester, rated: false, tap: 'فعلاً نه');
    expect(r.$2, 1);
    expect(r.$3, 0);
    expect(r.$1.state['ratedBazaar'], isNot(true));
  });
}
