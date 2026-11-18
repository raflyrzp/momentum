package dev.momentum.momentum

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class MomentumWidgetReceiver : HomeWidgetGlanceWidgetReceiver<MomentumWidget>() {
  override val glanceAppWidget = MomentumWidget()
}
