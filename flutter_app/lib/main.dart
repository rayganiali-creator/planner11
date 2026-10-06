import 'dart:async';

import 'package:flutter/foundation.dart';
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

void main() {
  // هر خطای پیش‌بینی‌نشده فقط ثبت می‌شود؛ برنامه نمی‌بندد و صفحه‌ی خطای خام (با جزئیات) به کاربر نشان داده نمی‌شود.
  runZonedGuarded(_main, (e, s) => debugPrint('uncaught: $e'));
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(['Vazirmatn font'], 'Copyright 2015-2024 The Vazirmatn Project Authors (https://github.com/rastikerdar/vazirmatn). Licensed under the SIL Open Font License, Version 1.1 (https://openfontlicense.org).');
    yield const LicenseEntryWithLineBreaks(['Lucide icons'], 'Lucide is licensed under the ISC License (https://lucide.dev/license).');
    yield const LicenseEntryWithLineBreaks(['Cafe Bazaar Poolakey'], 'Licensed under the Apache License, Version 2.0 (https://github.com/cafebazaar/Poolakey).');
  });
  final prevOnError = FlutterError.onError;
  FlutterError.onError = (d) {
    if (!kReleaseMode) prevOnError?.call(d);
    debugPrint('flutter error: ${d.exceptionAsString()}');
  };
  ErrorWidget.builder = (d) => kReleaseMode ? const SizedBox.shrink() : ErrorWidget(d.exception);
  // پوشه‌ی خصوصیِ برنامه (همان `files/` اندروید): از برنامه‌های دیگر قابل خواندن نیست.
  final dir = await getApplicationSupportDirectory();
  final store = AppStore('${dir.path}/state.json')..load();
  final toasts = ToastBus();
  final actions = AppActions(store, toasts);
  try {
    actions.renderAll(); // renderAll() اولیه‌ی نسخه‌ی HTML
  } catch (e) {
    debugPrint('initial render failed: $e'); // داده‌ی خراب نباید جلوی بالا آمدنِ برنامه را بگیرد
  }
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
