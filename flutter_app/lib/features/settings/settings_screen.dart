// تنظیمات: تم (شدتِ روشن/تاریک)، رنگ‌ها، زبان، تقویم، اندازه‌ی فونت، پشتیبان.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../calendar/tile_style.dart';
import '../../app/i18n.dart';
import '../../data/app_store.dart';
import '../../data/files_service.dart';
import '../../ui/app_themes.dart';
import '../../ui/custom_theme.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../onboarding/onboarding.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final files = context.read<FilesService>();
    final p = context.rp;
    final st = store.state;
    final fa = context.isFa;
    void set(String k, Object? v) {
      st[k] = v;
      store.save();
    }

    Widget section(String title, Widget child, {String? hint}) => Padding(
          padding: const EdgeInsets.only(bottom: RpSpace.s3),
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: rpText(RpType.body, weight: 800, color: p.text)),
              const SizedBox(height: RpSpace.s2),
              child,
              if (hint != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(hint, style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.8))),
            ]),
          ),
        );

    final tc = (st['tileColors'] is Map ? st['tileColors'] as Map : const {});

    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Row(children: [Expanded(child: Text(context.tr('تنظیمات', 'Settings'), style: rpText(RpType.titleL, weight: 800, color: p.text))), const HelpButton('settings')]),
        const SizedBox(height: RpSpace.s3),
        section(
          context.tr('🎨 ظاهر و تم', '🎨 Appearance & Theme'),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('حالت', 'Mode'), style: rpText(RpType.label, weight: 500, color: p.muted)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final m in const [('light', 'روشن', 'Light'), ('dark', 'تاریک', 'Dark'), ('system', 'سیستم', 'System')])
                ChoiceChip(
                  key: ValueKey('mode-${m.$1}'),
                  label: Text(fa ? m.$2 : m.$3),
                  selected: themeMode(st) == m.$1,
                  onSelected: (_) {
                    st['theme'] = m.$1;
                    st['themeIntensity'] = m.$1 == 'dark' ? 100 : 0; // کلیدِ سازگار با بکاپ
                    store.save();
                  },
                ),
            ]),
            const SizedBox(height: RpSpace.s3),
            Text(context.tr('تم', 'Theme'), style: rpText(RpType.label, weight: 500, color: p.muted)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in appThemes) _ThemeCard(def: t, selected: themeById(st['accentTheme']).id == t.id, dark: context.rpBrightness == Brightness.dark, onTap: () => set('accentTheme', t.id)),
            ]),
          ]),
          hint: context.tr('تم و حالت مستقل‌اند: مثلاً «زمرد + تاریک». انتخاب در حافظه می‌ماند.', 'Theme and mode are independent, e.g. “Emerald + Dark”. Your choice is remembered.'),
        ),
        section(
          context.tr('شکل کاشی‌ها (۲۰+ شکل)', 'Tile Shapes (20+)'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in tileShapes) _ChoiceBtn(key: ValueKey('shape-${t.id}'), label: fa ? t.fa : t.en, active: (st['tileShape'] ?? 'round') == t.id, onTap: () => set('tileShape', t.id)),
          ]),
        ),
        section(
          context.tr('جلوه کاشی‌ها (۱۵+ جلوه)', 'Tile Effects (15+)'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in tileEffects) _ChoiceBtn(key: ValueKey('effect-${t.id}'), label: fa ? t.fa : t.en, active: (st['tileEffect'] ?? 'none') == t.id, onTap: () => set('tileEffect', t.id)),
          ]),
        ),
        section(
          context.tr('رنگ کاشی‌های روز در تقویم', 'Calendar day tile colors'),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SwatchRow(label: context.tr('روز موفق', 'Success day'), selected: tc['success'], options: const ['#3E9B4F', '#2F9E57', '#1E8E5A', '#2B7FB8', '#0E8FB0'], onPick: (h) => set('tileColors', {...tc, 'success': h})),
            _SwatchRow(label: context.tr('روز ناموفق', 'Failed day'), selected: tc['fail'], options: const ['#C0483B', '#D0455F', '#E65100', '#B03A5B', '#8E3B8E'], onPick: (h) => set('tileColors', {...tc, 'fail': h})),
            _SwatchRow(label: context.tr('روز ثبت‌نشده', 'Unset day'), selected: tc['neutral'], options: const ['#E5DBC8', '#DCDCDC', '#D5E2EC', '#EBD7DE', '#D8E4D8'], onPick: (h) => set('tileColors', {...tc, 'neutral': h})),
          ]),
          hint: context.tr('این رنگ‌ها روی کاشی‌های ماه/سال اعمال می‌شن؛ در حالت تاریک نسخه‌ی روشن‌ترشان استفاده می‌شود.', 'These colors apply to the month/year tiles; a lighter version is used in dark mode.'),
        ),
        section(
          context.tr('زبان', 'Language'),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('فارسی'), selected: st['lang'] != 'en', onSelected: (_) => set('lang', 'fa')),
            ChoiceChip(label: const Text('English'), selected: st['lang'] == 'en', onSelected: (_) => set('lang', 'en')),
          ]),
        ),
        section(
          context.tr('تقویم', 'Calendar'),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, children: [
              ChoiceChip(label: Text(context.tr('شنبه', 'Saturday')), selected: ((st['weekStart'] as num?) ?? 0) == 0, onSelected: (_) => set('weekStart', 0)),
              ChoiceChip(label: Text(context.tr('یکشنبه', 'Sunday')), selected: ((st['weekStart'] as num?) ?? 0) == 1, onSelected: (_) => set('weekStart', 1)),
            ]),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr('نمایش روزهای تعطیل', 'Show holidays')), value: st['showHolidays'] == true, onChanged: (v) => set('showHolidays', v)),
            Text(context.tr('نوع تقویم (پیش‌فرض: جلالی)', 'Calendar Type (default: Jalali)'), style: rpText(RpType.label, weight: 700, color: p.muted)),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: Text(context.tr('جلالی', 'Jalali')), selected: st['calendarType'] != 'gregorian', onSelected: (_) => set('calendarType', 'jalali')),
              ChoiceChip(label: Text(context.tr('میلادی', 'Gregorian')), selected: st['calendarType'] == 'gregorian', onSelected: (_) => set('calendarType', 'gregorian')),
            ]),
            Text(context.tr('همه‌ی تاریخ‌ها، انتخابگرهای تاریخ، یادآورها و گزارش‌ها از این تقویم پیروی می‌کنند.', 'All dates, date pickers, reminders and reports follow this calendar.'), style: rpText(RpType.caption, weight: 500, color: p.muted)),
          ]),
        ),
        section(
          context.tr('اندازه فونت', 'Font Size'),
          Wrap(spacing: 8, children: [
            for (final f in const [('small', 'کوچک', 'Small'), ('medium', 'متوسط', 'Medium'), ('large', 'بزرگ', 'Large')])
              ChoiceChip(label: Text(fa ? f.$2 : f.$3), selected: (st['fontSize'] ?? 'medium') == f.$1, onSelected: (_) => set('fontSize', f.$1)),
          ]),
        ),
        section(
          context.tr('راهنمای استفاده', 'How to use'),
          Column(children: [
            RpButton(context.tr('🎓 نمایش دوباره‌ی آموزش اولیه', '🎓 Show onboarding tutorial again'), kind: BtnKind.tonal, onTap: () {
              final t = context.read<AppTexts?>();
              if (t != null) showOnboarding(context, t);
            }),
            const SizedBox(height: 8),
            RpButton(context.tr('📜 قوانین و شرایط استفاده', '📜 Terms of Use'), kind: BtnKind.tonal, onTap: () {
              final t = context.read<AppTexts?>();
              if (t != null) showTerms(context, t, viewOnly: true);
            }),
            const SizedBox(height: 8),
            RpButton(context.tr('📦 مجوزهای متن‌باز', '📦 Open-source licenses'), kind: BtnKind.tonal, onTap: () => showLicensePage(context: context, applicationName: context.tr('روتین پلنر', 'Routine Planner'), applicationVersion: '${AppVersion.name} (${AppVersion.code})')),
          ]),
        ),
        section(
          context.tr('پشتیبان‌گیری', 'Backup'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            RpButton(context.tr('📥 خروجی گرفتن', '📥 Export'), small: true, onTap: files.exportBackup),
            RpButton(context.tr('📤 اشتراک‌گذاری', '📤 Share'), small: true, kind: BtnKind.tonal, onTap: files.shareBackup),
            RpButton(context.tr('📂 وارد کردن', '📂 Import'), small: true, kind: BtnKind.tonal, onTap: files.importBackup),
            RpButton(context.tr('📊 CSV', '📊 CSV'), small: true, kind: BtnKind.tonal, onTap: files.exportCsv),
            RpButton(context.tr('📄 PDF', '📄 PDF'), small: true, kind: BtnKind.tonal, onTap: files.exportPdf),
          ]),
          hint: context.tr('خروجی‌ها در پوشه Downloads ذخیره می‌شوند.', 'Exports are saved to Downloads.'),
        ),
        section(
          context.tr('تماس با ما', 'Contact Us'),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('برای ارتباط با توسعه‌دهنده:', 'To reach the developer:'), style: rpText(RpType.label, weight: 500, color: p.muted)),
            const SelectableText('manseyed2000@gmail.com', textDirection: TextDirection.ltr),
            const SizedBox(height: 6),
            Text('${context.tr('نسخه', 'Version')} ${AppVersion.name} (${AppVersion.code})', style: rpText(RpType.caption, weight: 500, color: p.muted)),
          ]),
        ),
      ],
    );
  }
}

class AppVersion {
  static const name = '2.6.3'; // باید با pubspec.yaml یکی باشد (تست می‌کند)
  static const code = 128;
}

/// ردیفِ رنگ‌های آماده (بدون انتخابگرِ آزادِ رنگ)
class _SwatchRow extends StatelessWidget {
  final String label;
  final Object? selected;
  final List<String> options;
  final void Function(String hex) onPick;
  const _SwatchRow({required this.label, required this.selected, required this.options, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final cur = '${selected ?? ''}'.toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: rpText(RpType.body, weight: 500, color: p.text)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final h in options)
            GestureDetector(
              key: ValueKey('sw-$label-$h'),
              onTap: () => onPick(h),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: parseHex(h), shape: BoxShape.circle, border: Border.all(color: cur == h.toUpperCase() ? p.text : p.line, width: cur == h.toUpperCase() ? 2.5 : 1)),
              ),
            ),
        ]),
      ]),
    );
  }
}

/// کارتِ تم: نام + ۵ نقطه‌ی رنگیِ همان تم (در حالتِ فعلی) + نشانِ انتخاب
class _ThemeCard extends StatelessWidget {
  final AppThemeDef def;
  final bool selected, dark;
  final VoidCallback onTap;
  const _ThemeCard({required this.def, required this.selected, required this.dark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final pal = def.of(dark);
    final fa = context.isFa;
    return GestureDetector(
      key: ValueKey('theme-${def.id}'),
      onTap: onTap,
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: pal.bg, borderRadius: BorderRadius.circular(RpRadius.md), border: Border.all(color: selected ? pal.primary : p.line, width: selected ? 2.5 : 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${def.emoji} ${fa ? def.fa : def.en}', style: rpText(RpType.body, weight: 600, color: pal.text, height: 1.3))),
            if (selected) Icon(Icons.check_circle_rounded, size: 18, color: pal.primary),
          ]),
          const SizedBox(height: 8),
          Row(children: [for (final c in [pal.primary, pal.secondary, pal.chart[2], pal.chart[3], pal.surface]) Container(width: 16, height: 16, margin: const EdgeInsetsDirectional.only(end: 5), decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: pal.line)))]),
          const SizedBox(height: 6),
          Text(context.tr('روشن / تاریک', 'Light / Dark'), style: rpText(RpType.caption, weight: 500, color: pal.muted, height: 1.2)),
        ]),
      ),
    );
  }
}


class _ChoiceBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChoiceBtn({super.key, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? p.primary : p.surface2,
          borderRadius: BorderRadius.circular(RpRadius.sm),
          border: Border.all(color: active ? p.primary : p.line),
        ),
        child: Text(label, style: rpText(RpType.label, weight: 700, color: active ? p.onPrimary : p.text)),
      ),
    );
  }
}
