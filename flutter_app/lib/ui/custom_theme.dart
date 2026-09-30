// شخصی‌سازی رنگ‌ها (تنظیمات): شدتِ روشن/تاریک، رنگ پس‌زمینه، رنگ اصلی، رنگ کاشی‌ها.
// حساب‌ها همان deriveBgVars / deriveTileColor / mixHexColors نسخه‌ی HTML است.
import 'dart:math' as math;
import 'dart:ui';

import '../core/doc.dart';
import 'tokens.dart';

class Accent {
  final String id, fa, en;
  final Color lightA, lightB, lightSoft, darkA, darkB, darkSoft;
  const Accent(this.id, this.fa, this.en, this.lightA, this.lightB, this.lightSoft, this.darkA, this.darkB, this.darkSoft);
}

Color _c(int v) => Color(0xFF000000 | v);
final List<Accent> accents = [
  Accent('teal', 'فیروزه‌ای', 'Teal', _c(0x146B69), _c(0x1E8C89), _c(0xE4F1EF), _c(0x3BC2BA), _c(0x2FA69E), _c(0x173330)),
  Accent('blue', 'آبی', 'Blue', _c(0x1D5DAD), _c(0x2E76CC), _c(0xE3EEFB), _c(0x5B9BE0), _c(0x7DB4EA), _c(0x122438)),
  Accent('purple', 'بنفش', 'Purple', _c(0x6C3FA6), _c(0x8757C4), _c(0xEEE4F8), _c(0xB792E8), _c(0xC9A9F0), _c(0x241835)),
  Accent('rose', 'صورتی', 'Rose', _c(0xB03A5B), _c(0xCC4E71), _c(0xFAE3EA), _c(0xE783A0), _c(0xEF9CB4), _c(0x331A22)),
  Accent('amber', 'کهربایی', 'Amber', _c(0xB4791E), _c(0xD19233), _c(0xFAF0DD), _c(0xE6B15C), _c(0xEFC27C), _c(0x332711)),
  Accent('slate', 'خاکستری', 'Slate', _c(0x4A5A68), _c(0x617283), _c(0xE8ECEF), _c(0x9BB0C0), _c(0xAFC2D0), _c(0x20282E)),
];

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

double intensityOf(Doc st) {
  final v = st['themeIntensity'];
  final t = v is num ? v.toDouble() : (st['theme'] == 'dark' ? 100.0 : 0.0);
  return t.clamp(0, 100) / 100;
}

/// رنگِ کاشی‌ها: در تم تیره روشن‌تر می‌شود (deriveTileColor)
Color tileColor(Color c, bool dark) {
  if (!dark) return c;
  final h = hexToHsl(c);
  return hslToColor(h.h, math.min(h.s + 5, 100), math.min(h.l + 22, 72));
}

RpPalette paletteFromState(Doc st) {
  final dark = st['theme'] == 'dark';
  final t = intensityOf(st);
  final base = dark ? RpPalette.dark : RpPalette.light;
  final other = dark ? RpPalette.light : RpPalette.dark;
  // شدتِ روشن/تاریک: سطح‌ها و متن‌ها بین دو پالت مخلوط می‌شوند (t نسبت به «تاریک» است)
  final k = dark ? 1 - t : t; // سهمِ پالتِ مقابل
  final acc = accents.firstWhere((a) => a.id == st['accentTheme'], orElse: () => accents.first);
  final bgHex = parseHex(st['bgColor']) ?? RpPalette.light.bg;
  final hsl = hexToHsl(bgHex);
  final lightBg = bgHex;
  final darkBg = hslToColor(hsl.h, math.min(hsl.s * .55, 35), 9);
  final darkSurface = hslToColor(hsl.h, math.min(hsl.s * .5, 30), 14);
  final darkSurface2 = hslToColor(hsl.h, math.min(hsl.s * .5, 30), 12);
  final lightSurface2 = hslToColor(hsl.h, math.min(hsl.s * .7, 25), 97);
  final bg = mix(lightBg, darkBg, t);
  final surface = mix(const Color(0xFFFFFFFF), darkSurface, t);
  final surface2 = mix(lightSurface2, darkSurface2, t);
  Color m(Color a, Color b) => mix(a, b, k);
  return RpPalette(
    bg: bg,
    surface: surface,
    surface2: surface2,
    line: m(base.line, other.line),
    text: m(base.text, other.text),
    muted: m(base.muted, other.muted),
    primary: dark ? acc.darkA : acc.lightA,
    primary2: dark ? acc.darkB : acc.lightB,
    primarySoft: m(dark ? acc.darkSoft : acc.lightSoft, dark ? RpPalette.light.primarySoft : RpPalette.dark.primarySoft),
    gold: base.gold, goldSoft: base.goldSoft, xp: base.xp, xpSoft: base.xpSoft, hp: base.hp, hpSoft: base.hpSoft,
    ok: base.ok, okSoft: base.okSoft, bad: base.bad, badSoft: base.badSoft, blue: base.blue, blueSoft: base.blueSoft,
    goldInk: base.goldInk, xpInk: base.xpInk, hpInk: base.hpInk, okInk: base.okInk, badInk: base.badInk, blueInk: base.blueInk, fire: base.fire,
    onPrimary: _onColor(dark ? acc.darkA : acc.lightA, base.onPrimary), onOk: base.onOk, onGold: base.onGold,
    btnA: dark ? acc.darkA : acc.lightA, btnB: dark ? acc.darkB : acc.lightB,
    skyTop: base.skyTop, skyBottom: base.skyBottom, hillA: base.hillA, hillB: base.hillB, ground: base.ground,
  );
}

/// متنِ روی رنگِ اصلی: همان onPrimary پالت؛ اگر خوانایی کم بود (مثلاً کهربایی روشن) تیره‌ی پالت را می‌گیرد
Color _onColor(Color bg, Color preferred) {
  double ratio(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return ((la > lb ? la : lb) + .05) / ((la > lb ? lb : la) + .05);
  }

  if (ratio(preferred, bg) >= 4.5) return preferred;
  const darkInk = Color(0xFF231C14);
  return ratio(darkInk, bg) > ratio(const Color(0xFFFFFFFF), bg) ? darkInk : const Color(0xFFFFFFFF);
}
