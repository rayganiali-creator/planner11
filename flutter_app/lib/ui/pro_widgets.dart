// ویجت‌های مرکزیِ Free/Pro: برای کاربر پرو هیچ‌چیز نمایش نمی‌دهند (بدون قفل، توضیح، پیام محدودیت و CTA).
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app/i18n.dart';
import '../app/nav.dart';
import '../core/pro_features.dart';
import '../data/actions.dart';
import '../data/app_store.dart';
import 'tokens.dart';
import 'widgets.dart';

extension ProContext on BuildContext {
  /// پرو بودن؛ با تغییرِ وضعیتِ پرو ویجت دوباره ساخته می‌شود
  bool get isPro => isProState(watch<AppStore>().state);
}

/// پیامِ محدودیتِ یک قابلیت را (فقط وقتی واقعاً مسدود شده) به‌صورت توست نشان می‌دهد.
void showProBlocked(BuildContext context, ProFeature f) {
  final i = proInfos[f]!;
  final a = context.read<AppActions>();
  if (isProState(a.store.state)) return; // کاربر پرو هرگز پیامِ محدودیت نمی‌بیند
  a.toasts.show('⭐ ${context.tr(i.lockFa, i.lockEn)}', ms: 3400);
}

/// رفتن به صفحه‌ی خریدها (بستنِ مودال‌های باز)
void goToPurchases(BuildContext context) {
  final nav = context.read<NavController>();
  Navigator.of(context).popUntil((r) => r.isFirst);
  nav.go(AppView.purchases);
}

/// قفل کوچک کنارِ گزینه‌های ویژه‌ی پرو؛ برای کاربر پرو نامرئی
class ProLockIcon extends StatelessWidget {
  final double size;
  const ProLockIcon({super.key, this.size = 14});
  @override
  Widget build(BuildContext context) {
    if (context.isPro) return const SizedBox.shrink();
    return Icon(LucideIcons.lock, size: size, color: context.rp.goldInk);
  }
}

/// کارتِ توضیحِ قفل: چه چیز رایگان است، پرو چه می‌دهد و دکمه‌ی ارتقا. برای کاربر پرو: هیچ.
class ProNotice extends StatelessWidget {
  final ProFeature feature;
  final bool showCta;
  const ProNotice(this.feature, {super.key, this.showCta = true});
  @override
  Widget build(BuildContext context) {
    if (context.isPro) return const SizedBox.shrink();
    final p = context.rp;
    final i = proInfos[feature]!;
    return Container(
      key: ValueKey('pro-notice-${feature.name}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.goldSoft, borderRadius: BorderRadius.circular(RpRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.lock, size: 16, color: p.goldInk),
          const SizedBox(width: 8),
          Expanded(child: Text(context.tr(i.titleFa, i.titleEn), style: rpText(RpType.body, weight: 600, color: p.goldInk))),
        ]),
        const SizedBox(height: 4),
        Text('${context.tr('رایگان: ', 'Free: ')}${context.tr(i.freeFa, i.freeEn)}', style: rpText(RpType.label, weight: 500, color: p.text, height: 1.6)),
        Text('${context.tr('پرو: ', 'Pro: ')}${context.tr(i.proFa, i.proEn)}', style: rpText(RpType.label, weight: 500, color: p.text, height: 1.6)),
        if (showCta) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(key: const ValueKey('pro-cta'), style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)), onPressed: () => goToPurchases(context), child: Text(context.tr('ارتقا به پرو', 'Upgrade to Pro'))),
          ),
        ],
      ]),
    );
  }
}

/// جدولِ مقایسه‌ی Free/Pro برای صفحه‌ی خریدها (کشویی؛ برای کاربر پرو نامرئی)
class ProComparison extends StatelessWidget {
  const ProComparison({super.key});
  @override
  Widget build(BuildContext context) {
    if (context.isPro) return const SizedBox.shrink();
    final p = context.rp;
    return RpCollapsible(
      key: const ValueKey('pro-comparison'),
      icon: LucideIcons.listChecks,
      title: context.tr('چه چیزی رایگان است و چه چیزی پرو؟', 'What is free and what is Pro?'),
      child: Column(children: [
        for (final e in proInfos.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr(e.titleFa, e.titleEn), style: rpText(RpType.body, weight: 600, color: p.text)),
              Text('${context.tr('رایگان: ', 'Free: ')}${context.tr(e.freeFa, e.freeEn)}', style: rpText(RpType.label, weight: 500, color: p.muted)),
              Text('${context.tr('پرو: ', 'Pro: ')}${context.tr(e.proFa, e.proEn)}', style: rpText(RpType.label, weight: 500, color: p.goldInk)),
            ]),
          ),
      ]),
    );
  }
}
