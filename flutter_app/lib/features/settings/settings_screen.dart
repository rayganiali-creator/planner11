// تنظیمات: تم (شدتِ روشن/تاریک)، رنگ‌ها، زبان، تقویم، اندازه‌ی فونت، پشتیبان.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../calendar/tile_style.dart';
import '../../app/i18n.dart';
import '../../data/app_store.dart';
import '../../data/files_service.dart';
import '../../ui/custom_theme.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../onboarding/onboarding.dart';

const levelColors = ['#146B69', '#D4A017', '#2E7D32', '#1D5DAD', '#6C3FA6', '#C62828', '#E65100', '#B03A5B', '#00897B', '#F9A825'];

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

    final intensity = (intensityOf(st) * 100).round();
    final tc = (st['tileColors'] is Map ? st['tileColors'] as Map : const {});
    Color col(Object? v, Color f) => parseHex(v) ?? f;

    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Text(context.tr('تنظیمات', 'Settings'), style: rpText(RpType.titleL, weight: 800, color: p.text)),
        const SizedBox(height: RpSpace.s3),
        section(
          context.tr('🌗 روشن / تاریک', '🌗 Light / Dark'),
          Row(children: [
            Text(context.tr('روشن', 'Light'), style: rpText(RpType.label, weight: 600, color: p.muted)),
            Expanded(child: Slider(value: intensity.toDouble(), min: 0, max: 100, divisions: 100, onChanged: (v) => set('themeIntensity', v.round()))),
            Text(context.tr('تاریک', 'Dark'), style: rpText(RpType.label, weight: 600, color: p.muted)),
            SizedBox(width: 44, child: Text(context.n('$intensity${fa ? '٪' : '%'}'), textAlign: TextAlign.end, style: rpText(RpType.label, weight: 800, color: p.text))),
          ]),
          hint: context.tr('با این اسلایدر می‌توانی میزان روشن یا تاریک بودن پس‌زمینه را دقیقاً از صفر تا صد تنظیم کنی.', 'Use this slider to set exactly how light or dark the background is, from 0 to 100.'),
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
          context.tr('رنگ پس‌زمینه (طیف کامل)', 'Background (full spectrum)'),
          _ColorRow(label: context.tr('هر رنگی که دوست داری انتخاب کن', 'Pick any color you like'), color: col(st['bgColor'], p.bg), onPick: (c) => set('bgColor', toHex(c))),
          hint: context.tr('در حالت تاریک، نسخه‌ی تیره‌ی همین رنگ به‌طور خودکار ساخته می‌شود.', 'In dark mode, a dark version of this color is generated automatically.'),
        ),
        section(
          context.tr('رنگ اصلی (دکمه‌ها و متن‌های برجسته)', 'Accent Color'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in accents)
              GestureDetector(
                onTap: () => set('accentTheme', a.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [a.lightA, a.lightB]),
                    borderRadius: BorderRadius.circular(RpRadius.sm),
                    border: Border.all(color: st['accentTheme'] == a.id || (st['accentTheme'] == null && a.id == 'teal') ? p.text : Colors.transparent, width: 2),
                  ),
                  child: Text(fa ? a.fa : a.en, style: rpText(RpType.label, weight: 700, color: Colors.white)),
                ),
              ),
          ]),
        ),
        section(
          context.tr('رنگ کاشی‌های روز در تقویم (طیف کامل)', 'Calendar day tile colors (full spectrum)'),
          Column(children: [
            _ColorRow(label: context.tr('روز موفق', 'Success day'), color: col(tc['success'], const Color(0xFF3E9B4F)), onPick: (c) => set('tileColors', {...tc, 'success': toHex(c)})),
            _ColorRow(label: context.tr('روز ناموفق', 'Failed day'), color: col(tc['fail'], const Color(0xFFC0483B)), onPick: (c) => set('tileColors', {...tc, 'fail': toHex(c)})),
            _ColorRow(label: context.tr('روز ثبت‌نشده', 'Unset day'), color: col(tc['neutral'], const Color(0xFFE5DBC8)), onPick: (c) => set('tileColors', {...tc, 'neutral': toHex(c)})),
          ]),
          hint: context.tr('این رنگ‌ها روی کاشی‌های ماه/سال اعمال می‌شن؛ در حالت تاریک نسخه‌ی روشن‌ترشان استفاده می‌شود.', 'These colors apply to the month/year tiles; a lighter version is used in dark mode.'),
        ),
        section(
          context.tr('🎨 رنگ دایره‌های پیشرفت', '🎨 Level Circle Colors'),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final h in levelColors)
                GestureDetector(
                  onTap: () => set('levelReachedColor', h),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: parseHex(h), shape: BoxShape.circle, border: Border.all(color: (st['levelReachedColor'] ?? '#146B69').toString().toUpperCase() == h ? p.text : Colors.transparent, width: 3)),
                    child: (st['levelReachedColor'] ?? '#146B69').toString().toUpperCase() == h ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            _ColorRow(label: context.tr('رنگ استادی', 'Mastery Color'), color: col(st['masteryColor'], const Color(0xFFC79A2E)), onPick: (c) => set('masteryColor', toHex(c))),
          ]),
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
  static const name = '2.0.0';
  static const code = 100;
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onPick;
  const _ColorRow({required this.label, required this.color, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return InkWell(
      onTap: () async {
        final c = await showColorPicker(context, color);
        if (c != null) onPick(c);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: rpText(RpType.body, weight: 500, color: p.text))),
          Container(width: 44, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: p.line))),
        ]),
      ),
    );
  }
}

/// انتخابگرِ رنگِ طیف کامل (سه لغزنده‌ی رنگ‌مایه/اشباع/روشنایی)
Future<Color?> showColorPicker(BuildContext context, Color initial) {
  final h0 = hexToHsl(initial);
  double h = h0.h, s = h0.s, l = h0.l;
  return showDialog<Color>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final c = hslToColor(h, s, l);
      return AlertDialog(
        title: Text(toHex(c), textDirection: TextDirection.ltr),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(height: 48, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(12))),
          Slider(value: h.clamp(0, 360).toDouble(), min: 0, max: 360, onChanged: (v) => setS(() => h = v)),
          Slider(value: s.clamp(0, 100).toDouble(), min: 0, max: 100, onChanged: (v) => setS(() => s = v)),
          Slider(value: l.clamp(0, 100).toDouble(), min: 0, max: 100, onChanged: (v) => setS(() => l = v)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('انصراف', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c), child: Text(ctx.tr('انتخاب', 'Select'))),
        ],
      );
    }),
  );
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
