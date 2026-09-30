// نمودارهای هر عادت: محرک، مشوق، علت موفقیت، علت شکست (دایره‌ای) + افزودن/حذف مورد.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../data/trigger_ops.dart';
import '../../ui/charts.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';

const _palette = [Color(0xFF1FA2A0), Color(0xFFF4B942), Color(0xFFEF6F6C), Color(0xFF7C6CF2), Color(0xFF3DA5F4), Color(0xFF43C59E), Color(0xFFF28CB1), Color(0xFF8D99AE)];

Future<void> showHabitCharts(BuildContext context, Map habit, {String type = 'trigger'}) {
  final store = context.read<AppStore>();
  final a = context.read<AppActions>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.rp.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RpRadius.xl))),
    builder: (_) => MultiProvider(providers: [ChangeNotifierProvider.value(value: store), Provider.value(value: a)], child: _Sheet(habit: habit, type: type)),
  );
}

class _Sheet extends StatefulWidget {
  final Map habit;
  final String type;
  const _Sheet({required this.habit, required this.type});
  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late String type = widget.type;
  final input = TextEditingController();
  bool get isReason => type == 'success' || type == 'fail';

  String label(BuildContext c, String t) => switch (t) {
        'incentive' => c.tr('مشوق', 'Incentive'),
        'success' => c.tr('علت موفقیت', 'Success reason'),
        'fail' => c.tr('علت شکست', 'Fail reason'),
        _ => c.tr('محرک', 'Trigger'),
      };

  @override
  Widget build(BuildContext context) {
    context.watch<AppStore>();
    final a = context.read<AppActions>();
    final p = context.rp;
    final hid = widget.habit['id'] as String;
    Map<String, int> freq(String t) => (t == 'success' || t == 'fail') ? a.reasonFreq(hid, t) : a.triggerFreq(hid, t);
    final cur = freq(type);
    final sorted = cur.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
    final colors = {'trigger': p.primary, 'incentive': p.gold, 'success': p.ok, 'fail': p.bad};
    Widget mini(String t) {
      final f = freq(t).entries.toList()..sort((x, y) => y.value.compareTo(x.value));
      final total = f.fold<int>(0, (s, x) => s + x.value);
      return Expanded(
        child: Column(children: [
          Text(label(context, t), style: rpText(RpType.caption, weight: 700, color: p.muted)),
          RpDonut(success: total, fail: 0, okColor: colors[t]!, badColor: p.bad, emptyColor: p.line, size: 84, center: Text(context.n(total), style: rpText(RpType.label, weight: 800, color: p.text))),
        ]),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ListView(padding: const EdgeInsets.all(RpSpace.s4), shrinkWrap: true, children: [
        Text('📊 ${context.tr('نمودارهای ', 'Charts for ')}${widget.habit['name']}', style: rpText(RpType.title, weight: 800, color: p.text)),
        const SizedBox(height: RpSpace.s3),
        Row(children: [mini('trigger'), mini('incentive'), mini('success'), mini('fail')]),
        const SizedBox(height: RpSpace.s3),
        Wrap(spacing: 8, children: [for (final t in const ['trigger', 'incentive', 'success', 'fail']) ChoiceChip(label: Text(label(context, t)), selected: type == t, onSelected: (_) => setState(() => type = t))]),
        const SizedBox(height: RpSpace.s2),
        Row(children: [
          Expanded(child: TextField(controller: input, decoration: InputDecoration(hintText: isReason ? (type == 'success' ? context.tr('مثلاً: برنامه‌ریزی خوب، انگیزه بالا...', 'e.g. good planning, high motivation...') : context.tr('مثلاً: کمبود وقت، خستگی، فراموشی...', 'e.g. lack of time, tiredness, forgot...')) : (type == 'incentive' ? context.tr('مثلاً: پاداش، استراحت، تشویق...', 'e.g. reward, break, encouragement...') : context.tr('مثلاً: بیدار شدن، استرس، نداشتن زمان...', 'e.g. waking up, stress, lack of time...'))))),
          const SizedBox(width: 8),
          RpButton(context.tr('افزودن', 'Add'), small: true, onTap: () {
            final t = input.text.trim();
            if (t.isEmpty) {
              a.toasts.show(context.tr('لطفاً متن را وارد کن', 'Please enter text'), ms: 2000);
              return;
            }
            if (isReason) {
              a.addManualReason(hid, type, t);
            } else {
              a.addTrigger(hid, t, type);
            }
            input.clear();
            a.toasts.show('✅ ${label(context, type)} ${context.tr('ثبت شد', 'saved')}', ms: 1500);
          }),
        ]),
        const SizedBox(height: RpSpace.s2),
        if (sorted.isEmpty) Text(context.tr('هیچ موردی ثبت نشده', 'No items recorded'), style: rpText(RpType.label, weight: 500, color: p.muted)),
        for (int i = 0; i < sorted.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.circle, size: 12, color: _palette[i % _palette.length]),
            title: Text(sorted[i].key, style: rpText(RpType.body, weight: 600, color: p.text)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(context.n(sorted[i].value), style: rpText(RpType.body, weight: 800, color: p.text)),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: p.badInk),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(title: Text(context.tr('حذف شود؟', 'Delete?')), actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.tr('انصراف', 'Cancel'))),
                      FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.tr('حذف', 'Delete'))),
                    ]),
                  );
                  if (ok != true) return;
                  if (isReason) {
                    a.deleteReasonFromHabit(hid, sorted[i].key, type);
                  } else {
                    for (final t in a.triggersFor(hid).where((t) => t['trigger'] == sorted[i].key && (t['type'] == 'incentive') == (type == 'incentive'))) {
                      a.removeTrigger(hid, '${t['id']}');
                    }
                  }
                },
              ),
            ]),
          ),
      ]),
    );
  }
}
