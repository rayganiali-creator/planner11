// «لحظه‌ی وسوسه»: پیشنهادهای تصادفی + مدیریتِ پیشنهادها (عمومی/مخصوص عادت).
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../data/urge_ops.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';

Future<void> showUrge(BuildContext context) {
  final store = context.read<AppStore>();
  final a = context.read<AppActions>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.rp.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RpRadius.xl))),
    builder: (_) => MultiProvider(providers: [ChangeNotifierProvider.value(value: store), Provider.value(value: a)], child: const _Urge()),
  );
}

class _Urge extends StatefulWidget {
  const _Urge();
  @override
  State<_Urge> createState() => _UrgeState();
}

class _UrgeState extends State<_Urge> {
  bool manage = false;
  late List<UrgeItem> shuffled = context.read<AppActions>().shuffledUrges();
  final text = TextEditingController();
  String scope = '';

  @override
  Widget build(BuildContext context) {
    context.watch<AppStore>();
    final a = context.read<AppActions>();
    final p = context.rp;
    final habits = (a.store.state['habits'] as List).cast<Map>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .9,
      maxChildSize: .95,
      builder: (ctx, sc) => ListView(controller: sc, padding: const EdgeInsets.all(RpSpace.s4), children: [
        Row(children: [
          if (manage) IconButton(icon: const Icon(LucideIcons.arrowRight), onPressed: () => setState(() {
                manage = false;
                shuffled = a.shuffledUrges();
              })),
          Expanded(child: Text(manage ? context.tr('مدیریت پیشنهادها', 'Manage suggestions') : context.tr('⚡ لحظه‌ی وسوسه', '⚡ Urge Moment'), style: rpText(RpType.title, weight: 800, color: p.text))),
          IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
        ]),
        if (!manage) ...[
          Text(context.tr('یکی از این کارها را همین الان انجام بده:', 'Do one of these right now:'), style: rpText(RpType.body, weight: 500, color: p.muted)),
          const SizedBox(height: RpSpace.s3),
          Row(children: [
            Expanded(child: RpButton(context.tr('🔀 پیشنهاد جدید', '🔀 Shuffle'), kind: BtnKind.tonal, onTap: () => setState(() => shuffled = a.shuffledUrges()))),
            const SizedBox(width: 8),
            Expanded(child: RpButton(context.tr('⚙️ مدیریت پیشنهادها', '⚙️ Manage'), kind: BtnKind.ghost, onTap: () => setState(() => manage = true))),
          ]),
          const SizedBox(height: RpSpace.s3),
          if (shuffled.isEmpty)
            Text(context.tr('موردی وجود نداره. از «مدیریت پیشنهادها» یکی اضافه کن.', 'No items yet. Add one from "Manage suggestions".'), textAlign: TextAlign.center, style: rpText(RpType.body, weight: 500, color: p.muted))
          else
            for (final s in shuffled)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(child: Row(children: [Text(s.emoji, style: const TextStyle(fontSize: 24)), const SizedBox(width: 12), Expanded(child: Text(s.text, style: rpText(RpType.body, weight: 600, color: p.text, height: 1.7)))])),
              ),
        ] else ...[
          TextField(controller: text, decoration: InputDecoration(labelText: context.tr('پیشنهاد جدید', 'New suggestion'))),
          DropdownButton<String>(
            isExpanded: true,
            value: scope,
            items: [
              DropdownMenuItem(value: '', child: Text(context.tr('🌐 عمومی (برای همه)', '🌐 General (for everyone)'))),
              for (final h in habits) DropdownMenuItem(value: h['id'] as String, child: Text('${h['name']}')),
            ],
            onChanged: (v) => setState(() => scope = v ?? ''),
          ),
          RpButton(context.tr('افزودن', 'Add'), icon: LucideIcons.plus, onTap: () {
            if (a.addUrge(text.text, scope)) setState(text.clear);
          }),
          const SizedBox(height: RpSpace.s3),
          for (final s in a.allUrgeSuggestions())
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(s.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(s.text, style: rpText(RpType.body, weight: 500, color: p.text)),
              subtitle: Text(s.scope, style: rpText(RpType.caption, weight: 600, color: p.muted)),
              trailing: IconButton(icon: Icon(LucideIcons.x, size: 18, color: p.badInk), onPressed: () {
                a.deleteUrge(s);
                setState(() {});
              }),
            ),
        ],
      ]),
    );
  }
}
