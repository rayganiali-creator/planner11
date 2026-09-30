import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/nav.dart';
import 'app/toast.dart';
import 'data/actions.dart';
import 'data/app_store.dart';
import 'data/native_api.dart';
import 'data/notifier.dart';
import 'data/pro_manager.dart';
import 'features/avatar/avatar_compose.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // پوشه‌ی خصوصیِ برنامه (همان `files/` اندروید): از برنامه‌های دیگر قابل خواندن نیست.
  final dir = await getApplicationSupportDirectory();
  final store = AppStore('${dir.path}/state.json')..load();
  final toasts = ToastBus();
  final actions = AppActions(store, toasts)..renderAll(); // renderAll() اولیه‌ی نسخه‌ی HTML
  final avData = await AvData.load();
  final pro = ProManager(store, ChannelNativeApi(), toasts, NoopNotifier());
  // همان رفتارِ HTML: بازیابیِ خرید هنگام بالا آمدن، هر دقیقه بررسیِ پایانِ دوره، و هنگام برگشت به برنامه
  pro.restore();
  Timer.periodic(const Duration(minutes: 1), (_) => pro.checkProExpiry());
  WidgetsBinding.instance.addObserver(_Resume(pro));
  runApp(RoutineApp(store: store, nav: NavController(), toasts: toasts, actions: actions, avData: avData, billing: pro));
}

class _Resume extends WidgetsBindingObserver {
  final ProManager pro;
  _Resume(this.pro);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) pro.checkProExpiry();
  }
}
