package com.talia.quran.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import com.talia.quran.MainActivity
import com.talia.quran.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Locale

class TaliaHomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        render(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        render(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    internal fun preview(context: Context): RemoteViews {
        val json = snapshotJson(context)
        val language = WidgetSnapshotFormatter.language(json) ?: deviceLanguage(context)
        val arabic = language == "ar"
        val localized = localizedContext(context, language)
        val rows = WidgetSnapshotFormatter.format(
            json,
            labels(localized),
            arabic,
            System.currentTimeMillis(),
        )
        return sizedViews(context, localized, rows, arabic, WidgetSize.MEDIUM)
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val json = snapshotJson(context)
        // The widget follows the app language written into the snapshot and
        // falls back to the device language (cleared or older snapshots).
        val language = WidgetSnapshotFormatter.language(json) ?: deviceLanguage(context)
        val arabic = language == "ar"
        val localized = localizedContext(context, language)
        val rows = WidgetSnapshotFormatter.format(json, labels(localized), arabic, System.currentTimeMillis())
        val portrait = context.resources.configuration.orientation != Configuration.ORIENTATION_LANDSCAPE
        for (widgetId in appWidgetIds) {
            val rendered = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // The launcher picks the layout as the user resizes, so the
                // content changes without another process wake.
                responsiveViews(context, localized, rows, arabic)
            } else {
                val options = appWidgetManager.getAppWidgetOptions(widgetId)
                val (width, height) = WidgetLayoutPolicy.span(
                    options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0),
                    options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0),
                    options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0),
                    options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0),
                    portrait,
                )
                sizedViews(
                    context,
                    localized,
                    rows,
                    arabic,
                    WidgetLayoutPolicy.sizeFor(width, height),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, rendered)
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun responsiveViews(
        context: Context,
        localized: Context,
        rows: WidgetRows,
        arabic: Boolean,
    ): RemoteViews = RemoteViews(
        mapOf(
            SizeF(
                WidgetLayoutPolicy.SMALL_MIN_WIDTH.toFloat(),
                WidgetLayoutPolicy.SMALL_MIN_HEIGHT.toFloat(),
            ) to sizedViews(context, localized, rows, arabic, WidgetSize.SMALL),
            SizeF(
                WidgetLayoutPolicy.MEDIUM_MIN_WIDTH.toFloat(),
                WidgetLayoutPolicy.MEDIUM_MIN_HEIGHT.toFloat(),
            ) to sizedViews(context, localized, rows, arabic, WidgetSize.MEDIUM),
            SizeF(
                WidgetLayoutPolicy.LARGE_MIN_WIDTH.toFloat(),
                WidgetLayoutPolicy.LARGE_MIN_HEIGHT.toFloat(),
            ) to sizedViews(context, localized, rows, arabic, WidgetSize.LARGE),
        ),
    )

    private fun sizedViews(
        context: Context,
        localized: Context,
        rows: WidgetRows,
        arabic: Boolean,
        size: WidgetSize,
    ): RemoteViews = views(context, localized, WidgetLayoutPolicy.apply(rows, size), arabic)

    // The app does not declare supportsRtl, so layoutDirection and textAlignment
    // are ignored. Arabic therefore uses a separate layout with absolute
    // right gravity (absolute gravity works without RTL support).
    private fun views(context: Context, localized: Context, rows: WidgetRows, arabic: Boolean): RemoteViews {
        val layout = if (arabic) R.layout.talia_home_widget_rtl else R.layout.talia_home_widget
        val views = RemoteViews(context.packageName, layout)
        setRow(views, R.id.widget_prayer, rows.prayerLine, link(context, "prayer"))
        setRow(views, R.id.widget_review, rows.reviewLine, link(context, "review"))
        setRow(views, R.id.widget_wird, rows.wirdLine, link(context, rows.wirdDestination))
        val done = rows.wirdDone
        val total = rows.wirdTotal
        val detail = rows.wirdRange != null && done != null && total != null
        views.setViewVisibility(R.id.widget_wird_range, if (rows.wirdRange != null) View.VISIBLE else View.GONE)
        if (rows.wirdRange != null) views.setTextViewText(R.id.widget_wird_range, rows.wirdRange)
        views.setViewVisibility(R.id.widget_wird_progress, if (detail) View.VISIBLE else View.GONE)
        if (detail && done != null && total != null) {
            views.setProgressBar(
                R.id.widget_wird_progress,
                total.coerceAtLeast(1),
                done.coerceIn(0, total),
                false,
            )
        }
        views.setViewVisibility(R.id.widget_wird_action, if (rows.showWirdAction) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.widget_wird_action, localized.getString(R.string.widget_wird_action))
        views.setOnClickPendingIntent(R.id.widget_wird_action, link(context, "wird"))
        val showEmpty = rows.prayerLine == null && rows.reviewLine == null && rows.wirdLine == null
        views.setViewVisibility(R.id.widget_empty, if (showEmpty) View.VISIBLE else View.GONE)
        val emptyText = when {
            rows.stale -> R.string.widget_stale
            rows.adultNoData -> R.string.widget_empty_adult
            else -> R.string.widget_empty_hint
        }
        views.setTextViewText(R.id.widget_empty, localized.getString(emptyText))
        views.setOnClickPendingIntent(R.id.widget_empty, link(context, ""))
        applyColors(views)
        return views
    }

    // API 31 resolves these in the launcher, so night mode and system colors
    // update without a new snapshot. Older releases use the night-qualified
    // colors baked in when the widget is redrawn.
    private fun applyColors(views: RemoteViews) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        views.setColor(R.id.widget_root, "setBackgroundColor", R.color.widget_background)
        views.setColor(R.id.widget_prayer, "setTextColor", R.color.widget_text_primary)
        for (id in intArrayOf(
            R.id.widget_review,
            R.id.widget_wird,
            R.id.widget_wird_range,
            R.id.widget_empty,
        )) {
            views.setColor(id, "setTextColor", R.color.widget_text_secondary)
        }
        views.setColor(R.id.widget_wird_action, "setTextColor", R.color.widget_background)
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

    private fun deviceLanguage(context: Context): String {
        val configuration = context.resources.configuration
        val locale = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            configuration.locales[0]
        } else {
            @Suppress("DEPRECATION")
            configuration.locale
        }
        return locale.language
    }

    private fun localizedContext(context: Context, language: String): Context {
        if (language != "ar" && language != "en") return context
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale(language))
        return context.createConfigurationContext(configuration)
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
        reviewsDone = context.getString(R.string.widget_reviews_done),
        noKhatmahPlan = context.getString(R.string.widget_no_khatmah),
        prayerUnset = context.getString(R.string.widget_prayer_unset),
        wirdRange = { from, to ->
            context.getString(R.string.widget_wird_range, from, to)
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
