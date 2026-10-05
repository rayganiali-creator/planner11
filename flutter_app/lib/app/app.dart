import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../data/actions.dart';
import '../data/app_store.dart';
import '../ui/app_themes.dart';
import '../ui/tokens.dart';
import '../features/avatar/avatar_compose.dart';
import '../data/billing.dart';
import '../data/files_service.dart';
import '../data/media_store.dart';
import '../data/notifier.dart';
import '../features/onboarding/onboarding.dart';
import 'nav.dart';
import 'nav_key.dart';
import 'shell.dart';
import 'toast.dart';

class RoutineApp extends StatelessWidget {
  final AppStore store;
  final NavController nav;
  final ToastBus toasts;
  final AppActions actions;
  final AvData? avData;
  final BillingService? billing;
  final Notifier? notifier;
  final FilesService? files;
  final MediaStore? media;
  final AppTexts? texts;
  const RoutineApp({super.key, required this.store, required this.nav, required this.toasts, required this.actions, this.avData, this.billing, this.notifier, this.files, this.media, this.texts});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStore>.value(value: store),
        ChangeNotifierProvider<NavController>.value(value: nav),
        Provider<AppActions>.value(value: actions),
        Provider<AvData?>.value(value: avData),
        Provider<Notifier>.value(value: notifier ?? NoopNotifier()),
        Provider<AppTexts?>.value(value: texts),
        Provider<MediaStore>.value(value: media ?? MediaStore('${Directory.systemTemp.path}/rp_media_fallback')),
        Provider<FilesService>.value(value: files ?? UnavailableFiles(toasts, () => store.state['lang'] != 'en')),
        Provider<BillingService>.value(value: billing ?? UnavailableBilling(toasts, () => store.state['lang'] != 'en')),
        ListenableProvider<ToastBus>.value(value: toasts),
      ],
      child: Consumer<AppStore>(builder: (context, s, _) {
        final fa = s.state['lang'] != 'en';
        final platform = MediaQuery.platformBrightnessOf(context);
        final dark = isDarkMode(s.state, platform);
        return MaterialApp(
          navigatorKey: rpNavKey,
          title: 'روتین پلنر',
          debugShowCheckedModeBanner: false,
          theme: buildRpTheme(dark ? Brightness.dark : Brightness.light, palette: paletteFor(s.state, platform)),
          themeMode: ThemeMode.light, // پالتِ کامل را تمِ انتخابی + حالت (روشن/تاریک/سیستم) تعیین می‌کند
          locale: Locale(fa ? 'fa' : 'en'),
          supportedLocales: const [Locale('fa'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(switch (s.state['fontSize']) { 'small' => 0.8, 'large' => 1.2, _ => 1.0 })),
            child: Directionality(
              textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
              child: Stack(children: [child!, ToastHost(bus: toasts)]),
            ),
          ),
          home: const Shell(),
        );
      }),
    );
  }
}
