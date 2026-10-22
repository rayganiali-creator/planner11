package com.routineplanner.app.widget

import android.graphics.Color

// پالتِ ویجت: آینه‌ی همان ۹ تمِ داخل برنامه (lib/ui/app_themes.dart) × روشن/تیره.
// رنگ‌ها عیناً از توکن‌های برنامه گرفته شده‌اند تا ویجت با تمِ انتخابیِ کاربر یکی باشد.
data class WPal(
    val cardTop: Int,
    val cardBottom: Int,
    val chip: Int,
    val line: Int,
    val ink: Int,
    val muted: Int,
    val accent: Int,
    val accent2: Int,
    val goldSoft: Int,
    val goldInk: Int,
    val bad: Int,
    val badSoft: Int,
    val chart: List<Int>,
)

object WidgetTheme {
    private fun c(hex: Long): Int = (0xFF000000L or hex).toInt()

    private fun blend(a: Int, b: Int, t: Float): Int = Color.rgb(
        (Color.red(a) + (Color.red(b) - Color.red(a)) * t).toInt(),
        (Color.green(a) + (Color.green(b) - Color.green(a)) * t).toInt(),
        (Color.blue(a) + (Color.blue(b) - Color.blue(a)) * t).toInt(),
    )

    // فقط فیلدهای لازمِ رندر از هر تم: bg, surface, surface2, line, text, muted, primary, primary2 + chart
    private data class Raw(
        val bg: Int, val surface: Int, val surface2: Int, val line: Int,
        val text: Int, val muted: Int, val p: Int, val p2: Int, val chart: List<Int>,
    )

    private fun raw(
        bg: Long, s: Long, s2: Long, line: Long, text: Long, muted: Long,
        p: Long, p2: Long, chart: List<Long>,
    ) = Raw(c(bg), c(s), c(s2), c(line), c(text), c(muted), c(p), c(p2), chart.map { c(it) })

    private val themes: Map<String, Pair<Raw, Raw>> = mapOf(
        "emerald" to (raw(0xF3F7F2, 0xFFFFFF, 0xEAF1EA, 0xD8E4D8, 0x14231A, 0x516657, 0x12754F, 0x148558, listOf(0x12754F, 0x5F9F7D, 0x2B7FB8, 0xC08411, 0xC0483C, 0x7A5AC9))
                to raw(0x08140F, 0x0F1E17, 0x0B1912, 0x1D372A, 0xE6F0E8, 0x8CA898, 0x3DD598, 0x2BB67F, listOf(0x3DD598, 0x8ADFBC, 0x5DB6F0, 0xF2C14E, 0xFF8672, 0xB49BFF))),
        "midnight" to (raw(0xF4F3FA, 0xFFFFFF, 0xEEECF7, 0xDDD9EE, 0x1B1833, 0x5C5878, 0x4B3FBF, 0x5F52D6, listOf(0x4B3FBF, 0x7C6CF0, 0x0E8FB0, 0xC08411, 0xD0455F, 0x2E9B6A))
                to raw(0x0C0B1E, 0x15142B, 0x111026, 0x2A2850, 0xECEBFA, 0x9E9BC6, 0xA196FF, 0x8B7EF8, listOf(0xA196FF, 0xC5BEFF, 0x49C6E5, 0xF2B84B, 0xFF7B93, 0x52D6A0))),
        "ocean" to (raw(0xF1F6FA, 0xFFFFFF, 0xE8F0F6, 0xD5E2EC, 0x0F2233, 0x4B6477, 0x0B6FA6, 0x0E7DB3, listOf(0x0B6FA6, 0x2A9ACC, 0x1E9A8A, 0xC08411, 0xC0483C, 0x7A5AC9))
                to raw(0x08121C, 0x0E1C2A, 0x0B1722, 0x1B3347, 0xE4EFF7, 0x88A5BA, 0x46C2F0, 0x2AA6D8, listOf(0x46C2F0, 0x8DD8F6, 0x3FD0B8, 0xF2C14E, 0xFF8672, 0xB49BFF))),
        "rose" to (raw(0xFAF3F5, 0xFFFFFF, 0xF5E9ED, 0xEBD7DE, 0x2A1620, 0x735261, 0xB0345D, 0xC4426E, listOf(0xB0345D, 0xD57296, 0x7A5AC9, 0xC08411, 0x2B7FB8, 0x2E9B6A))
                to raw(0x170A10, 0x22111A, 0x1C0E15, 0x3A2030, 0xF5E6EC, 0xB896A6, 0xF58AAE, 0xE8709A, listOf(0xF58AAE, 0xF6B3C9, 0xB49BFF, 0xF2C14E, 0x5DB6F0, 0x52D6A0))),
        "amber" to (raw(0xFBF5EA, 0xFFFFFF, 0xF6ECD9, 0xEBDDBF, 0x2B1D0C, 0x74593A, 0xA04F06, 0xB65E10, listOf(0xA04F06, 0xC48426, 0x2B7FB8, 0x2E8B57, 0xC0483C, 0x7A5AC9))
                to raw(0x150E06, 0x21160A, 0x1B1208, 0x3A2A14, 0xF6EAD7, 0xC0A47C, 0xF2A33D, 0xE08A1E, listOf(0xF2A33D, 0xF6C77F, 0x5DB6F0, 0x52D6A0, 0xFF8672, 0xB49BFF))),
        "mono" to (raw(0xF6F6F6, 0xFFFFFF, 0xEEEEEE, 0xDCDCDC, 0x111111, 0x585858, 0x1E1E1E, 0x3A3A3A, listOf(0x1E1E1E, 0x6A6A6A, 0x2B7FB8, 0xC08411, 0xC0483C, 0x2E8B57))
                to raw(0x0B0B0B, 0x151515, 0x101010, 0x2A2A2A, 0xF2F2F2, 0x9C9C9C, 0xF2F2F2, 0xCFCFCF, listOf(0xF2F2F2, 0xB0B0B0, 0x5DB6F0, 0xF2C14E, 0xFF8672, 0x52D6A0))),
        "royal" to (raw(0xF2F6FD, 0xFFFFFF, 0xE8EFFA, 0xD3DEF0, 0x0F1B33, 0x4A5B78, 0x1D4ED8, 0x2759E0, listOf(0x1D4ED8, 0x5B8DEF, 0x1E9A8A, 0xC08411, 0xC0483C, 0x7A5AC9))
                to raw(0x090F1D, 0x111A2E, 0x0D1526, 0x22304D, 0xE6EDFB, 0x8FA2C4, 0x6C9BFF, 0x4F84F5, listOf(0x6C9BFF, 0xA8C4FF, 0x3FD0B8, 0xF2C14E, 0xFF8672, 0xB49BFF))),
        "coral" to (raw(0xFDF4F1, 0xFFFFFF, 0xF9E8E2, 0xF0D5CC, 0x2B1713, 0x7A5249, 0xB93A25, 0xCB4A30, listOf(0xB93A25, 0xD9674A, 0x2B7FB8, 0xC08411, 0x7A5AC9, 0x2E9B6A))
                to raw(0x170C09, 0x22130F, 0x1C0F0C, 0x3B2119, 0xF7E9E4, 0xBC9A8E, 0xFF8B6E, 0xF2724F, listOf(0xFF8B6E, 0xFFB8A3, 0x5DB6F0, 0xF2C14E, 0xB49BFF, 0x52D6A0))),
        "lagoon" to (raw(0xF0F7F7, 0xFFFFFF, 0xE4F1F0, 0xCFE3E2, 0x0C2224, 0x456769, 0x0B6E66, 0x0D7F76, listOf(0x0B6E66, 0x2A9D92, 0x2B7FB8, 0xC08411, 0xC0483C, 0x7A5AC9))
                to raw(0x07161A, 0x0D2328, 0x0A1C20, 0x1A3A40, 0xE2F2F2, 0x86AAAD, 0x3FD6C6, 0x2BBFB0, listOf(0x3FD6C6, 0x8CE8DC, 0x5DB6F0, 0xF2C14E, 0xFF8672, 0xB49BFF))),
    )

    fun palette(themeId: String?, dark: Boolean): WPal {
        val pair = themes[themeId] ?: themes.getValue("emerald")
        val r = if (dark) pair.second else pair.first
        return WPal(
            cardTop = r.surface,
            cardBottom = r.surface2,
            chip = if (dark) blend(r.surface, Color.WHITE, 0.055f) else r.bg,
            line = r.line,
            ink = r.text,
            muted = r.muted,
            accent = r.p,
            accent2 = r.p2,
            goldSoft = if (dark) c(0x33290F) else c(0xF7EBCB),
            goldInk = if (dark) c(0xE6BF5C) else c(0x83651E),
            bad = if (dark) c(0xF0806F) else c(0xD04A3C),
            badSoft = if (dark) c(0x3A2220) else c(0xF8E1DD),
            chart = r.chart,
        )
    }
}
