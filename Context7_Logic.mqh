//+------------------------------------------------------------------+
//|                                              Context7_Logic.mqh |
//| Arquitetura: Context7 - Lógica de Replicação de Objetos          |
//+------------------------------------------------------------------+
#property copyright "Wayre Solutions"
#property version   "1.01"
#property strict

class CContext7_Replicator {
private:
    long     m_src_chart_id;
    string   m_symbol;

    bool IsTypeSupported(ENUM_OBJECT type) {
        switch(type) {
            case OBJ_VLINE: case OBJ_HLINE: case OBJ_TREND: 
            case OBJ_TRIANGLE: case OBJ_RECTANGLE: 
            case OBJ_FIBO: case OBJ_STDDEVCHANNEL: return true;
            default: return false;
        }
    }

    bool IsNameAllowed(string name) {
        string prefixes[] = {"M1", "M2", "M5", "M15", "H1", "H4", "Daily", "Weekly"};
        for(int i=0; i<ArraySize(prefixes); i++) {
            if(StringFind(name, prefixes[i]) == 0) return true;
        }
        return false;
    }

    void SyncLevels(long dst_chart, string name) {
        int levels_src = (int)ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELS);
        int levels_dst = (int)ObjectGetInteger(dst_chart, name, OBJPROP_LEVELS);
        
        if(levels_src != levels_dst) ObjectSetInteger(dst_chart, name, OBJPROP_LEVELS, levels_src);
        
        for(int i=0; i<levels_src; i++) {
            double val_src = ObjectGetDouble(m_src_chart_id, name, OBJPROP_LEVELVALUE, i);
            double val_dst = ObjectGetDouble(dst_chart, name, OBJPROP_LEVELVALUE, i);
            if(MathAbs(val_src - val_dst) > Point()) ObjectSetDouble(dst_chart, name, OBJPROP_LEVELVALUE, i, val_src);

            color col_src = (color)ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELCOLOR, i);
            color col_dst = (color)ObjectGetInteger(dst_chart, name, OBJPROP_LEVELCOLOR, i);
            if(col_src != col_dst) ObjectSetInteger(dst_chart, name, OBJPROP_LEVELCOLOR, i, col_src);

            ENUM_LINE_STYLE style_src = (ENUM_LINE_STYLE)ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELSTYLE, i);
            ENUM_LINE_STYLE style_dst = (ENUM_LINE_STYLE)ObjectGetInteger(dst_chart, name, OBJPROP_LEVELSTYLE, i);
            if(style_src != style_dst) ObjectSetInteger(dst_chart, name, OBJPROP_LEVELSTYLE, i, style_src);

            int width_src = (int)ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELWIDTH, i);
            int width_dst = (int)ObjectGetInteger(dst_chart, name, OBJPROP_LEVELWIDTH, i);
            if(width_src != width_dst) ObjectSetInteger(dst_chart, name, OBJPROP_LEVELWIDTH, i, width_src);

            string text_src = ObjectGetString(m_src_chart_id, name, OBJPROP_LEVELTEXT, i);
            string text_dst = ObjectGetString(dst_chart, name, OBJPROP_LEVELTEXT, i);
            if(text_src != text_dst) ObjectSetString(dst_chart, name, OBJPROP_LEVELTEXT, i, text_src);
        }
    }

public:
    CContext7_Replicator() : m_src_chart_id(ChartID()), m_symbol(_Symbol) {}

    void ProcessEvent(const int id, const string &sparam) {
        if(!IsNameAllowed(sparam)) {
            // Print("SYNC_DEBUG: Name not allowed: ", sparam);
            return;
        }

        if(id == CHARTEVENT_OBJECT_CREATE || id == CHARTEVENT_OBJECT_CHANGE || id == CHARTEVENT_OBJECT_DRAG) {
            Replicate(sparam, false);
        } else if(id == CHARTEVENT_OBJECT_DELETE) {
            Print("SYNC_DEBUG: Deletion Event detected for: ", sparam);
            Replicate(sparam, true);
        }
    }

    void Replicate(string name, bool is_delete) {
        if (is_delete) {
             long target_chart = ChartFirst();
             while(target_chart != -1) {
                 if(target_chart != m_src_chart_id && ChartSymbol(target_chart) == m_symbol) {
                     // Print("SYNC_DEBUG: Checking target chart ", target_chart, " for object ", name);
                     if(ObjectFind(target_chart, name) >= 0) {
                         Print("SYNC_DEBUG: Deleting ", name, " on chart ", target_chart);
                         bool res = ObjectDelete(target_chart, name);
                         if(!res) Print("SYNC_DEBUG: Failed to delete ", name, " Error: ", GetLastError());
                         ChartRedraw(target_chart);
                     }
                 }
                 target_chart = ChartNext(target_chart);
             }
             return;
        }

        if(ObjectFind(m_src_chart_id, name) < 0) return;

        ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(m_src_chart_id, name, OBJPROP_TYPE);
        if(!IsTypeSupported(type)) return;

        long target_chart = ChartFirst();
        while(target_chart != -1) {
            if(target_chart != m_src_chart_id && ChartSymbol(target_chart) == m_symbol) {
                
                int points = 0;
                switch(type) {
                    case OBJ_VLINE: case OBJ_HLINE: points = 1; break;
                    case OBJ_TRIANGLE: points = 3; break;
                    default: points = 2; 
                }
                
                if(ObjectFind(target_chart, name) < 0) {
                     if(!ObjectCreate(target_chart, name, type, 0, 0, 0)) {
                         Print("SYNC_ERROR: Failed to create ", name, " on chart ", target_chart);
                         continue;
                     }
                     // Force visibility and selectability immediately after creation
                     ObjectSetInteger(target_chart, name, OBJPROP_HIDDEN, false);
                     ObjectSetInteger(target_chart, name, OBJPROP_SELECTABLE, true);
                     ObjectSetInteger(target_chart, name, OBJPROP_SELECTED, false); 
                     
                     // Show Object (Auto-Scroll)
                     long time_0 = ObjectGetInteger(m_src_chart_id, name, OBJPROP_TIME, 0);
                     if(time_0 > 0) {
                         ENUM_TIMEFRAMES period = ChartPeriod(target_chart);
                         int bar_idx = iBarShift(m_symbol, period, (datetime)time_0);
                         if(bar_idx >= 0) {
                             ChartNavigate(target_chart, CHART_END, -bar_idx);
                         }
                     }
                }

                for(int p=0; p<points; p++) {
                    long time_src = ObjectGetInteger(m_src_chart_id, name, OBJPROP_TIME, p);
                    long time_dst = ObjectGetInteger(target_chart, name, OBJPROP_TIME, p);
                    if(time_src != time_dst) ObjectSetInteger(target_chart, name, OBJPROP_TIME, p, time_src);

                    double price_src = ObjectGetDouble(m_src_chart_id, name, OBJPROP_PRICE, p);
                    double price_dst = ObjectGetDouble(target_chart, name, OBJPROP_PRICE, p);
                    if(MathAbs(price_src - price_dst) > Point()) ObjectSetDouble(target_chart, name, OBJPROP_PRICE, p, price_src);
                }

                // --- Sync Visual Properties ---
                if(ObjectGetInteger(target_chart, name, OBJPROP_HIDDEN)) ObjectSetInteger(target_chart, name, OBJPROP_HIDDEN, false);
                if(!ObjectGetInteger(target_chart, name, OBJPROP_SELECTABLE)) ObjectSetInteger(target_chart, name, OBJPROP_SELECTABLE, true);

                color color_src = (color)ObjectGetInteger(m_src_chart_id, name, OBJPROP_COLOR);
                color color_dst = (color)ObjectGetInteger(target_chart, name, OBJPROP_COLOR);
                if(color_src != color_dst) ObjectSetInteger(target_chart, name, OBJPROP_COLOR, color_src);

                ENUM_LINE_STYLE style_src = (ENUM_LINE_STYLE)ObjectGetInteger(m_src_chart_id, name, OBJPROP_STYLE);
                ENUM_LINE_STYLE style_dst = (ENUM_LINE_STYLE)ObjectGetInteger(target_chart, name, OBJPROP_STYLE);
                if(style_src != style_dst) ObjectSetInteger(target_chart, name, OBJPROP_STYLE, style_src);

                int width_src = (int)ObjectGetInteger(m_src_chart_id, name, OBJPROP_WIDTH);
                int width_dst = (int)ObjectGetInteger(target_chart, name, OBJPROP_WIDTH);
                if(width_src != width_dst) ObjectSetInteger(target_chart, name, OBJPROP_WIDTH, width_src);

                bool back_src = (bool)ObjectGetInteger(m_src_chart_id, name, OBJPROP_BACK);
                bool back_dst = (bool)ObjectGetInteger(target_chart, name, OBJPROP_BACK);
                if(back_src != back_dst) ObjectSetInteger(target_chart, name, OBJPROP_BACK, back_src);

                long zorder_src = ObjectGetInteger(m_src_chart_id, name, OBJPROP_ZORDER);
                long zorder_dst = ObjectGetInteger(target_chart, name, OBJPROP_ZORDER);
                if(zorder_src != zorder_dst) ObjectSetInteger(target_chart, name, OBJPROP_ZORDER, zorder_src);

                if(type == OBJ_TREND || type == OBJ_FIBO || type == OBJ_STDDEVCHANNEL) {
                     bool ray_src = (bool)ObjectGetInteger(m_src_chart_id, name, OBJPROP_RAY_RIGHT);
                     bool ray_dst = (bool)ObjectGetInteger(target_chart, name, OBJPROP_RAY_RIGHT);
                     if(ray_src != ray_dst) ObjectSetInteger(target_chart, name, OBJPROP_RAY_RIGHT, ray_src);
                }
                
                if(type == OBJ_RECTANGLE || type == OBJ_TRIANGLE) {
                     bool fill_src = (bool)ObjectGetInteger(m_src_chart_id, name, OBJPROP_FILL);
                     bool fill_dst = (bool)ObjectGetInteger(target_chart, name, OBJPROP_FILL);
                     if(fill_src != fill_dst) ObjectSetInteger(target_chart, name, OBJPROP_FILL, fill_src);
                }

                if(type == OBJ_FIBO || type == OBJ_STDDEVCHANNEL) {
                     SyncLevels(target_chart, name);
                }
                
                if(type == OBJ_STDDEVCHANNEL) {
                     double dev_src = ObjectGetDouble(m_src_chart_id, name, OBJPROP_DEVIATION);
                     double dev_dst = ObjectGetDouble(target_chart, name, OBJPROP_DEVIATION);
                     if(MathAbs(dev_src - dev_dst) > 0.0000001) ObjectSetDouble(target_chart, name, OBJPROP_DEVIATION, dev_src);
                }

                // --- Sync Timeframes ---
                long tf_src = ObjectGetInteger(m_src_chart_id, name, OBJPROP_TIMEFRAMES);
                long tf_dst = ObjectGetInteger(target_chart, name, OBJPROP_TIMEFRAMES);
                if(tf_src != tf_dst) ObjectSetInteger(target_chart, name, OBJPROP_TIMEFRAMES, tf_src);

                ChartRedraw(target_chart);
            }
            target_chart = ChartNext(target_chart);
        }
    }
};