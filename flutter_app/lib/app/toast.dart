// Toast: همان showToast نسخه‌ی HTML (پیام + مدت + کلاس)، ولی روی Overlay برنامه.
import 'package:flutter/material.dart';

import '../ui/tokens.dart';

class ToastMsg {
  final String text;
  final String? cls; // level-toast-up | level-toast-mastery | toast-success
  final int ms;
  ToastMsg(this.text, {this.cls, this.ms = 3500});
}

class ToastBus extends ChangeNotifier {
  ToastMsg? current;
  int _token = 0;

  void show(String text, {String? cls, int ms = 3500}) {
    current = ToastMsg(text, cls: cls, ms: ms);
    final t = ++_token;
    notifyListeners();
    Future.delayed(Duration(milliseconds: ms), () {
      if (_token == t) {
        current = null;
        notifyListeners();
      }
    });
  }
}

class ToastHost extends StatelessWidget {
  final ToastBus bus;
  const ToastHost({super.key, required this.bus});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bus,
      builder: (context, _) {
        final m = bus.current;
        final p = context.rp;
        final mastery = m?.cls == 'level-toast-mastery';
        final up = m?.cls == 'level-toast-up';
        final colors = mastery
            ? [p.gold, const Color(0xFFF1D27A)]
            : up
                ? [p.btnA, p.btnB]
                : [p.surface, p.surface];
        final fg = mastery ? p.onGold : (up ? p.onPrimary : p.text);
        return IgnorePointer(
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedSlide(
                duration: RpMotion.base,
                curve: RpMotion.ease,
                offset: m == null ? const Offset(0, -1.5) : Offset.zero,
                child: AnimatedOpacity(
                  duration: RpMotion.base,
                  opacity: m == null ? 0 : 1,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(RpRadius.md),
                      border: Border.all(color: p.line),
                      boxShadow: RpShadow.e3(context.rpBrightness),
                    ),
                    child: Text(m?.text ?? '', textAlign: TextAlign.center, style: rpText(RpType.body, weight: 700, color: fg)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
