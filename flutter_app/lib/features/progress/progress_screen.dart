// صفحه‌ی «پیشرفت»: سطح، XP، استمرار، نشان‌های ویژه، دستاوردهای اخیر، نقاط عطفِ بعدی، آمار، مسیر (Timeline)، عنوان‌ها، فصل و تاریخچه.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../app/nav.dart';
import '../../core/pro_features.dart';
import '../../core/progress/achievements.dart';
import '../../core/progress/engine.dart';
import '../../core/progress/ledger.dart';
import '../../core/progress/stats.dart';
import '../../data/actions.dart';
import '../../ui/pro_widgets.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import 'badge_emblem.dart';
import 'badge_sheet.dart';
import 'profile_card.dart';
import 'progress_data.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final d = progressDataOf(context);
    final s = d.snap;
    final sp = RpSpace.s3;
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Text(context.tr('پیشرفت', 'Progress'), style: rpText(RpType.titleL, weight: 800, color: p.text)),
        SizedBox(height: sp),
        // ۱) سطح و XP
        AppCard(
          key: const ValueKey('level-card'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(context.tr('سطح ${context.n(s.level)}', 'Level ${s.level}'), style: rpText(32, weight: 800, color: p.text, height: 1.1)),
              const SizedBox(width: 10),
              Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(rankName(context, s.rank), style: rpText(RpType.bodyL, weight: 700, color: p.primary))),
            ]),
            if (s.title != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(context.tr(s.title!.nameFa, s.title!.nameEn), style: rpText(RpType.label, weight: 600, color: p.goldInk))),
            const SizedBox(height: RpSpace.s3),
            XpBar(d),
            const SizedBox(height: RpSpace.s2),
            Text('${context.tr('کل XP: ', 'Total XP: ')}${groupDigits(context, s.xp)}', style: rpText(RpType.caption, weight: 500, color: p.muted)),
          ]),
        ),
        SizedBox(height: sp),
        // ۲) استمرار
        Row(children: [
          Expanded(child: _MiniCard(icon: LucideIcons.flame, color: p.fire, value: context.tr('${context.n(s.streak)} روز', '${s.streak} days'), label: context.tr('استمرار', 'Streak'), vkey: 'progress-streak')),
          const SizedBox(width: 10),
          Expanded(child: _MiniCard(icon: LucideIcons.award, color: p.goldInk, value: '${context.n(s.badgeCount)} / ${context.n(s.totalBadges)}', label: context.tr('نشان‌ها', 'Badges'), onTap: () => context.read<NavController>().go(AppView.badges))),
        ]),
        SizedBox(height: sp),
        // ۳) نشان‌های ویژه
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(context.tr('نشان‌های ویژه', 'Featured badges'), style: rpText(RpType.body, weight: 700, color: p.text))),
              TextButton(onPressed: () => showFeaturedPicker(context), child: Text(context.tr('انتخاب', 'Choose'))),
            ]),
            FeaturedRow(d, size: 64),
          ]),
        ),
        SizedBox(height: sp),
        // ۴) دستاوردهای اخیر
        _Section(
          title: context.tr('آخرین دستاوردها', 'Recent achievements'),
          trailing: TextButton(onPressed: () => context.read<NavController>().go(AppView.badges), child: Text(context.tr('همه', 'All'))),
          child: d.recent().isEmpty
              ? _Empty(context.tr('هنوز دستاوردی ثبت نشده. با انجامِ واقعیِ عادت‌ها و کارها شروع کن.', 'No achievements yet. Start by doing real work.'))
              : Column(children: [for (final a in d.recent()) _AchRow(a)]),
        ),
        SizedBox(height: sp),
        // ۵) هدف‌های بعدی
        _Section(
          title: context.tr('هدف‌های بعدی', 'Next milestones'),
          child: Column(children: [
            for (final a in d.nextUp()) _AchRow(a, showProgress: true),
            if (!s.maxed)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Icon(LucideIcons.trendingUp, size: 18, color: p.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(context.tr('سطح ${context.n(s.level + 1)}', 'Level ${s.level + 1}'), style: rpText(RpType.body, weight: 600, color: p.text))),
                  Text(context.tr('${groupDigits(context, s.toNext)} XP باقی مانده', '${groupDigits(context, s.toNext)} XP remaining'), style: rpText(RpType.label, weight: 500, color: p.muted)),
                ]),
              ),
          ]),
        ),
        SizedBox(height: sp),
        // ۶) آمار
        _StatsSection(d),
        SizedBox(height: sp),
        // ۷) مسیرِ من
        RpCollapsible(key: const ValueKey('timeline-section'), icon: LucideIcons.route, title: context.tr('مسیر من (نقاط عطف)', 'My journey (milestones)'), child: _Timeline(d)),
        SizedBox(height: sp),
        // ۸) عنوان‌ها
        RpCollapsible(key: const ValueKey('titles-section'), icon: LucideIcons.badgeCheck, title: context.tr('عنوان‌ها', 'Titles'), child: _Titles(d)),
        SizedBox(height: sp),
        // ۹) فصل (پرو)
        RpCollapsible(key: const ValueKey('season-section'), icon: LucideIcons.calendarRange, title: context.tr('فصل‌ها', 'Seasons'), child: const _Seasons()),
        SizedBox(height: sp),
        // ۱۰) تاریخچه (پرو)
        RpCollapsible(key: const ValueKey('history-section'), icon: LucideIcons.history, title: context.tr('تاریخچه‌ی XP', 'XP history'), child: const _History()),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;
  final String? vkey;
  final VoidCallback? onTap;
  const _MiniCard({required this.icon, required this.color, required this.value, required this.label, this.vkey, this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return AppCard(
      child: InkWell(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, key: vkey == null ? null : ValueKey(vkey), maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.bodyL, weight: 800, color: p.text, height: 1.2)),
              Text(label, style: rpText(RpType.caption, weight: 500, color: p.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Expanded(child: Text(title, style: rpText(RpType.body, weight: 700, color: p.text))), ?trailing]),
        const SizedBox(height: 6),
        child,
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: rpText(RpType.label, weight: 500, color: context.rp.muted, height: 1.8)));
}

class _AchRow extends StatelessWidget {
  final AchStatus a;
  final bool showProgress;
  const _AchRow(this.a, {this.showProgress = false});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return InkWell(
      key: ValueKey('ach-${a.def.id}'),
      onTap: () => showBadgeSheet(context, a.def.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          BadgeEmblem(def: a.def, state: a.state, ratio: a.ratio, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(achName(context, a.def), style: rpText(RpType.body, weight: 600, color: p.text)),
              if (showProgress) ...[
                const SizedBox(height: 4),
                RpProgressBar(value: a.ratio, colors: [p.primary, p.primary2], height: 5),
              ] else if (a.unlockedAt != null)
                Text(dateOfMs(context, a.unlockedAt!), style: rpText(RpType.caption, weight: 500, color: p.muted)),
            ]),
          ),
          if (showProgress) Padding(padding: const EdgeInsetsDirectional.only(start: 10), child: Text(remainingText(context, a), style: rpText(RpType.caption, weight: 500, color: p.muted))),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- آمار
class _StatsSection extends StatelessWidget {
  final ProgressData d;
  const _StatsSection(this.d);
  @override
  Widget build(BuildContext context) {
    final pro = context.isPro;
    final rows = [
      ('consistency', context.tr('استمرار', 'Consistency'), d.stats.consistency),
      ('productivity', context.tr('بهره‌وری', 'Productivity'), d.stats.productivity),
      ('focus', context.tr('تمرکز', 'Focus'), d.stats.focus),
      ('reading', context.tr('مطالعه', 'Reading'), d.stats.reading),
      ('discipline', context.tr('انضباط', 'Discipline'), d.stats.discipline),
    ];
    return _Section(
      title: context.tr('آمار (۳۰ روز اخیر)', 'Statistics (last 30 days)'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final r in rows) _StatRow(r.$1, r.$2, r.$3, pro),
        if (!pro && rows.any((r) => r.$3.previous != null)) const ProNotice(ProFeature.advancedStats),
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String id, label;
  final StatValue v;
  final bool pro;
  const _StatRow(this.id, this.label, this.v, this.pro);
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final f = statFormulas[id]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(label, style: rpText(RpType.body, weight: 600, color: p.text))),
          if (v.value != null) Text(context.tr('${context.n(v.value!)}٪', '${v.value}%'), key: ValueKey('stat-$id'), style: rpText(RpType.bodyL, weight: 800, color: p.text)),
          IconButton(
            key: ValueKey('formula-$id'),
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            tooltip: context.tr('فرمول', 'Formula'),
            icon: Icon(LucideIcons.info, color: p.muted),
            onPressed: () => showRpSheet<void>(context: context, builder: (c) => SafeArea(child: Padding(padding: const EdgeInsets.all(RpSpace.s4), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [RpSheetHeader(label), Text(c.tr(f.$1, f.$2), style: rpText(RpType.body, weight: 500, color: p.text, height: 1.9))])))),
          ),
        ]),
        if (v.value == null)
          Text(context.tr('داده کافی برای محاسبه وجود ندارد.', 'Not enough data to calculate.'), key: ValueKey('stat-$id-empty'), style: rpText(RpType.label, weight: 500, color: p.muted))
        else ...[
          RpProgressBar(value: v.value! / 100, colors: [p.primary, p.primary2], height: 6),
          if (pro && v.previous != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.tr('دوره‌ی قبل: ${context.n(v.previous!)}٪ · تغییر: ${context.n(v.change! > 0 ? '+${v.change}' : '${v.change}')}٪', 'Previous: ${v.previous}% · Change: ${v.change! > 0 ? '+' : ''}${v.change}%'),
                key: ValueKey('stat-$id-change'),
                style: rpText(RpType.caption, weight: 600, color: v.change! >= 0 ? p.okInk : p.badInk),
              ),
            ),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------- مسیر (Timeline)
class _Timeline extends StatelessWidget {
  final ProgressData d;
  const _Timeline(this.d);
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final prog = progressOf(context.read<AppActions>().store.state);
    final startedAt = (prog['startedAt'] as num?)?.toInt();
    final items = <(String, int?, bool)>[];
    for (final m in milestoneCatalog) {
      int? at;
      if (m.kind == 'start') {
        at = startedAt;
      } else {
        at = d.byId(m.ref)?.unlockedAt ?? (d.byId(m.ref)?.unlocked == true ? startedAt : null);
      }
      items.add((context.tr(m.nameFa, m.nameEn), at, at != null));
    }
    int nextIdx = items.indexWhere((e) => !e.$3);
    return Column(children: [
      for (int i = 0; i < items.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 28,
              child: Column(children: [
                Container(width: 2, height: 6, color: i == 0 ? Colors.transparent : p.line),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: items[i].$3 ? p.primary : Colors.transparent, border: Border.all(color: items[i].$3 ? p.primary : (i == nextIdx ? p.primary : p.line), width: 2)),
                ),
                Expanded(child: Container(width: 2, color: i == items.length - 1 ? Colors.transparent : p.line)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(items[i].$1, key: ValueKey('ms-$i'), style: rpText(RpType.body, weight: items[i].$3 || i == nextIdx ? 700 : 500, color: items[i].$3 ? p.text : (i == nextIdx ? p.primary : p.muted))),
                  Text(items[i].$2 != null ? dateOfMs(context, items[i].$2!) : (i == nextIdx ? context.tr('هدفِ بعدی', 'Next') : context.tr('در پیش', 'Upcoming')), style: rpText(RpType.caption, weight: 500, color: p.muted)),
                ]),
              ),
            ),
          ]),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- عنوان‌ها
class _Titles extends StatelessWidget {
  final ProgressData d;
  const _Titles(this.d);
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final a = context.read<AppActions>();
    final active = d.snap.title?.id;
    return Wrap(spacing: 8, runSpacing: 4, children: [
      for (final t in titleCatalog)
        () {
          final un = d.byId(t.achId)?.unlocked == true;
          return Tooltip(
            message: un ? '' : context.tr('با دریافتِ «${achName(context, achById(t.achId)!)}» باز می‌شود', 'Unlocked by "${achName(context, achById(t.achId)!)}"'),
            child: ChoiceChip(
              key: ValueKey('title-${t.id}'),
              label: Row(mainAxisSize: MainAxisSize.min, children: [Text(context.tr(t.nameFa, t.nameEn)), if (!un) ...[const SizedBox(width: 4), Icon(LucideIcons.lock, size: 12, color: p.muted)]]),
              selected: active == t.id,
              onSelected: (_) {
                if (!un) {
                  a.toasts.show(context.tr('با دریافتِ «${achName(context, achById(t.achId)!)}» باز می‌شود', 'Unlocked by "${achName(context, achById(t.achId)!)}"'));
                  return;
                }
                setActiveTitle(a.store.state, active == t.id ? null : t.id);
                a.store.save();
              },
            ),
          );
        }(),
    ]);
  }
}

// ---------------------------------------------------------------- فصل (پرو)
class _Seasons extends StatelessWidget {
  const _Seasons();
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final a = context.read<AppActions>();
    final pro = context.isPro;
    if (!pro) return const ProNotice(ProFeature.seasons);
    final prog = progressOf(a.store.state);
    final cur = prog['season'];
    final arch = (prog['seasons'] as List).cast<Map>().reversed.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (cur is Map) ...[
        Text('${cur['name']} · ${context.tr('استمرار', 'Consistency')}', style: rpText(RpType.body, weight: 700, color: p.text)),
        Text('XP ${context.tr('فصل', 'season')}: ${groupDigits(context, xpBetween(a.store.state, '${cur['start']}', '${cur['end']}'))}', key: const ValueKey('season-xp'), style: rpText(RpType.label, weight: 500, color: p.muted)),
        Text('${cur['start']} → ${cur['end']}', style: rpText(RpType.caption, weight: 500, color: p.muted)),
      ] else ...[
        Text(context.tr('فصلِ فعالی نداری. با شروعِ فصل، XP فصلی جدا از XP دائمی شمرده می‌شود.', 'No active season. Season XP is counted separately from permanent XP.'), style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.8)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final n in [30, 60, 90]) OutlinedButton(key: ValueKey('season-$n'), onPressed: () { startSeason(a.store.state, a.today, n); a.renderAll(); }, child: Text(context.tr('${context.n(n)} روزه', '$n days'))),
        ]),
      ],
      if (arch.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(context.tr('بایگانی فصل‌ها', 'Season archive'), style: rpText(RpType.body, weight: 700, color: p.text)),
        for (final s in arch) Padding(padding: const EdgeInsets.only(top: 4), child: Text('${s['name']} · ${s['start']} → ${s['end']} · ${groupDigits(context, (s['xp'] as num).toInt())} XP', style: rpText(RpType.label, weight: 500, color: p.muted))),
      ],
    ]);
  }
}

// ---------------------------------------------------------------- تاریخچه‌ی XP (پرو)
class _History extends StatelessWidget {
  const _History();
  static const _names = {'habit': ('عادت', 'Habit'), 'daily': ('تکمیلِ روزانه', 'Daily completion'), 'todo': ('کار', 'Task'), 'pomodoro': ('تمرکز', 'Focus'), 'challenge': ('چالش', 'Challenge'), 'library': ('مطالعه', 'Reading'), 'journal': ('مرورِ روزانه', 'Daily review'), 'streak': ('استمرار', 'Streak bonus')};
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    if (!context.isPro) return const ProNotice(ProFeature.progressHistory);
    final st = context.read<AppActions>().store.state;
    final ev = validEvents(st).toList()..sort((a, b) => ((b['ts'] as num?) ?? 0).compareTo((a['ts'] as num?) ?? 0));
    if (ev.isEmpty) return _Empty(context.tr('هنوز رویدادی ثبت نشده.', 'No events yet.'));
    return Column(children: [
      for (final e in ev.take(40))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(context.tr(_names[e['type']]?.$1 ?? '${e['type']}', _names[e['type']]?.$2 ?? '${e['type']}'), style: rpText(RpType.label, weight: 600, color: p.text))),
            Text('${e['date']}', style: rpText(RpType.caption, weight: 500, color: p.muted)),
            SizedBox(width: 56, child: Text('+${context.n(e['amount'])}', textAlign: TextAlign.end, style: rpText(RpType.label, weight: 700, color: p.primary))),
          ]),
        ),
    ]);
  }
}
