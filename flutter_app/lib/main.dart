import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/nav.dart';
import 'app/toast.dart';
import 'data/actions.dart';
import 'data/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // پوشه‌ی خصوصیِ برنامه (همان `files/` اندروید): از برنامه‌های دیگر قابل خواندن نیست.
  final dir = await getApplicationSupportDirectory();
  final store = AppStore('${dir.path}/state.json')..load();
  final toasts = ToastBus();
  final actions = AppActions(store, toasts)..renderAll(); // renderAll() اولیه‌ی نسخه‌ی HTML
  runApp(RoutineApp(store: store, nav: NavController(), toasts: toasts, actions: actions));
}
