// صفحه‌ی کارها (To-Do): افزودن سریع، فهرست با زمان/تکرار/زیرتسک، ویرایش، حذف و پاک‌کردنِ انجام‌شده‌ها.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/pro_features.dart';
import '../../ui/pro_widgets.dart';
import '../../app/i18n.dart';
import '../../core/date_fmt.dart';
import '../shared/date_picker.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../data/notifier.dart';
import '../../data/todo_ops.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';

const _faWd = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
const _enWd = ['Sa', 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr'];

String formatDueLabel(int dueAt, {required bool fa, required bool jalali}) =>
    dateTimeLabel(DateTime.fromMillisecondsSinceEpoch(dueAt), jalali: jalali, fa: fa, sep: ' - ');

String todoRepeatSummary(Map t, bool fa) {
  final m = t['repeatMode'];
  if (m == null || m == 'none') return '';
  if (m == 'daily') return fa ? 'همه‌روزه' : 'Daily';
  final names = fa ? _faWd : _enWd;
  final days = [for (final d in (t['repeatDays'] as List? ?? const [])) (d as num).toInt()]..sort();
  return days.isNotEmpty ? days.map((i) => names[i]).join('، ') : (fa ? 'روزهای خاص' : 'Custom days');
}

Future<int?> pickDateTime(BuildContext context, int? initial) async {
  final now = DateTime.now();
  final init = initial != null ? DateTime.fromMillisecondsSinceEpoch(initial) : now;
  final d = await pickDate(context, init, first: DateTime(now.year - 1), last: DateTime(now.year + 5));
  if (d == null || !context.mounted) return null;
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(init),
    builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
  );
  if (t == null) return null;
  return DateTime(d.year, d.month, d.day, t.hour, t.minute).millisecondsSinceEpoch;
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final c = TextEditingController();
  int? due;
  String repeat = 'none';
  int shown = 80;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppActions>().resetRepeatingTodosIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final actions = context.read<AppActions>();
    final notifier = context.read<Notifier>();
    final p = context.rp;
    final fa = context.isFa;
    final now = actions.today;
    final all = ((store.state['todos'] as List?) ?? const []).cast<Map>();
    final todos = all.where((t) => todoAppliesOn(t, now)).toList();
    final sorted = [...todos]..sort((a, b) {
        final ad = a['done'] == true, bd = b['done'] == true;
        if (ad != bd) return ad ? 1 : -1;
        return ((b['createdAt'] as num?) ?? 0).compareTo((a['createdAt'] as num?) ?? 0);
      });
    final done = todos.where((t) => t['done'] == true).length;
    final nowMs = now.millisecondsSinceEpoch;
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Text(context.tr('کارها', 'To-Do'), style: rpText(RpType.titleL, weight: 800, color: p.text)),
        const SizedBox(height: RpSpace.s3),
        Row(children: [
          _Count(context.n(todos.length), context.tr('کل', 'Total'), p.blueInk, p.blueSoft),
          const SizedBox(width: RpSpace.s2),
          _Count(context.n(done), context.tr('انجام‌شده', 'Done'), p.okInk, p.okSoft),
          const SizedBox(width: RpSpace.s2),
          _Count(context.n(todos.length - done), context.tr('مانده', 'Pending'), p.goldInk, p.goldSoft),
        ]),
        const SizedBox(height: RpSpace.s3),
        AppCard(
          child: Column(children: [
            TextField(controller: c, decoration: InputDecoration(hintText: context.tr('کار جدید…', 'New task…'))),
            const SizedBox(height: RpSpace.s2),
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final v = await pickDateTime(context, due);
                  if (v != null) setState(() => due = v);
                },
                icon: const Icon(LucideIcons.alarmClock, size: 16),
                label: Text(due == null ? context.tr('زمان', 'Time') : formatDueLabel(due!, fa: fa, jalali: isJalali(store.state))),
              ),
              ChoiceChip(label: Text(context.tr('همه‌روزه', 'Daily')), selected: repeat == 'daily', onSelected: (s) => setState(() => repeat = s ? 'daily' : 'none')),
              RpButton(context.tr('افزودن', 'Add'), small: true, icon: LucideIcons.plus, onTap: () {
                final t = actions.addTodo(c.text, dueAt: due, repeatMode: repeat, notifier: notifier);
                if (t == null) {
                  actions.toasts.show(context.tr('لطفاً عنوان کار را وارد کن', 'Please enter a task title'), ms: 2000);
                  return;
                }
                c.clear();
                setState(() => due = null);
                actions.toasts.show(context.tr('✅ کار اضافه شد', '✅ Task added'), ms: 1500);
              }),
            ]),
          ]),
        ),
        const SizedBox(height: RpSpace.s3),
        if (sorted.isEmpty)
          AppCard(child: Text(context.tr('هیچ کاری برای امروز نیست. یک کار جدید اضافه کن! ✅', 'No tasks for today. Add a new one! ✅'), style: rpText(RpType.body, weight: 500, color: p.muted)))
        else
          for (final t in sorted.take(shown))
            _TodoCard(todo: t, nowMs: nowMs, actions: actions, notifier: notifier),
        if (sorted.length > shown)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: RpButton(context.tr('نمایش بیشتر (${context.n(sorted.length - shown)} کار دیگر)', 'Show more (${sorted.length - shown} more)'), kind: BtnKind.tonal, onTap: () => setState(() => shown += 80)),
          ),
        if (todos.any((t) => t['done'] == true))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: RpButton(context.tr('پاک‌کردن انجام‌شده‌ها', 'Clear done'), kind: BtnKind.ghost, icon: LucideIcons.trash2, onTap: actions.clearDoneTodos),
          ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  final String v, label;
  final Color fg, bg;
  const _Count(this.v, this.label, this.fg, this.bg);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: RpSpace.s3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(RpRadius.md)),
          child: Column(children: [
            Text(v, style: rpText(RpType.title, weight: 800, color: fg)),
            Text(label, style: rpText(RpType.caption, weight: 600, color: context.rp.muted)),
          ]),
        ),
      );
}

class _TodoCard extends StatelessWidget {
  final Map todo;
  final int nowMs;
  final AppActions actions;
  final Notifier notifier;
  const _TodoCard({required this.todo, required this.nowMs, required this.actions, required this.notifier});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    final t = todo;
    final done = t['done'] == true;
    final dueAt = (t['dueAt'] as num?)?.toInt();
    final overdue = !done && dueAt != null && dueAt <= nowMs;
    final soon = !done && dueAt != null && dueAt > nowMs && dueAt - nowMs <= 30 * 60000;
    final subs = ((t['subtasks'] as List?) ?? const []).cast<Map>();
    final rep = todoRepeatSummary(t, fa);
    return Padding(
      padding: const EdgeInsets.only(bottom: RpSpace.s2),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(
              onTap: () => actions.toggleTodo(t['id'] as String, notifier: notifier),
              child: Icon(done ? LucideIcons.circleCheck : LucideIcons.circle, color: done ? p.okInk : p.muted),
            ),
            const SizedBox(width: RpSpace.s3),
            Expanded(
              child: Text('${t['title']}', style: rpText(RpType.body, weight: 700, color: done ? p.muted : p.text).copyWith(decoration: done ? TextDecoration.lineThrough : null)),
            ),
            IconButton(icon: Icon(LucideIcons.pencil, size: 18, color: p.muted), tooltip: context.tr('ویرایش', 'Edit'), onPressed: () => _edit(context)),
            IconButton(
              icon: Icon(LucideIcons.trash2, size: 18, color: p.badInk),
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
                if (ok == true) actions.deleteTodo(t['id'] as String, notifier: notifier);
              },
            ),
          ]),
          if (dueAt != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 36),
              child: Text('⏰ ${formatDueLabel(dueAt, fa: fa, jalali: isJalali(context.read<AppStore>().state))}', style: rpText(RpType.label, weight: 600, color: overdue ? p.badInk : soon ? p.fire : p.muted)),
            ),
          if (rep.isNotEmpty)
            Padding(padding: const EdgeInsetsDirectional.only(start: 36), child: Text('🔁 $rep', style: rpText(RpType.label, weight: 500, color: p.muted))),
          if (subs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 36, top: 4),
              child: Text('☑ ${context.tr('${context.n(subs.where((x) => x['done'] == true).length)} از ${context.n(subs.length)}', '${subs.where((x) => x['done'] == true).length}/${subs.length}')}', style: rpText(RpType.label, weight: 700, color: p.primary)),
            ),
            for (final s in subs)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 28),
                child: InkWell(
                  onTap: () => actions.toggleSubtask(t['id'] as String, s['id'] as String),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Row(children: [
                      Icon(s['done'] == true ? LucideIcons.squareCheck : LucideIcons.square, size: 18, color: s['done'] == true ? p.okInk : p.muted),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${s['title']}', style: rpText(RpType.body, weight: 500, color: s['done'] == true ? p.muted : p.text))),
                    ]),
                  ),
                ),
              ),
          ],
        ]),
      ),
    );
  }

  void _edit(BuildContext context) {
    showRpSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TodoEditor(todo: todo, actions: actions, notifier: notifier),
    );
  }
}

class _TodoEditor extends StatefulWidget {
  final Map todo;
  final AppActions actions;
  final Notifier notifier;
  const _TodoEditor({required this.todo, required this.actions, required this.notifier});
  @override
  State<_TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends State<_TodoEditor> {
  late final title = TextEditingController(text: '${widget.todo['title']}');
  final sub = TextEditingController();
  late int? due = (widget.todo['dueAt'] as num?)?.toInt();
  late String mode = '${widget.todo['repeatMode'] ?? 'none'}';
  late bool high = widget.todo['priority'] == 'high';
  late List<int> days = [for (final d in (widget.todo['repeatDays'] as List? ?? const [])) (d as num).toInt()];
  late List<Map> subs = [for (final s in (widget.todo['subtasks'] as List? ?? const []).cast<Map>()) {...s}];

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    final a = widget.actions;
    final names = fa ? _faWd : _enWd;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(RpSpace.s4), children: [
        RpSheetHeader(context.tr('ویرایش کار', 'Edit task')),
        const SizedBox(height: RpSpace.s3),
        TextField(controller: title, decoration: InputDecoration(labelText: context.tr('عنوان', 'Title'))),
        SwitchListTile(key: const ValueKey('todo-high'), dense: true, contentPadding: EdgeInsets.zero, title: Text(context.tr('کارِ مهم', 'Important task')), subtitle: Text(context.tr('۱۲ XP به‌جای ۸ XP هنگام انجام', '12 XP instead of 8 on completion')), value: high, onChanged: (v) => setState(() => high = v)),
        const SizedBox(height: RpSpace.s2),
        Row(children: [
          OutlinedButton.icon(
            onPressed: () async {
              final v = await pickDateTime(context, due);
              if (v != null) setState(() => due = v);
            },
            icon: const Icon(LucideIcons.alarmClock, size: 16),
            label: Text(due == null ? context.tr('بدون زمان', 'No time') : formatDueLabel(due!, fa: fa, jalali: isJalali(widget.actions.store.state))),
          ),
          if (due != null) IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => setState(() => due = null)),
        ]),
        const SizedBox(height: RpSpace.s2),
        Wrap(spacing: 8, children: [
          for (final m in const [('none', 'بدون تکرار', 'No repeat'), ('daily', 'همه‌روزه', 'Daily'), ('custom', 'روزهای خاص', 'Custom days')])
            ChoiceChip(
              label: Text(fa ? m.$2 : m.$3),
              selected: mode == m.$1,
              onSelected: (_) {
                if (m.$1 == 'custom' && !a.isPro) {
                  showProBlocked(context, ProFeature.todoRepeatDays);
                  return;
                }
                setState(() => mode = m.$1);
              },
            ),
        ]),
        if (mode == 'custom')
          Wrap(spacing: 6, children: [
            for (int i = 0; i < 7; i++) FilterChip(label: Text(names[i]), selected: days.contains(i), onSelected: (s) => setState(() => s ? days.add(i) : days.remove(i))),
          ]),
        const SizedBox(height: RpSpace.s3),
        Text(context.tr('زیرتسک‌ها', 'Subtasks'), style: rpText(RpType.label, weight: 700, color: p.muted)),
        for (final s in subs)
          Row(children: [
            IconButton(icon: Icon(s['done'] == true ? LucideIcons.squareCheck : LucideIcons.square), onPressed: () => setState(() => s['done'] = !(s['done'] == true))),
            Expanded(child: Text('${s['title']}')),
            IconButton(icon: const Icon(LucideIcons.trash2, size: 18), onPressed: () => setState(() => subs.remove(s))),
          ]),
        Row(children: [
          Expanded(child: TextField(controller: sub, decoration: InputDecoration(hintText: context.tr('زیرتسک جدید', 'New subtask')))),
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              final tt = sub.text.trim();
              if (tt.isEmpty) return;
              if (!a.isPro && subs.length >= freeSubtaskLimit) {
                showProBlocked(context, ProFeature.subtasks);
                return;
              }
              setState(() {
                subs.add({'id': subUid(DateTime.now().millisecondsSinceEpoch), 'title': tt, 'done': false});
                sub.clear();
              });
            },
          ),
        ]),
        const ProNotice(ProFeature.subtasks, showCta: false),
        const SizedBox(height: RpSpace.s4),
        Row(children: [
          Expanded(child: RpButton(context.tr('انصراف', 'Cancel'), kind: BtnKind.ghost, onTap: () => Navigator.pop(context))),
          const SizedBox(width: RpSpace.s3),
          Expanded(
            child: RpButton(context.tr('ذخیره', 'Save'), onTap: () {
              final ok = a.saveTodoEdit(widget.todo['id'] as String, title: title.text, dueAt: due, repeatMode: mode, repeatDays: days, subs: subs, high: high, notifier: widget.notifier);
              if (!ok) {
                a.toasts.show(context.tr('عنوان نمی‌تونه خالی باشه', 'Title cannot be empty'), ms: 2000);
                return;
              }
              Navigator.pop(context);
              a.toasts.show(context.tr('✅ ذخیره شد', '✅ Saved'), ms: 1500);
            }),
          ),
        ]),
      ]),
    );
  }
}
