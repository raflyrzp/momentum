package dev.momentum.momentum

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONArray

/**
 * Widget "Hari Ini". Hanya menampilkan data yang dikirim dari Dart
 * (lib/services/home_widget_service.dart); mencentang kebiasaan memicu callback
 * Dart di latar belakang, sehingga seluruh logika XP/streak tetap di Flutter.
 */
class MomentumWidget : GlanceAppWidget() {

  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent { Content(context, currentState()) }
  }

  private data class Item(val id: Int, val name: String, val done: Boolean, val streak: Int)

  private fun readItems(state: HomeWidgetGlanceState): List<Item> {
    val prefs = state.preferences
    val today = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date())
    // Data dari hari sebelumnya: daftar masih berguna, tetapi status selesainya tidak.
    val stale = prefs.getString("today_day", null) != today
    return try {
      val array = JSONArray(prefs.getString("today_json", "[]") ?: "[]")
      List(array.length()) { i ->
        val o = array.getJSONObject(i)
        Item(
            id = o.getInt("id"),
            name = o.getString("name"),
            done = !stale && o.optBoolean("done"),
            streak = o.optInt("streak"),
        )
      }
    } catch (e: Exception) {
      emptyList()
    }
  }

  @Composable
  private fun Content(context: Context, state: HomeWidgetGlanceState) {
    val items = readItems(state)
    val doneCount = items.count { it.done }

    Column(
        modifier =
            GlanceModifier.fillMaxSize()
                .background(Background)
                .cornerRadius(16.dp)
                .padding(12.dp)
                .clickable(onClick = actionStartActivity<MainActivity>(context))
    ) {
      Row(
          modifier = GlanceModifier.fillMaxWidth().padding(horizontal = 4.dp),
          verticalAlignment = Alignment.CenterVertically,
      ) {
        Text(
            "Hari Ini",
            style = TextStyle(color = Snow, fontSize = 15.sp, fontWeight = FontWeight.Bold),
            modifier = GlanceModifier.defaultWeight(),
        )
        Text(
            "$doneCount/${items.size}",
            style = TextStyle(color = Slate, fontSize = 13.sp, fontWeight = FontWeight.Medium),
        )
      }
      Spacer(GlanceModifier.height(8.dp))

      if (items.isEmpty()) {
        Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center) {
          Text(
              "Belum ada kebiasaan untuk hari ini",
              style = TextStyle(color = Slate, fontSize = 13.sp),
          )
        }
      } else {
        LazyColumn { items(items.size) { index -> HabitRow(items[index]) } }
      }
    }
  }

  @Composable
  private fun HabitRow(item: Item) {
    val rowModifier =
        GlanceModifier.fillMaxWidth()
            .background(if (item.done) SurfaceDone else Surface)
            .cornerRadius(12.dp)
            .padding(horizontal = 12.dp, vertical = 10.dp)

    Box(modifier = GlanceModifier.fillMaxWidth().padding(vertical = 3.dp)) {
      Row(
          // Kebiasaan yang sudah selesai tidak bisa diketuk lagi dari widget,
          // supaya tidak terurungkan secara tidak sengaja.
          modifier =
              if (item.done) rowModifier
              else
                  rowModifier.clickable(
                      onClick =
                          actionRunCallback<CompleteHabitAction>(
                              actionParametersOf(HabitIdKey to item.id)
                          )
                  ),
          verticalAlignment = Alignment.CenterVertically,
      ) {
        Box(
            modifier =
                GlanceModifier.size(22.dp)
                    .background(if (item.done) Emerald else Outline)
                    .cornerRadius(11.dp),
            contentAlignment = Alignment.Center,
        ) {
          if (item.done) {
            Text(
                "✓",
                style =
                    TextStyle(color = Background, fontSize = 13.sp, fontWeight = FontWeight.Bold),
            )
          }
        }
        Spacer(GlanceModifier.width(10.dp))
        Text(
            item.name,
            maxLines = 1,
            style =
                TextStyle(
                    color = if (item.done) Slate else Snow,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                ),
            modifier = GlanceModifier.defaultWeight(),
        )
        if (item.streak > 0) {
          Text(
              "${item.streak}",
              style = TextStyle(color = Amber, fontSize = 13.sp, fontWeight = FontWeight.Bold),
          )
        }
      }
    }
  }

  companion object {
    val HabitIdKey = ActionParameters.Key<Int>("habitId")

    private val Background = ColorProvider(Color(0xFF0F1115))
    private val Surface = ColorProvider(Color(0xFF181B22))
    private val SurfaceDone = ColorProvider(Color(0xFF16332C))
    private val Outline = ColorProvider(Color(0xFF2F3542))
    private val Emerald = ColorProvider(Color(0xFF10B981))
    private val Amber = ColorProvider(Color(0xFFF59E0B))
    private val Snow = ColorProvider(Color(0xFFF8FAFC))
    private val Slate = ColorProvider(Color(0xFF94A3B8))
  }
}

/** Meneruskan ketukan ke Dart: `momentum://complete?id=<habitId>`. */
class CompleteHabitAction : ActionCallback {
  override suspend fun onAction(
      context: Context,
      glanceId: GlanceId,
      parameters: ActionParameters,
  ) {
    val id = parameters[MomentumWidget.HabitIdKey] ?: return
    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("momentum://complete?id=$id"))
        .send()
  }
}
