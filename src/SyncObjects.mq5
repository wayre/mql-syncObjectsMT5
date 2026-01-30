//+------------------------------------------------------------------+
//|                                              SyncObjects.mq5     |
//| Sincronizador de Objetos - Wrapper Context7                      |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property copyright "Wayre Solutions"
#property version "1.01"
#property indicator_buffers 1
#property indicator_plots 0
#property indicator_type1 DRAW_NONE

#include "Includes/Context7_Logic.mqh"

// ID do evento customizado para sincronização de objetos
#define EVENT_SYNC_OBJECT 1101

CContext7_Replicator* g_replicator;

int OnInit() {
    IndicatorSetString(INDICATOR_SHORTNAME, "SyncObjects");
    g_replicator = new CContext7_Replicator();
    if (CheckPointer(g_replicator) == POINTER_INVALID || !g_replicator.Init())
        return (INIT_FAILED);
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    if (CheckPointer(g_replicator) == POINTER_DYNAMIC) {
        g_replicator.OnRemoval(reason);
        delete g_replicator;
    }
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime& time[],
                const double& open[], const double& high[], const double& low[],
                const double& close[], const long& tick_volume[], const long& volume[],
                const int& spread[]) {
    return rates_total;
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) {
    if (g_replicator != NULL) {
        g_replicator.ProcessEvent(id, sparam);

        //--- Dispara evento customizado para TODOS os gráficos (Broadcast)
        if (id == CHARTEVENT_OBJECT_CREATE || id == CHARTEVENT_OBJECT_CHANGE || id == CHARTEVENT_OBJECT_DRAG) {
            if (g_replicator.IsNameAllowed(sparam)) {
                long target_chart = ChartFirst();
                while (target_chart != -1) {
                    // Envia para todos os gráficos do mesmo símbolo (incluindo o atual)
                    if (ChartSymbol(target_chart) == _Symbol) {
                        EventChartCustom(target_chart, EVENT_SYNC_OBJECT, 0, 0, sparam);
                    }
                    target_chart = ChartNext(target_chart);
                }
            }
        }
    }
}