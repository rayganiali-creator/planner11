// ابزارهای رنگ (هگز/HSL/ترکیب) و رنگِ کاشی‌های تقویم. پالتِ برنامه اکنون از ui/app_themes.dart می‌آید
// (انتخابِ آزادِ رنگ حذف شد؛ فقط تم‌های آماده).
import 'dart:math' as math;
import 'dart:ui';



Color? parseHex(Object? v) {
  if (v is String && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) return Color(int.parse('FF${v.substring(1)}', radix: 16));
  return null;
}

String toHex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Color mix(Color a, Color b, double t) => Color.fromARGB(
      255,
      (a.r * 255 + (b.r - a.r) * 255 * t).round(),
      (a.g * 255 + (b.g - a.g) * 255 * t).round(),
      (a.b * 255 + (b.b - a.b) * 255 * t).round(),
    );

({double h, double s, double l}) hexToHsl(Color c) {
  final r = c.r, g = c.g, b = c.b;
  final mx = math.max(r, math.max(g, b)), mn = math.min(r, math.min(g, b));
  final l = (mx + mn) / 2;
  double h = 0, s = 0;
  if (mx != mn) {
    final d = mx - mn;
    s = l > .5 ? d / (2 - mx - mn) : d / (mx + mn);
    if (mx == r) {
      h = (g - b) / d + (g < b ? 6 : 0);
    } else if (mx == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    h /= 6;
  }
  return (h: h * 360, s: s * 100, l: l * 100);
}

Color hslToColor(double h, double s, double l) {
  final hh = h / 360, ss = s / 100, ll = l / 100;
  double hue(double p, double q, double t) {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  }

  double r, g, b;
  if (ss == 0) {
    r = g = b = ll;
  } else {
    final q = ll < .5 ? ll * (1 + ss) : ll + ss - ll * ss, p = 2 * ll - q;
    r = hue(p, q, hh + 1 / 3);
    g = hue(p, q, hh);
    b = hue(p, q, hh - 1 / 3);
  }
  return Color.fromARGB(255, (r * 255).round(), (g * 255).round(), (b * 255).round());
}

/// رنگِ کاشی‌ها: در تم تیره روشن‌تر می‌شود (deriveTileColor)
Color tileColor(Color c, bool dark) {
  if (!dark) return c;
  final h = hexToHsl(c);
  return hslToColor(h.h, math.min(h.s + 5, 100), math.min(h.l + 22, 72));
}
