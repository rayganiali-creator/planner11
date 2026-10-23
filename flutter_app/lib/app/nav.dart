// ناوبریِ تب‌ها با همان قاعده‌ی نسخه‌ی HTML (switchToView + rpHandleAndroidBack):
// هر ورودِ واقعی به یک تبِ تازه، تبِ قبلی را در پشته می‌گذارد (سقف ۲۰)؛ Back به همان تبِ قبلی برمی‌گردد،
// اگر پشته خالی بود به خانه، و در خانه از برنامه خارج می‌شود.
import 'package:flutter/foundation.dart';

enum AppView { dashboard, habits, month, year, library, purchases, journal, pomodoro, todo, settings, analytics, smart, progress, badges }

class NavController extends ChangeNotifier {
  static const AppView home = AppView.dashboard;
  AppView current = home;
  final List<AppView> history = [];

  void go(AppView v, {bool isBack = false}) {
    if (!isBack && current != v) {
      history.add(current);
      if (history.length > 20) history.removeAt(0);
    }
    current = v;
    notifyListeners();
  }

  /// true = مصرف شد؛ false = باید از برنامه خارج شد.
  bool handleBack() {
    if (current != home) {
      if (history.isNotEmpty) {
        go(history.removeLast(), isBack: true);
      } else {
        go(home, isBack: true);
      }
      return true;
    }
    return false;
  }
}
