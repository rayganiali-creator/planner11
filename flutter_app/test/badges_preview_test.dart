// پیش‌نمایشِ تصویریِ صفحه‌ی نشان‌ها در اپ (مجموعه‌ی ۴۸تایی) — فقط برای دیدنِ نتیجه: flutter test --update-goldens test/badges_preview_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/progress/achievements.dart';
import 'package:routine_planner/core/progress/engine.dart';

import 'progress_ui_test.dart';

void main() {
  testWidgets('پیش‌نمایشِ صفحه‌ی نشان‌ها', (tester) async {
    final loader = FontLoader('Vazirmatn')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Vazirmatn-arabic.ttf').readAsBytesSync())));
    await loader.load();
    final (store, _, _) = await boot(tester, view: AppView.badges, size: const Size(1080, 4200), prep: (s, a) {
      final hid = addHabit(a, 'ورزش');
      (s.state['habits'] as List).single['createdAt'] = iso(40);
      s.state['records'] = {for (int i = 0; i < 20; i++) iso(i): {hid: 'success'}};
      final un = ((s.state['progress'] ??= <String, dynamic>{}) as Map);
      un['unlocked'] = <String, dynamic>{
        for (final id in ['first_habit', 'cons_3', 'cons_7', 'cons_14', 'focus_1', 'focus_5', 'deep_focus', 'task_1', 'task_10', 'task_50', 'book_1', 'book_5', 'chal_1', 'level_10', 'level_25'])
          id: {'at': base.millisecondsSinceEpoch, 'date': iso(0)}
      };
    });
    expect(achievementCatalog.length, 48);
    for (int i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (int i = 0; i < 6 && find.byKey(const ValueKey('reveal-ok')).evaluate().isNotEmpty; i++) {
      await tester.tap(find.byKey(const ValueKey('reveal-ok')).last);
      await tester.pump(const Duration(milliseconds: 800));
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('/tmp/g/badges_screen.png'));
    await drain(tester);
  });
}
