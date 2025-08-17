//+------------------------------------------------------------------+
//| ChartUtils.mqh - Chart drawing and helper utilities              |
//+------------------------------------------------------------------+
#ifndef __CHARTUTILS_MQH__
#define __CHARTUTILS_MQH__

class ChartUtils {
public:
    static void RemoveLadderLabels() {
        for(int i=1; i<=7; ++i) {
            string label = "LadderLabel_" + IntegerToString(i);
            if(ObjectFind(0, label) >= 0) ObjectDelete(0, label);
        }
    }
    static void DrawLadderLabels(double entry, double step, bool isBuy) {
        RemoveLadderLabels();
        for(int i=1; i<=7; ++i) {
            double price = isBuy ? entry + i*step : entry - i*step;
            string label = "LadderLabel_" + IntegerToString(i);
            ObjectCreate(0, label, OBJ_TEXT, 0, Time[0], price);
            ObjectSetText(label, IntegerToString(i), 10, "Arial", clrBlue);
        }
    }
    static void RemoveEntrySLLines() {
        string names[2] = {"EntryLine", "SLLine"};
        for(int i=0; i<2; ++i) {
            if(ObjectFind(0, names[i]) >= 0) ObjectDelete(0, names[i]);
            string label = names[i] + "_Label";
            if(ObjectFind(0, label) >= 0) ObjectDelete(0, label);
        }
    }
    static void DrawEntrySLLines(double entry, double sl) {
        RemoveEntrySLLines();
        ObjectCreate(0, "EntryLine", OBJ_HLINE, 0, 0, entry);
        ObjectSetInteger(0, "EntryLine", OBJPROP_COLOR, clrGreen);
        ObjectSetInteger(0, "EntryLine", OBJPROP_WIDTH, 2);
        ObjectCreate(0, "EntryLine_Label", OBJ_TEXT, 0, Time[0], entry);
        ObjectSetText("EntryLine_Label", "Entry", 10, "Arial", clrGreen);
        ObjectCreate(0, "SLLine", OBJ_HLINE, 0, 0, sl);
        ObjectSetInteger(0, "SLLine", OBJPROP_COLOR, clrRed);
        ObjectSetInteger(0, "SLLine", OBJPROP_WIDTH, 2);
        ObjectCreate(0, "SLLine_Label", OBJ_TEXT, 0, Time[0], sl);
        ObjectSetText("SLLine_Label", "SL", 10, "Arial", clrRed);
    }
    static void RemoveLadderLines() {
        for(int i=0; i<=7; ++i) {
            string name = "Ladder_" + IntegerToString(i);
            if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
        }
    }
    static void DrawLadderLines(double entry, double step, bool isBuy) {
        color ladderColor = isBuy ? clrBlue : clrRed;
        for(int i=0; i<=7; ++i) {
            string name = "Ladder_" + IntegerToString(i);
            double price = isBuy ? entry + i*step : entry - i*step;
            ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
            ObjectSetInteger(0, name, OBJPROP_COLOR, ladderColor);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, i==0 ? 2 : 1);
        }
    }
};

#endif // __CHARTUTILS_MQH__
