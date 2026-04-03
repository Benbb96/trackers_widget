package com.example.trackers_widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.widget.RemoteViews
import org.json.JSONObject

private const val PREFS_NAME = "HomeWidgetPreferences"

class TrackerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        for (appWidgetId in appWidgetIds) {
            val trackerJson = prefs.getString("tracker_$appWidgetId", null)
            val views: RemoteViews = when {
                trackerJson != null -> try {
                    val tracker = JSONObject(trackerJson)
                    val name = tracker.getString("nom")
                    val colorHex = tracker.getString("color")
                    val contrastHex = tracker.getString("contrast_color")
                    val trackerId = tracker.getInt("id")
                    val bgColor = Color.parseColor(if (colorHex.startsWith("#")) colorHex else "#$colorHex")
                    val fgColor = Color.parseColor(if (contrastHex.startsWith("#")) contrastHex else "#$contrastHex")
                    buildWidgetViews(context, appWidgetId, name, bgColor, fgColor, trackerId)
                } catch (_: Exception) {
                    RemoteViews(context.packageName, R.layout.tracker_widget).apply {
                        setTextViewText(R.id.widget_name, "Erreur")
                    }
                }
                else -> RemoteViews(context.packageName, R.layout.tracker_widget).apply {
                    setTextViewText(R.id.widget_name, "À configurer")
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val editor = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove("tracker_$appWidgetId")
        }
        editor.apply()
    }
}
