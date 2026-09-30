import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../data/actions.dart';
import '../data/app_store.dart';
import '../ui/custom_theme.dart';
import '../ui/tokens.dart';
import '../features/avatar/avatar_compose.dart';
import '../data/billing.dart';
import '../data/files_service.dart';
import '../data/notifier.dart';
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
  const RoutineApp({super.key, required this.store, required this.nav, required this.toasts, required this.actions, this.avData, this.billing, this.notifier, this.files});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStore>.value(value: store),
        ChangeNotifierProvider<NavController>.value(value: nav),
        Provider<AppActions>.value(value: actions),
        Provider<AvData?>.value(value: avData),
        Provider<Notifier>.value(value: notifier ?? NoopNotifier()),
        Provider<FilesService>.value(value: files ?? UnavailableFiles(toasts, () => store.state['lang'] != 'en')),
        Provider<BillingService>.value(value: billing ?? UnavailableBilling(toasts, () => store.state['lang'] != 'en')),
        ListenableProvider<ToastBus>.value(value: toasts),
      ],
      child: Consumer<AppStore>(builder: (context, s, _) {
        final fa = s.state['lang'] != 'en';
        final dark = s.state['theme'] == 'dark';
        return MaterialApp(
          navigatorKey: rpNavKey,
          title: 'روتین پلنر',
          debugShowCheckedModeBanner: false,
          theme: buildRpTheme(dark ? Brightness.dark : Brightness.light, palette: paletteFromState(s.state)),
          themeMode: ThemeMode.light, // رنگ‌ها را paletteFromState تعیین می‌کند (شدتِ روشن/تاریک، لهجه، پس‌زمینه)
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
