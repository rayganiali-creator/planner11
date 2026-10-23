package com.routineplanner.app.widget

import android.content.Context
import org.json.JSONObject

// اسنپ‌شاتِ ویجت: همان JSONای که Dart (lib/data/widget_sync.dart) با متدِ updateWidget
// از کانالِ rp/native می‌فرستد؛ اینجا در SharedPreferences نگه داشته می‌شود تا ویجت
// بدون باز شدنِ برنامه هم تازه بماند.
data class WidgetHabit(
    val name: String,
    val time: String,
    val status: String, // success | fail | unset
    val colorIdx: Int,
)

data class WidgetSnapshot(
    val rtl: Boolean,
    val themeId: String,
    val mode: String, // light | dark | system
    val title: String,
    val dateLine: String,
    val todayLabel: String,
    val emptyText: String,
    val progressText: String,
    val smallCountText: String,
    val streakText: String,
    val streak: Int,
    val done: Int,
    val total: Int,
    val pct: Int,
    val habits: List<WidgetHabit>,
) {
    companion object {
        fun fromJson(o: JSONObject): WidgetSnapshot {
            val arr = o.optJSONArray("habits")
            val habits = mutableListOf<WidgetHabit>()
            if (arr != null) {
                for (i in 0 until arr.length()) {
                    val h = arr.optJSONObject(i) ?: continue
                    habits.add(
                        WidgetHabit(
                            name = h.optString("name"),
                            time = h.optString("time"),
                            status = h.optString("status", "unset"),
                            colorIdx = h.optInt("colorIdx", i),
                        )
                    )
                }
            }
            return WidgetSnapshot(
                rtl = o.optBoolean("rtl", true),
                themeId = o.optString("themeId", "emerald"),
                mode = o.optString("mode", "light"),
                title = o.optString("title"),
                dateLine = o.optString("dateLine"),
                todayLabel = o.optString("todayLabel"),
                emptyText = o.optString("emptyText"),
                progressText = o.optString("progressText"),
                smallCountText = o.optString("smallCountText"),
                streakText = o.optString("streakText"),
                streak = o.optInt("streak", 0),
                done = o.optInt("done", 0),
                total = o.optInt("total", 0),
                pct = o.optInt("pct", 0),
                habits = habits,
            )
        }
    }
}

object WidgetStore {
    private const val PREFS = "rp_widget"
    private const val KEY = "snapshot"

    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY, json).apply()
    }

    fun load(context: Context): WidgetSnapshot? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            ?: return null
        return try {
            WidgetSnapshot.fromJson(JSONObject(raw))
        } catch (e: Exception) {
            null
        }
    }
}
