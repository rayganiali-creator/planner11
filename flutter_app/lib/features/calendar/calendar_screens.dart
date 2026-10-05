// تقویم ماهانه و سالانه (شمسی/میلادی) + پنجره‌ی ثبتِ روز. همان چیدمان و رنگ‌بندیِ tileGradient نسخه‌ی HTML.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'tile_style.dart';
import '../../app/i18n.dart';
import '../../core/calendar.dart';
import '../../core/date_fmt.dart';
import '../../core/doc.dart';
import '../../core/habits.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../ui/custom_theme.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../onboarding/onboarding.dart';
import '../record_flow.dart';

const _faWdShort = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

Color _hex(Object? v, Color fallback) {
  if (v is String && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) return Color(int.parse('FF${v.substring(1)}', radix: 16));
  return fallback;
}

/// tileGradient: همه موفق/همه شکست/ بدون عادت = رنگِ ساده؛ وگرنه نمودارِ دایره‌ای (conic) از بالا ساعت‌گرد
class DayPie extends CustomPainter {
  final DayStats s;
  final Color ok, bad, neutral;
  final TileStyle style;
  DayPie(this.s, this.ok, this.bad, this.neutral, [this.style = const TileStyle()]);
  @override
  void paint(Canvas c, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = tilePath(style.shape, size);
    style.paintOuter(c, path);
    c.save();
    c.clipPath(path);
    if (s.total == 0) {
      c.drawRect(r, Paint()..color = neutral);
    } else if (s.success == s.total) {
      c.drawRect(r, Paint()..color = ok);
    } else if (s.fail == s.total) {
      c.drawRect(r, Paint()..color = bad);
    } else {
      c.drawRect(r, Paint()..color = neutral);
      double a = -math.pi / 2;
      final big = Rect.fromCircle(center: r.center, radius: size.longestSide);
      void seg(int n, Color col) {
        if (n <= 0) return;
        final sweep = n / s.total * 2 * math.pi;
        c.drawArc(big, a, sweep, true, Paint()..color = col);
        a += sweep;
      }

      seg(s.success, ok);
      seg(s.fail, bad);
    }
    if (style.hasInner) {
      final ir = r.deflate(size.shortestSide * .15);
      final ip = tilePath(style.shape, ir.size).shift(ir.topLeft);
      style.paintInner(c, ip, ir, false);
    }
    style.paintOverlay(c, path, r);
    c.restore();
  }

  @override
  bool shouldRepaint(DayPie o) => o.s != s || o.ok != ok || o.bad != bad || o.neutral != neutral || o.style != style;
}

TileStyle tileStyleOf(Doc st, RpPalette p) => TileStyle(
      shape: (st['tileShape'] as String?) ?? 'round',
      effect: (st['tileEffect'] as String?) ?? 'none',
      accent: p.gold,
      primary: p.primary,
      border: p.line,
    );

class _Colors {
  final Color ok, bad, neutral;
  _Colors(Doc st, RpPalette p)
      : ok = tileColor(_hex((st['tileColors'] as Map?)?['success'], p.ok), st['theme'] == 'dark'),
        bad = tileColor(_hex((st['tileColors'] as Map?)?['fail'], p.bad), st['theme'] == 'dark'),
        neutral = tileColor(_hex((st['tileColors'] as Map?)?['neutral'], p.line), st['theme'] == 'dark');
}

({DateTime first, int len}) _monthInfo(bool jalali, int y, int m) {
  if (jalali) {
    final g = toGregorian(y, m, 1);
    return (first: DateTime(g.gy, g.gm, g.gd), len: jalaaliMonthLength(y, m));
  }
  return (first: DateTime(y, m, 1), len: DateTime(y, m + 1, 0).day);
}

DateTime _dayOf(bool jalali, int y, int m, int d) {
  if (jalali) {
    final g = toGregorian(y, m, d);
    return DateTime(g.gy, g.gm, g.gd);
  }
  return DateTime(y, m, d);
}

class MonthScreen extends StatefulWidget {
  const MonthScreen({super.key});
  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  int? y, m;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final actions = context.read<AppActions>();
    final p = context.rp;
    final st = store.state;
    final fa = context.isFa;
    final jalali = st['calendarType'] == 'jalali';
    final today = startOfDay(actions.today);
    if (y == null) {
      if (jalali) {
        final j = toJalaali(today.year, today.month, today.day);
        y = j.jy;
        m = j.jm;
      } else {
        y = today.year;
        m = today.month;
      }
    }
    final info = _monthInfo(jalali, y!, m!);
    final weekStart = (st['weekStart'] as num?)?.toInt() ?? 0;
    final off = (jsWeekdayToPersianIndex(jsWeekday(info.first)) - weekStart + 7) % 7;
    final label = jalali
        ? (fa ? persianMonths[m! - 1] : enMonths[toGregorian(y!, m!, 1).gm - 1])
        : (fa ? enMonths[m! - 1] : '${enMonths[m! - 1]} $y');
    final sub = jalali ? (fa ? toPersianDigits(y) : '$y') : '';
    final cols = _Colors(st, p);
    void move(int delta) => setState(() {
          m = m! + delta;
          if (m! > 12) {
            m = 1;
            y = y! + 1;
          } else if (m! < 1) {
            m = 12;
            y = y! - 1;
          }
        });
    final wds = fa ? _faWdShort : enWeekdaysShort;
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        const Align(alignment: AlignmentDirectional.centerEnd, child: HelpButton('calendar')),
        Row(children: [
          IconButton(onPressed: () => move(-1), icon: Icon(LucideIcons.chevronRight, color: p.text), tooltip: context.tr('ماه قبل', 'Previous')),
          Expanded(
            child: Column(children: [
              Text(label, style: rpText(RpType.titleL, weight: 800, color: p.text)),
              if (sub.isNotEmpty) Text(sub, style: rpText(RpType.label, weight: 500, color: p.muted)),
            ]),
          ),
          IconButton(onPressed: () => move(1), icon: Icon(LucideIcons.chevronLeft, color: p.text), tooltip: context.tr('ماه بعد', 'Next')),
        ]),
        const SizedBox(height: RpSpace.s3),
        AppCard(
          child: Column(children: [
            Row(children: [
              for (int i = 0; i < 7; i++) Expanded(child: Center(child: Text(wds[(i + weekStart) % 7], style: rpText(RpType.label, weight: 700, color: p.muted)))),
            ]),
            const SizedBox(height: RpSpace.s2),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (int i = 0; i < off; i++) const SizedBox.shrink(),
                for (int dn = 1; dn <= info.len; dn++) _Tile(date: _dayOf(jalali, y!, m!, dn), num: dn, today: today, cols: cols, st: st, fa: fa),
              ],
            ),
          ]),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final DateTime date;
  final int num;
  final DateTime today;
  final _Colors cols;
  final Doc st;
  final bool fa;
  const _Tile({required this.date, required this.num, required this.today, required this.cols, required this.st, required this.fa});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final iso = dateToISO(date);
    final stats = dayStats(st, iso);
    final isToday = date == today, future = date.isAfter(today);
    final holiday = st['showHolidays'] == true && date.weekday == DateTime.friday;
    return Semantics(
      button: true,
      label: iso,
      child: GestureDetector(
        key: ValueKey('day-$iso'),
        onTap: () => showDaySheet(context, date),
        child: Opacity(
          opacity: future ? .55 : 1,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(RpRadius.sm), border: isToday ? Border.all(color: p.primary, width: 2) : null),
            child: CustomPaint(
              painter: DayPie(stats, cols.ok, cols.bad, cols.neutral, tileStyleOf(st, p)),
              child: Center(
                child: Text(
                  fa ? toPersianDigits(num) : '$num',
                  style: rpText(RpType.label, weight: 700, color: holiday ? p.badInk : (stats.total > 0 && (stats.success == stats.total || stats.fail == stats.total) ? Colors.white : p.text)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class YearScreen extends StatefulWidget {
  const YearScreen({super.key});
  @override
  State<YearScreen> createState() => _YearScreenState();
}

class _YearScreenState extends State<YearScreen> {
  int? y;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final p = context.rp;
    final st = store.state;
    final fa = context.isFa;
    final jalali = st['calendarType'] == 'jalali';
    final today = startOfDay(context.read<AppActions>().today);
    y ??= jalali ? toJalaali(today.year, today.month, today.day).jy : today.year;
    final weekStart = (st['weekStart'] as num?)?.toInt() ?? 0;
    final cols = _Colors(st, p);
    final months = fa ? persianMonths : enMonths;
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        Row(children: [
          IconButton(onPressed: () => setState(() => y = y! - 1), icon: Icon(LucideIcons.chevronRight, color: p.text)),
          Expanded(child: Center(child: Text(fa ? toPersianDigits(y) : '$y', style: rpText(RpType.titleL, weight: 800, color: p.text)))),
          IconButton(onPressed: () => setState(() => y = y! + 1), icon: Icon(LucideIcons.chevronLeft, color: p.text)),
        ]),
        const SizedBox(height: RpSpace.s3),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth >= 720 ? 3 : 2;
          return Wrap(
            spacing: RpSpace.s3,
            runSpacing: RpSpace.s3,
            children: [
              for (int mm = 1; mm <= 12; mm++)
                SizedBox(
                  width: (c.maxWidth - (w - 1) * RpSpace.s3) / w,
                  child: AppCard(
                    padding: const EdgeInsets.all(RpSpace.s3),
                    child: _MiniMonth(title: months[mm - 1], jalali: jalali, y: y!, m: mm, weekStart: weekStart, today: today, cols: cols, st: st, fa: fa),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final String title;
  final bool jalali, fa;
  final int y, m, weekStart;
  final DateTime today;
  final _Colors cols;
  final Doc st;
  const _MiniMonth({required this.title, required this.jalali, required this.y, required this.m, required this.weekStart, required this.today, required this.cols, required this.st, required this.fa});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final info = _monthInfo(jalali, y, m);
    final off = (jsWeekdayToPersianIndex(jsWeekday(info.first)) - weekStart + 7) % 7;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: rpText(RpType.body, weight: 800, color: p.text)),
      const SizedBox(height: 6),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: [
          for (int i = 0; i < off; i++) const SizedBox.shrink(),
          for (int dn = 1; dn <= info.len; dn++)
            Builder(builder: (_) {
              final d = _dayOf(jalali, y, m, dn);
              final stats = dayStats(st, dateToISO(d));
              return GestureDetector(
                key: ValueKey('day-${dateToISO(d)}'),
                onTap: () => showDaySheet(context, d),
                child: Opacity(
                  opacity: d.isAfter(today) ? .5 : 1,
                  child: CustomPaint(
                    painter: DayPie(stats, cols.ok, cols.bad, cols.neutral, tileStyleOf(st, p)),
                    child: Center(child: Text(fa ? toPersianDigits(dn) : '$dn', style: rpText(RpType.caption, weight: 600, color: st['showHolidays'] == true && d.weekday == DateTime.friday ? p.badInk : p.text).copyWith(fontSize: 9))),
                  ),
                ),
              );
            }),
        ],
      ),
    ]);
  }
}

// ---------------------------------------------------------------- پنجره‌ی ثبتِ روز
Future<void> showDaySheet(BuildContext context, DateTime d) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.rp.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RpRadius.xl))),
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: context.read<AppStore>()),
        Provider.value(value: context.read<AppActions>()),
      ],
      child: _DaySheet(date: d),
    ),
  );
}

class _DaySheet extends StatelessWidget {
  final DateTime date;
  const _DaySheet({required this.date});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final actions = context.read<AppActions>();
    final p = context.rp;
    final fa = context.isFa;
    final st = store.state;
    final iso = dateToISO(date);
    final future = date.isAfter(startOfDay(actions.today));
    final title = dateLabel(date, jalali: isJalali(st), fa: fa, weekday: true);
    final app = applicableHabitsForISO(st, iso);
    final rec = (st['records'] as Map?)?[iso] as Map? ?? const {};
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(RpSpace.s4),
      children: [
        Text(title, style: rpText(RpType.title, weight: 800, color: p.text)),
        const SizedBox(height: 4),
        Text(
          app.isEmpty ? context.tr('برای این روز عادتی فعال نیست.', 'No active habits.') : (future ? context.tr('این روز هنوز نرسیده.', 'Not yet.') : context.tr('نتیجه رو ثبت کن:', 'Record:')),
          style: rpText(RpType.body, weight: 500, color: p.muted),
        ),
        const SizedBox(height: RpSpace.s3),
        for (final h in app) _Row(habit: h, iso: iso, raw: rec[h['id']], future: future, actions: actions),
      ],
    );
  }
}

class _Row extends StatefulWidget {
  final Map habit;
  final String iso;
  final Object? raw;
  final bool future;
  final AppActions actions;
  const _Row({required this.habit, required this.iso, required this.raw, required this.future, required this.actions});
  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  late final TextEditingController c = TextEditingController(text: _val());
  String _val() {
    final r = widget.raw;
    final v = r is Map ? r['value'] : r;
    return v == null ? '' : '$v';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final h = widget.habit;
    final id = h['id'] as String;
    final raw = widget.raw;
    Widget btn(IconData icon, bool on, Color col, Color soft, VoidCallback t) => Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: GestureDetector(
            onTap: widget.future ? null : t,
            child: Container(width: 44, height: 44, decoration: BoxDecoration(color: on ? col : soft, borderRadius: BorderRadius.circular(RpRadius.sm)), child: Icon(icon, size: 20, color: on ? Colors.white : col)),
          ),
        );
    final Widget actions;
    if (h['type'] == 'binary') {
      actions = Row(mainAxisSize: MainAxisSize.min, children: [
        btn(LucideIcons.check, raw == 'success', p.okInk, p.okSoft, () => recordBinaryFlow(context, id, widget.iso, 'success', alreadyActive: raw == 'success')),
        btn(LucideIcons.x, raw == 'fail', p.badInk, p.badSoft, () => recordBinaryFlow(context, id, widget.iso, 'fail', alreadyActive: raw == 'fail')),
      ]);
    } else {
      actions = Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 80, child: TextField(controller: c, enabled: !widget.future, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(isDense: true))),
        btn(LucideIcons.check, false, p.okInk, p.okSoft, () {
          final v = double.tryParse(c.text.trim());
          recordValueFlow(context, id, widget.iso, v == null ? null : (v == v.roundToDouble() ? v.toInt() : v));
        }),
      ]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: RpSpace.s2),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: RpSpace.s4, vertical: RpSpace.s3),
        child: Row(children: [
          Expanded(child: Text('${h['name']}', style: rpText(RpType.body, weight: 700, color: p.text))),
          actions,
        ]),
      ),
    );
  }
}
