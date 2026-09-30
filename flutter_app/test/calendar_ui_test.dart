import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/habit_ops.dart';

void main() {
  for (final cal in ['jalali', 'gregorian']) {
    for (final view in [AppView.month, AppView.year]) {
      testWidgets('$view ($cal): رسم می‌شود و ثبتِ روز از پنجره‌ی روز کار می‌کند', (tester) async {
        tester.view.physicalSize = const Size(1080, 2600);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final dir = Directory.systemTemp.createTempSync('rp_c');
        addTearDown(() => dir.deleteSync(recursive: true));
        final store = AppStore('${dir.path}/s.json')..load();
        store.state['calendarType'] = cal;
        final toasts = ToastBus();
        final a = AppActions(store, toasts);
        a.saveHabit(HabitForm(a.todayISO)..name = 'ورزش');
        final nav = NavController()..go(view);
        await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
        await tester.pump(const Duration(milliseconds: 500));
        final f = find.byKey(ValueKey('day-${a.todayISO}'));
        expect(f, findsOneWidget);
        await tester.ensureVisible(f.first);
        await tester.pump();
        await tester.tap(f.first, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
        expect(find.text('ورزش'), findsOneWidget);
        await tester.tap(find.byIcon(LucideIcons.check));
        await tester.pump(const Duration(milliseconds: 300));
        expect(((store.state['records'] as Map)[a.todayISO] as Map)[(store.state['habits'] as List).first['id']], 'success');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
