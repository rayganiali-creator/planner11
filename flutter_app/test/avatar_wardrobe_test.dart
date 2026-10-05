import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/avatar_ops.dart';
import 'package:routine_planner/features/avatar/avatar_compose.dart';
import 'package:routine_planner/features/avatar/avatar_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AvData data;
  setUpAll(() async => data = await AvData.load());
  testWidgets('کمد آواتار: انتخاب هر دسته آیتم‌های همان دسته را نشان می‌دهد', (tester) async {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_wr');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts)..chooseGender('male');
    await tester.pumpWidget(RoutineApp(store: store, nav: NavController(), toasts: toasts, actions: a, avData: data));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(AvatarView).last);
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    expect(find.text('آواتار من'), findsOneWidget);
    for (final (chip, sample) in [('🦺 زره', 'armor'), ('💇 مو', 'hair'), ('🧢 کلاه', 'hat')]) {
      final hs = find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.horizontal);
      for (int i = 0; i < 30 && find.text(chip).evaluate().isEmpty; i++) {
        await tester.drag(hs, Offset(i < 15 ? 160 : -160, 0));
        await tester.pump();
      }
      expect(find.text(chip), findsOneWidget, reason: 'chip $chip not reachable');
      await tester.pump();
      await tester.tap(find.text(chip));
      await tester.pump(const Duration(milliseconds: 300));
      final expectNames = [for (final it in data.items.values) if (it.category == sample && it.compatible('male')) it.name];
      expect(expectNames, isNotEmpty);
      expect(find.text(expectNames.first!), findsWidgets, reason: sample);
    }
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });
}
