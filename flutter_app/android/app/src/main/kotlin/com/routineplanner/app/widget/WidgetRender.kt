package com.routineplanner.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.view.View
import android.widget.RemoteViews
import com.routineplanner.app.MainActivity
import com.routineplanner.app.R

// رندرِ ویجت صفحه‌ی اصلی روتین پلنر: کارتِ مینیمال با همان توکن‌های برنامه.
// پس‌زمینه، نشانه‌ها، نوار و حلقه‌ی پیشرفت بیت‌مپ‌اند تا گرادیان و درخششِ طرح دقیق دربیاید.
object WidgetRender {

    enum class Kind { MEDIUM, SMALL }

    fun updateAll(context: Context) {
        val mgr = AppWidgetManager.getInstance(context)
        for (cls in listOf(RoutineWidgetProvider::class.java, RoutineWidgetSmallProvider::class.java)) {
            val ids = mgr.getAppWidgetIds(ComponentName(context, cls))
            for (id in ids) {
                val kind = if (cls == RoutineWidgetProvider::class.java) Kind.MEDIUM else Kind.SMALL
                mgr.updateAppWidget(id, build(context, kind))
            }
        }
    }

    private fun isDark(context: Context, snap: WidgetSnapshot): Boolean = when (snap.mode) {
        "dark" -> true
        "light" -> false
        else -> (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
    }

    private fun placeholder(context: Context): WidgetSnapshot {
        val en = context.resources.configuration.locales[0].language == "en"
        return WidgetSnapshot(
            rtl = !en, themeId = "emerald", mode = "system",
            title = if (en) "Today's routine" else "روتین امروز",
            dateLine = "", todayLabel = if (en) "Today" else "امروز",
            emptyText = if (en) "Open the app to see today's habits" else "برنامه را باز کنید تا عادت‌های امروز دیده شوند",
            progressText = "", smallCountText = if (en) "Open the app" else "برنامه را باز کنید",
            streakText = "", streak = 0, done = 0, total = 0, pct = 0, habits = emptyList(),
        )
    }

    fun build(context: Context, kind: Kind): RemoteViews {
        val snap = WidgetStore.load(context) ?: placeholder(context)
        val dark = isDark(context, snap)
        val pal = WidgetTheme.palette(snap.themeId, dark)
        val layout = if (kind == Kind.MEDIUM) R.layout.widget_rp_medium else R.layout.widget_rp_small
        val v = RemoteViews(context.packageName, layout)

        val launch = PendingIntent.getActivity(
            context, if (kind == Kind.MEDIUM) 11 else 12,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        v.setOnClickPendingIntent(R.id.widget_root, launch)

        if (kind == Kind.MEDIUM) fillMedium(v, snap, pal) else fillSmall(v, snap, pal)
        return v
    }

    // ------------------------------------------------------------ medium
    private fun fillMedium(v: RemoteViews, s: WidgetSnapshot, pal: WPal) {
        v.setImageViewBitmap(R.id.bg, bgBitmap(880, 600, 46f, pal, s.rtl))
        v.setImageViewBitmap(R.id.mark, markBitmap(104, pal))
        v.setTextViewText(R.id.title, s.title)
        v.setTextColor(R.id.title, pal.ink)
        v.setTextViewText(R.id.date, s.dateLine)
        v.setTextColor(R.id.date, pal.muted)

        if (s.streak > 0) {
            v.setViewVisibility(R.id.streak_box, View.VISIBLE)
            v.setImageViewBitmap(R.id.streak_bg, pillBitmap(440, 112, pal.goldSoft))
            v.setImageViewBitmap(R.id.flame, flameBitmap(72))
            v.setTextViewText(R.id.streak, s.streakText)
            v.setTextColor(R.id.streak, pal.goldInk)
        } else {
            v.setViewVisibility(R.id.streak_box, View.GONE)
        }

        val rowIds = listOf(R.id.row1, R.id.row2, R.id.row3, R.id.row4)
        val empty = s.total == 0
        v.setViewVisibility(R.id.rows, if (empty) View.GONE else View.VISIBLE)
        v.setViewVisibility(R.id.empty, if (empty) View.VISIBLE else View.GONE)
        if (empty) {
            v.setTextViewText(R.id.empty, s.emptyText)
            v.setTextColor(R.id.empty, pal.muted)
        }
        for (i in rowIds.indices) {
            val row = rowIds[i]
            val h = s.habits.getOrNull(i)
            if (h == null) {
                v.setViewVisibility(row, View.GONE)
                continue
            }
            v.setViewVisibility(row, View.VISIBLE)
            val bgId = intArrayOf(R.id.row1_bg, R.id.row2_bg, R.id.row3_bg, R.id.row4_bg)[i]
            val checkId = intArrayOf(R.id.row1_check, R.id.row2_check, R.id.row3_check, R.id.row4_check)[i]
            val dotId = intArrayOf(R.id.row1_dot, R.id.row2_dot, R.id.row3_dot, R.id.row4_dot)[i]
            val nameId = intArrayOf(R.id.row1_name, R.id.row2_name, R.id.row3_name, R.id.row4_name)[i]
            val timeId = intArrayOf(R.id.row1_time, R.id.row2_time, R.id.row3_time, R.id.row4_time)[i]
            v.setImageViewBitmap(bgId, chipBitmap(800, 136, 44f, pal.chip))
            v.setImageViewBitmap(checkId, statusBitmap(80, h.status, pal))
            v.setImageViewBitmap(dotId, dotBitmap(28, pal.chart[h.colorIdx.mod(pal.chart.size)]))
            v.setTextViewText(nameId, h.name)
            v.setTextColor(nameId, if (h.status == "unset") pal.ink else pal.muted)
            v.setTextViewText(timeId, h.time)
            v.setTextColor(timeId, pal.muted)
        }

        v.setViewVisibility(R.id.footer, if (empty) View.GONE else View.VISIBLE)
        if (!empty) {
            v.setTextViewText(R.id.progress_text, s.progressText)
            v.setTextColor(R.id.progress_text, pal.muted)
            v.setTextViewText(R.id.pct, "${s.pct}٪".takeIf { s.rtl } ?: "${s.pct}%")
            v.setTextColor(R.id.pct, pal.accent)
            v.setImageViewBitmap(R.id.bar, barBitmap(800, 24, pal, s.done.toFloat() / s.total.coerceAtLeast(1), s.rtl))
        }
    }

    // ------------------------------------------------------------ small
    private fun fillSmall(v: RemoteViews, s: WidgetSnapshot, pal: WPal) {
        v.setImageViewBitmap(R.id.bg, bgBitmap(560, 560, 46f, pal, s.rtl))
        v.setImageViewBitmap(R.id.mark, markBitmap(88, pal))
        v.setTextViewText(R.id.today, s.todayLabel)
        v.setTextColor(R.id.today, pal.ink)
        v.setImageViewBitmap(R.id.ring, ringBitmap(440, pal, if (s.total == 0) 0f else s.done.toFloat() / s.total))
        v.setTextViewText(R.id.pct_big, if (s.rtl) "${s.pct}٪" else "${s.pct}%")
        v.setTextColor(R.id.pct_big, pal.ink)
        v.setTextViewText(R.id.count, s.smallCountText)
        v.setTextColor(R.id.count, pal.muted)
        if (s.streak > 0) {
            v.setViewVisibility(R.id.streak_box, View.VISIBLE)
            v.setImageViewBitmap(R.id.streak_bg, pillBitmap(440, 112, pal.goldSoft))
            v.setImageViewBitmap(R.id.flame, flameBitmap(64))
            v.setTextViewText(R.id.streak, s.streakText)
            v.setTextColor(R.id.streak, pal.goldInk)
        } else {
            v.setViewVisibility(R.id.streak_box, View.GONE)
        }
    }

    // ------------------------------------------------------------ bitmaps
    private fun paint() = Paint(Paint.ANTI_ALIAS_FLAG)

    private fun bgBitmap(w: Int, h: Int, radius: Float, pal: WPal, rtl: Boolean): Bitmap {
        val b = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())
        val p = paint()
        p.shader = LinearGradient(0f, 0f, 0f, h.toFloat(), pal.cardTop, pal.cardBottom, Shader.TileMode.CLAMP)
        cv.drawRoundRect(rect, radius, radius, p)
        // درخششِ ملایمِ رنگِ تم در گوشه‌ی شروع
        val gx = if (rtl) w.toFloat() else 0f
        val glow = paint()
        glow.shader = RadialGradient(gx, 0f, w * 0.75f, Color.argb(46, Color.red(pal.accent2), Color.green(pal.accent2), Color.blue(pal.accent2)), Color.TRANSPARENT)
        cv.save()
        val clip = Path().apply { addRoundRect(rect, radius, radius, Path.Direction.CW) }
        cv.clipPath(clip)
        cv.drawRect(rect, glow)
        cv.restore()
        val border = paint().apply { style = Paint.Style.STROKE; strokeWidth = 2f; color = pal.line }
        cv.drawRoundRect(RectF(1f, 1f, w - 1f, h - 1f), radius, radius, border)
        return b
    }

    private fun markBitmap(size: Int, pal: WPal): Bitmap {
        val b = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        val p = paint()
        p.shader = LinearGradient(0f, 0f, 0f, size.toFloat(), pal.accent2, pal.accent, Shader.TileMode.CLAMP)
        cv.drawRoundRect(RectF(0f, 0f, size.toFloat(), size.toFloat()), size * 0.32f, size * 0.32f, p)
        val chk = paint().apply { style = Paint.Style.STROKE; strokeWidth = size * 0.11f; color = Color.WHITE; strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND }
        val path = Path()
        path.moveTo(size * 0.30f, size * 0.52f)
        path.lineTo(size * 0.45f, size * 0.67f)
        path.lineTo(size * 0.72f, size * 0.36f)
        cv.drawPath(path, chk)
        return b
    }

    private fun flameBitmap(size: Int): Bitmap {
        val b = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        val cx = size / 2f
        fun flame(scale: Float, color: Int, dy: Float) {
            val s = size * 0.42f * scale
            val cy = size / 2f + dy
            val path = Path()
            path.moveTo(cx, cy - s)
            path.cubicTo(cx + s * 0.62f, cy + s * 0.25f, cx + s * 0.42f, cy + s * 0.55f, cx + s * 0.42f, cy + s * 0.78f)
            path.cubicTo(cx + s * 0.2f, cy + s * 0.95f, cx - s * 0.2f, cy + s * 0.95f, cx - s * 0.42f, cy + s * 0.78f)
            path.cubicTo(cx - s * 0.42f, cy + s * 0.55f, cx - s * 0.62f, cy + s * 0.25f, cx, cy - s)
            cv.drawPath(path, paint().apply { this.color = color })
        }
        flame(1f, 0xFFE8842C.toInt(), 0f)
        flame(0.55f, 0xFFF5B73E.toInt(), size * 0.14f)
        return b
    }

    private fun statusBitmap(size: Int, status: String, pal: WPal): Bitmap {
        val b = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        val cx = size / 2f
        when (status) {
            "success" -> {
                cv.drawCircle(cx, cx, cx, paint().apply { color = pal.accent })
                val chk = paint().apply { style = Paint.Style.STROKE; strokeWidth = size * 0.11f; color = Color.WHITE; strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND }
                val path = Path()
                path.moveTo(size * 0.31f, size * 0.52f)
                path.lineTo(size * 0.45f, size * 0.66f)
                path.lineTo(size * 0.70f, size * 0.37f)
                cv.drawPath(path, chk)
            }
            "fail" -> {
                cv.drawCircle(cx, cx, cx, paint().apply { color = pal.badSoft })
                val x = paint().apply { style = Paint.Style.STROKE; strokeWidth = size * 0.10f; color = pal.bad; strokeCap = Paint.Cap.ROUND }
                cv.drawLine(size * 0.36f, size * 0.36f, size * 0.64f, size * 0.64f, x)
                cv.drawLine(size * 0.64f, size * 0.36f, size * 0.36f, size * 0.64f, x)
            }
            else -> {
                val ring = paint().apply { style = Paint.Style.STROKE; strokeWidth = size * 0.07f; color = pal.line }
                cv.drawCircle(cx, cx, cx - size * 0.05f, ring)
            }
        }
        return b
    }

    private fun dotBitmap(size: Int, color: Int): Bitmap {
        val b = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        Canvas(b).drawCircle(size / 2f, size / 2f, size / 2f, paint().apply { this.color = color })
        return b
    }

    private fun chipBitmap(w: Int, h: Int, radius: Float, color: Int): Bitmap {
        val b = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        Canvas(b).drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), radius, radius, paint().apply { this.color = color })
        return b
    }

    private fun pillBitmap(w: Int, h: Int, color: Int): Bitmap = chipBitmap(w, h, h / 2f, color)

    private fun barBitmap(w: Int, h: Int, pal: WPal, frac: Float, rtl: Boolean): Bitmap {
        val b = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())
        cv.drawRoundRect(rect, h / 2f, h / 2f, paint().apply { color = pal.line })
        val fw = (w * frac.coerceIn(0f, 1f))
        if (fw > 0f) {
            val p = paint()
            p.shader = if (rtl) LinearGradient(w.toFloat(), 0f, w - fw, 0f, pal.accent, pal.accent2, Shader.TileMode.CLAMP)
            else LinearGradient(0f, 0f, fw, 0f, pal.accent, pal.accent2, Shader.TileMode.CLAMP)
            val fill = if (rtl) RectF(w - fw, 0f, w.toFloat(), h.toFloat()) else RectF(0f, 0f, fw, h.toFloat())
            cv.save()
            val clip = Path().apply { addRoundRect(rect, h / 2f, h / 2f, Path.Direction.CW) }
            cv.clipPath(clip)
            cv.drawRect(fill, p)
            cv.restore()
        }
        return b
    }

    private fun ringBitmap(size: Int, pal: WPal, frac: Float): Bitmap {
        val b = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        val sw = size * 0.105f
        val rect = RectF(sw / 2, sw / 2, size - sw / 2, size - sw / 2)
        cv.drawCircle(size / 2f, size / 2f, (size - sw) / 2f, paint().apply { style = Paint.Style.STROKE; strokeWidth = sw; color = pal.line })
        val steps = 64
        val sweep = 360f * frac.coerceIn(0f, 1f)
        if (sweep > 0f) {
            val p = paint().apply { style = Paint.Style.STROKE; strokeWidth = sw }
            for (i in 0 until steps) {
                p.color = lerpColor(pal.accent2, pal.accent, i / steps.toFloat())
                cv.drawArc(rect, -90f + sweep * i / steps, sweep / steps + 1.5f, false, p)
            }
        }
        return b
    }

    private fun lerpColor(a: Int, bb: Int, t: Float): Int = Color.rgb(
        (Color.red(a) + (Color.red(bb) - Color.red(a)) * t).toInt(),
        (Color.green(a) + (Color.green(bb) - Color.green(a)) * t).toInt(),
        (Color.blue(a) + (Color.blue(bb) - Color.blue(a)) * t).toInt(),
    )
}
