// پرسشِ «نظر بدهی؟» هنگام خروج از برنامه (کافه‌بازار).
// قاعده: اگر کاربر «ثبت نظر» را زد، دیگر نمایش داده نمی‌شود؛ وگرنه در هر خروج دوباره می‌پرسد.
// توجه: بازار نتیجه‌ی ثبتِ نظر را به برنامه خبر نمی‌دهد؛ ضربه روی «ثبت نظر» به‌منزله‌ی انجامِ کار گرفته می‌شود.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../data/app_store.dart';
import '../../ui/tokens.dart';

const _channel = MethodChannel('rp/native');

/// صفحه‌ی ثبتِ نظرِ همین برنامه را در کافه‌بازار باز می‌کند (false = بازار نصب نیست/باز نشد).
Future<bool> openBazaarReview() async {
  try {
    await _channel.invokeMethod('openReview');
    return true;
  } catch (_) {
    return false;
  }
}

bool hasRatedOnBazaar(Map state) => state['ratedBazaar'] == true;

/// خروجِ کاربر را مدیریت می‌کند: یا می‌پرسد یا مستقیم خارج می‌شود.
Future<void> askReviewOrExit(BuildContext context, {Future<bool> Function()? open, VoidCallback? exit}) async {
  final store = context.read<AppStore>();
  final doExit = exit ?? () => SystemNavigator.pop();
  if (hasRatedOnBazaar(store.state)) {
    doExit();
    return;
  }
  final p = context.rp;
  final choice = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RpRadius.lg)),
      icon: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (int i = 0; i < 5; i++) const Icon(LucideIcons.star, size: 26, color: Color(0xFFFFB300), fill: 1),
      ]),
      title: Text(context.tr('از روتین پلنر راضی بودی؟', 'Enjoying Routine Planner?'), textAlign: TextAlign.center, style: rpText(RpType.titleL, weight: 800, color: p.text)),
      content: Text(
        context.tr('اگه این برنامه به منظم‌تر شدن روزهات کمک کرده، یه نظر و ۵ ستاره توی کافه‌بازار بزرگ‌ترین هدیه‌ایه که می‌تونی به ما بدی؛ فقط چند ثانیه وقت می‌گیره و به ما انگیزه می‌ده بهترش کنیم. 💛', 'If it helped you keep your days in order, a 5-star review on Cafe Bazaar is the best gift you can give us. It takes just a few seconds.'),
        textAlign: TextAlign.center,
        style: rpText(RpType.body, weight: 500, color: p.muted),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        FilledButton.icon(onPressed: () => Navigator.pop(ctx, 1), icon: const Icon(LucideIcons.star, size: 16), label: Text(context.tr('حتماً، ثبت نظر ⭐', 'Sure, leave a review ⭐'))),
        TextButton(onPressed: () => Navigator.pop(ctx, 2), child: Text(context.tr('فعلاً نه، خروج', 'Not now, exit'), style: TextStyle(color: p.muted))),
      ],
    ),
  );
  if (choice == 1) {
    final ok = await (open ?? openBazaarReview)();
    if (ok) {
      store.state['ratedBazaar'] = true;
      store.save();
    }
    // برنامه باز می‌ماند: کاربر پس از ثبتِ نظر به همین‌جا برمی‌گردد.
  } else if (choice == 2) {
    doExit();
  }
}
