// انتخابِ تاریخ: جلالی (پیش‌فرض) با انتخابگرِ اختصاصی، میلادی با انتخابگرِ Material. خروجی همیشه DateTime میلادی است.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../core/calendar.dart';
import '../../core/date_fmt.dart';
import '../../data/app_store.dart';
import '../../ui/tokens.dart';

Future<DateTime?> pickDate(BuildContext context, DateTime initial, {DateTime? first, DateTime? last}) {
  final jalali = isJalali(context.read<AppStore>().state);
  final f = first ?? DateTime(initial.year - 1), l = last ?? DateTime(initial.year + 5);
  if (!jalali) return showDatePicker(context: context, initialDate: initial, firstDate: f, lastDate: l);
  return showDialog<DateTime>(context: context, builder: (_) => JalaliDatePickerDialog(initial: initial, first: f, last: l));
}

class JalaliDatePickerDialog extends StatefulWidget {
  final DateTime initial, first, last;
  const JalaliDatePickerDialog({super.key, required this.initial, required this.first, required this.last});
  @override
  State<JalaliDatePickerDialog> createState() => _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<JalaliDatePickerDialog> {
  late int y, m;
  late DateTime sel = DateTime(widget.initial.year, widget.initial.month, widget.initial.day);

  @override
  void initState() {
    super.initState();
    final j = toJalaali(sel.year, sel.month, sel.day);
    y = j.jy;
    m = j.jm;
  }

  void _move(int dm) => setState(() {
        var mm = m + dm, yy = y;
        while (mm > 12) {
          mm -= 12;
          yy++;
        }
        while (mm < 1) {
          mm += 12;
          yy--;
        }
        y = yy;
        m = mm;
      });

  DateTime _day(int d) {
    final g = toGregorian(y, m, d);
    return DateTime(g.gy, g.gm, g.gd);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    final len = jaalaliLen(y, m);
    final offset = jsWeekdayToPersianIndex(jsWeekday(_day(1)));
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final first = DateTime(widget.first.year, widget.first.month, widget.first.day), last = DateTime(widget.last.year, widget.last.month, widget.last.day);
    final wds = fa ? persianWeekdaysShort : enWeekdaysShort;
    return Dialog(
      backgroundColor: p.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(RpSpace.s4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(children: [
                IconButton(key: const ValueKey('jp-prev-year'), tooltip: context.tr('سال قبل', 'Previous year'), onPressed: () => _move(-12), icon: const Icon(LucideIcons.chevronsLeft, size: 18)),
                IconButton(key: const ValueKey('jp-prev'), onPressed: () => _move(-1), icon: const Icon(LucideIcons.chevronLeft)),
                Expanded(
                  child: Text('${monthName(y, m, jalali: true, fa: fa)} ${fa ? toPersianDigits(y) : y}', textAlign: TextAlign.center, style: rpText(RpType.title, weight: 800, color: p.text)),
                ),
                IconButton(key: const ValueKey('jp-next'), onPressed: () => _move(1), icon: const Icon(LucideIcons.chevronRight)),
                IconButton(key: const ValueKey('jp-next-year'), tooltip: context.tr('سال بعد', 'Next year'), onPressed: () => _move(12), icon: const Icon(LucideIcons.chevronsRight, size: 18)),
              ]),
            ),
            const SizedBox(height: 4),
            Directionality(
              textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
              child: Column(children: [
                Row(children: [for (final w in wds) Expanded(child: Center(child: Text(w, style: rpText(RpType.caption, weight: 700, color: p.muted))))]),
                const SizedBox(height: 4),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  children: [
                    for (int i = 0; i < offset; i++) const SizedBox.shrink(),
                    for (int d = 1; d <= len; d++)
                      Builder(builder: (_) {
                        final dt = _day(d);
                        final disabled = dt.isBefore(first) || dt.isAfter(last);
                        final on = dt == sel, isToday = dt == t0;
                        return GestureDetector(
                          key: ValueKey('jd-$y-$m-$d'),
                          onTap: disabled ? null : () => setState(() => sel = dt),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: on ? p.primary : null,
                              border: isToday && !on ? Border.all(color: p.primary) : null,
                            ),
                            child: Text(fa ? toPersianDigits(d) : '$d', style: rpText(RpType.label, weight: on ? 800 : 600, color: disabled ? p.muted.withValues(alpha: .4) : (on ? p.onPrimary : p.text))),
                          ),
                        );
                      }),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: RpSpace.s3),
            Row(children: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('انصراف', 'Cancel'))),
              TextButton(
                onPressed: () {
                  final j = toJalaali(t0.year, t0.month, t0.day);
                  setState(() {
                    sel = t0;
                    y = j.jy;
                    m = j.jm;
                  });
                },
                child: Text(context.tr('امروز', 'Today')),
              ),
              const Spacer(),
              FilledButton(key: const ValueKey('jp-ok'), onPressed: () => Navigator.pop(context, sel), child: Text(context.tr('تأیید', 'OK'))),
            ]),
          ]),
        ),
      ),
    );
  }
}

int jaalaliLen(int y, int m) => jalaaliMonthLength(y, m);
