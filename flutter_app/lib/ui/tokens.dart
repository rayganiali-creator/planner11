// Design System — منبع واحدِ توکن‌ها (معادلِ بخش TOKENS در docs/flutter-migration/design-preview.html).
// هیچ صفحه‌ای رنگ/اندازه‌ی خام نمی‌نویسد؛ همه از اینجا می‌خوانند.
//
// قاعده‌ی خوانایی: هر متنی که روی زمینه‌ی کم‌رنگِ خودش می‌نشیند از «جوهر» (…Ink) استفاده می‌کند،
// نه از رنگ پرکننده. این را test/tokens_test.dart با فرمول WCAG اجرا و تضمین می‌کند.
import 'package:flutter/material.dart';

@immutable
class RpPalette {
  final Color bg, surface, surface2, line, text, muted;
  final Color primary, primary2, primarySoft;
  final Color gold, goldSoft, xp, xpSoft, hp, hpSoft, ok, okSoft, bad, badSoft, blue, blueSoft;
  final Color goldInk, xpInk, hpInk, okInk, badInk, blueInk, fire;
  final Color onPrimary, onOk, onGold, btnA, btnB;
  final Color skyTop, skyBottom, hillA, hillB, ground;
  final Color secondary;
  final List<Color> chart; // پالتِ نمودارها (Pie/Bar/Progress) مخصوصِ هر تم و حالت
  const RpPalette({
    required this.bg, required this.surface, required this.surface2, required this.line, required this.text, required this.muted,
    required this.primary, required this.primary2, required this.primarySoft,
    required this.gold, required this.goldSoft, required this.xp, required this.xpSoft, required this.hp, required this.hpSoft,
    required this.ok, required this.okSoft, required this.bad, required this.badSoft, required this.blue, required this.blueSoft,
    required this.goldInk, required this.xpInk, required this.hpInk, required this.okInk, required this.badInk, required this.blueInk,
    required this.fire, required this.onPrimary, required this.onOk, required this.onGold, required this.btnA, required this.btnB,
    required this.skyTop, required this.skyBottom, required this.hillA, required this.hillB, required this.ground,
    required this.secondary, required this.chart,
  });

  static const light = RpPalette(
    bg: Color(0xFFF5F1E8), surface: Color(0xFFFFFFFF), surface2: Color(0xFFFAF6EE), line: Color(0xFFE9E0CF),
    text: Color(0xFF231C14), muted: Color(0xFF786B58),
    primary: Color(0xFF136B68), primary2: Color(0xFF22958F), primarySoft: Color(0xFFE2F1EE),
    gold: Color(0xFFC99A2E), goldSoft: Color(0xFFF7EBCB), xp: Color(0xFF7357E8), xpSoft: Color(0xFFECE8FD),
    hp: Color(0xFFE0485A), hpSoft: Color(0xFFFBE3E6), ok: Color(0xFF2F9E57), okSoft: Color(0xFFDDF1E4),
    bad: Color(0xFFD04A3C), badSoft: Color(0xFFF8E1DD), blue: Color(0xFF2F7FD1), blueSoft: Color(0xFFE1EEFA),
    goldInk: Color(0xFF83651E), xpInk: Color(0xFF6A4CE7), hpInk: Color(0xFFC72235), okInk: Color(0xFF247842),
    badInk: Color(0xFFB7392C), blueInk: Color(0xFF276BB0), fire: Color(0xFFA9520A),
    onPrimary: Color(0xFFFFFFFF), onOk: Color(0xFFFFFFFF), onGold: Color(0xFF231C14), btnA: Color(0xFF0F5F5C), btnB: Color(0xFF1B7F79),
    skyTop: Color(0xFF6EC6E6), skyBottom: Color(0xFFE3F5F2), hillA: Color(0xFF2E9B8E), hillB: Color(0xFF1E7F78), ground: Color(0xFF176C66),
    secondary: Color(0xFF22958F), chart: [Color(0xFF136B68), Color(0xFF7357E8), Color(0xFFC99A2E), Color(0xFF2F7FD1), Color(0xFFD04A3C), Color(0xFF2F9E57)],
  );

  static const dark = RpPalette(
    bg: Color(0xFF0A1413), surface: Color(0xFF111E1D), surface2: Color(0xFF0E1918), line: Color(0xFF1E3330),
    text: Color(0xFFEEE8DB), muted: Color(0xFF8CA29D),
    primary: Color(0xFF3DC7BE), primary2: Color(0xFF2BA79F), primarySoft: Color(0xFF12302D),
    gold: Color(0xFFE6BF5C), goldSoft: Color(0xFF33290F), xp: Color(0xFF9C86FF), xpSoft: Color(0xFF221E45),
    hp: Color(0xFFFF6B7A), hpSoft: Color(0xFF3A1A20), ok: Color(0xFF4FBF72), okSoft: Color(0xFF14321F),
    bad: Color(0xFFF0806F), badSoft: Color(0xFF3A2220), blue: Color(0xFF5DA6F0), blueSoft: Color(0xFF15283C),
    goldInk: Color(0xFFE6BF5C), xpInk: Color(0xFF9C86FF), hpInk: Color(0xFFFF6B7A), okInk: Color(0xFF4FBF72),
    badInk: Color(0xFFF0806F), blueInk: Color(0xFF5DA6F0), fire: Color(0xFFF59A3C),
    onPrimary: Color(0xFF04201E), onOk: Color(0xFF06210F), onGold: Color(0xFF231C14), btnA: Color(0xFF3DC7BE), btnB: Color(0xFF2BA79F),
    skyTop: Color(0xFF0A1B36), skyBottom: Color(0xFF1B4A5E), hillA: Color(0xFF0F4A48), hillB: Color(0xFF0B3836), ground: Color(0xFF082C2A),
    secondary: Color(0xFF2BA79F), chart: [Color(0xFF3DC7BE), Color(0xFF9C86FF), Color(0xFFE6BF5C), Color(0xFF5DA6F0), Color(0xFFF0806F), Color(0xFF4FBF72)],
  );
}

/// نام‌های استانداردِ Design Token (نگاشت به فیلدهای پالت)
extension RpTokens on RpPalette {
  Color get background => bg;
  Color get backgroundSecondary => surface2;
  Color get surfaceElevated => surface;
  Color get surfacePressed => Color.alphaBlend(primary.withValues(alpha: .08), surface);
  Color get primaryHover => primary2;
  Color get primaryPressed => btnA;
  Color get accent => gold;
  Color get textPrimary => text;
  Color get textSecondary => Color.lerp(text, muted, .5)!;
  Color get textMuted => muted;
  Color get border => line;
  Color get divider => line;
  Color get success => ok;
  Color get warning => gold;
  Color get error => bad;
  Color get info => blue;
  Color get overlay => const Color(0x85060E0D);
  Color get shadow => const Color(0x33000000);
}

/// مقیاس تایپوگرافی: ۷ اندازه (نسخه‌ی قبلی ۲۳ اندازه‌ی پراکنده داشت).
class RpType {
  static const double display = 32, titleL = 22, title = 18, bodyL = 16, body = 14, label = 12, caption = 11;
}

/// شعاع گوشه: ۶ مقدار (قبلاً ۱۷ مقدار).
class RpRadius {
  static const double xs = 8, sm = 12, md = 16, lg = 20, xl = 28, pill = 999;
}

/// شبکه‌ی ۴.
class RpSpace {
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20, s6 = 24, s8 = 32;
}

class RpMotion {
  static const Duration fast = Duration(milliseconds: 120), base = Duration(milliseconds: 220), slow = Duration(milliseconds: 360);
  static const Curve ease = Cubic(.22, 1, .36, 1);
}

/// سایه‌ها (سه پله).
class RpShadow {
  static List<BoxShadow> e1(Brightness b) => [BoxShadow(color: b == Brightness.dark ? const Color(0x66000000) : const Color(0x0F231C14), blurRadius: 2, offset: const Offset(0, 1))];
  static List<BoxShadow> e2(Brightness b) => [BoxShadow(color: b == Brightness.dark ? const Color(0x59000000) : const Color(0x14231C14), blurRadius: 20, offset: const Offset(0, 6))];
  static List<BoxShadow> e3(Brightness b) => [BoxShadow(color: b == Brightness.dark ? const Color(0x99000000) : const Color(0x2E231C14), blurRadius: 44, offset: const Offset(0, 18))];
}

/// دسترسی به پالت از هر ویجت: `context.rp.primary`
@immutable
class RpTheme extends ThemeExtension<RpTheme> {
  final RpPalette p;
  final Brightness brightness;
  const RpTheme(this.p, this.brightness);
  @override
  RpTheme copyWith({RpPalette? p, Brightness? brightness}) => RpTheme(p ?? this.p, brightness ?? this.brightness);
  @override
  RpTheme lerp(ThemeExtension<RpTheme>? other, double t) => t < .5 ? this : (other as RpTheme);
}

extension RpContext on BuildContext {
  RpPalette get rp => Theme.of(this).extension<RpTheme>()!.p;
  Brightness get rpBrightness => Theme.of(this).extension<RpTheme>()!.brightness;
}

const String kFontFamily = 'Vazirmatn';
const List<String> kFontFallback = ['VazirmatnLatin'];

/// تایپوگرافیِ یکپارچه: متنِ معمولی (≤۱۴) همیشه Medium (۵۰۰)؛ ۱۶ تا سقف ۶۰۰؛ فقط تیترها (≥۱۸) وزنِ بالاتر می‌گیرند.
int rpEffectiveWeight(double size, int weight) => size >= RpType.title ? weight : (size >= RpType.bodyL ? (weight > 600 ? 600 : weight) : 500);

TextStyle rpText(double size, {int weight = 500, Color? color, double height = 1.6}) {
  final w = rpEffectiveWeight(size, weight);
  return TextStyle(
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFallback,
    fontSize: size,
    fontWeight: FontWeight.values[((w / 100).round().clamp(1, 9)) - 1],
    fontVariations: [FontVariation('wght', w.toDouble())], // فونت variable است (۱۰۰..۹۰۰)
    color: color,
    height: height,
  );
}

ThemeData buildRpTheme(Brightness b, {RpPalette? palette}) {
  final p = palette ?? (b == Brightness.dark ? RpPalette.dark : RpPalette.light);
  final scheme = ColorScheme(
    brightness: b, primary: p.primary, onPrimary: p.onPrimary, secondary: p.gold, onSecondary: p.onGold,
    error: p.bad, onError: p.onOk, surface: p.surface, onSurface: p.text,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFallback,
    splashFactory: InkRipple.splashFactory,
    extensions: [RpTheme(p, b)],
    // --- اجزای یکپارچه‌ی Design System (مودال‌ها، دکمه‌ها، ورودی‌ها، چیپ‌ها) ---
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RpRadius.lg)),
      titleTextStyle: rpText(RpType.bodyL, weight: 600, color: p.text, height: 1.4),
      contentTextStyle: rpText(RpType.body, weight: 500, color: p.text),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.surface,
      showDragHandle: true,
      dragHandleColor: p.line,
      dragHandleSize: const Size(40, 4),
      elevation: 8,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RpRadius.lg))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(RpRadius.sm), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(RpRadius.sm), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(RpRadius.sm), borderSide: BorderSide(color: p.primary, width: 1.5)),
      hintStyle: rpText(RpType.body, weight: 500, color: p.muted),
      labelStyle: rpText(RpType.body, weight: 500, color: p.muted),
      floatingLabelStyle: rpText(RpType.label, weight: 500, color: p.primary),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(0, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RpRadius.sm)), textStyle: rpText(RpType.body, weight: 500, height: 1.2))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42), side: BorderSide(color: p.line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RpRadius.sm)), textStyle: rpText(RpType.body, weight: 500, height: 1.2))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RpRadius.sm)), textStyle: rpText(RpType.body, weight: 500, height: 1.2))),
    chipTheme: ChipThemeData(
      labelStyle: rpText(RpType.label, weight: 500, color: p.text, height: 1.2),
      backgroundColor: p.surface2,
      selectedColor: p.primarySoft,
      side: BorderSide(color: p.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RpRadius.pill)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    dividerTheme: DividerThemeData(color: p.line, space: 1, thickness: 1),
    textTheme: TextTheme(
      displayLarge: rpText(RpType.display, weight: 700, color: p.text, height: 1.15),
      titleLarge: rpText(RpType.titleL, weight: 700, color: p.text, height: 1.3),
      titleMedium: rpText(RpType.title, weight: 700, color: p.text, height: 1.3),
      bodyLarge: rpText(RpType.bodyL, weight: 600, color: p.text),
      bodyMedium: rpText(RpType.body, weight: 500, color: p.text),
      labelLarge: rpText(RpType.label, weight: 500, color: p.muted),
      labelSmall: rpText(RpType.caption, weight: 500, color: p.muted),
    ),
  );
}
