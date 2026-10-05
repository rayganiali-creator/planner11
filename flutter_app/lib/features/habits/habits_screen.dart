// صفحه‌ی عادت‌ها: کارت‌های مینیمال (سکه‌ی دریافتی، استریک، رکورد)، ثبت امروز (دوحالتی یا ورودی عددی درجا)،
// فلشِ بازشو برای یادداشت/عکس/سطح‌ها، ویرایش، حذف، جابه‌جایی و عادتِ جدید.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/pro_features.dart';
import '../../ui/pro_widgets.dart';
import '../../app/i18n.dart';
import '../../core/calendar.dart';
import '../../core/doc.dart';
import '../../core/habits.dart';
import '../../core/progress/ledger.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../data/habit_ops.dart';
import '../../ui/tokens.dart';
import '../onboarding/onboarding.dart';
import '../../ui/widgets.dart';
import '../record_flow.dart';
import 'habit_charts_sheet.dart';
import '../../data/media_store.dart';
import '../media/media_widgets.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final actions = context.read<AppActions>();
    final p = context.rp;
    final st = store.state;
    final habits = (st['habits'] as List).cast<Map>();
    final now = actions.today;
    final iso = dateToISO(startOfDay(now));
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Row(children: [
          Expanded(child: Text(context.tr('عادت‌ها', 'Habits'), style: rpText(RpType.titleL, weight: 800, color: p.text))),
          HelpButton('habits'),
          const SizedBox(width: 4),
          FilledButton.icon(
            key: const ValueKey('new-habit'),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RpRadius.sm))),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(context.tr('عادت جدید', 'New habit')),
            onPressed: () {
              if (!actions.canCreateHabit()) {
                showProBlocked(context, ProFeature.habits);
                return;
              }
              showHabitEditor(context, null);
            },
          ),
        ]),
        const SizedBox(height: RpSpace.s3),
        if (habits.isEmpty) AppCard(child: Text(context.tr('هنوز عادتی ندارید. با «عادت جدید» یکی بسازید.', 'No habits yet. Create one with “New habit”.'), style: rpText(RpType.body, weight: 500, color: p.muted))),
        for (int i = 0; i < habits.length; i++) _HabitCard(key: ValueKey('hc-${habits[i]['id']}'), habit: habits[i], index: i, iso: iso, now: now),
      ],
    );
  }
}

class _HabitCard extends StatefulWidget {
  final Map habit;
  final int index;
  final String iso;
  final DateTime now;
  const _HabitCard({super.key, required this.habit, required this.index, required this.iso, required this.now});
  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> {
  bool open = false;

  Widget _stat(BuildContext context, IconData icon, Color color, String value, String label, String tip) {
    final p = context.rp;
    return Tooltip(
      message: tip,
      triggerMode: TooltipTriggerMode.tap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: rpText(RpType.label, weight: 800, color: p.text)),
        const SizedBox(width: 3),
        Text(label, style: rpText(RpType.caption, weight: 600, color: p.muted)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit, iso = widget.iso, now = widget.now;
    final p = context.rp;
    final store = context.read<AppStore>();
    final actions = context.read<AppActions>();
    final st = store.state;
    final fa = context.isFa;
    final id = habit['id'] as String;
    final xp = validEvents(st, type: 'habit').where((e) => e['sourceId'] == id).fold<int>(0, (a, e) => a + (e['amount'] as int));
    final streak = computeHabitStreak(st, habit, now);
    final best = computeHabitBestRecord(st, habit);
    final applies = habitAppliesOnISO(habit, iso);
    final ok = habitSuccessOnISO(st, habit, iso);
    final type = habit['type'];
    return Padding(
      padding: const EdgeInsets.only(bottom: RpSpace.s3),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s2, RpSpace.s3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('${habit['name'] ?? ''}', style: rpText(RpType.bodyL, weight: 800, color: p.text))),
            if (habit['important'] == true) RpChip(context.tr('مهم', 'Important')),
            IconButton(
              key: ValueKey('expand-$id'),
              tooltip: context.tr('یادداشت و عکس', 'Notes & photos'),
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              onPressed: () => setState(() => open = !open),
              icon: AnimatedRotation(turns: open ? .5 : 0, duration: RpMotion.fast, child: Icon(Icons.keyboard_arrow_down_rounded, color: p.muted)),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(LucideIcons.ellipsisVertical, color: p.muted, size: 18),
              onSelected: (v) async {
                if (v == 'edit') showHabitEditor(context, habit);
                if (v == 'charts') showHabitCharts(context, habit);
                if (v == 'down') actions.moveHabitDown(widget.index);
                if (v == 'del') {
                  final okDel = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(fa ? 'حذف؟' : 'Delete?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(fa ? 'انصراف' : 'Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(fa ? 'حذف' : 'Delete')),
                      ],
                    ),
                  );
                  if (okDel == true) actions.deleteHabit(id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(fa ? 'ویرایش' : 'Edit')),
                PopupMenuItem(value: 'charts', child: Text(fa ? '📊 نمودارهای عادت' : '📊 Habit charts')),
                PopupMenuItem(value: 'down', child: Text(fa ? 'انتقال به پایین' : 'Move down')),
                PopupMenuItem(value: 'del', child: Text(fa ? 'حذف' : 'Delete')),
              ],
            ),
          ]),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: RpSpace.s2),
            child: Wrap(spacing: 14, runSpacing: 4, children: [
              _stat(context, LucideIcons.sparkles, p.primary, context.n(xp), 'XP', context.tr('مجموع XP واقعیِ کسب‌شده از این عادت', 'Total real XP earned from this habit')),
              _stat(context, LucideIcons.flame, p.fire, context.n(streak), context.tr('روز پیاپی', 'day streak'), context.tr('چند روزِ پشت‌سرهم این عادت را موفق انجام داده‌ای', 'Consecutive days you completed this habit')),
              if (best != null) _stat(context, LucideIcons.trophy, p.goldInk, context.n(best), context.tr('رکورد', 'best'), context.tr('بلندترین رشته‌ی روزهای پیاپیِ موفقِ این عادت', 'Your longest streak of successful days for this habit')),
            ]),
          ),
          const SizedBox(height: RpSpace.s3),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: RpSpace.s2),
            child: !applies
                ? Text(context.tr('امروز سررسید ندارد', 'Not due today'), style: rpText(RpType.label, weight: 500, color: p.muted))
                : type == 'binary'
                    ? Row(children: [
                        Expanded(child: _BinaryBtn(icon: LucideIcons.x, label: context.tr('نشد', 'Missed'), on: ok == false && _hasRecord(st, iso, id), color: p.badInk, soft: p.badSoft, onTap: () => recordBinaryFlow(context, id, iso, 'fail', alreadyActive: ok == false && _hasRecord(st, iso, id)))),
                        const SizedBox(width: RpSpace.s2),
                        Expanded(child: _BinaryBtn(icon: LucideIcons.check, label: context.tr('انجام شد', 'Done'), on: ok == true, color: p.okInk, soft: p.okSoft, onTap: () => recordBinaryFlow(context, id, iso, 'success', alreadyActive: ok == true))),
                      ])
                    : _InlineValue(habit: habit, iso: iso, state: st),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(top: RpSpace.s3, end: RpSpace.s2),
                    child: _HabitDetails(habit: habit),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ]),
      ),
    );
  }

  static bool _hasRecord(Map st, String iso, String id) => ((st['records'] as Map?)?[iso] as Map?)?.containsKey(id) ?? false;
}

class _BinaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool on;
  final Color color, soft;
  final VoidCallback onTap;
  const _BinaryBtn({required this.icon, required this.label, required this.on, required this.color, required this.soft, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: RpMotion.fast,
          height: 42,
          decoration: BoxDecoration(color: on ? color : soft, borderRadius: BorderRadius.circular(RpRadius.sm)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: on ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label, style: rpText(RpType.label, weight: 800, color: on ? Colors.white : color)),
          ]),
        ),
      );
}

/// ثبتِ مقدارِ عادت‌های عددی/زمانی درجا (همان مسیر recordValueFlow: «چرا؟»، پاداش/تنبیه، استریک، سکه)
class _InlineValue extends StatefulWidget {
  final Map habit;
  final String iso;
  final Doc state;
  const _InlineValue({required this.habit, required this.iso, required this.state});
  @override
  State<_InlineValue> createState() => _InlineValueState();
}

class _InlineValueState extends State<_InlineValue> {
  final _c = TextEditingController();
  final _f = FocusNode();

  num? get _cur {
    final raw = ((widget.state['records'] as Map?)?[widget.iso] as Map?)?[widget.habit['id']];
    final v = raw is Map ? raw['value'] : raw; // مثل JS رشته ذخیره می‌شود
    return v is num ? v : (v == null ? null : num.tryParse('$v'));
  }

  String _fmt(num v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  void initState() {
    super.initState();
    final v = _cur;
    if (v != null) _c.text = _fmt(v);
  }

  @override
  void didUpdateWidget(_InlineValue o) {
    super.didUpdateWidget(o);
    if (!_f.hasFocus) {
      final v = _cur;
      final t = v == null ? '' : _fmt(v);
      if (_c.text != t) _c.text = t;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  static num? parseNumber(String raw) {
    const fa = '۰۱۲۳۴۵۶۷۸۹', ar = '٠١٢٣٤٥٦٧٨٩';
    final b = StringBuffer();
    for (final ch in raw.trim().split('')) {
      final i = fa.indexOf(ch), k = ar.indexOf(ch);
      b.write(i >= 0 ? '$i' : k >= 0 ? '$k' : (ch == '٫' || ch == ',' || ch == '،') ? '.' : ch);
    }
    final v = double.tryParse(b.toString());
    if (v == null || v.isNaN || v.isInfinite || v < 0) return null;
    return v == v.roundToDouble() ? v.toInt() : v;
  }

  Future<void> _save() async {
    final actions = context.read<AppActions>();
    _f.unfocus();
    if (_c.text.trim().isEmpty) {
      if (_cur != null) actions.clear(widget.iso, widget.habit['id'] as String);
      return;
    }
    final v = parseNumber(_c.text);
    if (v == null) {
      actions.toasts.show(context.tr('عدد معتبر وارد کن', 'Enter a valid number'), ms: 2000);
      return;
    }
    await recordValueFlow(context, widget.habit['id'] as String, widget.iso, v);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final h = widget.habit;
    final ok = habitSuccessOnISO(widget.state, h, widget.iso);
    final timer = h['type'] == 'timer';
    final unit = timer ? context.tr('دقیقه', 'min') : '${h['numericUnit'] ?? ''}';
    final target = timer ? h['timerTarget'] : h['numericTarget'];
    final cur = _cur;
    final caption = [
      cur != null ? context.n(_fmt(cur)) : context.tr('ثبت نشده', 'Not logged'),
      if (target is num) '/ ${context.n(_fmt(target))}',
      unit,
    ].where((e) => e.isNotEmpty).join(' ');
    return Row(children: [
      Expanded(child: Text(caption, style: rpText(RpType.label, weight: 700, color: ok == true ? p.okInk : p.muted))),
      SizedBox(
        width: 84,
        height: 42,
        child: TextField(
          key: ValueKey('value-${h['id']}'),
          controller: _c,
          focusNode: _f,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          style: rpText(RpType.bodyL, weight: 800, color: p.text),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: p.surface2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            hintText: '0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(RpRadius.sm), borderSide: BorderSide.none),
          ),
        ),
      ),
      const SizedBox(width: RpSpace.s2),
      GestureDetector(
        key: ValueKey('save-${h['id']}'),
        onTap: _save,
        child: AnimatedContainer(
          duration: RpMotion.fast,
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: ok == true ? p.okInk : p.okSoft, borderRadius: BorderRadius.circular(RpRadius.sm)),
          child: Icon(LucideIcons.check, size: 20, color: ok == true ? Colors.white : p.okInk),
        ),
      ),
    ]);
  }
}

/// بخشِ بازشدنیِ کارت: یادداشت (ذخیره‌ی خودکار) و عکس‌ها
class _HabitDetails extends StatefulWidget {
  final Map habit;
  const _HabitDetails({required this.habit});
  @override
  State<_HabitDetails> createState() => _HabitDetailsState();
}

class _HabitDetailsState extends State<_HabitDetails> {
  late final AppStore store = context.read<AppStore>();
  late final String id = widget.habit['id'] as String;
  late final TextEditingController c = TextEditingController(text: '${_notes[id] ?? ''}');
  Timer? _t;

  Map get _notes => store.state['habitNotes'] is Map ? store.state['habitNotes'] as Map : (store.state['habitNotes'] = <String, dynamic>{}) as Map;

  void _flush() {
    _t?.cancel();
    final v = c.text;
    if (v.trim().isNotEmpty) {
      _notes[id] = v;
    } else {
      _notes.remove(id);
    }
    store.save();
  }

  @override
  void dispose() {
    if (_t?.isActive ?? false) _flush();
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        key: ValueKey('notes-$id'),
        controller: c,
        maxLines: 4,
        minLines: 2,
        onChanged: (_) {
          _t?.cancel();
          _t = Timer(const Duration(milliseconds: 700), _flush);
        },
        onTapOutside: (_) {
          if (_t?.isActive ?? false) _flush();
        },
        decoration: InputDecoration(
          hintText: context.tr('یادداشت…', 'Notes…'),
          filled: true,
          fillColor: p.surface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(RpRadius.sm), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: RpSpace.s3),
      PhotoStrip(kind: PhotoKind.habit, ownerId: id),
    ]);
  }
}

// ---------------------------------------------------------------- ویرایشگر
Future<void> showHabitEditor(BuildContext context, Map? habit) {
  final actions = context.read<AppActions>();
  final form = habit == null ? HabitForm(actions.todayISO) : HabitForm.from(habit);
  return showRpSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _Editor(form: form, editingId: habit?['id'] as String?, actions: actions),
  );
}

class _Editor extends StatefulWidget {
  final HabitForm form;
  final String? editingId;
  final AppActions actions;
  const _Editor({required this.form, required this.editingId, required this.actions});
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  HabitForm get f => widget.form;
  late final name = TextEditingController(text: f.name);
  late final unit = TextEditingController(text: f.numericUnit);

  /// دکمه‌های قرص‌شکلِ هم‌عرض (segmented)
  Widget _segRow<T>(List<(String, T)> opts, T group, void Function(T) on) {
    final p = context.rp;
    return Row(children: [
      for (int i = 0; i < opts.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => on(opts[i].$2)),
            child: AnimatedContainer(
              duration: RpMotion.fast,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: opts[i].$2 == group ? p.primarySoft : p.surface2, borderRadius: BorderRadius.circular(RpRadius.sm), border: Border.all(color: opts[i].$2 == group ? p.primary : Colors.transparent, width: 1.5)),
              child: Text(opts[i].$1, style: rpText(RpType.label, weight: 800, color: opts[i].$2 == group ? p.primary : p.muted)),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(top: RpSpace.s4, bottom: 6), child: Text(t, style: rpText(RpType.caption, weight: 800, color: context.rp.muted)));

  InputDecoration _dec(String hint, {String? label}) {
    final p = context.rp;
    return InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: p.surface2, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(RpRadius.sm), borderSide: BorderSide.none));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    final days = fa ? ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'] : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const prio = [('gold', Color(0xFFE0B13E)), ('green', Color(0xFF3FA35A)), ('yellow', Color(0xFFE6C84A)), ('red', Color(0xFFD9534F))];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ListView(padding: const EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, RpSpace.s4), shrinkWrap: true, children: [
        RpSheetHeader(widget.editingId == null ? (fa ? 'عادت جدید' : 'New Habit') : (fa ? 'ویرایش عادت' : 'Edit Habit')),
        const SizedBox(height: RpSpace.s3),
        TextField(controller: name, style: rpText(RpType.bodyL, weight: 700, color: p.text), decoration: _dec(fa ? 'نام عادت' : 'Habit name'), onChanged: (v) => f.name = v),
        _label(fa ? 'نوع' : 'Type'),
        _segRow<String>([(fa ? 'انجام / نشد' : 'Yes / No', 'binary'), (fa ? 'عددی' : 'Number', 'numeric'), (fa ? 'زمانی' : 'Timer', 'timer')], f.type, (v) => f.type = v),
        if (f.type == 'numeric') ...[
          _label(fa ? 'هدف' : 'Goal'),
          Row(children: [
            Expanded(child: TextFormField(initialValue: '${f.numericTarget}', keyboardType: TextInputType.number, decoration: _dec(fa ? 'هدف' : 'Target'), onChanged: (v) => f.numericTarget = double.tryParse(v) ?? 1)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: unit, decoration: _dec(fa ? 'واحد' : 'Unit'), onChanged: (v) => f.numericUnit = v)),
          ]),
        ],
        if (f.type == 'timer') ...[_label(fa ? 'هدف (دقیقه)' : 'Goal (minutes)'), TextFormField(initialValue: '${f.timerTarget}', keyboardType: TextInputType.number, decoration: _dec(fa ? 'دقیقه' : 'Minutes'), onChanged: (v) => f.timerTarget = double.tryParse(v) ?? 30)],
        if (f.type != 'binary') ...[
          const SizedBox(height: RpSpace.s2),
          _segRow<String>([(fa ? 'بیشتر بهتر' : 'More is better', 'more'), (fa ? 'کمتر بهتر' : 'Less is better', 'less')], f.direction, (v) => f.direction = v),
        ],
        _label(fa ? 'برنامه' : 'Schedule'),
        _segRow<String>([(fa ? 'هر روز' : 'Daily', 'daily'), (fa ? 'روزهای خاص' : 'Custom days', 'custom')], f.scheduleMode, (v) => f.scheduleMode = v),
        if (f.scheduleMode == 'custom') ...[
          const SizedBox(height: RpSpace.s2),
          Wrap(spacing: 6, children: [
            for (int d = 0; d < 7; d++)
              FilterChip(
                visualDensity: VisualDensity.compact,
                label: Text(days[d]),
                selected: f.activeDays.contains(d),
                onSelected: (s) => setState(() => s ? f.activeDays.add(d) : f.activeDays.remove(d)),
              ),
          ]),
        ],
        const SizedBox(height: RpSpace.s2),
        SwitchListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(fa ? 'دائمی' : 'Permanent'), value: f.permanent, onChanged: (v) => setState(() => f.permanent = v)),
        if (!f.permanent) TextFormField(initialValue: '${f.durationDays}', keyboardType: TextInputType.number, decoration: _dec(fa ? 'تعداد روز' : 'Days'), onChanged: (v) => f.durationDays = int.tryParse(v) ?? 1),
        _label(fa ? 'اولویت' : 'Priority'),
        Row(children: [
          for (final pr in prio)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: GestureDetector(
                onTap: () => setState(() => f.priority = pr.$1),
                child: AnimatedContainer(duration: RpMotion.fast, width: 34, height: 34, decoration: BoxDecoration(color: pr.$2, shape: BoxShape.circle, border: Border.all(color: f.priority == pr.$1 ? p.text : Colors.transparent, width: 3))),
              ),
            ),
        ]),
        const SizedBox(height: RpSpace.s2),
        SwitchListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(fa ? 'یادآوری روزانه' : 'Daily reminder'), value: f.reminderEnabled, onChanged: (v) => setState(() => f.reminderEnabled = v)),
        if (f.reminderEnabled)
          ListTile(
            key: const ValueKey('habit-reminder-time'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.clock),
            title: Text(fa ? 'ساعت یادآوری' : 'Reminder time'),
            trailing: Text(fa ? toPersianDigits(f.reminderTime) : f.reminderTime, style: rpText(RpType.bodyL, weight: 600)),
            onTap: () async {
              final parts = f.reminderTime.split(':');
              final cur = TimeOfDay(hour: int.tryParse(parts.first) ?? 8, minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
              final t = await showTimePicker(
                context: context,
                initialTime: cur,
                builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
              );
              if (t != null) setState(() => f.reminderTime = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
            },
          ),
        const SizedBox(height: RpSpace.s2),
        RpCollapsible(
          key: const ValueKey('editor-more'),
          card: false,
          title: fa ? 'اهمیت، پاداش و هدف هفتگی' : 'Importance, reward & weekly goal',
          icon: LucideIcons.gift,
          child: Column(children: [
            SwitchListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(fa ? 'عادتِ مهم یا دشوار' : 'Important or hard habit'), subtitle: Text(fa ? '۱۵ XP به‌جای ۱۰ XP برای هر بار انجام' : '15 XP instead of 10 per completion'), value: f.important, onChanged: (v) => setState(() => f.important = v)),
            const SizedBox(height: 8),
            TextFormField(initialValue: f.rewardText, decoration: _dec(fa ? 'پاداش' : 'Reward'), onChanged: (v) => f.rewardText = v),
            const SizedBox(height: 8),
            TextFormField(initialValue: f.punishmentText, decoration: _dec(fa ? 'تنبیه' : 'Punishment'), onChanged: (v) => f.punishmentText = v),
            const SizedBox(height: 8),
            TextFormField(initialValue: f.weeklyGoal?.toString() ?? '', keyboardType: TextInputType.number, decoration: _dec(fa ? 'هدف هفتگی (اختیاری)' : 'Weekly goal (optional)'), onChanged: (v) => f.weeklyGoal = int.tryParse(v.trim())),
          ]),
        ),
        const SizedBox(height: RpSpace.s4),
        Row(children: [
          Expanded(child: RpButton(fa ? 'انصراف' : 'Cancel', kind: BtnKind.ghost, onTap: () => Navigator.pop(context))),
          const SizedBox(width: RpSpace.s3),
          Expanded(
            child: RpButton(fa ? 'ذخیره' : 'Save', onTap: () {
              if (widget.actions.saveHabit(f, editingId: widget.editingId) != null) Navigator.pop(context);
            }),
          ),
        ]),
      ]),
    );
  }
}
