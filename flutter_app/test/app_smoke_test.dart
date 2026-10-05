// دودِ برنامه: داشبورد بالا می‌آید، ثبتِ عادت از مسیرِ واقعی (AppActions) انجام و ذخیره می‌شود،
// تب‌ها جابه‌جا می‌شوند و Back اندروید همان ترتیب را دارد.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';

void main() {
  testWidgets('dashboard renders, habit toggle persists, nav back works', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_smoke');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/state.json')..load();
    store.state['habits'] = [
      {'id': 'h1', 'name': 'ورزش', 'type': 'binary', 'reward': 10, 'direction': 'more'},
    ];
    final toasts = ToastBus();
    final actions = AppActions(store, toasts)..renderAll();
    final nav = NavController();
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: actions));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('روتین پلنر'), findsWidgets);
    expect(find.text('ورزش', findRichText: true, skipOffstage: false), findsWidgets);

    final iso = actions.todayISO;
    await tester.scrollUntilVisible(find.byIcon(LucideIcons.check), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.check));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    await tester.tap(find.text('رد شدن')); // پنجره‌ی «چرا؟»
    await tester.pump(const Duration(milliseconds: 400));
    expect(((store.state['records'] as Map)[iso] as Map)['h1'], 'success');
    expect(File('${dir.path}/state.json').existsSync(), isTrue);

    nav.go(AppView.habits);
    await tester.pump(const Duration(milliseconds: 400));
    expect(nav.handleBack(), isTrue);
    expect(nav.current, AppView.dashboard);
    expect(nav.handleBack(), isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
