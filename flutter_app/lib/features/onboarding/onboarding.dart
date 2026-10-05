// اولین اجرا: ۱) زبان ۲) قوانین ۳) آموزش اولیه ۴) ساخت آواتار — همان ترتیب و متن‌های نسخه‌ی HTML
// (متن‌ها عیناً با tool/extract_texts.js از www/index.html استخراج شده‌اند).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../core/calendar.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';

class AppTexts {
  final Map raw;
  AppTexts(this.raw);
  static Future<AppTexts> load() async => AppTexts(jsonDecode(await rootBundle.loadString('assets/texts.json')) as Map);
  List<Map> get onboarding => (raw['onboarding'] as List).cast<Map>();
  List<Map> get terms => (raw['terms'] as List).cast<Map>();
  Map get help => raw['help'] as Map;
  Object? get termsVersion => raw['termsVersion'];
  int get onboardingVersion => (raw['onboardingVersion'] as num).toInt();
}

bool needsLang(Map st) => st['langChosen'] != true;
bool needsTerms(Map st, AppTexts t) => st['termsAcceptedVersion'] != t.termsVersion;
bool needsOnboarding(Map st, AppTexts t) => st['onboardingDone'] != true || ((st['onboardingVersion'] as num?) ?? 1) < t.onboardingVersion;

/// اجرای زنجیره‌ی اولین بار (و هر بار که قوانین/آموزش نسخه‌ی تازه‌ای شد)
Future<void> runFirstRunFlow(BuildContext context, AppTexts texts) async {
  final store = context.read<AppStore>();
  Future<void> dlg(Widget w) => showDialog<void>(context: context, barrierDismissible: false, useRootNavigator: true, builder: (_) => PopScope(canPop: false, child: w));
  if (needsLang(store.state)) {
    await dlg(const _LangPicker());
    if (!context.mounted) return;
  }
  if (needsTerms(store.state, texts)) {
    await showTerms(context, texts, viewOnly: false);
    if (!context.mounted) return;
  }
  if (needsOnboarding(store.state, texts)) {
    await showOnboarding(context, texts);
    if (!context.mounted) return;
  }
}

class _LangPicker extends StatelessWidget {
  const _LangPicker();
  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final p = context.rp;
    void pick(String l) {
      store.state['lang'] = l;
      store.state['langChosen'] = true;
      store.save();
      Navigator.pop(context);
    }

    return AlertDialog(
      backgroundColor: p.surface,
      title: const Column(children: [Text('🌐', style: TextStyle(fontSize: 40)), Text('فارسی یا English؟')]),
      content: const Text('Choose your language · زبان خود را انتخاب کنید', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(onPressed: () => pick('fa'), child: const Text('🌐 فارسی')),
        FilledButton(onPressed: () => pick('en'), child: const Text('🌐 English')),
      ],
    );
  }
}

Future<void> showTerms(BuildContext context, AppTexts t, {required bool viewOnly}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: viewOnly,
    builder: (_) => PopScope(canPop: viewOnly, child: _Terms(texts: t, viewOnly: viewOnly)),
  );
}

class _Terms extends StatefulWidget {
  final AppTexts texts;
  final bool viewOnly;
  const _Terms({required this.texts, required this.viewOnly});
  @override
  State<_Terms> createState() => _TermsState();
}

class _TermsState extends State<_Terms> {
  bool ok = false;
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    final store = context.read<AppStore>();
    return Dialog(
      backgroundColor: p.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .88),
        child: Padding(
          padding: const EdgeInsets.all(RpSpace.s4),
          child: Column(children: [
            const Text('📜', style: TextStyle(fontSize: 34)),
            Text(context.tr('قوانین و شرایط استفاده', 'Terms of Use'), style: rpText(RpType.title, weight: 800, color: p.text)),
            Text(context.tr('لطفاً پیش از استفاده از برنامه، موارد زیر را مطالعه کنید', 'Please review the following before using the app'), textAlign: TextAlign.center, style: rpText(RpType.label, weight: 500, color: p.muted)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(children: [
                for (int i = 0; i < widget.texts.terms.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${fa ? toPersianDigits(i + 1) : i + 1}. ${widget.texts.terms[i]['icon']} ${fa ? widget.texts.terms[i]['titleFa'] : widget.texts.terms[i]['titleEn']}', style: rpText(RpType.body, weight: 800, color: p.text)),
                      const SizedBox(height: 4),
                      Text('${fa ? widget.texts.terms[i]['bodyFa'] : widget.texts.terms[i]['bodyEn']}', style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.9)),
                    ]),
                  ),
              ]),
            ),
            if (!widget.viewOnly) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: ok,
                onChanged: (v) => setState(() => ok = v == true),
                title: Text(context.tr('با استفاده از نرم‌افزار، قوانین و شرایط استفاده را می‌پذیرم.', 'By using this app, I accept the Terms of Use.'), style: rpText(RpType.label, weight: 600, color: p.text)),
              ),
              RpButton(context.tr('قوانین را می‌پذیرم', 'I accept the terms'), onTap: ok
                  ? () {
                      store.state['termsAcceptedVersion'] = widget.texts.termsVersion;
                      store.state['termsAcceptedAt'] = DateTime.now().millisecondsSinceEpoch;
                      store.save();
                      Navigator.pop(context);
                    }
                  : null),
            ] else
              RpButton(context.tr('بستن', 'Close'), kind: BtnKind.tonal, onTap: () => Navigator.pop(context)),
          ]),
        ),
      ),
    );
  }
}

Future<void> showOnboarding(BuildContext context, AppTexts t) =>
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => PopScope(canPop: false, child: _Onboarding(texts: t)));

class _Onboarding extends StatefulWidget {
  final AppTexts texts;
  const _Onboarding({required this.texts});
  @override
  State<_Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<_Onboarding> {
  int step = 0;
  void _close() {
    final s = context.read<AppStore>();
    s.state['onboardingDone'] = true;
    s.state['onboardingVersion'] = widget.texts.onboardingVersion;
    s.save();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    final slides = widget.texts.onboarding;
    final sl = slides[step];
    final last = step == slides.length - 1;
    return Dialog(
      backgroundColor: p.surface,
      child: Padding(
        padding: const EdgeInsets.all(RpSpace.s5),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 4, children: [for (int i = 0; i < slides.length; i++) Container(width: i == step ? 18 : 6, height: 6, decoration: BoxDecoration(color: i == step ? p.primary : p.line, borderRadius: BorderRadius.circular(3)))]),
          const SizedBox(height: RpSpace.s4),
          Flexible(
            child: SingleChildScrollView(
              child: Column(children: [
                Text('${sl['icon']}', style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                Text('${fa ? sl['titleFa'] : sl['titleEn']}', style: rpText(RpType.title, weight: 800, color: p.text)),
                const SizedBox(height: 8),
                Text('${fa ? sl['textFa'] : sl['textEn']}', textAlign: TextAlign.center, style: rpText(RpType.body, weight: 500, color: p.muted, height: 1.9)),
              ]),
            ),
          ),
          const SizedBox(height: RpSpace.s4),
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 4, spacing: 8, children: [
            TextButton(onPressed: _close, child: Text(context.tr('رد شدن', 'Skip'))),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
              TextButton(onPressed: step == 0 ? null : () => setState(() => step--), child: Text(context.tr('قبلی', 'Back'))),
              FilledButton(onPressed: () => last ? _close() : setState(() => step++), child: Text(last ? context.tr('شروع کن', 'Get started') : context.tr('بعدی', 'Next'))),
            ]),
          ]),
        ]),
      ),
    );
  }
}

/// دکمه‌ی ❓ کنار صفحه‌ها (pomodoro | habits | challenge | calendar | progress)
Future<void> showHelp(BuildContext context, AppTexts t, String key) {
  final h = t.help[key] as Map?;
  if (h == null) return Future.value();
  final fa = context.isFa;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Column(children: [Text('${h['icon']}', style: const TextStyle(fontSize: 36)), Text('${fa ? h['titleFa'] : h['titleEn']}')]),
      content: SingleChildScrollView(child: Text('${fa ? h['textFa'] : h['textEn']}', style: rpText(RpType.body, weight: 500, color: ctx.rp.text, height: 1.9))),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('باشه', 'OK')))],
    ),
  );
}

class HelpButton extends StatelessWidget {
  final String helpKey;
  const HelpButton(this.helpKey, {super.key});
  @override
  Widget build(BuildContext context) {
    final t = context.read<AppTexts?>();
    if (t == null) return const SizedBox.shrink();
    return IconButton(tooltip: context.tr('راهنما', 'Help'), icon: Icon(Icons.help_outline, color: context.rp.muted), onPressed: () => showHelp(context, t, helpKey));
  }
}
