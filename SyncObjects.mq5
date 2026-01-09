//+------------------------------------------------------------------+
//|                                              SyncObjects.mq5     |
//| Sincronizador de Objetos - Wrapper Context7                      |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0
#property copyright "Wayre Solutions"
#property version   "1.01"

#include "Context7_Logic.mqh"

CContext7_Replicator *g_replicator;

int OnInit() {
    g_replicator = new CContext7_Replicator();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    if(CheckPointer(g_replicator) == POINTER_DYNAMIC) delete g_replicator;
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[],
                const double &close[], const long &tick_volume[], const long &volume[],
                const int &spread[]) {
    return rates_total;
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    if(g_replicator != NULL) g_replicator.ProcessEvent(id, sparam);
}