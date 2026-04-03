package com.example.trackers_widget

import android.app.Activity
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.RemoteViews
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

private const val API_BASE = "https://www.benbb96.com/fr"

class TrackActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val trackerId = intent.getIntExtra("tracker_id", -1)
        val widgetId = intent.getIntExtra("widget_id", AppWidgetManager.INVALID_APPWIDGET_ID)

        if (trackerId == -1) { finish(); return }

        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val token = prefs.getString("api_token", null)

        if (token == null) {
            if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                showTokenMissingFeedback(widgetId)
            }
            return
        }

        Thread {
            var success = false
            try {
                val url = URL("$API_BASE/tracker/api/track")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Authorization", "Token $token")
                conn.setRequestProperty("Content-Type", "application/json")
                conn.connectTimeout = 10_000
                conn.readTimeout = 10_000
                conn.doOutput = true
                conn.outputStream.use { it.write("""{"tracker":$trackerId}""".toByteArray()) }
                val code = conn.responseCode
                conn.disconnect()
                success = code == 200 || code == 201
            } catch (_: Exception) {}

            runOnUiThread {
                if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    showFeedback(widgetId, prefs, trackerId, success)
                } else {
                    finish()
                }
            }
        }.start()
    }

    private fun showTokenMissingFeedback(widgetId: Int) {
        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val trackerJson = prefs.getString("tracker_$widgetId", null) ?: run { finish(); return }
        try {
            val tracker = org.json.JSONObject(trackerJson)
            val name = tracker.getString("nom")
            val colorHex = tracker.getString("color")
            val contrastHex = tracker.getString("contrast_color")
            val bgColor = android.graphics.Color.parseColor(if (colorHex.startsWith("#")) colorHex else "#$colorHex")
            val fgColor = android.graphics.Color.parseColor(if (contrastHex.startsWith("#")) contrastHex else "#$contrastHex")
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val views = android.widget.RemoteViews(packageName, R.layout.tracker_widget).apply {
                setTextViewText(R.id.widget_name, "⚠ Token manquant")
                setTextColor(R.id.widget_name, fgColor)
                setInt(R.id.widget_root, "setBackgroundColor", bgColor)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                val trackerId = tracker.getInt("id")
                appWidgetManager.updateAppWidget(widgetId, buildWidgetViews(this, widgetId, name, bgColor, fgColor, trackerId))
                finish()
            }, 3000)
        } catch (_: Exception) { finish() }
    }

    private fun showFeedback(widgetId: Int, prefs: android.content.SharedPreferences, trackerId: Int, success: Boolean) {
        val trackerJson = prefs.getString("tracker_$widgetId", null) ?: run { finish(); return }
        try {
            val tracker = JSONObject(trackerJson)
            val name = tracker.getString("nom")
            val colorHex = tracker.getString("color")
            val contrastHex = tracker.getString("contrast_color")
            val bgColor = Color.parseColor(if (colorHex.startsWith("#")) colorHex else "#$colorHex")
            val fgColor = Color.parseColor(if (contrastHex.startsWith("#")) contrastHex else "#$contrastHex")

            val appWidgetManager = AppWidgetManager.getInstance(this)
            val label = if (success) "✓ $name" else "✗ $name"

            val feedbackViews = RemoteViews(packageName, R.layout.tracker_widget).apply {
                setTextViewText(R.id.widget_name, label)
                setTextColor(R.id.widget_name, fgColor)
                setInt(R.id.widget_root, "setBackgroundColor", bgColor)
            }
            appWidgetManager.updateAppWidget(widgetId, feedbackViews)

            Handler(Looper.getMainLooper()).postDelayed({
                val normalViews = buildWidgetViews(this, widgetId, name, bgColor, fgColor, trackerId)
                appWidgetManager.updateAppWidget(widgetId, normalViews)
                finish()
            }, 2000)
        } catch (_: Exception) {
            finish()
        }
    }
}

fun buildWidgetViews(
    context: Context,
    widgetId: Int,
    name: String,
    bgColor: Int,
    fgColor: Int,
    trackerId: Int
): RemoteViews {
    val tapIntent = Intent(context, TrackActivity::class.java).apply {
        putExtra("tracker_id", trackerId)
        putExtra("widget_id", widgetId)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    val pendingIntent = PendingIntent.getActivity(
        context, widgetId, tapIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    return RemoteViews(context.packageName, R.layout.tracker_widget).apply {
        setTextViewText(R.id.widget_name, name)
        setTextColor(R.id.widget_name, fgColor)
        setInt(R.id.widget_root, "setBackgroundColor", bgColor)
        setOnClickPendingIntent(R.id.widget_root, pendingIntent)
    }
}
