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

    void SyncLevels(long dst_chart, string name) {
        int levels = (int)ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELS);
        ObjectSetInteger(dst_chart, name, OBJPROP_LEVELS, levels);
        for(int i=0; i<levels; i++) {
            ObjectSetDouble(dst_chart, name, OBJPROP_LEVELVALUE, i, ObjectGetDouble(m_src_chart_id, name, OBJPROP_LEVELVALUE, i));
            ObjectSetInteger(dst_chart, name, OBJPROP_LEVELCOLOR, i, ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELCOLOR, i));
            ObjectSetInteger(dst_chart, name, OBJPROP_LEVELSTYLE, i, ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELSTYLE, i));
            ObjectSetInteger(dst_chart, name, OBJPROP_LEVELWIDTH, i, ObjectGetInteger(m_src_chart_id, name, OBJPROP_LEVELWIDTH, i));
            ObjectSetString(dst_chart, name, OBJPROP_LEVELTEXT, i, ObjectGetString(m_src_chart_id, name, OBJPROP_LEVELTEXT, i));
        }
    }

public:
    CContext7_Replicator() : m_src_chart_id(ChartID()), m_symbol(_Symbol) {}

    void ProcessEvent(const int id, const string &sparam) {
        if(id == CHARTEVENT_OBJECT_CREATE || id == CHARTEVENT_OBJECT_CHANGE || id == CHARTEVENT_OBJECT_DRAG) {
            Replicate(sparam, false);
        } else if(id == CHARTEVENT_OBJECT_DELETE) {
            Replicate(sparam, true);
        }
    }

    void Replicate(string name, bool is_delete) {
        if (is_delete) {
             long target_chart = ChartFirst();
             while(target_chart != -1) {
                 if(target_chart != m_src_chart_id && ChartSymbol(target_chart) == m_symbol) {
                     ObjectDelete(target_chart, name);
                     ChartRedraw(target_chart);
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
                     ObjectCreate(target_chart, name, type, 0, 0, 0);
                }

                for(int p=0; p<points; p++) {
                    ObjectSetInteger(target_chart, name, OBJPROP_TIME, p, ObjectGetInteger(m_src_chart_id, name, OBJPROP_TIME, p));
                    ObjectSetDouble(target_chart, name, OBJPROP_PRICE, p, ObjectGetDouble(m_src_chart_id, name, OBJPROP_PRICE, p));
                }

                ObjectSetInteger(target_chart, name, OBJPROP_COLOR, ObjectGetInteger(m_src_chart_id, name, OBJPROP_COLOR));
                ObjectSetInteger(target_chart, name, OBJPROP_STYLE, ObjectGetInteger(m_src_chart_id, name, OBJPROP_STYLE));
                ObjectSetInteger(target_chart, name, OBJPROP_WIDTH, ObjectGetInteger(m_src_chart_id, name, OBJPROP_WIDTH));
                ObjectSetInteger(target_chart, name, OBJPROP_BACK, ObjectGetInteger(m_src_chart_id, name, OBJPROP_BACK));
                ObjectSetInteger(target_chart, name, OBJPROP_ZORDER, ObjectGetInteger(m_src_chart_id, name, OBJPROP_ZORDER));

                if(type == OBJ_TREND || type == OBJ_FIBO || type == OBJ_STDDEVCHANNEL) {
                     ObjectSetInteger(target_chart, name, OBJPROP_RAY_RIGHT, ObjectGetInteger(m_src_chart_id, name, OBJPROP_RAY_RIGHT));
                }
                
                if(type == OBJ_RECTANGLE || type == OBJ_TRIANGLE) {
                     ObjectSetInteger(target_chart, name, OBJPROP_FILL, ObjectGetInteger(m_src_chart_id, name, OBJPROP_FILL));
                }

                if(type == OBJ_FIBO || type == OBJ_STDDEVCHANNEL) {
                     SyncLevels(target_chart, name);
                }
                
                if(type == OBJ_STDDEVCHANNEL) {
                     ObjectSetDouble(target_chart, name, OBJPROP_DEVIATION, ObjectGetDouble(m_src_chart_id, name, OBJPROP_DEVIATION));
                }

                ChartRedraw(target_chart);
            }
            target_chart = ChartNext(target_chart);
        }
    }
};