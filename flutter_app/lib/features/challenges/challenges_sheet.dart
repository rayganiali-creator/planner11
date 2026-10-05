// چالش‌ها: ساخت (آماده‌ها رایگان، شخصی پرو)، فعال‌ها با شمارش معکوس، تاریخچه و مدال‌ها (پرو).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/pro_features.dart';
import '../../ui/pro_widgets.dart';
import '../../app/i18n.dart';
import '../../core/calendar.dart';
import '../../core/date_fmt.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../data/challenge_ops.dart';
import '../../data/notifier.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../onboarding/onboarding.dart';
import '../todo/todo_screen.dart' show pickDateTime;

String formatCountdown(int ms, bool fa) {
  if (ms <= 0) return fa ? 'در حال بررسی…' : 'checking…';
  final s = ms ~/ 1000, d = s ~/ 86400, h = (s % 86400) ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  final parts = d > 0 ? '${d}d ${h}h' : h > 0 ? '${h}h ${m}m' : '${m}m ${sec}s';
  if (!fa) return parts;
  return toPersianDigits(parts).replaceFirst('d', 'روز').replaceFirst('h', 'ساعت').replaceFirst('m', 'دقیقه').replaceFirst('s', 'ثانیه');
}

String formatDuration(int v, String unit, bool fa) {
  const fm = {'minutes': 'دقیقه', 'hours': 'ساعت', 'days': 'روز'}, em = {'minutes': 'min', 'hours': 'h', 'days': 'd'};
  return fa ? '${toPersianDigits(v)} ${fm[unit]}' : '$v${em[unit]}';
}

Future<void> showChallenges(BuildContext context, {String? tab}) {
  final store = context.read<AppStore>();
  final a = context.read<AppActions>();
  final n = context.read<Notifier>();
  return showRpSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => MultiProvider(
      providers: [ChangeNotifierProvider.value(value: store), Provider.value(value: a), Provider.value(value: n)],
      child: _Sheet(initial: tab ?? (a.challenges.any((c) => c['status'] == 'active' || c['status'] == 'pending_review') ? 'active' : 'create')),
    ),
  );
}

/// پنجره‌ی «انجامش دادی؟» برای چالشِ زمان‌دارِ به‌سررسیده
Future<void> showChallengeCheckin(BuildContext context, Map c) {
  final a = context.read<AppActions>();
  final n = context.read<Notifier>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Column(children: [Text('${c['icon']}', style: const TextStyle(fontSize: 40)), Text('${c['name']}')]),
      content: Text(ctx.tr('مهلت چالش تموم شد! انجامش دادی؟', 'The deadline is up! Did you complete it?'), textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            a.resolveCheckin(c['id'] as String, false, notifier: n);
          },
          child: Text(ctx.tr('نه', 'No')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            a.resolveCheckin(c['id'] as String, true, notifier: n);
          },
          child: Text(ctx.tr('آره! 🎉', 'Yes! 🎉')),
        ),
      ],
    ),
  );
}

class _Sheet extends StatefulWidget {
  final String initial;
  const _Sheet({required this.initial});
  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late String tab = widget.initial;
  Timer? _t;
  final form = ChallengeForm();
  final name = TextEditingController(), rewardText = TextEditingController();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && tab == 'active') setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppStore>();
    final p = context.rp;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .9,
      minChildSize: .4,
      builder: (ctx, sc) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(RpSpace.s3),
          child: Row(children: [
            for (final t in const [('create', 'ساخت', 'Create'), ('active', 'فعال', 'Active'), ('history', 'تاریخچه', 'History')])
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text(context.isFa ? t.$2 : t.$3), selected: tab == t.$1, onSelected: (_) => setState(() => tab = t.$1))),
            const Spacer(),
            const HelpButton('challenge'),
            IconButton(key: const ValueKey('sheet-close'), visualDensity: VisualDensity.compact, iconSize: 20, onPressed: () => Navigator.maybePop(context), icon: Icon(Icons.close_rounded, color: p.muted)),
          ]),
        ),
        Expanded(
          child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(RpSpace.s4, 0, RpSpace.s4, RpSpace.s6), children: [
            if (tab == 'create') ..._create(context),
            if (tab == 'active') ..._active(context),
            if (tab == 'history') ..._history(context),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _create(BuildContext context) {
    final a = context.read<AppActions>();
    final n = context.read<Notifier>();
    final p = context.rp;
    final fa = context.isFa;
    final pro = a.store.state['isPremium'] == true;
    return [
      Text(context.tr('چالش‌های آماده', 'Ready-made challenges'), style: rpText(RpType.body, weight: 800, color: p.text)),
      const SizedBox(height: 8),
      for (final pr in challengePresets)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: Row(children: [
              Text(pr.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(fa ? pr.nameFa : pr.nameEn, style: rpText(RpType.body, weight: 800, color: p.text)),
                  Text(
                    '${pr.kind == 'timed' ? (fa ? '${toPersianDigits(pr.days)} روز' : '${pr.days} days') : (fa ? '${toPersianDigits(pr.target)} بار' : '${pr.target} times')} · 🪙 ${context.n(pr.reward)}',
                    style: rpText(RpType.label, weight: 500, color: p.muted),
                  ),
                ]),
              ),
              RpButton(
                a.presetRunning(pr.id) ? context.tr('در حال انجام', 'Joined') : context.tr('شرکت', 'Join'),
                small: true,
                onTap: a.presetRunning(pr.id)
                    ? null
                    : () {
                        final ch = a.joinPreset(pr.id, notifier: n);
                        if (ch != null) {
                          a.toasts.show(fa ? '🔥 به چالش «${ch['name']}» پیوستی!' : '🔥 Challenge joined!', ms: 2600);
                          setState(() => tab = 'active');
                        }
                      },
              ),
            ]),
          ),
        ),
      const SizedBox(height: 12),
      if (!pro)
        const ProNotice(ProFeature.challengesCustom)
      else
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('چالش شخصی', 'Custom challenge'), style: rpText(RpType.body, weight: 800, color: p.text)),
            TextField(controller: name, decoration: InputDecoration(labelText: context.tr('اسم چالش', 'Name')), onChanged: (v) => form.name = v),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final e in challengeEmojis) ChoiceChip(label: Text(e), selected: form.icon == e, onSelected: (_) => setState(() => form.icon = e)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final k in const [('count', 'تعدادی', 'Count'), ('timed', 'زمان‌دار', 'Timed'), ('both', 'هر دو', 'Both')])
                ChoiceChip(label: Text(fa ? k.$2 : k.$3), selected: form.kind == k.$1, onSelected: (_) => setState(() => form.kind = k.$1)),
            ]),
            if (form.kind == 'count' || form.kind == 'both') ...[
              TextFormField(initialValue: '${form.target}', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('هدف (تعداد)', 'Target')), onChanged: (v) => form.target = int.tryParse(v) ?? 1),
              TextField(decoration: InputDecoration(labelText: context.tr('واحد', 'Unit')), onChanged: (v) => form.unit = v),
            ],
            if (form.kind == 'timed' || form.kind == 'both') ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                ChoiceChip(label: Text(context.tr('مدت', 'Duration')), selected: form.deadlineMode == 'duration', onSelected: (_) => setState(() => form.deadlineMode = 'duration')),
                ChoiceChip(label: Text(context.tr('تاریخ دقیق', 'Exact date')), selected: form.deadlineMode == 'exact', onSelected: (_) => setState(() => form.deadlineMode = 'exact')),
              ]),
              if (form.deadlineMode == 'duration')
                Row(children: [
                  Expanded(child: TextFormField(initialValue: '${form.durationValue}', keyboardType: TextInputType.number, onChanged: (v) => form.durationValue = int.tryParse(v) ?? 1)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: form.durationUnit,
                    items: [for (final u in const [('minutes', 'دقیقه', 'minutes'), ('hours', 'ساعت', 'hours'), ('days', 'روز', 'days')]) DropdownMenuItem(value: u.$1, child: Text(fa ? u.$2 : u.$3))],
                    onChanged: (v) => setState(() => form.durationUnit = v!),
                  ),
                ])
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    final v = await pickDateTime(context, form.exactAt);
                    if (v != null) setState(() => form.exactAt = v);
                  },
                  icon: const Icon(LucideIcons.calendarClock, size: 16),
                  label: Text(form.exactAt == null ? context.tr('انتخاب تاریخ و ساعت', 'Pick date & time') : DateTime.fromMillisecondsSinceEpoch(form.exactAt!).toString().substring(0, 16)),
                ),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr('یادآوری دوره‌ای', 'Periodic reminders')), value: form.reminderOn, onChanged: (v) => setState(() => form.reminderOn = v)),
              if (form.reminderOn)
                TextFormField(initialValue: '${form.reminderHours}', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('هر چند ساعت (۱ تا ۷۲)', 'Every N hours (1–72)')), onChanged: (v) => form.reminderHours = int.tryParse(v) ?? 2),
            ],
            TextFormField(initialValue: '${form.rewardCoins}', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('جایزه (سکه، حداکثر ۵۰)', 'Reward coins (max 50)')), onChanged: (v) {
              final x = int.tryParse(v) ?? 0;
              form.rewardCoins = x;
              if (x > 50) a.toasts.show(context.tr('حداکثر جایزه‌ی هر چالش ۵۰ سکه است.', 'The maximum reward per challenge is 50 coins.'), ms: 2200);
            }),
            TextField(controller: rewardText, decoration: InputDecoration(labelText: context.tr('جایزه‌ی دلخواه (متن)', 'Custom reward (text)')), onChanged: (v) => form.rewardText = v),
            const SizedBox(height: 12),
            RpButton(context.tr('شروع چالش', 'Start challenge'), icon: LucideIcons.flame, onTap: () {
              final err = a.createChallenge(form, notifier: n);
              if (err == 'name') return a.toasts.show(context.tr('اسم چالش رو وارد کن', 'Enter a challenge name'));
              if (err == 'date') return a.toasts.show(context.tr('یه تاریخ و ساعت معتبر و در آینده انتخاب کن', 'Pick a valid future date/time'));
              a.toasts.show(fa ? '🔥 چالش «${form.name.trim()}» ثبت شد!' : '🔥 Challenge "${form.name.trim()}" started!');
              name.clear();
              rewardText.clear();
              form.name = '';
              form.rewardText = '';
              setState(() => tab = 'active');
            }),
          ]),
        ),
    ];
  }

  Widget _badge(BuildContext context, String s) {
    final p = context.rp;
    final fa = context.isFa;
    final m = {
      'active': ('در حال انجام', 'Active', p.primary),
      'pending_review': ('در انتظار پاسخ', 'Pending', p.goldInk),
      'success': ('موفق ✓', 'Success ✓', p.okInk),
      'failed': ('ناموفق', 'Failed', p.badInk),
      'cancelled': ('لغو شده', 'Cancelled', p.badInk),
    }[s] ?? ('در حال انجام', 'Active', p.primary);
    return Text(fa ? m.$1 : m.$2, style: rpText(RpType.label, weight: 800, color: m.$3));
  }

  List<Widget> _active(BuildContext context) {
    final a = context.read<AppActions>();
    final n = context.read<Notifier>();
    final p = context.rp;
    final fa = context.isFa;
    final items = a.challenges.where((c) => c['status'] == 'active' || c['status'] == 'pending_review').toList()
      ..sort((x, y) => ((y['createdAt'] as num?) ?? 0).compareTo((x['createdAt'] as num?) ?? 0));
    if (items.isEmpty) return [AppCard(child: Text(context.tr('هنوز چالش فعالی نداری. یکی بساز! 🔥', 'No active challenges yet. Make one! 🔥'), style: rpText(RpType.body, weight: 500, color: p.muted)))];
    final now = a.clock().millisecondsSinceEpoch;
    return [
      for (final c in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${c['icon']}', style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(child: Text('${c['name']}', style: rpText(RpType.body, weight: 800, color: p.text))),
                _badge(context, '${c['status']}'),
              ]),
              const SizedBox(height: 6),
              if (c['kind'] == 'count' || c['kind'] == 'both') ...[
                Text(fa ? '${toPersianDigits(c['progressCount'] ?? 0)} از ${toPersianDigits(c['targetCount'])} ${c['unit'] ?? ''}' : '${c['progressCount'] ?? 0} / ${c['targetCount']} ${c['unit'] ?? ''}', style: rpText(RpType.label, weight: 600, color: p.muted)),
                const SizedBox(height: 4),
                RpProgressBar(value: (((c['progressCount'] as num?) ?? 0) / (c['targetCount'] as num)).clamp(0, 1).toDouble(), colors: [p.primary, p.primary2]),
                if (c['kind'] == 'both' && c['deadlineAt'] is num) Text(formatCountdown((c['deadlineAt'] as num).toInt() - now, fa), style: rpText(RpType.label, weight: 600, color: p.goldInk)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  OutlinedButton(onPressed: () => a.incrementChallenge(c['id'] as String, 1, notifier: n), child: const Text('+1')),
                  FilledButton(onPressed: () => a.finishCountChallenge(c['id'] as String, notifier: n), child: Text(context.tr('✓ تمومش کن', '✓ Finish'))),
                  TextButton(onPressed: () => a.cancelChallenge(c['id'] as String, notifier: n), child: Text(context.tr('لغو', 'Cancel'))),
                ]),
              ] else ...[
                Text(
                  '${context.tr('مهلت: ', 'Deadline: ')}${c['durationValue'] != null ? formatDuration((c['durationValue'] as num).toInt(), '${c['durationUnit']}', fa) : DateTime.fromMillisecondsSinceEpoch((c['deadlineAt'] as num).toInt()).toString().substring(0, 16)}',
                  style: rpText(RpType.label, weight: 500, color: p.muted),
                ),
                Text(formatCountdown((c['deadlineAt'] as num).toInt() - now, fa), style: rpText(RpType.body, weight: 800, color: p.goldInk)),
                const SizedBox(height: 8),
                TextButton(onPressed: () => a.cancelChallenge(c['id'] as String, notifier: n), child: Text(context.tr('لغو', 'Cancel'))),
              ],
            ]),
          ),
        ),
    ];
  }

  List<Widget> _history(BuildContext context) {
    final a = context.read<AppActions>();
    final p = context.rp;
    final fa = context.isFa;
    final pro = a.store.state['isPremium'] == true;
    final medals = ((a.store.state['medals'] as List?) ?? const []).cast<Map>().reversed.toList();
    final items = a.challenges.where((c) => const ['success', 'failed', 'cancelled'].contains(c['status'])).toList()
      ..sort((x, y) => (((y['completedAt'] ?? y['createdAt']) as num?) ?? 0).compareTo(((x['completedAt'] ?? x['createdAt']) as num?) ?? 0));
    return [
      Text(context.tr('مدال‌ها', 'Medals'), style: rpText(RpType.body, weight: 800, color: p.text)),
      const SizedBox(height: 8),
      if (medals.isEmpty)
        AppCard(child: Text('🏅 ${pro ? context.tr('با موفق شدن در چالش‌های شخصی، اینجا مدال می‌گیری.', 'Complete your challenges to earn medals here.') : context.tr('مدال‌ها مخصوص نسخه‌ی پرو هستند.', 'Medals are a Pro feature.')}', style: rpText(RpType.body, weight: 500, color: p.muted)))
      else
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final m in medals)
            SizedBox(width: 84, child: Column(children: [Text(m['tier'] == 'gold' ? '🥇' : m['tier'] == 'silver' ? '🥈' : '🥉', style: const TextStyle(fontSize: 32)), Text('${m['name']}', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: rpText(RpType.caption, weight: 600, color: p.muted))])),
        ]),
      const SizedBox(height: RpSpace.s4),
      if (items.isEmpty)
        AppCard(child: Text(context.tr('هنوز تاریخچه‌ای نیست.', 'No history yet.'), style: rpText(RpType.body, weight: 500, color: p.muted)))
      else
        for (final c in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text('${c['icon']}', style: const TextStyle(fontSize: 24)), const SizedBox(width: 10), Expanded(child: Text('${c['name']}', style: rpText(RpType.body, weight: 800, color: p.text))), _badge(context, '${c['status']}')]),
                if (c['completedAt'] is num) Text(_date((c['completedAt'] as num).toInt(), fa), style: rpText(RpType.label, weight: 500, color: p.muted)),
                if (c['status'] == 'success') Text('🪙 ${context.n(c['rewardCoins'] ?? 0)}${'${c['rewardText'] ?? ''}'.isNotEmpty ? ' + 🎁 ${c['rewardText']}' : ''}', style: rpText(RpType.label, weight: 600, color: p.goldInk)),
              ]),
            ),
          ),
    ];
  }

  String _date(int ms, bool fa) => dateNumeric(DateTime.fromMillisecondsSinceEpoch(ms), jalali: isJalali(context.read<AppStore>().state), fa: fa);
}
