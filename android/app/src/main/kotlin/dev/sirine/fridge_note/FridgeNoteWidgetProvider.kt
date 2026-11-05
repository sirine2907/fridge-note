package dev.sirine.fridge_note

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget with the current list. The Flutter side
 * (HomeWidgetUpdater) saves the texts, this class only puts them on screen.
 */
class FridgeNoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.fridge_note_widget).apply {
                setTextViewText(R.id.widget_title, widgetData.getString("list_name", "fridge-note"))
                setTextViewText(R.id.widget_count, widgetData.getString("items_left", ""))
                setTextViewText(
                    R.id.widget_items,
                    widgetData.getString("items", context.getString(R.string.widget_empty)),
                )

                val shopper = widgetData.getString("shopper", "") ?: ""
                setTextViewText(R.id.widget_shopper, shopper)
                setViewVisibility(R.id.widget_shopper, if (shopper.isEmpty()) View.GONE else View.VISIBLE)

                // Tapping anywhere opens the app.
                val open = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, open)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
