package com.talia.quran.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import com.talia.quran.MainActivity
import com.talia.quran.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class TaliaHomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val json = snapshotJson(context)
        val arabic = isArabic(context)
        val rows = WidgetSnapshotFormatter.format(json, labels(context), arabic, System.currentTimeMillis())
        for (widgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(widgetId, views(context, rows))
        }
    }

    private fun views(context: Context, rows: WidgetRows): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.talia_home_widget)
        setRow(views, R.id.widget_prayer, rows.prayerLine, link(context, "prayer"))
        setRow(views, R.id.widget_review, rows.reviewLine, link(context, "review"))
        setRow(views, R.id.widget_wird, rows.wirdLine, link(context, "khatmah"))
        views.setViewVisibility(R.id.widget_empty, if (rows.empty) View.VISIBLE else View.GONE)
        views.setOnClickPendingIntent(R.id.widget_empty, link(context, ""))
        return views
    }

    private fun setRow(
        views: RemoteViews,
        id: Int,
        text: String?,
        pendingIntent: PendingIntent,
    ) {
        views.setViewVisibility(id, if (text == null) View.GONE else View.VISIBLE)
        if (text != null) views.setTextViewText(id, text)
        views.setOnClickPendingIntent(id, pendingIntent)
    }

    // Each URI identifies its own immutable intent. The plugin supplies the
    // Android 14/15 activity-launch options as well as the launch action.
    private fun link(context: Context, destination: String): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("talia://widget/$destination"),
        )

    private fun isArabic(context: Context): Boolean {
        val configuration = context.resources.configuration
        val locale = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            configuration.locales[0]
        } else {
            @Suppress("DEPRECATION")
            configuration.locale
        }
        return locale.language == "ar"
    }

    private fun labels(context: Context) = WidgetSnapshotLabels(
        prayerNames = mapOf(
            "fajr" to context.getString(R.string.widget_prayer_fajr),
            "dhuhr" to context.getString(R.string.widget_prayer_dhuhr),
            "asr" to context.getString(R.string.widget_prayer_asr),
            "maghrib" to context.getString(R.string.widget_prayer_maghrib),
            "isha" to context.getString(R.string.widget_prayer_isha),
        ),
        reviewLine = { count ->
            context.resources.getQuantityString(R.plurals.widget_reviews_due, count, count)
        },
        wirdLine = { name, done, total ->
            context.getString(R.string.widget_wird_progress, name, done, total)
        },
    )

    private fun snapshotJson(context: Context): String? = try {
        HomeWidgetPlugin.getData(context).getString(snapshotKey, null)
    } catch (_: ClassCastException) {
        null
    }

    private companion object {
        const val snapshotKey = "talia_widget_snapshot_v1"
    }
}
