// «نشان‌های من»: مجموعه‌ی کامل با فیلتر و مرتب‌سازی (همه‌ی فیلترها برای همه آزاد است).
import 'package:flutter/material.dart';

import '../../app/i18n.dart';
import '../../core/progress/achievements.dart';
import '../../ui/pro_widgets.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import 'badge_emblem.dart';
import 'badge_sheet.dart';
import 'progress_data.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});
  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  String cat = 'all', sort = 'default', stateF = 'all';
  BadgeTier? tierF;

  List<AchStatus> _apply(ProgressData d) {
    var l = d.statuses.where((s) => cat == 'all' || s.def.cat == cat).toList();
    if (stateF != 'all') l = l.where((s) => stateF == 'unlocked' ? s.unlocked : stateF == 'near' ? s.state == AchState.near : (!s.unlocked)).toList();
    if (tierF != null) l = l.where((s) => s.def.tier == tierF).toList();
    switch (sort) {
      case 'recent':
        l.sort((a, b) => (b.unlockedAt ?? -1).compareTo(a.unlockedAt ?? -1));
      case 'progress':
        l.sort((a, b) => (a.unlocked ? -1 : 0) == (b.unlocked ? -1 : 0) ? b.ratio.compareTo(a.ratio) : (a.unlocked ? 1 : -1));
      case 'rarest':
        l.sort((a, b) => b.def.rarity.index.compareTo(a.def.rarity.index));
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final d = progressDataOf(context);
    final pro = context.isPro;
    final shown = _apply(d);
    final cats = [('all', context.tr('همه', 'All')), for (final c in badgeCategories) (c.id, context.tr(c.nameFa, c.nameEn))];
    Widget chip(String label, bool on, VoidCallback f, {bool locked = false}) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: ChoiceChip(label: Row(mainAxisSize: MainAxisSize.min, children: [Text(label), if (locked) ...[const SizedBox(width: 4), const ProLockIcon(size: 12)]]), selected: on, onSelected: (_) => f(), visualDensity: VisualDensity.compact),
        );
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Row(children: [
          Expanded(child: Text(context.tr('نشان‌های من', 'My badges'), style: rpText(RpType.titleL, weight: 800, color: p.text))),
          Text('${context.n(d.snap.badgeCount)} / ${context.n(d.snap.totalBadges)}', key: const ValueKey('badge-count'), style: rpText(RpType.bodyL, weight: 700, color: p.primary)),
        ]),
        const SizedBox(height: RpSpace.s2),
        RpProgressBar(value: d.snap.totalBadges == 0 ? 0 : d.snap.badgeCount / d.snap.totalBadges, colors: [p.primary, p.primary2], height: 6),
        const SizedBox(height: RpSpace.s3),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final c in cats) chip(c.$2, cat == c.$1, () => setState(() => cat = c.$1))])),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Text(context.tr('مرتب‌سازی: ', 'Sort: '), style: rpText(RpType.label, weight: 500, color: p.muted)),
            chip(context.tr('پیش‌فرض', 'Default'), sort == 'default', () => setState(() => sort = 'default')),
            chip(context.tr('تازه‌دریافت‌شده', 'Recently unlocked'), sort == 'recent', () => setState(() => sort = 'recent')),
            chip(context.tr('پیشرفت', 'Progress'), sort == 'progress', () => setState(() => sort = 'progress')),
            chip(context.tr('کمیاب‌ترین', 'Rarest'), sort == 'rarest', () => setState(() => sort = 'rarest')),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Text(context.tr('فیلتر پیشرفته: ', 'Advanced: '), style: rpText(RpType.label, weight: 500, color: p.muted)),
            for (final e in [('all', context.tr('همه', 'All')), ('unlocked', context.tr('بازشده', 'Unlocked')), ('near', context.tr('نزدیک', 'Near')), ('locked', context.tr('قفل', 'Locked'))]) chip(e.$2, stateF == e.$1, () => setState(() => stateF = e.$1)),
            for (final t in BadgeTier.values) chip(context.tr(tierNameFa(t), tierNameEn(t)), tierF == t, () => setState(() => tierF = tierF == t ? null : t)),
          ]),
        ),
        const SizedBox(height: RpSpace.s3),
        if (shown.isEmpty)
          Padding(padding: const EdgeInsets.all(RpSpace.s6), child: Text(context.tr('موردی با این فیلتر نیست.', 'Nothing matches this filter.'), textAlign: TextAlign.center, style: rpText(RpType.body, weight: 500, color: p.muted)))
        else
          GridView.builder(
            key: const ValueKey('badge-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 104, mainAxisSpacing: 14, crossAxisSpacing: 8, mainAxisExtent: 136),
            itemCount: shown.length,
            itemBuilder: (_, i) => _Tile(shown[i], pro),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final AchStatus s;
  final bool pro;
  const _Tile(this.s, this.pro);
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return InkWell(
      key: ValueKey('badge-${s.def.id}'),
      borderRadius: BorderRadius.circular(RpRadius.md),
      onTap: () => showBadgeSheet(context, s.def.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(children: [
          BadgeEmblem(def: s.def, state: s.state, ratio: s.ratio, size: 68, premium: pro && s.unlocked),
          const SizedBox(height: 6),
          Text(achName(context, s.def), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: rpText(RpType.caption, weight: 600, color: s.unlocked ? p.text : p.muted, height: 1.3)),
          if (!s.unlocked) Text(progressText(context, s), maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(10, weight: 500, color: s.state == AchState.near ? p.primary : p.muted, height: 1.4)),
        ]),
      ),
    );
  }
}

