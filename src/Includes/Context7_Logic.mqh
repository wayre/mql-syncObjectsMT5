//+------------------------------------------------------------------+
//|                                              Context7_Logic.mqh |
//| Arquitetura: Context7 - Lógica de Replicação de Objetos          |
//+------------------------------------------------------------------+
#property copyright "Wayre Solutions"
#property version "1.01"
#property strict

class CContext7_Replicator {
  private:
    long m_src_chart_id;
    string m_symbol;

    bool IsTypeSupported(ENUM_OBJECT type) {
        switch (type) {
        case OBJ_VLINE:
        case OBJ_HLINE:
        case OBJ_TREND:
        case OBJ_ARROWED_LINE:
        case OBJ_TRIANGLE:
        case OBJ_RECTANGLE:
        case OBJ_FIBO:
        case OBJ_STDDEVCHANNEL:
        case OBJ_ARROW_BUY:
        case OBJ_ARROW_SELL:
            return true;
        default:
            return false;
        }
    }

  public:
    bool IsNameAllowed(string name) {
        string prefixes[] = {"M1", "M2", "M5", "M15", "H1", "H4", "Daily", "Weekly", "#"};
        for (int i = 0; i < ArraySize(prefixes); i++) {
            if (StringFind(name, prefixes[i]) == 0)
                return true;
        }
        return false;
    }

  private:
    void SyncLevels(long dst_chart, string name) {
        //--- Determina se é um caso especial de auto-formatação
        bool isSpecial = (StringFind(name, "#") == 0 && (ENUM_OBJECT)ObjectGetInteger(m_src_chart_id, name, OBJPROP_TYPE) == OBJ_FIBO);

        int levels_src = (int)ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELS);
        int target_count = isSpecial ? 41 : levels_src;

        //--- 1. Sincroniza Quantidade (Se for especial, corrige o original também)
        if (isSpecial && levels_src != target_count)
            ObjectSetInteger(m_src_chart_id, name, OBJPROP_LEVELS, target_count);

        if (ObjectGetInteger(dst_chart, name, OBJPROP_LEVELS) != target_count)
            ObjectSetInteger(dst_chart, name, OBJPROP_LEVELS, target_count);

        //--- 2. Loop único para Sincronizar Valores e Propriedades Visuais
        for (int i = 0; i < target_count; i++) {
            double val;
            if (isSpecial) {
                val = (double)(i - 20); // Regra: -20 até 20
                // Auto-ajuste no original para manter consistência
                if (MathAbs(ObjectGetDouble(m_src_chart_id, name, OBJPROP_LEVELVALUE, i) - val) > 0.000001)
                    ObjectSetDouble(m_src_chart_id, name, OBJPROP_LEVELVALUE, i, val);
            } else {
                val = ObjectGetDouble(m_src_chart_id, name, OBJPROP_LEVELVALUE, i);
            }

            // Sincroniza Valor no Destino
            if (MathAbs(ObjectGetDouble(dst_chart, name, OBJPROP_LEVELVALUE, i) - val) > 0.000001)
                ObjectSetDouble(dst_chart, name, OBJPROP_LEVELVALUE, i, val);

            //--- 3. Propriedades Comuns (Sempre Origem -> Destino)
            color col_src = (color)ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELCOLOR, i);
            if ((color)ObjectGetInteger(dst_chart, name, OBJPROP_LEVELCOLOR, i) != col_src)
                ObjectSetInteger(dst_chart, name, OBJPROP_LEVELCOLOR, i, col_src);

            ENUM_LINE_STYLE style_src = (ENUM_LINE_STYLE)ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELSTYLE, i);
            if ((ENUM_LINE_STYLE)ObjectGetInteger(dst_chart, name, OBJPROP_LEVELSTYLE, i) != style_src)
                ObjectSetInteger(dst_chart, name, OBJPROP_LEVELSTYLE, i, style_src);

            int width_src = (int)ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELWIDTH, i);
            if ((int)ObjectGetInteger(dst_chart, name, OBJPROP_LEVELWIDTH, i) != width_src)
                ObjectSetInteger(dst_chart, name, OBJPROP_LEVELWIDTH, i, width_src);

            string text_src = ObjectGetString(m_src_chart_id, name, OBJPROP_LEVELTEXT, i);
            if (ObjectGetString(dst_chart, name, OBJPROP_LEVELTEXT, i) != text_src)
                ObjectSetString(dst_chart, name, OBJPROP_LEVELTEXT, i, text_src);
        }
    }

    void ShowObject(long target_chart, long time_pos, double ratio) {
        if (time_pos > 0) {
            ENUM_TIMEFRAMES period = ChartPeriod(target_chart);
            int bar_idx = iBarShift(m_symbol, period, (datetime)time_pos);
            if (bar_idx >= 0) {
                // Desativa AutoScroll
                ChartSetInteger(target_chart, CHART_AUTOSCROLL, false);

                // Obtém barras visíveis no destino para manter a proporção
                int target_vis = (int)ChartGetInteger(target_chart, CHART_VISIBLE_BARS);

                // Cálculo para ChartNavigate(CHART_END, ...)
                // ratio = (LeftBar - ObjBar) / VisBars
                // LeftBarTarget = ObjBarTarget + (ratio * VisBarsTarget)
                // RightBarTarget = LeftBarTarget - VisBarsTarget
                // Pos = -RightBarTarget = VisBarsTarget - LeftBarTarget

                // Ajuste do Deslocamento do Gráfico (Shift)
                double shift_size = ChartGetDouble(target_chart, CHART_SHIFT_SIZE);
                bool shift_enabled = ChartGetInteger(target_chart, CHART_SHIFT);
                int shift_bars = 0;

                if (shift_enabled && shift_size > 0)
                    shift_bars = (int)(target_vis * shift_size / 100.0);

                int target_left = bar_idx + (int)(ratio * target_vis);
                int nav_pos = target_vis - target_left;

                // Compensa o deslocamento do gráfico subtraindo as barras vazias
                nav_pos -= shift_bars;

                ChartNavigate(target_chart, CHART_END, nav_pos);
                ChartRedraw(target_chart);
            }
        }
    }

  public:
    CContext7_Replicator() : m_src_chart_id(ChartID()), m_symbol(_Symbol) {
    }

    bool Init() {
        bool res = true;
        res &= ChartSetInteger(m_src_chart_id, CHART_EVENT_OBJECT_CREATE, true);
        res &= ChartSetInteger(m_src_chart_id, CHART_EVENT_OBJECT_DELETE, true);
        if (!res)
            Print("SYNC_ERROR: Failed to enable chart events. Error: ", GetLastError());
        return res;
    }

    void OnRemoval(const int reason) {
        if (reason == REASON_REMOVE) {
            long target_chart = ChartFirst();
            while (target_chart != -1) {
                if (target_chart != m_src_chart_id && ChartSymbol(target_chart) == m_symbol) {
                    ChartIndicatorDelete(target_chart, 0, "SyncObjects");
                }
                target_chart = ChartNext(target_chart);
            }
        }
    }

    void ProcessEvent(const int id, const string& sparam) {
        if (id != CHARTEVENT_OBJECT_CREATE && id != CHARTEVENT_OBJECT_CHANGE &&
            id != CHARTEVENT_OBJECT_DRAG && id != CHARTEVENT_OBJECT_DELETE)
            return;

        if (!IsNameAllowed(sparam)) {
            if (id == CHARTEVENT_OBJECT_DELETE || id == CHARTEVENT_OBJECT_CREATE)
                return;
        }

        if (id == CHARTEVENT_OBJECT_CREATE || id == CHARTEVENT_OBJECT_CHANGE || id == CHARTEVENT_OBJECT_DRAG) {
            Replicate(sparam, false);

            // Sync View (Scroll) logic driven by ProcessEvent
            // Only sync view if the object is selected (User interaction) to prevent echo loops
            if (ObjectGetInteger(m_src_chart_id, sparam, OBJPROP_SELECTED)) {
                ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(m_src_chart_id, sparam, OBJPROP_TYPE);
                if (IsTypeSupported(type)) {
                    long time_0 = ObjectGetInteger(m_src_chart_id, sparam, OBJPROP_TIME, 0);

                    //--- Calcula PROPORÇÃO da tela (0.0 = Esquerda, 1.0 = Direita)
                    int src_bar_idx = iBarShift(m_symbol, _Period, (datetime)time_0);
                    int src_first_vis = (int)ChartGetInteger(m_src_chart_id, CHART_FIRST_VISIBLE_BAR);
                    int src_vis_bars = (int)ChartGetInteger(m_src_chart_id, CHART_VISIBLE_BARS);

                    // Proteção contra divisão por zero
                    if (src_vis_bars < 1)
                        src_vis_bars = 1;

                    // Ratio: quão longe da borda ESQUERDA o objeto está (em %)
                    // Se objeto está na esq (index = first), ratio = 0.
                    // Se objeto está na dir (index = first - vis), ratio = 1 (aprox).
                    double ratio = (double)(src_first_vis - src_bar_idx) / (double)src_vis_bars;

                    long target_chart = ChartFirst();
                    while (target_chart != -1) {
                        if (target_chart != m_src_chart_id && ChartSymbol(target_chart) == m_symbol) {
                            ShowObject(target_chart, time_0, ratio);
                        }
                        target_chart = ChartNext(target_chart);
                    }
                }
            }

        } else if (id == CHARTEVENT_OBJECT_DELETE) {
            Replicate(sparam, true);
        }
    }

    void Replicate(string name, bool is_delete) {
        if (is_delete) {
            long target_chart = ChartFirst();
            while (target_chart != -1) {
                if (target_chart != m_src_chart_id && ChartSymbol(target_chart) == m_symbol) {
                    if (ObjectFind(target_chart, name) >= 0) {
                        bool res = ObjectDelete(target_chart, name);
                        if (!res)
                            Alert("SYNC_ERROR: Failed to delete ", name, " Error: ", GetLastError());
                        ChartRedraw(target_chart);
                    }
                }
                target_chart = ChartNext(target_chart);
            }
            return;
        }

        if (ObjectFind(m_src_chart_id, name) < 0)
            return;

        ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(m_src_chart_id, name, OBJPROP_TYPE);
        if (!IsTypeSupported(type))
            return;

        long target_chart = ChartFirst();
        while (target_chart != -1) {
            if (target_chart != m_src_chart_id && ChartSymbol(target_chart) == m_symbol) {

                int points = 0;
                switch (type) {
                case OBJ_VLINE:
                case OBJ_HLINE:
                    points = 1;
                    break;
                case OBJ_TRIANGLE:
                    points = 3;
                    break;
                default:
                    points = 2;
                }

                if (ObjectFind(target_chart, name) < 0) {
                    if (!ObjectCreate(target_chart, name, type, 0, 0, 0)) {
                        Print("SYNC_ERROR: Failed to create ", name, " on chart ", target_chart);
                        continue;
                    }
                    // Force visibility and selectability immediately after creation
                    ObjectSetInteger(target_chart, name, OBJPROP_HIDDEN, false);
                    ObjectSetInteger(target_chart, name, OBJPROP_SELECTABLE, true);
                    ObjectSetInteger(target_chart, name, OBJPROP_SELECTED, false);

                    // Show Object (Auto-Scroll) - Moved to ProcessEvent
                }

                for (int p = 0; p < points; p++) {
                    long time_src = ObjectGetInteger(m_src_chart_id, name, OBJPROP_TIME, p);
                    long time_dst = ObjectGetInteger(target_chart, name, OBJPROP_TIME, p);
                    if (time_src != time_dst) {
                        ObjectSetInteger(target_chart, name, OBJPROP_TIME, p, time_src);
                        // ShowObject moved to ProcessEvent
                    }

                    double price_src = ObjectGetDouble(m_src_chart_id, name, OBJPROP_PRICE, p);
                    double price_dst = ObjectGetDouble(target_chart, name, OBJPROP_PRICE, p);
                    if (MathAbs(price_src - price_dst) > Point())
                        ObjectSetDouble(target_chart, name, OBJPROP_PRICE, p, price_src);
                }

                // --- Sync Visual Properties ---
                if (ObjectGetInteger(target_chart, name, OBJPROP_HIDDEN))
                    ObjectSetInteger(target_chart, name, OBJPROP_HIDDEN, false);
                if (!ObjectGetInteger(target_chart, name, OBJPROP_SELECTABLE))
                    ObjectSetInteger(target_chart, name, OBJPROP_SELECTABLE, true);

                color color_src = (color)ObjectGetInteger(m_src_chart_id, name, OBJPROP_COLOR);
                color color_dst = (color)ObjectGetInteger(target_chart, name, OBJPROP_COLOR);
                if (color_src != color_dst)
                    ObjectSetInteger(target_chart, name, OBJPROP_COLOR, color_src);

                ENUM_LINE_STYLE style_src = (ENUM_LINE_STYLE)ObjectGetInteger(m_src_chart_id, name, OBJPROP_STYLE);
                ENUM_LINE_STYLE style_dst = (ENUM_LINE_STYLE)ObjectGetInteger(target_chart, name, OBJPROP_STYLE);
                if (style_src != style_dst)
                    ObjectSetInteger(target_chart, name, OBJPROP_STYLE, style_src);

                int width_src = (int)ObjectGetInteger(m_src_chart_id, name, OBJPROP_WIDTH);
                int width_dst = (int)ObjectGetInteger(target_chart, name, OBJPROP_WIDTH);
                if (width_src != width_dst)
                    ObjectSetInteger(target_chart, name, OBJPROP_WIDTH, width_src);

                bool back_src = (bool)ObjectGetInteger(m_src_chart_id, name, OBJPROP_BACK);
                bool back_dst = (bool)ObjectGetInteger(target_chart, name, OBJPROP_BACK);
                if (back_src != back_dst)
                    ObjectSetInteger(target_chart, name, OBJPROP_BACK, back_src);

                long zorder_src = ObjectGetInteger(m_src_chart_id, name, OBJPROP_ZORDER);
                long zorder_dst = ObjectGetInteger(target_chart, name, OBJPROP_ZORDER);
                if (zorder_src != zorder_dst)
                    ObjectSetInteger(target_chart, name, OBJPROP_ZORDER, zorder_src);

                if (type == OBJ_TREND || type == OBJ_FIBO || type == OBJ_STDDEVCHANNEL) {
                    bool ray_src = (bool)ObjectGetInteger(m_src_chart_id, name, OBJPROP_RAY_RIGHT);
                    bool ray_dst = (bool)ObjectGetInteger(target_chart, name, OBJPROP_RAY_RIGHT);
                    if (ray_src != ray_dst)
                        ObjectSetInteger(target_chart, name, OBJPROP_RAY_RIGHT, ray_src);
                }

                if (type == OBJ_RECTANGLE || type == OBJ_TRIANGLE) {
                    bool fill_src = (bool)ObjectGetInteger(m_src_chart_id, name, OBJPROP_FILL);
                    bool fill_dst = (bool)ObjectGetInteger(target_chart, name, OBJPROP_FILL);
                    if (fill_src != fill_dst)
                        ObjectSetInteger(target_chart, name, OBJPROP_FILL, fill_src);
                }

                if (type == OBJ_FIBO || type == OBJ_STDDEVCHANNEL) {
                    SyncLevels(target_chart, name);
                }

                if (type == OBJ_STDDEVCHANNEL) {
                    double dev_src = ObjectGetDouble(m_src_chart_id, name, OBJPROP_DEVIATION);
                    double dev_dst = ObjectGetDouble(target_chart, name, OBJPROP_DEVIATION);
                    if (MathAbs(dev_src - dev_dst) > 0.0000001)
                        ObjectSetDouble(target_chart, name, OBJPROP_DEVIATION, dev_src);
                }

                // --- Sync Timeframes ---
                long tf_src = ObjectGetInteger(m_src_chart_id, name, OBJPROP_TIMEFRAMES);
                long tf_dst = ObjectGetInteger(target_chart, name, OBJPROP_TIMEFRAMES);
                if (tf_src != tf_dst)
                    ObjectSetInteger(target_chart, name, OBJPROP_TIMEFRAMES, tf_src);

                ChartRedraw(target_chart);
            }
            target_chart = ChartNext(target_chart);
        }
    }
};