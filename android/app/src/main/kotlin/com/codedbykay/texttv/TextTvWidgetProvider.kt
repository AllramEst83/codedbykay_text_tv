package com.codedbykay.texttv

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The home-screen widget: a page's number and its headlines on black, the page
 * set in the app and kept up to date by the background job. Everything shown
 * is read from what the app saved through the home_widget plugin; keys are the
 * ones in `lib/services/widget_platform.dart`. A tap opens the app on the page.
 */
class TextTvWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val page = widgetData.getInt("widget_page", 0)
        val updated = widgetData.getString("widget_updated", "") ?: ""
        val lines = (0 until LINES).map { widgetData.getString("widget_line_$it", "") ?: "" }
        val loaded = page != 0 && lines.any { it.isNotEmpty() }

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.text_tv_widget)

            views.setTextViewText(
                R.id.widget_title,
                if (page != 0) "${context.getString(R.string.widget_title)} $page"
                else context.getString(R.string.widget_title),
            )
            views.setTextViewText(R.id.widget_updated, updated)

            for ((index, viewId) in LINE_IDS.withIndex()) {
                val text = lines[index]
                views.setTextViewText(viewId, text)
                views.setViewVisibility(
                    viewId,
                    if (loaded && text.isNotEmpty()) View.VISIBLE else View.GONE,
                )
            }
            views.setTextViewText(R.id.widget_empty, context.getString(R.string.widget_empty))
            views.setViewVisibility(R.id.widget_empty, if (loaded) View.GONE else View.VISIBLE)

            val link = Uri.parse("texttv://page/${if (page != 0) page else 100}")
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, link),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private companion object {
        const val LINES = 8
        val LINE_IDS = intArrayOf(
            R.id.widget_line_0, R.id.widget_line_1, R.id.widget_line_2, R.id.widget_line_3,
            R.id.widget_line_4, R.id.widget_line_5, R.id.widget_line_6, R.id.widget_line_7,
        )
    }
}
