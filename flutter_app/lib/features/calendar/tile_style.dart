import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// شکل و جلوه‌ی کاشی‌های روز (tileShape / tileEffect در HTML)
class TileShape {
  final String id, fa, en;
  const TileShape(this.id, this.fa, this.en);
}

const tileShapes = [
  TileShape('round', 'دایره', 'Circle'), TileShape('square', 'مربع', 'Square'), TileShape('hex', 'شش‌ضلعی', 'Hexagon'),
  TileShape('star', 'ستاره', 'Star'), TileShape('diamond', 'لوزی', 'Diamond'), TileShape('pentagon', 'پنج‌ضلعی', 'Pentagon'),
  TileShape('octagon', 'هشت‌ضلعی', 'Octagon'), TileShape('heart', 'قلب', 'Heart'), TileShape('flower', 'گل', 'Flower'),
  TileShape('shield', 'سپر', 'Shield'), TileShape('drop', 'قطره', 'Drop'), TileShape('ribbon', 'نوار', 'Ribbon'),
  TileShape('scallop', 'اسکالوپ', 'Scallop'), TileShape('bevel', 'پخ', 'Bevel'), TileShape('squircle', 'مربع گرد', 'Squircle'),
  TileShape('tunnel', 'تونل', 'Tunnel'), TileShape('arc', 'قوس', 'Arc'), TileShape('pill', 'کپسول', 'Pill'), TileShape('blob', 'لکه', 'Blob'),
];

const tileEffects = [
  TileShape('none', 'بدون جلوه', 'None'), TileShape('glass', 'شیشه‌ای', 'Glass'), TileShape('frost', 'یخ‌زده', 'Frost'),
  TileShape('3d', 'سه‌بعدی', '3D'), TileShape('glow', 'درخشان', 'Glow'), TileShape('emboss', 'برجسته', 'Emboss'),
  TileShape('neon', 'نئون', 'Neon'), TileShape('shadow', 'سایه‌دار', 'Shadow'), TileShape('glossy', 'براق', 'Glossy'),
  TileShape('flat', 'تخت', 'Flat'), TileShape('minimal', 'مینیمال', 'Minimal'), TileShape('rainbow', 'رنگین‌کمان', 'Rainbow'),
  TileShape('matte', 'مات', 'Matte'), TileShape('metallic', 'فلزی', 'Metallic'),
];

const _polys = <String, List<double>>{
  'hex': [25, 0, 75, 0, 100, 50, 75, 100, 25, 100, 0, 50],
  'star': [50, 0, 61, 35, 98, 35, 68, 57, 79, 91, 50, 70, 21, 91, 32, 57, 2, 35, 39, 35],
  'diamond': [50, 0, 100, 50, 50, 100, 0, 50],
  'pentagon': [50, 0, 100, 38, 81, 100, 19, 100, 0, 38],
  'octagon': [30, 0, 70, 0, 100, 30, 100, 70, 70, 100, 30, 100, 0, 70, 0, 30],
  'flower': [50, 0, 61, 20, 85, 10, 75, 35, 100, 50, 75, 65, 85, 90, 61, 80, 50, 100, 39, 80, 15, 90, 25, 65, 0, 50, 25, 35, 15, 10, 39, 20],
  'shield': [50, 0, 100, 25, 100, 75, 50, 100, 0, 75, 0, 25],
  'drop': [50, 0, 100, 60, 75, 100, 25, 100, 0, 60],
  'ribbon': [0, 0, 70, 0, 100, 50, 70, 100, 0, 100, 30, 50],
};

bool isPolygonShape(String id) => _polys.containsKey(id) || id == 'heart';

/// شعاع‌های گوشه‌ها: [tl, tr, br, bl] به‌صورت (rx, ry) برحسب پیکسل
Path tilePath(String id, Size s) {
  final w = s.width, h = s.height;
  final r = Offset.zero & s;
  final poly = _polys[id];
  if (poly != null) {
    final p = Path()..moveTo(poly[0] / 100 * w, poly[1] / 100 * h);
    for (int i = 2; i < poly.length; i += 2) {
      p.lineTo(poly[i] / 100 * w, poly[i + 1] / 100 * h);
    }
    return p..close();
  }
  if (id == 'heart') {
    double x(double v) => v / 100 * w;
    double y(double v) => v / 100 * h;
    return Path()
      ..moveTo(x(50), y(90))
      ..cubicTo(x(22), y(68), x(4), y(45), x(4), y(25))
      ..cubicTo(x(4), y(10), x(16), y(0), x(30), y(0))
      ..cubicTo(x(40), y(0), x(47), y(6), x(50), y(15))
      ..cubicTo(x(53), y(6), x(60), y(0), x(70), y(0))
      ..cubicTo(x(84), y(0), x(96), y(10), x(96), y(25))
      ..cubicTo(x(96), y(45), x(78), y(68), x(50), y(90))
      ..close();
  }
  Radius rad(double rx, [double? ry]) => Radius.elliptical(rx, ry ?? rx);
  RRect rr(Radius tl, Radius tr, Radius br, Radius bl) => RRect.fromRectAndCorners(r, topLeft: tl, topRight: tr, bottomRight: br, bottomLeft: bl);
  final m = math.min(w, h);
  RRect q;
  switch (id) {
    case 'square':
      q = RRect.fromRectAndRadius(r, const Radius.circular(2));
    case 'scallop':
      q = rr(rad(math.min(30, m / 2)), rad(math.min(30, m / 2)), rad(10), rad(10));
    case 'bevel':
      q = rr(rad(4), rad(math.min(18, m / 2)), rad(4), rad(math.min(18, m / 2)));
    case 'squircle':
      q = RRect.fromRectAndRadius(r, Radius.elliptical(w * .3, h * .3));
    case 'tunnel':
      q = rr(rad(w / 2, h / 2), rad(w / 2, h / 2), Radius.zero, Radius.zero);
    case 'arc':
      q = rr(rad(w / 2, h / 2), Radius.zero, rad(w / 2, h / 2), Radius.zero);
    case 'pill':
      q = RRect.fromRectAndRadius(r, Radius.circular(m / 2));
    case 'blob':
      q = rr(Radius.elliptical(w * .4, h * .5), Radius.elliptical(w * .6, h * .4), Radius.elliptical(w * .3, h * .6), Radius.elliptical(w * .7, h * .5));
    default: // round
      q = RRect.fromRectAndRadius(r, Radius.elliptical(w / 2, h / 2));
  }
  return Path()..addRRect(q);
}

class TileStyle {
  final String shape, effect;
  final Color accent, primary, border;
  const TileStyle({this.shape = 'round', this.effect = 'none', this.accent = const Color(0xFFC79A2E), this.primary = const Color(0xFF2A8C82), this.border = const Color(0x22000000)});
  @override
  bool operator ==(Object other) => other is TileStyle && other.shape == shape && other.effect == effect && other.accent == accent && other.primary == primary && other.border == border;
  @override
  int get hashCode => Object.hash(shape, effect, accent, primary, border);

  bool get hasInner => effect != 'none';

  /// پیش از clip کشیده می‌شود (سایه‌های بیرونی؛ در HTML برای شکل‌های clip-path بریده می‌شوند)
  void paintOuter(Canvas c, Path path) {
    if (isPolygonShape(shape)) return;
    void sh(Color col, double blur, double dy, {double spread = 0}) {
      c.drawPath(path.shift(Offset(0, dy)), Paint()..color = col..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2));
    }

    switch (effect) {
      case 'glass':
        sh(const Color(0x2E1F2687), 32, 8);
      case 'frost':
        sh(const Color(0x1F000000), 32, 8);
      case '3d':
        sh(const Color(0x33000000), 24, 8);
      case 'glow':
        sh(accent, 24, 0);
        sh(const Color(0x26C79A2E), 48, 0);
      case 'emboss':
        sh(const Color(0x1A000000), 8, 4);
      case 'neon':
        sh(primary, 20, 0);
      case 'shadow':
        sh(const Color(0x2E000000), 28, 8);
      case 'metallic':
        sh(const Color(0x14000000), 12, 4);
      case 'matte':
        sh(const Color(0x0A000000), 8, 2);
      case 'minimal':
        sh(const Color(0x0A000000), 4, 1);
    }
  }

  /// پس از رنگ‌آمیزی داخل clip (روکش، لبه، سایه‌های درونی)
  void paintOverlay(Canvas c, Path path, Rect r) {
    Paint stroke(Color col, double w) => Paint()..style = PaintingStyle.stroke..strokeWidth = w..color = col;
    Paint grad(List<Color> cs, List<double> st) => Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, cs, st);
    switch (effect) {
      case 'glass':
        c.drawPath(path, stroke(const Color(0x59FFFFFF), 2));
      case 'frost':
        c.drawPath(path, stroke(const Color(0x33FFFFFF), 2));
      case 'glow':
        c.drawPath(path, stroke(accent, 2));
        c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 18..color = const Color(0x33C79A2E)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      case 'emboss':
        c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = const Color(0x59FFFFFF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        c.drawPath(path.shift(const Offset(0, -4)), Paint()..style = PaintingStyle.stroke..strokeWidth = 6..color = const Color(0x33000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      case 'neon':
        c.drawPath(path, stroke(primary, 2));
        c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 24..color = primary.withValues(alpha: .55)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      case 'glossy':
        c.drawPath(path, grad(const [Color(0x73FFFFFF), Color(0x05FFFFFF), Color(0x40FFFFFF)], const [0, .5, 1]));
      case 'flat':
        c.drawPath(path, stroke(border, 4));
      case 'minimal' || 'matte' || 'metallic':
        c.drawPath(path, stroke(border, 2));
        if (effect == 'metallic') c.drawPath(path.shift(const Offset(0, 1)), stroke(const Color(0x80FFFFFF), 1));
      case 'rainbow':
        c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..shader = ui.Gradient.sweep(r.center, const [Color(0xFFFF0000), Color(0xFFFF8800), Color(0xFFFFFF00), Color(0xFF00FF00), Color(0xFF0088FF), Color(0xFF8800FF), Color(0xFFFF0000)], const [0, .17, .33, .5, .67, .83, 1]),
        );
    }
  }

  /// مربع/شکلِ داخلیِ ۷۰٪ (.inner)
  void paintInner(Canvas c, Path innerPath, Rect ir, bool dark) {
    Color? fill;
    switch (effect) {
      case 'glass': fill = const Color(0x2EFFFFFF);
      case 'frost': fill = const Color(0x14FFFFFF);
      case '3d': fill = const Color(0x1FFFFFFF);
      case 'glow' || 'emboss' || 'shadow' || 'matte' || 'flat': fill = const Color(0x14FFFFFF);
      case 'neon': fill = const Color(0x26000000);
      case 'rainbow': fill = dark ? const Color(0x73000000) : const Color(0x40000000);
    }
    if (fill != null) c.drawPath(innerPath, Paint()..color = fill);
    if (effect == 'glossy' || effect == 'metallic') {
      c.drawPath(innerPath, Paint()..shader = ui.Gradient.linear(ir.topLeft, ir.bottomRight, effect == 'glossy' ? const [Color(0x4DFFFFFF), Color(0x05FFFFFF), Color(0x26FFFFFF)] : const [Color(0x33FFFFFF), Color(0x0DFFFFFF)], effect == 'glossy' ? const [0, .5, 1] : null));
    }
    if (const {'flat', 'matte', 'metallic', 'glass', 'frost', 'neon'}.contains(effect)) {
      c.drawPath(innerPath, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = effect == 'neon' ? primary : (effect == 'glass' || effect == 'frost') ? const Color(0x33FFFFFF) : border);
    }
  }
}
