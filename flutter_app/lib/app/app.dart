import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../data/actions.dart';
import '../data/app_store.dart';
import '../ui/tokens.dart';
import 'nav.dart';
import 'shell.dart';
import 'toast.dart';

class RoutineApp extends StatelessWidget {
  final AppStore store;
  final NavController nav;
  final ToastBus toasts;
  final AppActions actions;
  const RoutineApp({super.key, required this.store, required this.nav, required this.toasts, required this.actions});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStore>.value(value: store),
        ChangeNotifierProvider<NavController>.value(value: nav),
        Provider<AppActions>.value(value: actions),
        ListenableProvider<ToastBus>.value(value: toasts),
      ],
      child: Consumer<AppStore>(builder: (context, s, _) {
        final fa = s.state['lang'] != 'en';
        final dark = s.state['theme'] == 'dark';
        return MaterialApp(
          title: 'روتین پلنر',
          debugShowCheckedModeBanner: false,
          theme: buildRpTheme(Brightness.light),
          darkTheme: buildRpTheme(Brightness.dark),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          locale: Locale(fa ? 'fa' : 'en'),
          supportedLocales: const [Locale('fa'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => Directionality(
            textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
            child: Stack(children: [child!, ToastHost(bus: toasts)]),
          ),
          home: const Shell(),
        );
      }),
    );
  }
}
