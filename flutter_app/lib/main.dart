import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/nav.dart';
import 'app/toast.dart';
import 'data/actions.dart';
import 'data/app_store.dart';
import 'data/backup_service.dart';
import 'data/local_notifier.dart';
import 'data/media_store.dart';
import 'data/native_api.dart';
import 'data/pro_manager.dart';
import 'features/onboarding/onboarding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // پوشه‌ی خصوصیِ برنامه (همان `files/` اندروید): از برنامه‌های دیگر قابل خواندن نیست.
  final dir = await getApplicationSupportDirectory();
  final store = AppStore('${dir.path}/state.json')..load();
  final toasts = ToastBus();
  final actions = AppActions(store, toasts)..renderAll(); // renderAll() اولیه‌ی نسخه‌ی HTML
  final texts = await AppTexts.load();
  final native = ChannelNativeApi();
  final media = MediaStore('${dir.path}/media');
  actions.media = media;
  final files = BackupService(actions, media, native, toasts);
  await files.importHandoff(dir.path); // فقط اگر rp_handoff.json (هنوز واردنشده) باشد؛ بعد از موفقیت تغییر نام می‌دهد
  final notifier = LocalNotifier();
  await notifier.init();
  final pro = ProManager(store, native, toasts, notifier);
  final sync = ReminderSync(store, notifier)..syncNow(); // مثل nativeResyncAllReminders هنگام باز شدن
  // همان رفتارِ HTML: بازیابیِ خرید هنگام بالا آمدن، هر دقیقه بررسیِ پایانِ دوره، و هنگام برگشت به برنامه
  pro.restore();
  Timer.periodic(const Duration(minutes: 1), (_) => pro.checkProExpiry());
  WidgetsBinding.instance.addObserver(_Resume(pro, sync));
  runApp(RoutineApp(store: store, nav: NavController(), toasts: toasts, actions: actions, billing: pro, files: files, notifier: notifier, media: media, texts: texts));
}

class _Resume extends WidgetsBindingObserver {
  final ProManager pro;
  final ReminderSync sync;
  _Resume(this.pro, this.sync);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      pro.checkProExpiry();
      sync.syncNow();
    }
  }
}
