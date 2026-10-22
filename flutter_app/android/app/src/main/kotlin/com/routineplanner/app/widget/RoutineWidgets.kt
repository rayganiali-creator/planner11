package com.routineplanner.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

// ویجت متوسط (لیستِ عادت‌های امروز) و ویجت کوچک (حلقه‌ی پیشرفت).
// به‌روزرسانی: از داخل برنامه با هر ذخیره‌ی state (کانالِ rp/native ← updateWidget)
// و دوره‌ای با updatePeriodMillis در فایلِ info.
class RoutineWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            manager.updateAppWidget(id, WidgetRender.build(context, WidgetRender.Kind.MEDIUM))
        }
    }
}

class RoutineWidgetSmallProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            manager.updateAppWidget(id, WidgetRender.build(context, WidgetRender.Kind.SMALL))
        }
    }
}
