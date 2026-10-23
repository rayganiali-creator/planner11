// جزئیاتِ نشان (مودالِ کوچک و Premium) + انتخابِ نشان‌های ویژه.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../core/progress/achievements.dart';
import '../../core/progress/engine.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import 'badge_emblem.dart';
import 'progress_data.dart';

String progressText(BuildContext c, AchStatus s) {
  final u = c.tr(s.def.unitFa(), s.def.unitEn());
  final v = groupDigits(c, s.shown.floor());
  final t = groupDigits(c, s.def.target.floor());
  return u.isEmpty ? '$v / $t' : (u == '%' ? '$v٪ / $t٪'.replaceAll('٪', c.isFa ? '٪' : '%') : '$v / $t $u');
}

String remainingText(BuildContext c, AchStatus s) {
  final r = s.remaining.ceil();
  final u = c.tr(s.def.unitFa(), s.def.unitEn());
  if (s.def.metric == 'consistency30' || s.def.metric == 'discipline90') return c.tr('${c.n(r)}٪ تا رسیدن به هدف', '${c.n(r)}% to go');
  return c.tr('${c.n(r)} ${u.isEmpty ? '' : u} باقی مانده', '${c.n(r)} ${u.isEmpty ? '' : u} remaining').trim();
}

Future<void> showBadgeSheet(BuildContext context, String achId) {
  return showRpSheet<void>(context: context, builder: (_) => BadgeSheet(achId));
}

class BadgeSheet extends StatelessWidget {
  final String achId;
  const BadgeSheet(this.achId, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final d = progressDataOf(context);
    final s = d.byId(achId);
    if (s == null) return const SizedBox.shrink();
    final def = s.def;
    final pro = context.watch<AppStore>().state['isPremium'] == true;
    final title = titleCatalog.where((t) => t.achId == def.id).firstOrNull;
    final featured = d.snap.featured.contains(def.id);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s1, RpSpace.s4, RpSpace.s4),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          RpSheetHeader(catName(context, def.cat)),
          Center(child: BadgeEmblem(def: def, state: s.state, ratio: s.ratio, size: 112, premium: pro)),
          const SizedBox(height: RpSpace.s3),
          Text(achName(context, def), key: const ValueKey('badge-name'), textAlign: TextAlign.center, style: rpText(RpType.title, weight: 800, color: p.text)),
          const SizedBox(height: 4),
          Text(achDesc(context, def), textAlign: TextAlign.center, style: rpText(RpType.body, weight: 500, color: p.muted, height: 1.8)),
          const SizedBox(height: RpSpace.s2),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
            RpChip(context.tr(tierNameFa(def.tier), tierNameEn(def.tier))),
            RpChip(context.tr(rarityNameFa(def.rarity), rarityNameEn(def.rarity))),
            if (title != null) RpChip('${context.tr('عنوان: ', 'Title: ')}${context.tr(title.nameFa, title.nameEn)}'),
          ]),
          const SizedBox(height: RpSpace.s3),
          if (s.unlocked) ...[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(LucideIcons.badgeCheck, size: 18, color: p.okInk),
              const SizedBox(width: 6),
              Text(context.tr('باز شده', 'Unlocked'), style: rpText(RpType.body, weight: 700, color: p.okInk)),
            ]),
            if (s.unlockedAt != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(dateOfMs(context, s.unlockedAt!), key: const ValueKey('badge-date'), textAlign: TextAlign.center, style: rpText(RpType.label, weight: 500, color: p.muted))),
            const SizedBox(height: RpSpace.s3),
            RpButton(featured ? context.tr('برداشتن از نشان‌های ویژه', 'Remove from featured') : context.tr('افزودن به نشان‌های ویژه', 'Add to featured'), kind: featured ? BtnKind.ghost : BtnKind.primary, icon: LucideIcons.star, onTap: () {
              final a = context.read<AppActions>();
              if (!toggleFeatured(a.store.state, def.id)) {
                a.toasts.show(context.tr('فقط نشانِ بازشده را می‌شود ویژه کرد', 'Only unlocked badges can be featured'));
                return;
              }
              a.store.save();
            }),
          ] else ...[
            Text(progressText(context, s), key: const ValueKey('badge-progress'), textAlign: TextAlign.center, style: rpText(RpType.bodyL, weight: 700, color: p.text)),
            const SizedBox(height: 6),
            RpProgressBar(value: s.ratio, colors: [p.primary, p.primary2], height: 8),
            const SizedBox(height: 6),
            Text(remainingText(context, s), textAlign: TextAlign.center, style: rpText(RpType.label, weight: 500, color: p.muted)),
          ],
        ]),
      ),
    );
  }
}

/// انتخابِ حداکثر ۳ نشانِ ویژه از میانِ نشان‌های بازشده
Future<void> showFeaturedPicker(BuildContext context, {String? cat}) {
  return showRpSheet<void>(context: context, builder: (_) => _FeaturedPicker(cat: cat));
}

class _FeaturedPicker extends StatelessWidget {
  final String? cat;
  const _FeaturedPicker({this.cat});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final d = progressDataOf(context);
    final list = cat == null ? d.unlockedList : d.unlockedList.where((s) => s.def.cat == cat).toList();
    final cname = cat == null ? null : badgeCategories.firstWhere((c) => c.id == cat);
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(RpSpace.s4, 0, RpSpace.s4, 0), child: RpSheetHeader(cname == null ? context.tr('نشان‌های ویژه (یکی از هر دسته)', 'Featured badges (one per category)') : context.tr('نشانِ ویژه‌ی «${cname.nameFa}»', 'Featured: ${cname.nameEn}'))),
        if (list.isEmpty)
          Padding(padding: const EdgeInsets.all(RpSpace.s5), child: Text(cat == null ? context.tr('هنوز نشانی نگرفته‌ای. با انجامِ واقعیِ کارها اولین نشانت را بگیر.', 'No badges yet. Earn your first by doing real work.') : context.tr('هنوز نشانی از این دسته نگرفته‌ای.', 'No badges in this category yet.'), textAlign: TextAlign.center, style: rpText(RpType.body, weight: 500, color: p.muted)))
        else
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.all(RpSpace.s4),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 96, mainAxisSpacing: 12, crossAxisSpacing: 8, childAspectRatio: .85),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final s = list[i];
                final on = d.snap.featured.contains(s.def.id);
                return GestureDetector(
                  key: ValueKey('pick-${s.def.id}'),
                  onTap: () {
                    final a = context.read<AppActions>();
                    if (!toggleFeatured(a.store.state, s.def.id)) a.toasts.show(context.tr('فقط نشانِ بازشده را می‌شود ویژه کرد', 'Only unlocked badges can be featured'));
                    a.store.save();
                    if (cat != null) Navigator.of(context).maybePop();
                  },
                  child: Column(children: [
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? p.primary : Colors.transparent, width: 2)),
                      padding: const EdgeInsets.all(3),
                      child: BadgeEmblem(def: s.def, state: AchState.unlocked, size: 56),
                    ),
                    const SizedBox(height: 4),
                    Text(achName(context, s.def), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: rpText(RpType.caption, weight: 500, color: p.text, height: 1.3)),
                  ]),
                );
              },
            ),
          ),
      ]),
    );
  }
}
