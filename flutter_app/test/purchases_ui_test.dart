import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/app.dart';
import 'package:routine_planner/app/nav.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/pro.dart';
import 'package:routine_planner/data/actions.dart';
import 'package:routine_planner/data/app_store.dart';

void main() {
  testWidgets('خریدها: ۱۵ روز مانده از یک‌ماهه + دوماهه = ۷۵ روز، و پلن‌های خریداری‌شده غیرفعال‌اند', (tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('rp_p');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    final now = DateTime.now().millisecondsSinceEpoch;
    const day = 86400000;
    final t1 = now - 15 * day, t2 = now - 1000;
    final purchases = [
      {'productId': 'rp_pro_1m', 'purchaseTime': t1, 'purchaseToken': 'tokenAAAAAAAAAAA1'},
      {'productId': 'rp_pro_2m', 'purchaseTime': t2, 'purchaseToken': 'tokenBBBBBBBBBBB2'},
    ];
    final w = computeProWindow(purchases);
    store.state['isPremium'] = true;
    store.state['proCache'] = {'purchases': purchases, 'expiresAt': w.expiresAt};
    final toasts = ToastBus();
    final a = AppActions(store, toasts);
    final nav = NavController()..go(AppView.purchases);
    await tester.pumpWidget(RoutineApp(store: store, nav: nav, toasts: toasts, actions: a));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('۷۵'), findsOneWidget);
    expect(find.text('خریداری‌شده'), findsNWidgets(2)); // ۱ماهه و ۲ماهه هنوز در دوره‌اند
    expect(find.text('افزودن'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
  });
}
