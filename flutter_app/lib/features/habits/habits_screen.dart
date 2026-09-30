// صفحه‌ی عادت‌ها: فهرست با سطح/پیشرفت/استریک/بهترین رکورد، ثبتِ امروز، ویرایش، حذف، جابه‌جایی و عادتِ جدید.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../core/calendar.dart';
import '../../core/habits.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../data/habit_ops.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../record_flow.dart';
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
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, 140),
        children: [
          Text(context.tr('عادت‌ها', 'Habits'), style: rpText(RpType.titleL, weight: 800, color: p.text)),
          const SizedBox(height: RpSpace.s3),
          if (habits.isEmpty)
            AppCard(child: Text(context.tr('هنوز عادتی ندارید. با دکمه‌ی پایین یکی بسازید.', 'No habits yet. Create one below.'), style: rpText(RpType.body, weight: 500, color: p.muted))),
          for (int i = 0; i < habits.length; i++) _HabitCard(habit: habits[i], index: i, iso: iso, now: now),
        ],
      ),
      Positioned(
        left: RpSpace.s4, right: RpSpace.s4, bottom: 104,
        child: RpButton(context.tr('عادت جدید', 'New habit'),
          icon: LucideIcons.plus,
          onTap: () {
            if (!actions.canCreateHabit()) {
              context.read<AppActions>().toasts.show(
                  context.tr('⭐ در نسخه‌ی رایگان حداکثر ۳ عادت فعال می‌توانید داشته باشید. برای عادت‌های نامحدود، پرو را تهیه کنید.', '⭐ The free plan allows up to 3 active habits. Get Pro for unlimited habits.'),
                  ms: 3400);
              return;
            }
            showHabitEditor(context, null);
          },
        ),
      ),
    ]);
  }
}

class _HabitCard extends StatelessWidget {
  final Map habit;
  final int index;
  final String iso;
  final DateTime now;
  const _HabitCard({required this.habit, required this.index, required this.iso, required this.now});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final store = context.read<AppStore>();
    final actions = context.read<AppActions>();
    final st = store.state;
    final fa = context.isFa;
    final id = habit['id'] as String;
    final pts = computeHabitPoints(st, id);
    final levels = habitActiveThresholds(habit);
    final cur = getLevelFromPoints(pts, levels);
    final next = levels.where((l) => l.minPoints > pts).firstOrNull;
    final prevMin = cur.minPoints;
    final prog = next == null ? 1.0 : ((pts - prevMin) / (next.minPoints - prevMin)).clamp(0.0, 1.0).toDouble();
    final streak = computeHabitStreak(st, habit, now);
    final best = computeHabitBestRecord(st, habit);
    final applies = habitAppliesOnISO(habit, iso);
    final ok = habitSuccessOnISO(st, habit, iso);
    final type = habit['type'];
    return Padding(
      padding: const EdgeInsets.only(bottom: RpSpace.s3),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${habit['name'] ?? ''}', style: rpText(RpType.bodyL, weight: 800, color: p.text))),
            RpChip(cur.icon.isNotEmpty ? '${cur.icon} ${fa ? cur.labelFa : cur.labelEn}' : (fa ? cur.labelFa : cur.labelEn)),
            PopupMenuButton<String>(
              icon: Icon(LucideIcons.ellipsisVertical, color: p.muted, size: 20),
              onSelected: (v) async {
                if (v == 'edit') showHabitEditor(context, habit);
                if (v == 'notes') _notesSheet(context, habit);
                if (v == 'down') {
                  actions.moveHabitDown(index);
                }
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
                PopupMenuItem(value: 'notes', child: Text(fa ? 'یادداشت و عکس' : 'Notes & photos')),
                PopupMenuItem(value: 'down', child: Text(fa ? 'انتقال به پایین' : 'Move down')),
                PopupMenuItem(value: 'del', child: Text(fa ? 'حذف' : 'Delete')),
              ],
            ),
          ]),
          const SizedBox(height: RpSpace.s2),
          RpProgressBar(value: prog, colors: [p.primary, p.primary2]),
          const SizedBox(height: 6),
          Text(
            next == null
                ? context.tr('${context.n(pts.round())} امتیاز · به بالاترین سطحِ این مرحله رسیدید', '${pts.round()} pts · top level of this stage')
                : context.tr('${context.n(pts.round())} / ${context.n(next.minPoints)} امتیاز', '${pts.round()} / ${next.minPoints} pts'),
            style: rpText(RpType.label, weight: 500, color: p.muted),
          ),
          const SizedBox(height: RpSpace.s2),
          Row(children: [
            Icon(LucideIcons.flame, size: 16, color: p.fire),
            const SizedBox(width: 4),
            Text(context.n(streak), style: rpText(RpType.label, weight: 700, color: p.fire)),
            const SizedBox(width: RpSpace.s4),
            if (best != null) ...[
              Icon(LucideIcons.trophy, size: 16, color: p.goldInk),
              const SizedBox(width: 4),
              Text(context.n(best), style: rpText(RpType.label, weight: 700, color: p.goldInk)),
            ],
            const Spacer(),
            if (!applies)
              Text(context.tr('امروز سررسید ندارد', 'Not due today'), style: rpText(RpType.label, weight: 500, color: p.muted))
            else if (type == 'binary') ...[
              _Mark(icon: LucideIcons.x, on: ok == false && _hasRecord(st, iso, id), color: p.badInk, soft: p.badSoft,
                  onTap: () => recordBinaryFlow(context, id, iso, 'fail', alreadyActive: ok == false && _hasRecord(st, iso, id))),
              const SizedBox(width: RpSpace.s2),
              _Mark(icon: LucideIcons.check, on: ok == true, color: p.okInk, soft: p.okSoft,
                  onTap: () => recordBinaryFlow(context, id, iso, 'success', alreadyActive: ok == true)),
            ] else
              OutlinedButton.icon(
                onPressed: () => _askValue(context, habit, iso),
                icon: Icon(ok == true ? LucideIcons.circleCheck : LucideIcons.pencil, size: 16),
                label: Text(_valueLabel(context, st, iso, habit)),
              ),
          ]),
        ]),
      ),
    );
  }

  static bool _hasRecord(Map st, String iso, String id) => ((st['records'] as Map?)?[iso] as Map?)?.containsKey(id) ?? false;

  static String _valueLabel(BuildContext context, Map st, String iso, Map h) {
    final raw = ((st['records'] as Map?)?[iso] as Map?)?[h['id']];
    final v = raw is Map ? raw['value'] : raw;
    final unit = h['type'] == 'timer' ? context.tr('دقیقه', 'min') : '${h['numericUnit'] ?? ''}';
    if (v == null) return context.tr('ثبت مقدار', 'Log value');
    return '${context.n(v)} $unit';
  }

  Future<void> _askValue(BuildContext context, Map h, String iso) async {
    final actions = context.read<AppActions>();
    final fa = context.isFa;
    final raw = ((actions.store.state['records'] as Map?)?[iso] as Map?)?[h['id']];
    final cur = raw is Map ? raw['value'] : raw;
    final c = TextEditingController(text: cur == null ? '' : '$cur');
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${h['name']}'),
        content: TextField(controller: c, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, '__clear'), child: Text(fa ? 'پاک کردن' : 'Clear')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(fa ? 'ثبت' : 'Save')),
        ],
      ),
    );
    if (r == null) return;
    if (r == '__clear') return actions.clear(iso, h['id'] as String);
    final v = double.tryParse(r.replaceAll('٫', '.'));
    if (v == null || !context.mounted) return;
    await recordValueFlow(context, h['id'] as String, iso, v == v.roundToDouble() ? v.toInt() : v);
  }
}

class _Mark extends StatelessWidget {
  final IconData icon;
  final bool on;
  final Color color, soft;
  final VoidCallback onTap;
  const _Mark({required this.icon, required this.on, required this.color, required this.soft, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: RpMotion.fast,
          width: 44, height: 44,
          decoration: BoxDecoration(color: on ? color : soft, borderRadius: BorderRadius.circular(RpRadius.sm)),
          child: Icon(icon, size: 20, color: on ? Colors.white : color),
        ),
      );
}

// ---------------------------------------------------------------- ویرایشگر
Future<void> showHabitEditor(BuildContext context, Map? habit) {
  final actions = context.read<AppActions>();
  final form = habit == null ? HabitForm(actions.todayISO) : HabitForm.from(habit);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.rp.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RpRadius.xl))),
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

  Widget _seg<T>(String label, T value, T group, void Function(T) on) => ChoiceChip(label: Text(label), selected: value == group, onSelected: (_) => setState(() => on(value)));

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    final days = fa ? ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'] : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ListView(padding: const EdgeInsets.all(RpSpace.s4), shrinkWrap: true, children: [
        Text(widget.editingId == null ? (fa ? 'عادت جدید' : 'New Habit') : (fa ? 'ویرایش عادت' : 'Edit Habit'), style: rpText(RpType.title, weight: 800, color: p.text)),
        const SizedBox(height: RpSpace.s3),
        TextField(controller: name, decoration: InputDecoration(labelText: fa ? 'نام عادت' : 'Habit name'), onChanged: (v) => f.name = v),
        const SizedBox(height: RpSpace.s3),
        Text(fa ? 'نوع' : 'Type', style: rpText(RpType.label, weight: 700, color: p.muted)),
        Wrap(spacing: 8, children: [
          _seg(fa ? 'انجام/نشد' : 'Yes/No', 'binary', f.type, (v) => f.type = v),
          _seg(fa ? 'عددی' : 'Number', 'numeric', f.type, (v) => f.type = v),
          _seg(fa ? 'زمانی' : 'Timer', 'timer', f.type, (v) => f.type = v),
        ]),
        if (f.type == 'numeric') ...[
          TextFormField(initialValue: '${f.numericTarget}', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: fa ? 'هدف' : 'Target'), onChanged: (v) => f.numericTarget = double.tryParse(v) ?? 1),
          TextField(controller: unit, decoration: InputDecoration(labelText: fa ? 'واحد' : 'Unit'), onChanged: (v) => f.numericUnit = v),
        ],
        if (f.type == 'timer')
          TextFormField(initialValue: '${f.timerTarget}', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: fa ? 'هدف (دقیقه)' : 'Target (min)'), onChanged: (v) => f.timerTarget = double.tryParse(v) ?? 30),
        if (f.type != 'binary') ...[
          const SizedBox(height: RpSpace.s2),
          Wrap(spacing: 8, children: [
            _seg(fa ? 'بیشتر بهتر' : 'More is better', 'more', f.direction, (v) => f.direction = v),
            _seg(fa ? 'کمتر بهتر' : 'Less is better', 'less', f.direction, (v) => f.direction = v),
          ]),
        ],
        const SizedBox(height: RpSpace.s3),
        Text(fa ? 'اولویت' : 'Priority', style: rpText(RpType.label, weight: 700, color: p.muted)),
        Wrap(spacing: 8, children: [
          for (final pr in const [('gold', '🥇'), ('green', '🟢'), ('yellow', '🟡'), ('red', '🔴')]) _seg(pr.$2, pr.$1, f.priority, (v) => f.priority = v),
        ]),
        const SizedBox(height: RpSpace.s3),
        Text(fa ? 'برنامه' : 'Schedule', style: rpText(RpType.label, weight: 700, color: p.muted)),
        Wrap(spacing: 8, children: [
          _seg(fa ? 'هر روز' : 'Daily', 'daily', f.scheduleMode, (v) => f.scheduleMode = v),
          _seg(fa ? 'روزهای خاص' : 'Custom days', 'custom', f.scheduleMode, (v) => f.scheduleMode = v),
        ]),
        if (f.scheduleMode == 'custom')
          Wrap(spacing: 6, children: [
            for (int d = 0; d < 7; d++)
              FilterChip(
                label: Text(days[d]),
                selected: f.activeDays.contains(d),
                onSelected: (s) => setState(() => s ? f.activeDays.add(d) : f.activeDays.remove(d)),
              ),
          ]),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(fa ? 'دائمی' : 'Permanent'), value: f.permanent, onChanged: (v) => setState(() => f.permanent = v)),
        if (!f.permanent)
          TextFormField(initialValue: '${f.durationDays}', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: fa ? 'تعداد روز' : 'Days'), onChanged: (v) => f.durationDays = int.tryParse(v) ?? 1),
        TextFormField(initialValue: '${f.rewardPoints}', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: fa ? 'امتیاز پاداش (حداکثر ۵۰)' : 'Reward points (max 50)'), onChanged: (v) => f.rewardPoints = int.tryParse(v) ?? 10),
        TextFormField(initialValue: f.weeklyGoal?.toString() ?? '', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: fa ? 'هدف هفتگی (اختیاری)' : 'Weekly goal (optional)'), onChanged: (v) => f.weeklyGoal = int.tryParse(v.trim())),
        TextFormField(initialValue: f.rewardText, decoration: InputDecoration(labelText: fa ? 'پاداش' : 'Reward'), onChanged: (v) => f.rewardText = v),
        TextFormField(initialValue: f.punishmentText, decoration: InputDecoration(labelText: fa ? 'تنبیه' : 'Punishment'), onChanged: (v) => f.punishmentText = v),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(fa ? 'یادآوری روزانه' : 'Daily reminder'), value: f.reminderEnabled, onChanged: (v) => setState(() => f.reminderEnabled = v)),
        if (f.reminderEnabled)
          TextFormField(initialValue: f.reminderTime, decoration: const InputDecoration(labelText: 'HH:MM'), onChanged: (v) => f.reminderTime = v),
        const SizedBox(height: RpSpace.s4),
        Row(children: [
          Expanded(child: RpButton(fa ? 'انصراف' : 'Cancel', kind: BtnKind.ghost, onTap: () => Navigator.pop(context))),
          const SizedBox(width: RpSpace.s3),
          Expanded(
            child: RpButton(fa ? 'ذخیره' : 'Save',
              onTap: () {
                if (widget.actions.saveHabit(f, editingId: widget.editingId) != null) Navigator.pop(context);
              },
            ),
          ),
        ]),
      ]),
    );
  }
}

/// یادداشتِ متنی + عکس‌های هر عادت (habitNotes مثل HTML: متنِ خالی ← حذفِ کلید)
void _notesSheet(BuildContext context, Map habit) {
  final store = context.read<AppStore>();
  final id = habit['id'] as String;
  final notes = store.state['habitNotes'] is Map ? store.state['habitNotes'] as Map : (store.state['habitNotes'] = <String, dynamic>{}) as Map;
  final c = TextEditingController(text: '${notes[id] ?? ''}');
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.rp.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RpRadius.xl))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(RpSpace.s4), children: [
        Text('${habit['name']}', style: rpText(RpType.title, weight: 800, color: ctx.rp.text)),
        const SizedBox(height: RpSpace.s3),
        TextField(controller: c, maxLines: 5, decoration: InputDecoration(labelText: ctx.tr('یادداشت', 'Notes'))),
        const SizedBox(height: RpSpace.s3),
        PhotoStrip(kind: PhotoKind.habit, ownerId: id),
        const SizedBox(height: RpSpace.s4),
        RpButton(ctx.tr('ذخیره', 'Save'), onTap: () {
          final v = c.text;
          if (v.trim().isNotEmpty) {
            notes[id] = v;
          } else {
            notes.remove(id);
          }
          store.save();
          Navigator.pop(ctx);
        }),
      ]),
    ),
  );
}
