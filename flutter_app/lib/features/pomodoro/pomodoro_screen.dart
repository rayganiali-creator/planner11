// پومودورو: حلقه‌ی زمان، فازها، نقطه‌های دور، شروع/مکث/ریست/رد، زمان‌های دلخواه (پرو).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/pro_features.dart';
import '../../ui/pro_widgets.dart';
import '../../app/i18n.dart';
import '../../core/calendar.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../data/notifier.dart';
import '../../data/pomodoro_ops.dart';
import '../../ui/tokens.dart';
import '../onboarding/onboarding.dart';
import '../../ui/widgets.dart';

String pomoFmt(int ms, bool fa) {
  final t = (ms / 1000).ceil(), m = t ~/ 60, s = t % 60;
  final str = '${pad2(m)}:${pad2(s)}';
  return fa ? toPersianDigits(str) : str;
}

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final a = context.read<AppActions>();
      if (a.pomoTick()) SystemSound.play(SystemSoundType.alert);
      if (mounted) setState(() {});
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
    final a = context.read<AppActions>();
    final n = context.read<Notifier>();
    final p = context.rp;
    final fa = context.isFa;
    final st = a.pomoState();
    final phase = '${st['phase']}';
    final rem = a.pomoRemaining(), total = a.pomoDurationMs(phase);
    final running = st['running'] == true;
    final pro = a.store.state['isPremium'] == true;
    final done = (((st['cycle'] as num?) ?? 0).toInt()) % 4;
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Row(children: [Expanded(child: Text(context.tr('پومودورو', 'Pomodoro'), style: rpText(RpType.titleL, weight: 800, color: p.text))), HelpButton('pomodoro')]),
        const SizedBox(height: RpSpace.s4),
        Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
          for (final ph in const ['focus', 'short', 'long'])
            ChoiceChip(label: Text(pomoLabel[ph]![fa ? 0 : 1]), selected: phase == ph, onSelected: (_) => a.pomoSetPhase(ph, notifier: n)),
        ]),
        const SizedBox(height: RpSpace.s5),
        Center(
          child: RpRing(
            value: total == 0 ? 0 : (rem / total).clamp(0.0, 1.0).toDouble(),
            size: 240,
            color: phase == 'focus' ? p.primary : p.ok,
            center: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(pomoFmt(rem, fa), style: rpText(RpType.display, weight: 800, color: p.text).copyWith(fontSize: 48)),
              Text(pomoLabel[phase]![fa ? 0 : 1], style: rpText(RpType.body, weight: 600, color: p.muted)),
            ]),
          ),
        ),
        const SizedBox(height: RpSpace.s4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < 4; i++)
            Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: i < done ? p.primary : p.line)),
        ]),
        const SizedBox(height: RpSpace.s5),
        Row(children: [
          Expanded(child: RpButton(context.tr('ریست', 'Reset'), kind: BtnKind.ghost, icon: LucideIcons.rotateCcw, onTap: () => a.pomoSetPhase(phase, notifier: n))),
          const SizedBox(width: RpSpace.s3),
          Expanded(
            flex: 2,
            child: RpButton(
              running ? context.tr('⏸ مکث', '⏸ Pause') : (rem < total ? context.tr('▶ ادامه', '▶ Resume') : context.tr('▶ شروع', '▶ Start')),
              onTap: () => running ? a.pomoPause(notifier: n) : a.pomoStart(notifier: n),
            ),
          ),
          const SizedBox(width: RpSpace.s3),
          Expanded(child: RpButton(context.tr('رد', 'Skip'), kind: BtnKind.ghost, icon: LucideIcons.skipForward, onTap: () => a.pomoSkip(notifier: n))),
        ]),
        const SizedBox(height: RpSpace.s5),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('زمان‌ها (دقیقه)', 'Durations (min)'), style: rpText(RpType.body, weight: 800, color: p.text)),
            const SizedBox(height: RpSpace.s2),
            Row(children: [
              for (final k in const [('focus', 'تمرکز', 'Focus', 180), ('short', 'کوتاه', 'Short', 60), ('long', 'بلند', 'Long', 90)])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _MinField(
                      key: ValueKey('${k.$1}-${a.pomoMinutes(k.$1)}'),
                      label: fa ? k.$2 : k.$3,
                      value: pro ? a.pomoMinutes(k.$1) : pomoDefaults[k.$1]!,
                      enabled: pro,
                      onTapDisabled: () => showProBlocked(context, ProFeature.pomodoroCustom),
                      onChanged: (v) => a.pomoSetMinutes(k.$1, v, k.$4),
                    ),
                  ),
                ),
            ]),
            const ProNotice(ProFeature.pomodoroCustom),
          ]),
        ),
      ],
    );
  }
}

class _MinField extends StatelessWidget {
  final String label;
  final int value;
  final bool enabled;
  final VoidCallback onTapDisabled;
  final ValueChanged<int> onChanged;
  const _MinField({super.key, required this.label, required this.value, required this.enabled, required this.onTapDisabled, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = TextEditingController(text: '$value');
    return GestureDetector(
      onTap: enabled ? null : onTapDisabled,
      child: TextField(
        controller: c,
        enabled: enabled,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => onChanged(int.tryParse(v) ?? value),
        onTapOutside: (_) => onChanged(int.tryParse(c.text) ?? value),
      ),
    );
  }
}
