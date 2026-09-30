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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AvData loaded;
  setUpAll(() async => loaded = await AvData.load());
  testWidgets('داشبورد: بدون جنسیت دعوت به ساخت؛ انتخاب جنسیت و باز شدن پنل', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final data = loaded;
    final dir = Directory.systemTemp.createTempSync('rp_av2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    await tester.pumpWidget(RoutineApp(store: store, nav: NavController(), toasts: toasts, actions: a, avData: data));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('آواتار خودت را بساز'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    await tester.tap(find.text('زن'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    expect(a.avState().gender, 'female');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });
}
