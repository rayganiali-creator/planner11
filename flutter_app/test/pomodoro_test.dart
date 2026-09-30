import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/notifier.dart';
import 'package:routine_planner/data/pomodoro_ops.dart';

class _Rec implements Notifier {
  final calls = <String>[];
  @override
  Future<void> scheduleOnce(String id, String title, String body, int atMs) async => calls.add('sched $id $atMs');
  @override
  Future<void> cancel(String id) async => calls.add('cancel $id');
}

void main() {
  test('چرخه‌ی کامل: تمرکز ← استراحت کوتاه … ← بلند بعد از ۴ دور؛ مکث؛ محدودیت رایگان', () async {
    final dir = Directory.systemTemp.createTempSync('rp_p');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    var now = DateTime(2026, 9, 30, 10);
    final a = AppActions(store, ToastBus(), clock: () => now);
    final n = _Rec();
    expect(a.pomoRemaining(), 25 * 60000);
    a.pomoStart(notifier: n);
    final p = a.pomoState();
    expect(p['endsAt'], now.millisecondsSinceEpoch + 25 * 60000);
    now = now.add(const Duration(minutes: 10));
    expect(a.pomoRemaining(), 15 * 60000);
    a.pomoPause(notifier: n);
    expect(p['remainingMs'], 15 * 60000);
    now = now.add(const Duration(hours: 1)); // مکث: زمان نمی‌گذرد
    expect(a.pomoRemaining(), 15 * 60000);
    a.pomoStart(notifier: n);
    now = now.add(const Duration(minutes: 15, seconds: 1));
    expect(a.pomoTick(), isTrue);
    expect(p['phase'], 'short');
    expect(p['cycle'], 1);
    expect(p['running'], false);
    final phases = <String>[];
    for (int i = 0; i < 6; i++) {
      a.pomoStart(notifier: n);
      now = now.add(const Duration(hours: 1));
      a.pomoTick();
      phases.add('${p['phase']}');
    }
    // دور ۱ تمام شد؛ دورهای ۲ و ۳ استراحت کوتاه، دور ۴ استراحت بلند
    expect(phases, ['focus', 'short', 'focus', 'short', 'focus', 'long']);
    expect(p['cycle'], 4);
    // رایگان: تنظیم دلخواه نادیده گرفته می‌شود
    a.pomoSetMinutes('focus', 50, 180);
    expect(a.pomoMinutes('focus'), 25);
    store.state['isPremium'] = true;
    a.pomoSetMinutes('focus', 500, 180);
    expect(a.pomoMinutes('focus'), 180); // سقف
    a.pomoSetMinutes('focus', 0, 180);
    expect(a.pomoMinutes('focus'), 1);
    a.pomoSetPhase('focus', notifier: n);
    expect(a.pomoRemaining(), 60000);
    expect(n.calls.any((c) => c.startsWith('sched pomodoro')), isTrue);
    await Future<void>.delayed(Duration.zero);
  });

  testWidgets('صفحه‌ی پومودورو: شروع و مکث', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_p2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    final nav = NavController()..go(AppView.pomodoro);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('۲۵:۰۰'), findsOneWidget);
    await tester.tap(find.text('▶ شروع'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(a.pomoState()['running'], true);
    expect(find.text('⏸ مکث'), findsOneWidget);
    await tester.tap(find.text('⏸ مکث'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(a.pomoState()['running'], false);
    await tester.pumpWidget(const SizedBox());
  });
}
