// خروجی PDF (buildPdfReportElement در HTML): گزارش با خود Flutter رسم می‌شود (شکل‌دهی درست حروف فارسی با Vazirmatn)،
// به تصویر درمی‌آید و صفحه‌به‌صفحه (A4) در PDF می‌نشیند — همان روشِ html2canvas + jsPDF.
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/calendar.dart';
import '../../core/doc.dart';
import '../../core/habits.dart';

const _teal = Color(0xFF146B69), _muted = Color(0xFF6B6680);

class PdfReport extends StatelessWidget {
  final Doc state;
  final DateTime today;
  const PdfReport({super.key, required this.state, required this.today});

  @override
  Widget build(BuildContext context) {
    final fa = state['lang'] != 'en';
    String num(Object n) => fa ? toPersianDigits(n) : '$n';
    final habits = ((state['habits'] as List?) ?? const []).whereType<Map<String, dynamic>>().toList();
    final todos = ((state['todos'] as List?) ?? const []).whereType<Map>().toList();
    final scores = (state['scores'] is Map ? state['scores'] as Map : const {});
    TextStyle ts(double size, {FontWeight w = FontWeight.w400, Color c = const Color(0xFF1D1A24)}) => TextStyle(fontFamily: 'Vazirmatn', fontSize: size, fontWeight: w, color: c, height: 1.7);
    final j = toJalaali(today.year, today.month, today.day);
    final dateTxt = fa ? toPersianDigits('${j.jy}/${j.jm}/${j.jd}') : dateToISO(today);

    Widget stat(String l, Object v) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF1F6F5), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [Text(num(v), style: ts(20, w: FontWeight.w800, c: _teal)), Text(l, style: ts(12, c: _muted))]),
          ),
        );

    final rows = <Widget>[];
    for (int idx = 0; idx < habits.length; idx++) {
      final h = habits[idx];
      int s = 0, f = 0;
      final cells = <Widget>[];
      for (int i = 29; i >= 0; i--) {
        final iso = dateToISO(addDays(today, -i));
        final r = habitAppliesOnISO(h, iso) ? habitSuccessOnISO(state, h, iso) : null;
        if (r == true) {
          s++;
        } else if (r == false) {
          f++;
        }
        cells.add(Container(width: 9, height: 9, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: r == true ? const Color(0xFF3FA35A) : r == false ? const Color(0xFFD9534F) : const Color(0xFFE4E0EA), borderRadius: BorderRadius.circular(2))));
      }
      final rate = (s + f) > 0 ? ((s * 100) / (s + f)).round() : 0;
      Widget cell(Widget w, int flex) => Expanded(flex: flex, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: w));
      rows.add(Container(
        color: idx.isOdd ? const Color(0xFFFAF9FC) : Colors.white,
        child: Row(children: [
          cell(Text('${h['name']}', style: ts(13, w: FontWeight.w700)), 4),
          cell(Text(num(s), style: ts(13)), 2),
          cell(Text(num(f), style: ts(13)), 2),
          cell(Text('${num(rate)}٪', style: ts(13, w: FontWeight.w800, c: _teal)), 2),
          cell(Directionality(textDirection: TextDirection.ltr, child: Wrap(runSpacing: 2, children: cells)), 6),
        ]),
      ));
    }

    return Directionality(
      textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: 794,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _teal, width: 3))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(fa ? 'گزارش روتین پلنر' : 'Routine Planner report', style: ts(24, w: FontWeight.w800, c: _teal)),
              Text(dateTxt, style: ts(14, c: _muted)),
            ]),
          ),
          if ('${state['profileName'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('${fa ? 'نام: ' : 'Name: '}${state['profileName']}', style: ts(14, w: FontWeight.w700))),
          Row(children: [
            stat(fa ? 'سکه‌ها' : 'Coins', scores['coins'] ?? 0),
            stat(fa ? 'سطح' : 'Level', scores['level'] ?? 0),
            stat(fa ? 'روزهای متوالی' : 'Streak', scores['streak'] ?? 0),
            stat(fa ? 'عادت‌ها' : 'Habits', habits.length),
          ]),
          const SizedBox(height: 20),
          Text(fa ? 'عملکرد عادت‌ها (۳۰ روز اخیر)' : 'Habits (last 30 days)', style: ts(17, w: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            color: _teal,
            child: Row(children: [
              for (final (t, fl) in [(fa ? 'عادت' : 'Habit', 4), (fa ? 'موفق' : 'Success', 2), (fa ? 'ناموفق' : 'Failed', 2), (fa ? 'درصد' : 'Rate', 2), (fa ? '۳۰ روز اخیر' : 'Last 30 days', 6)])
                Expanded(flex: fl, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7), child: Text(t, style: ts(13, w: FontWeight.w800, c: Colors.white)))),
            ]),
          ),
          if (habits.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(fa ? 'هنوز عادتی ثبت نشده.' : 'No habits yet.', style: ts(14, c: _muted))) else ...rows,
          if (todos.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(fa ? 'لیست کارها' : 'To-do', style: ts(17, w: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final t in todos.take(60))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                child: Text('${t['done'] == true ? '✅ ' : '⬜ '}${t['title']}', style: ts(14)),
              ),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: Text(fa ? 'ساخته‌شده با روتین پلنر' : 'Generated by Routine Planner', textAlign: TextAlign.center, style: ts(11, c: const Color(0xFF9A95AD)))),
        ]),
      ),
    );
  }
}

/// گزارش را روی overlay (خارج از صفحه) رسم، به PNG تبدیل و به PDF صفحه‌بندی می‌کند.
Future<Uint8List> buildPdfReport(Doc state, OverlayState overlay, {DateTime? today}) async {
  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -20000,
      top: 0,
      child: Material(
        color: Colors.white,
        child: Theme(
          data: ThemeData(fontFamily: 'Vazirmatn'),
          child: RepaintBoundary(key: key, child: PdfReport(state: state, today: today ?? startOfDay(DateTime.now()))),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 2);
    return await imageToPdf(img);
  } finally {
    entry.remove();
  }
}

/// تصویر بلند ← صفحه‌های A4 (برش بر اساس نسبت 210×297)
Future<Uint8List> imageToPdf(ui.Image img) async {
  final pageH = (img.width * 297 / 210).floor();
  final doc = pw.Document();
  for (int y = 0; y < img.height; y += pageH) {
    final h = (img.height - y) < pageH ? img.height - y : pageH;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(Rect.fromLTWH(0, 0, img.width.toDouble(), h.toDouble()), Paint()..color = Colors.white);
    c.drawImageRect(img, Rect.fromLTWH(0, y.toDouble(), img.width.toDouble(), h.toDouble()), Rect.fromLTWH(0, 0, img.width.toDouble(), h.toDouble()), Paint());
    final part = await rec.endRecording().toImage(img.width, h);
    final png = (await part.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    final mem = pw.MemoryImage(png);
    final hMm = h * 210 / img.width;
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(210 * PdfPageFormat.mm, 297 * PdfPageFormat.mm, marginAll: 0),
      build: (_) => pw.Align(alignment: pw.Alignment.topLeft, child: pw.Image(mem, width: 210 * PdfPageFormat.mm, height: hMm * PdfPageFormat.mm)),
    ));
  }
  return doc.save();
}
