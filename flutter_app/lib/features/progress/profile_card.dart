// کارتِ پروفایل (جایگزینِ آواتار): یک «کارتِ دستاوردِ شخصی»؛ نه شیتِ شخصیتِ بازی.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../app/nav.dart';
import '../../core/progress/achievements.dart';
import '../../core/progress/config.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import 'badge_emblem.dart';
import 'badge_sheet.dart';
import 'progress_data.dart';

class XpBar extends StatelessWidget {
  final ProgressData d;
  const XpBar(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final s = d.snap;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      RpProgressBar(value: s.ratio, colors: [p.primary, p.primary2], height: 8),
      const SizedBox(height: 6),
      Row(children: [
        Text(s.maxed ? '${groupDigits(context, s.xp)} XP' : '${groupDigits(context, s.into)} / ${groupDigits(context, s.needed)} XP', key: const ValueKey('xp-line'), style: rpText(RpType.label, weight: 600, color: p.text)),
        const SizedBox(width: 8),
        Expanded(child: Text(s.maxed ? context.tr('بالاترین سطح', 'Max level') : context.tr('${groupDigits(context, s.toNext)} XP تا سطح بعد', '${groupDigits(context, s.toNext)} XP to next level'), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.label, weight: 500, color: p.muted))),
      ]),
    ]);
  }
}

String rankName(BuildContext c, RankDef r) => c.tr(r.nameFa, r.nameEn);

/// سه نشانِ ویژه؛ جای خالی = دعوت به انتخاب
class FeaturedRow extends StatelessWidget {
  final ProgressData d;
  final double size;
  const FeaturedRow(this.d, {super.key, this.size = 60});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final pro = context.isPro0;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (int i = 0; i < maxFeaturedBadges; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: i < d.snap.featured.length
              ? GestureDetector(
                  key: ValueKey('featured-$i'),
                  onTap: () => showBadgeSheet(context, d.snap.featured[i]),
                  child: BadgeEmblem(def: d.byId(d.snap.featured[i])!.def, state: AchState.unlocked, size: size, premium: pro))
              : GestureDetector(
                  key: ValueKey('featured-empty-$i'),
                  onTap: () => showFeaturedPicker(context),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.line, width: 1.2)),
                    child: Icon(LucideIcons.plus, size: 18, color: p.muted),
                  ),
                ),
        ),
    ]);
  }
}

extension on BuildContext {
  bool get isPro0 => watch<AppStore>().state['isPremium'] == true;
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final d = progressDataOf(context);
    final s = d.snap;
    final name = '${context.watch<AppStore>().state['profileName'] ?? ''}'.trim();
    return AppCard(
      key: const ValueKey('profile-card'),
      child: InkWell(
        borderRadius: BorderRadius.circular(RpRadius.lg),
        onTap: () => context.read<NavController>().go(AppView.progress),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(name.isEmpty ? context.tr('مسیر رشد من', 'My growth') : name, key: const ValueKey('profile-name'), maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.bodyL, weight: 700, color: p.text))),
                    GestureDetector(
                      key: const ValueKey('profile-name-edit'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showEditNameDialog(context),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(LucideIcons.pencil, size: 15, color: p.muted)),
                    ),
                  ]),
                  if (s.title != null) Text(context.tr(s.title!.nameFa, s.title!.nameEn), key: const ValueKey('profile-title'), style: rpText(RpType.label, weight: 600, color: p.goldInk)),
                ]),
              ),
              Icon(context.isFa ? LucideIcons.chevronLeft : LucideIcons.chevronRight, size: 18, color: p.muted),
            ]),
            const SizedBox(height: RpSpace.s3),
            FeaturedRow(d),
            const SizedBox(height: RpSpace.s3),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(context.tr('سطح ${context.n(s.level)}', 'LEVEL ${s.level}'), key: const ValueKey('profile-level'), style: rpText(RpType.title, weight: 800, color: p.text, height: 1.2)),
              const SizedBox(width: 8),
              Flexible(child: Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(rankName(context, s.rank), key: const ValueKey('profile-rank'), maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.body, weight: 600, color: p.primary)))),
            ]),
            const SizedBox(height: RpSpace.s2),
            XpBar(d),
            const SizedBox(height: RpSpace.s3),
            Row(children: [
              Icon(LucideIcons.flame, size: 16, color: p.fire),
              const SizedBox(width: 4),
              Flexible(child: Text(context.tr('${context.n(s.streak)} روز استمرار', '${s.streak}-day streak'), key: const ValueKey('profile-streak'), maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.label, weight: 600, color: p.text))),
              const Spacer(),
              Icon(LucideIcons.award, size: 16, color: p.goldInk),
              const SizedBox(width: 4),
              Flexible(child: Text(context.tr('${context.n(s.badgeCount)} نشان', '${s.badgeCount} badges'), key: const ValueKey('profile-badges'), maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.label, weight: 600, color: p.text))),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// ویرایشِ نامِ کاربر
Future<void> showEditNameDialog(BuildContext context) {
  final actions = context.read<AppActions>();
  final cur = '${context.read<AppStore>().state['profileName'] ?? ''}'.trim();
  final ctl = TextEditingController(text: cur == 'کاربر' ? '' : cur);
  return showDialog<void>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(context.tr('نامِ شما', 'Your name')),
      content: TextField(
        key: const ValueKey('name-field'),
        controller: ctl,
        autofocus: true,
        maxLength: 30,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: context.tr('مثلاً علی', 'e.g. Alex')),
        onSubmitted: (v) {
          actions.setProfileName(v);
          Navigator.of(dctx).pop();
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dctx).pop(), child: Text(context.tr('انصراف', 'Cancel'))),
        TextButton(
          key: const ValueKey('name-save'),
          onPressed: () {
            actions.setProfileName(ctl.text);
            Navigator.of(dctx).pop();
          },
          child: Text(context.tr('ذخیره', 'Save')),
        ),
      ],
    ),
  );
}
