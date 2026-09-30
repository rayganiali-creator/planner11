// ژورنال: افزودن، جست‌وجو، ویرایش، حذف، یادآوری (پرو) و نمایش تدریجی.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../core/calendar.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../data/journal_ops.dart';
import '../../data/notifier.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../todo/todo_screen.dart' show pickDateTime;

String fmtDateTime(int ms, bool fa) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final t = '${pad2(d.hour)}:${pad2(d.minute)}';
  if (fa) {
    final j = toJalaali(d.year, d.month, d.day);
    return toPersianDigits('${j.jd} ${persianMonths[j.jm - 1]} — $t');
  }
  return '${enMonths[d.month - 1]} ${d.day} — $t';
}

/// پنجره‌ی انتخابِ یادآوری؛ برای یادداشت و کتاب مشترک است
Future<void> showReminderPicker(BuildContext context, String kind, Map item) {
  final a = context.read<AppActions>();
  final n = context.read<Notifier>();
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: context.rp.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RpRadius.xl))),
    builder: (_) => _ReminderSheet(kind: kind, item: item, actions: a, notifier: n),
  );
}

class _ReminderSheet extends StatefulWidget {
  final String kind;
  final Map item;
  final AppActions actions;
  final Notifier notifier;
  const _ReminderSheet({required this.kind, required this.item, required this.actions, required this.notifier});
  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late int at = (widget.item['remindAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch + 3600000;
  late String repeat = '${widget.item['remindRepeat'] ?? 'none'}';
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final pro = widget.actions.isProUser;
    final fa = context.isFa;
    final sub = widget.kind == 'journal' ? '${widget.item['text'] ?? ''}' : '${widget.item['title'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.all(RpSpace.s4),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.tr('یادآوری', 'Reminder'), style: rpText(RpType.title, weight: 800, color: p.text)),
        Text(sub.length > 48 ? sub.substring(0, 48) : sub, style: rpText(RpType.label, weight: 500, color: p.muted)),
        if (!pro)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(context.tr('⭐ یادآوری یادداشت و کتاب از امکانات پرو است.', '⭐ Reminders for notes and books are a Pro feature.'), style: rpText(RpType.body, weight: 600, color: p.goldInk)),
          ),
        const SizedBox(height: RpSpace.s3),
        OutlinedButton.icon(
          onPressed: pro
              ? () async {
                  final v = await pickDateTime(context, at);
                  if (v != null) setState(() => at = v);
                }
              : null,
          icon: const Icon(LucideIcons.alarmClock, size: 16),
          label: Text(fmtDateTime(at, fa)),
        ),
        const SizedBox(height: RpSpace.s2),
        Wrap(spacing: 8, children: [
          for (final r in const [('none', 'بدون تکرار', 'No repeat'), ('daily', 'روزانه', 'Daily'), ('weekly', 'هفتگی', 'Weekly'), ('monthly', 'ماهانه', 'Monthly')])
            ChoiceChip(label: Text(fa ? r.$2 : r.$3), selected: repeat == r.$1, onSelected: pro ? (_) => setState(() => repeat = r.$1) : null),
        ]),
        const SizedBox(height: RpSpace.s4),
        Row(children: [
          Expanded(
            child: RpButton(context.tr('حذف یادآوری', 'Clear'), kind: BtnKind.ghost, onTap: pro
                ? () {
                    widget.actions.clearItemReminder(widget.kind, widget.item['id'] as String, notifier: widget.notifier);
                    Navigator.pop(context);
                  }
                : null),
          ),
          const SizedBox(width: RpSpace.s3),
          Expanded(
            child: RpButton(context.tr('ثبت', 'Save'), onTap: pro
                ? () {
                    final ok = widget.actions.setItemReminder(widget.kind, widget.item['id'] as String, at, repeat, notifier: widget.notifier);
                    if (!ok) {
                      widget.actions.toasts.show(context.tr('زمان باید در آینده باشد.', 'Pick a future time.'), ms: 2500);
                      return;
                    }
                    Navigator.pop(context);
                    widget.actions.toasts.show(context.tr('⏰ یادآوری ثبت شد: ${fmtDateTime(at, true)}', '⏰ Reminder set: ${fmtDateTime(at, false)}'), ms: 3000, cls: 'toast-success');
                  }
                : null),
          ),
        ]),
      ]),
    );
  }
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final text = TextEditingController();
  final search = TextEditingController();
  int shown = 30;
  String? editing;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final a = context.read<AppActions>();
    final n = context.read<Notifier>();
    final p = context.rp;
    final fa = context.isFa;
    final q = search.text.trim().toLowerCase();
    var entries = ((store.state['journal'] as List?) ?? const []).cast<Map>();
    if (q.isNotEmpty) entries = entries.where((e) => '${e['text']}'.toLowerCase().contains(q)).toList();
    final all = [...entries]..sort((x, y) => ((y['createdAt'] as num?) ?? 0).compareTo((x['createdAt'] as num?) ?? 0));
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return ListView(
      padding: const EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, 140),
      children: [
        Text(context.tr('ژورنال', 'Journal'), style: rpText(RpType.titleL, weight: 800, color: p.text)),
        const SizedBox(height: RpSpace.s3),
        AppCard(
          child: Column(children: [
            TextField(controller: text, maxLines: 4, maxLength: 2000, decoration: InputDecoration(hintText: context.tr('امروز چه خبر بود؟', 'What happened today?'))),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: RpButton(context.tr('ثبت یادداشت', 'Add entry'), small: true, icon: LucideIcons.plus, onTap: () {
                if (a.addJournal(text.text)) {
                  text.clear();
                  setState(() {});
                }
              }),
            ),
          ]),
        ),
        const SizedBox(height: RpSpace.s3),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.search, size: 18),
            hintText: context.tr('جست‌وجو در یادداشت‌ها', 'Search entries'),
            suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => setState(search.clear)),
          ),
        ),
        const SizedBox(height: RpSpace.s3),
        if (all.isEmpty)
          AppCard(child: Text('📝 ${q.isNotEmpty ? context.tr('نتیجه‌ای یافت نشد.', 'No results found.') : context.tr('هنوز یادداشتی ثبت نکردی.', 'No journal entries yet.')}', style: rpText(RpType.body, weight: 500, color: p.muted)))
        else
          for (final e in all.take(shown))
            Padding(
              padding: const EdgeInsets.only(bottom: RpSpace.s2),
              child: AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('📅 ${fmtFull((e['createdAt'] as num).toInt(), fa)}', style: rpText(RpType.label, weight: 600, color: p.muted)),
                  const SizedBox(height: 6),
                  if (editing == e['id'])
                    _Edit(entry: e, onDone: () => setState(() => editing = null), actions: a)
                  else ...[
                    Text('${e['text']}', style: rpText(RpType.body, weight: 500, color: p.text, height: 1.9)),
                    if (e['remindAt'] is num && (e['remindAt'] as num) > nowMs)
                      Padding(padding: const EdgeInsets.only(top: 6), child: Text('⏰ ${context.tr('یادآوری: ', 'Reminder: ')}${fmtDateTime((e['remindAt'] as num).toInt(), fa)}', style: rpText(RpType.label, weight: 600, color: p.goldInk))),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      IconButton(icon: Icon(LucideIcons.alarmClock, size: 18, color: p.muted), tooltip: context.tr('یادآوری', 'Reminder'), onPressed: () => showReminderPicker(context, 'journal', e)),
                      IconButton(icon: Icon(LucideIcons.pencil, size: 18, color: p.muted), tooltip: context.tr('ویرایش', 'Edit'), onPressed: () => setState(() => editing = e['id'] as String)),
                      IconButton(
                        icon: Icon(LucideIcons.x, size: 18, color: p.badInk),
                        tooltip: context.tr('حذف', 'Delete'),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text(context.tr('حذف شود؟', 'Delete?')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.tr('انصراف', 'Cancel'))),
                                FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.tr('حذف', 'Delete'))),
                              ],
                            ),
                          );
                          if (ok == true) a.deleteJournal(e['id'] as String, notifier: n);
                        },
                      ),
                    ]),
                  ],
                ]),
              ),
            ),
        if (all.length > shown)
          RpButton(context.tr('نمایش بیشتر (${context.n(all.length - shown)} یادداشت دیگر)', 'Show more (${all.length - shown} more)'), kind: BtnKind.tonal, onTap: () => setState(() => shown += 30)),
      ],
    );
  }
}

String fmtFull(int ms, bool fa) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final ts = '${pad2(d.hour)}:${pad2(d.minute)}';
  if (fa) {
    final j = toJalaali(d.year, d.month, d.day);
    return '${toPersianDigits(j.jd)} ${persianMonths[j.jm - 1]} ${toPersianDigits(j.jy)} — ${toPersianDigits(ts)}';
  }
  return '${enMonths[d.month - 1]} ${d.day}, ${d.year} — $ts';
}

class _Edit extends StatefulWidget {
  final Map entry;
  final VoidCallback onDone;
  final AppActions actions;
  const _Edit({required this.entry, required this.onDone, required this.actions});
  @override
  State<_Edit> createState() => _EditState();
}

class _EditState extends State<_Edit> {
  late final c = TextEditingController(text: '${widget.entry['text']}');
  @override
  Widget build(BuildContext context) => Column(children: [
        TextField(controller: c, maxLines: 5, maxLength: 2000),
        Row(children: [
          Expanded(child: RpButton(context.tr('انصراف', 'Cancel'), kind: BtnKind.ghost, small: true, onTap: widget.onDone)),
          const SizedBox(width: 8),
          Expanded(
            child: RpButton(context.tr('ذخیره', 'Save'), small: true, onTap: () {
              if (widget.actions.editJournal(widget.entry['id'] as String, c.text)) widget.onDone();
            }),
          ),
        ]),
      ]);
}
