// نمودارهای کم‌حاشیه: میله‌ای (روند)، دایره‌ای (موفق/ناموفق)، میله‌ی افقی (مقایسه). بدون نمودار خطی.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

class RpBarChart extends StatelessWidget {
  final List<String> labels;
  final List<int?> values; // 0..100، null = بدون داده
  final Color color;
  final double height;
  final String semantics;
  const RpBarChart({super.key, required this.labels, required this.values, required this.color, this.height = 180, this.semantics = ''});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Semantics(
      label: semantics,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _BarPainter(labels, values, color, p.line, p.muted, p.primarySoft),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<String> labels;
  final List<int?> values;
  final Color bar, grid, text, empty;
  _BarPainter(this.labels, this.values, this.bar, this.grid, this.text, this.empty);

  @override
  void paint(Canvas c, Size s) {
    const left = 34.0, bottom = 22.0, top = 6.0;
    final w = s.width - left, h = s.height - bottom - top;
    final gp = Paint()..color = grid..strokeWidth = 1;
    for (final v in [0, 25, 50, 75, 100]) {
      final y = top + h * (1 - v / 100);
      c.drawLine(Offset(left, y), Offset(s.width, y), gp);
      _t(c, '$v%', Offset(0, y - 6), 10, text);
    }
    final n = values.length;
    if (n == 0) return;
    final slot = w / n;
    final bw = math.min(slot * .62, 26.0);
    final step = n > 14 ? (n / 7).ceil() : 1; // برچسب‌های ماه را ۷تا‌۷تا نشان بده
    for (int i = 0; i < n; i++) {
      final cx = left + slot * (i + .5);
      final v = values[i];
      if (v != null) {
        final bh = math.max(2.0, h * v / 100);
        c.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(cx - bw / 2, top + h - bh, bw, bh), topLeft: const Radius.circular(6), topRight: const Radius.circular(6)), Paint()..color = bar);
      } else {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - bw / 2, top + h - 3, bw, 3), const Radius.circular(2)), Paint()..color = empty);
      }
      if (i % step == 0 && i < labels.length) _t(c, labels[i], Offset(cx, s.height - 16), 10, text, center: true);
    }
  }

  void _t(Canvas c, String t, Offset o, double size, Color col, {bool center = false}) {
    final tp = TextPainter(text: TextSpan(text: t, style: rpText(size, weight: 500, color: col, height: 1)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, center ? Offset(o.dx - tp.width / 2, o.dy) : o);
  }

  @override
  bool shouldRepaint(_BarPainter o) => o.values != values || o.labels != labels || o.bar != bar || o.grid != grid;
}

class RpDonut extends StatelessWidget {
  final int success, fail;
  final Color okColor, badColor, emptyColor;
  final double size;
  final Widget? center;
  const RpDonut({super.key, required this.success, required this.fail, required this.okColor, required this.badColor, required this.emptyColor, this.size = 160, this.center});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _DonutPainter(success, fail, okColor, badColor, emptyColor), child: Center(child: center)),
      );
}

class _DonutPainter extends CustomPainter {
  final int ok, bad;
  final Color okC, badC, emptyC;
  _DonutPainter(this.ok, this.bad, this.okC, this.badC, this.emptyC);
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(14, 14, s.width - 28, s.height - 28);
    final sw = s.width * .13;
    Paint pt(Color col) => Paint()..style = PaintingStyle.stroke..strokeWidth = sw..color = col..strokeCap = StrokeCap.butt;
    final total = ok + bad;
    if (total == 0) {
      c.drawArc(r, 0, math.pi * 2, false, pt(emptyC));
      return;
    }
    var a = -math.pi / 2;
    final so = ok / total * math.pi * 2, sb = bad / total * math.pi * 2;
    if (ok > 0) c.drawArc(r, a, so, false, pt(okC));
    a += so;
    if (bad > 0) c.drawArc(r, a, sb, false, pt(badC));
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.ok != ok || o.bad != bad || o.okC != okC || o.badC != badC;
}

/// میله‌ی افقی برای مقایسه‌ی عادت‌ها (خوانا برای نام‌های بلند)
class RpHBar extends StatelessWidget {
  final String label;
  final int value; // 0..100
  final Color color;
  const RpHBar({super.key, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Semantics(
        label: '$label $value%',
        child: Row(children: [
          SizedBox(width: 92, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.label, weight: 600, color: p.text))),
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(6)),
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(widthFactor: (value / 100).clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)))),
            ),
          ),
          SizedBox(width: 40, child: Text('$value%', textAlign: TextAlign.end, style: rpText(RpType.label, weight: 800, color: p.text))),
        ]),
      ),
    );
  }
}
