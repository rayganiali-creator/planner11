// سیستم Theme: ۹ هویتِ بصریِ مستقل × (Light / Dark). هر کدام یک مجموعه‌ی کاملِ توکن است (نه فقط رنگِ اصلی).
// ساختار (Layout/Typography/Component) برای همه یکسان است؛ فقط هویتِ رنگی عوض می‌شود.
// انتخابِ تم در state['accentTheme'] و حالت در state['theme'] (light | dark | system) ذخیره می‌شود (کلیدهای قدیمیِ بکاپ).
import 'package:flutter/material.dart';

import '../core/doc.dart';
import 'tokens.dart';

class AppThemeDef {
  final String id, fa, en, emoji;
  final RpPalette light, dark;
  const AppThemeDef(this.id, this.fa, this.en, this.emoji, this.light, this.dark);
  RpPalette of(bool isDark) => isDark ? dark : light;
}

Color _c(int v) => Color(0xFF000000 | v);

RpPalette _make(RpPalette base, {
  required int bg, required int surface, required int surface2, required int line, required int text, required int muted,
  required int primary, required int primary2, required int soft, required int on, required int secondary, required List<int> chart,
}) =>
    RpPalette(
      bg: _c(bg), surface: _c(surface), surface2: _c(surface2), line: _c(line), text: _c(text), muted: _c(muted),
      primary: _c(primary), primary2: _c(primary2), primarySoft: _c(soft),
      gold: base.gold, goldSoft: base.goldSoft, xp: base.xp, xpSoft: base.xpSoft, hp: base.hp, hpSoft: base.hpSoft,
      ok: base.ok, okSoft: base.okSoft, bad: base.bad, badSoft: base.badSoft, blue: base.blue, blueSoft: base.blueSoft,
      goldInk: base.goldInk, xpInk: base.xpInk, hpInk: base.hpInk, okInk: base.okInk, badInk: base.badInk, blueInk: base.blueInk, fire: base.fire,
      onPrimary: _c(on), onOk: base.onOk, onGold: base.onGold, btnA: _c(primary), btnB: _c(primary2),
      skyTop: base.skyTop, skyBottom: base.skyBottom, hillA: base.hillA, hillB: base.hillB, ground: base.ground,
      secondary: _c(secondary), chart: [for (final c in chart) _c(c)],
    );

final RpPalette _lightBase = RpPalette.light, _darkBase = RpPalette.dark;

final List<AppThemeDef> appThemes = [
  AppThemeDef('emerald', 'زمرد', 'Emerald', '🌿',
      _make(_lightBase, bg: 0xF3F7F2, surface: 0xFFFFFF, surface2: 0xEAF1EA, line: 0xD8E4D8, text: 0x14231A, muted: 0x516657, primary: 0x12754F, primary2: 0x148558, soft: 0xDDF0E5, on: 0xFFFFFF, secondary: 0x6FA98A, chart: [0x12754F, 0x5F9F7D, 0x2B7FB8, 0xC08411, 0xC0483C, 0x7A5AC9]),
      _make(_darkBase, bg: 0x08140F, surface: 0x0F1E17, surface2: 0x0B1912, line: 0x1D372A, text: 0xE6F0E8, muted: 0x8CA898, primary: 0x3DD598, primary2: 0x2BB67F, soft: 0x123325, on: 0x052015, secondary: 0x8ADFBC, chart: [0x3DD598, 0x8ADFBC, 0x5DB6F0, 0xF2C14E, 0xFF8672, 0xB49BFF])),
  AppThemeDef('midnight', 'نیمه‌شب', 'Midnight', '🌙',
      _make(_lightBase, bg: 0xF4F3FA, surface: 0xFFFFFF, surface2: 0xEEECF7, line: 0xDDD9EE, text: 0x1B1833, muted: 0x5C5878, primary: 0x4B3FBF, primary2: 0x5F52D6, soft: 0xE7E4FB, on: 0xFFFFFF, secondary: 0x7C6CF0, chart: [0x4B3FBF, 0x7C6CF0, 0x0E8FB0, 0xC08411, 0xD0455F, 0x2E9B6A]),
      _make(_darkBase, bg: 0x0C0B1E, surface: 0x15142B, surface2: 0x111026, line: 0x2A2850, text: 0xECEBFA, muted: 0x9E9BC6, primary: 0xA196FF, primary2: 0x8B7EF8, soft: 0x26224D, on: 0x120E3A, secondary: 0xC5BEFF, chart: [0xA196FF, 0xC5BEFF, 0x49C6E5, 0xF2B84B, 0xFF7B93, 0x52D6A0])),
  AppThemeDef('ocean', 'اقیانوس', 'Ocean', '🌊',
      _make(_lightBase, bg: 0xF1F6FA, surface: 0xFFFFFF, surface2: 0xE8F0F6, line: 0xD5E2EC, text: 0x0F2233, muted: 0x4B6477, primary: 0x0B6FA6, primary2: 0x0E7DB3, soft: 0xDCEEF8, on: 0xFFFFFF, secondary: 0x3AA6D6, chart: [0x0B6FA6, 0x2A9ACC, 0x1E9A8A, 0xC08411, 0xC0483C, 0x7A5AC9]),
      _make(_darkBase, bg: 0x08121C, surface: 0x0E1C2A, surface2: 0x0B1722, line: 0x1B3347, text: 0xE4EFF7, muted: 0x88A5BA, primary: 0x46C2F0, primary2: 0x2AA6D8, soft: 0x11344A, on: 0x04202E, secondary: 0x8DD8F6, chart: [0x46C2F0, 0x8DD8F6, 0x3FD0B8, 0xF2C14E, 0xFF8672, 0xB49BFF])),
  AppThemeDef('rose', 'گل‌سرخ', 'Rose', '🌸',
      _make(_lightBase, bg: 0xFAF3F5, surface: 0xFFFFFF, surface2: 0xF5E9ED, line: 0xEBD7DE, text: 0x2A1620, muted: 0x735261, primary: 0xB0345D, primary2: 0xC4426E, soft: 0xF9E0E8, on: 0xFFFFFF, secondary: 0xD77A9C, chart: [0xB0345D, 0xD57296, 0x7A5AC9, 0xC08411, 0x2B7FB8, 0x2E9B6A]),
      _make(_darkBase, bg: 0x170A10, surface: 0x22111A, surface2: 0x1C0E15, line: 0x3A2030, text: 0xF5E6EC, muted: 0xB896A6, primary: 0xF58AAE, primary2: 0xE8709A, soft: 0x3A1827, on: 0x3B0A1E, secondary: 0xF6B3C9, chart: [0xF58AAE, 0xF6B3C9, 0xB49BFF, 0xF2C14E, 0x5DB6F0, 0x52D6A0])),
  AppThemeDef('amber', 'کهربا', 'Amber', '🌅',
      _make(_lightBase, bg: 0xFBF5EA, surface: 0xFFFFFF, surface2: 0xF6ECD9, line: 0xEBDDBF, text: 0x2B1D0C, muted: 0x74593A, primary: 0xA04F06, primary2: 0xB65E10, soft: 0xF9E8CC, on: 0xFFFFFF, secondary: 0xD9983A, chart: [0xA04F06, 0xC48426, 0x2B7FB8, 0x2E8B57, 0xC0483C, 0x7A5AC9]),
      _make(_darkBase, bg: 0x150E06, surface: 0x21160A, surface2: 0x1B1208, line: 0x3A2A14, text: 0xF6EAD7, muted: 0xC0A47C, primary: 0xF2A33D, primary2: 0xE08A1E, soft: 0x3A2810, on: 0x2A1600, secondary: 0xF6C77F, chart: [0xF2A33D, 0xF6C77F, 0x5DB6F0, 0x52D6A0, 0xFF8672, 0xB49BFF])),
  AppThemeDef('mono', 'تک‌رنگ', 'Monochrome', '⚪',
      _make(_lightBase, bg: 0xF6F6F6, surface: 0xFFFFFF, surface2: 0xEEEEEE, line: 0xDCDCDC, text: 0x111111, muted: 0x585858, primary: 0x1E1E1E, primary2: 0x3A3A3A, soft: 0xE8E8E8, on: 0xFFFFFF, secondary: 0x777777, chart: [0x1E1E1E, 0x6A6A6A, 0x2B7FB8, 0xC08411, 0xC0483C, 0x2E8B57]),
      _make(_darkBase, bg: 0x0B0B0B, surface: 0x151515, surface2: 0x101010, line: 0x2A2A2A, text: 0xF2F2F2, muted: 0x9C9C9C, primary: 0xF2F2F2, primary2: 0xCFCFCF, soft: 0x262626, on: 0x111111, secondary: 0xB0B0B0, chart: [0xF2F2F2, 0xB0B0B0, 0x5DB6F0, 0xF2C14E, 0xFF8672, 0x52D6A0])),
  AppThemeDef('royal', 'آبی سلطنتی', 'Royal Blue', '🔷',
      _make(_lightBase, bg: 0xF2F6FD, surface: 0xFFFFFF, surface2: 0xE8EFFA, line: 0xD3DEF0, text: 0x0F1B33, muted: 0x4A5B78, primary: 0x1D4ED8, primary2: 0x2759E0, soft: 0xDCE7FC, on: 0xFFFFFF, secondary: 0x5B8DEF, chart: [0x1D4ED8, 0x5B8DEF, 0x1E9A8A, 0xC08411, 0xC0483C, 0x7A5AC9]),
      _make(_darkBase, bg: 0x090F1D, surface: 0x111A2E, surface2: 0x0D1526, line: 0x22304D, text: 0xE6EDFB, muted: 0x8FA2C4, primary: 0x6C9BFF, primary2: 0x4F84F5, soft: 0x172A52, on: 0x071433, secondary: 0xA8C4FF, chart: [0x6C9BFF, 0xA8C4FF, 0x3FD0B8, 0xF2C14E, 0xFF8672, 0xB49BFF])),
  AppThemeDef('coral', 'مرجانی', 'Coral', '🧡',
      _make(_lightBase, bg: 0xFDF4F1, surface: 0xFFFFFF, surface2: 0xF9E8E2, line: 0xF0D5CC, text: 0x2B1713, muted: 0x7A5249, primary: 0xB93A25, primary2: 0xCB4A30, soft: 0xFBE1D9, on: 0xFFFFFF, secondary: 0xF08A6E, chart: [0xB93A25, 0xD9674A, 0x2B7FB8, 0xC08411, 0x7A5AC9, 0x2E9B6A]),
      _make(_darkBase, bg: 0x170C09, surface: 0x22130F, surface2: 0x1C0F0C, line: 0x3B2119, text: 0xF7E9E4, muted: 0xBC9A8E, primary: 0xFF8B6E, primary2: 0xF2724F, soft: 0x3B1B12, on: 0x3A0E04, secondary: 0xFFB8A3, chart: [0xFF8B6E, 0xFFB8A3, 0x5DB6F0, 0xF2C14E, 0xB49BFF, 0x52D6A0])),
  AppThemeDef('lagoon', 'فیروزه‌ای', 'Lagoon', '🐚',
      _make(_lightBase, bg: 0xF0F7F7, surface: 0xFFFFFF, surface2: 0xE4F1F0, line: 0xCFE3E2, text: 0x0C2224, muted: 0x456769, primary: 0x0B6E66, primary2: 0x0D7F76, soft: 0xD5EFEC, on: 0xFFFFFF, secondary: 0x3DB3A8, chart: [0x0B6E66, 0x2A9D92, 0x2B7FB8, 0xC08411, 0xC0483C, 0x7A5AC9]),
      _make(_darkBase, bg: 0x07161A, surface: 0x0D2328, surface2: 0x0A1C20, line: 0x1A3A40, text: 0xE2F2F2, muted: 0x86AAAD, primary: 0x3FD6C6, primary2: 0x2BBFB0, soft: 0x0F3A3B, on: 0x042226, secondary: 0x8CE8DC, chart: [0x3FD6C6, 0x8CE8DC, 0x5DB6F0, 0xF2C14E, 0xFF8672, 0xB49BFF])),
];

const String defaultThemeId = 'emerald';

/// شناسه‌های قدیمیِ «رنگ اصلی» (accentTheme در نسخه‌ی HTML/نسخه‌های قبل) → تمِ جدیدِ نزدیک؛ داده‌ی کاربر دست‌نخورده می‌ماند.
const Map<String, String> _legacyAccent = {'teal': 'emerald', 'blue': 'ocean', 'purple': 'midnight', 'rose': 'rose', 'amber': 'amber', 'slate': 'mono'};

AppThemeDef themeById(Object? id) {
  final k = _legacyAccent['$id'] ?? '$id';
  return appThemes.firstWhere((t) => t.id == k, orElse: () => appThemes.first);
}

/// حالتِ نمایش: light | dark | system (هر مقدارِ دیگر = light)
String themeMode(Doc st) => switch (st['theme']) { 'dark' => 'dark', 'system' => 'system', _ => 'light' };

bool isDarkMode(Doc st, Brightness platform) {
  final m = themeMode(st);
  return m == 'dark' || (m == 'system' && platform == Brightness.dark);
}

RpPalette paletteFor(Doc st, Brightness platform) => themeById(st['accentTheme']).of(isDarkMode(st, platform));
