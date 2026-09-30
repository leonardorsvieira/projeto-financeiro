package br.com.meubolso.meubolso

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MeuBolsoWidgetProvider : HomeWidgetProvider() {
    private val linhas = intArrayOf(R.id.widget_venc_1, R.id.widget_venc_2, R.id.widget_venc_3)
    private val datas = intArrayOf(R.id.widget_venc_1_data, R.id.widget_venc_2_data, R.id.widget_venc_3_data)
    private val nomes = intArrayOf(R.id.widget_venc_1_nome, R.id.widget_venc_2_nome, R.id.widget_venc_3_nome)
    private val valores = intArrayOf(R.id.widget_venc_1_valor, R.id.widget_venc_2_valor, R.id.widget_venc_3_valor)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val saldo = widgetData.getString("widget_saldo", "R$ —") ?: "R$ —"
                val qtd = (widgetData.getString("widget_venc_qtd", "0") ?: "0").toIntOrNull() ?: 0

                setTextViewText(R.id.widget_saldo, saldo)
                for (i in 0 until 3) {
                    val n = i + 1
                    if (n <= qtd) {
                        setTextViewText(datas[i], widgetData.getString("widget_venc_${n}_data", "") ?: "")
                        setTextViewText(nomes[i], widgetData.getString("widget_venc_${n}_nome", "") ?: "")
                        setTextViewText(valores[i], widgetData.getString("widget_venc_${n}_valor", "") ?: "")
                        setViewVisibility(linhas[i], View.VISIBLE)
                    } else {
                        setViewVisibility(linhas[i], View.GONE)
                    }
                }
                setViewVisibility(R.id.widget_vazio, if (qtd == 0) View.VISIBLE else View.GONE)

                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
