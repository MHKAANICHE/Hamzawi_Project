//+------------------------------------------------------------------+
//|                                         ChartVisualizer.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// Visual Settings
#define ENTRY_MARKER_COLOR    clrDodgerBlue
#define SL_MARKER_COLOR       clrRed
#define TP_MARKER_COLOR       clrGreen
#define LINE_STYLE_ENTRY      STYLE_SOLID
#define LINE_STYLE_SL         STYLE_DOT
#define LINE_STYLE_TP         STYLE_DASH
#define LINE_WIDTH_NORMAL     1
#define LINE_WIDTH_ACTIVE     2

// Label Settings
#define LABEL_CORNER          CORNER_RIGHT_UPPER
#define LABEL_FONT           "Arial"
#define LABEL_FONTSIZE       10
#define LABEL_COLOR          clrBlack

//+------------------------------------------------------------------+
//| Chart Visualization Manager Class                                  |
//+------------------------------------------------------------------+
class CChartVisualizer {
private:
    string         m_symbol;
    int           m_window;
    bool          m_initialized;
    
    // Object naming
    string         m_prefix;
    int           m_objectCounter;
    
    // Position markers
    string         m_entryLine;
    string         m_stopLossLine;
    string         m_takeProfitLines[];
    
    // Information labels
    string         m_infoLabels[];
    int           m_labelCount;
    
    // Internal methods
    string         GenerateObjectName(string type);
    void          CleanupObjects(string prefix);
    bool          CreateLabel(string &name, string text, int x, int y, 
                            color clr = LABEL_COLOR);
    
public:
                  CChartVisualizer();
                 ~CChartVisualizer();
    
    // Initialization
    bool          Init(string symbol);
    
    // Position visualization
    bool          ShowEntryMarker(double price, bool isBuy);
    bool          ShowStopLoss(double price);
    bool          ShowTakeProfit(double price, int level);
    void          UpdatePositionLines(double entry, double sl, 
                                    const double &tpLevels[]);
    
    // Information display
    bool          AddInfoLabel(string text, int x, int y, color clr = LABEL_COLOR);
    bool          UpdateInfoLabel(int index, string text);
    void          ClearInfoLabels();
    
    // Trade status
    void          ShowTradeStatus(string status, bool isActive);
    void          ShowLevelProgress(int current, int target);
    void          ShowProfitInfo(double current, double target);
    
    // Cleanup
    void          RemoveAllObjects();
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CChartVisualizer::CChartVisualizer() {
    m_symbol = NULL;
    m_window = 0;
    m_initialized = false;
    m_prefix = "GC_Visual_";
    m_objectCounter = 0;
    m_labelCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CChartVisualizer::~CChartVisualizer() {
    RemoveAllObjects();
}

//+------------------------------------------------------------------+
//| Initialize visualizer                                              |
//+------------------------------------------------------------------+
bool CChartVisualizer::Init(string symbol) {
    if(symbol == "") return false;
    
    m_symbol = symbol;
    m_window = 0;
    m_initialized = true;
    
    return true;
}

//+------------------------------------------------------------------+
//| Generate unique object name                                        |
//+------------------------------------------------------------------+
string CChartVisualizer::GenerateObjectName(string type) {
    m_objectCounter++;
    return m_prefix + type + "_" + IntegerToString(m_objectCounter);
}

//+------------------------------------------------------------------+
//| Remove objects with specific prefix                                |
//+------------------------------------------------------------------+
void CChartVisualizer::CleanupObjects(string prefix) {
    ObjectsDeleteAll(0, prefix);
}

//+------------------------------------------------------------------+
//| Create information label                                          |
//+------------------------------------------------------------------+
bool CChartVisualizer::CreateLabel(string &name, string text, int x, int y,
                                 color clr = LABEL_COLOR) {
    name = GenerateObjectName("Label");
    
    if(!ObjectCreate(0, name, OBJ_LABEL, m_window, 0, 0)) {
        Print("Failed to create label: ", GetLastError());
        return false;
    }
    
    ObjectSet(name, OBJPROP_CORNER, LABEL_CORNER);
    ObjectSet(name, OBJPROP_XDISTANCE, x);
    ObjectSet(name, OBJPROP_YDISTANCE, y);
    ObjectSetText(name, text, LABEL_FONTSIZE, LABEL_FONT, clr);
    
    return true;
}

//+------------------------------------------------------------------+
//| Show entry marker                                                 |
//+------------------------------------------------------------------+
bool CChartVisualizer::ShowEntryMarker(double price, bool isBuy) {
    if(!m_initialized || price <= 0) return false;
    
    m_entryLine = GenerateObjectName("Entry");
    
    if(!ObjectCreate(0, m_entryLine, OBJ_HLINE, m_window, 0, price)) {
        Print("Failed to create entry line: ", GetLastError());
        return false;
    }
    
    ObjectSet(m_entryLine, OBJPROP_COLOR, ENTRY_MARKER_COLOR);
    ObjectSet(m_entryLine, OBJPROP_STYLE, LINE_STYLE_ENTRY);
    ObjectSet(m_entryLine, OBJPROP_WIDTH, LINE_WIDTH_ACTIVE);
    
    return true;
}

//+------------------------------------------------------------------+
//| Show stop loss line                                               |
//+------------------------------------------------------------------+
bool CChartVisualizer::ShowStopLoss(double price) {
    if(!m_initialized || price <= 0) return false;
    
    m_stopLossLine = GenerateObjectName("StopLoss");
    
    if(!ObjectCreate(0, m_stopLossLine, OBJ_HLINE, m_window, 0, price)) {
        Print("Failed to create stop loss line: ", GetLastError());
        return false;
    }
    
    ObjectSet(m_stopLossLine, OBJPROP_COLOR, SL_MARKER_COLOR);
    ObjectSet(m_stopLossLine, OBJPROP_STYLE, LINE_STYLE_SL);
    ObjectSet(m_stopLossLine, OBJPROP_WIDTH, LINE_WIDTH_NORMAL);
    
    return true;
}

//+------------------------------------------------------------------+
//| Show take profit line                                             |
//+------------------------------------------------------------------+
bool CChartVisualizer::ShowTakeProfit(double price, int level) {
    if(!m_initialized || price <= 0) return false;
    
    string tpLine = GenerateObjectName("TakeProfit_" + IntegerToString(level));
    
    if(!ObjectCreate(0, tpLine, OBJ_HLINE, m_window, 0, price)) {
        Print("Failed to create take profit line: ", GetLastError());
        return false;
    }
    
    ObjectSet(tpLine, OBJPROP_COLOR, TP_MARKER_COLOR);
    ObjectSet(tpLine, OBJPROP_STYLE, LINE_STYLE_TP);
    ObjectSet(tpLine, OBJPROP_WIDTH, LINE_WIDTH_NORMAL);
    
    ArrayResize(m_takeProfitLines, ArraySize(m_takeProfitLines) + 1);
    m_takeProfitLines[ArraySize(m_takeProfitLines) - 1] = tpLine;
    
    return true;
}

//+------------------------------------------------------------------+
//| Update all position lines                                         |
//+------------------------------------------------------------------+
void CChartVisualizer::UpdatePositionLines(double entry, double sl,
                                         const double &tpLevels[]) {
    if(!m_initialized) return;
    
    // Remove existing lines
    RemoveAllObjects();
    
    // Create new lines
    ShowEntryMarker(entry, true);
    ShowStopLoss(sl);
    
    for(int i = 0; i < ArraySize(tpLevels); i++) {
        ShowTakeProfit(tpLevels[i], i + 1);
    }
}

//+------------------------------------------------------------------+
//| Add information label                                             |
//+------------------------------------------------------------------+
bool CChartVisualizer::AddInfoLabel(string text, int x, int y, 
                                  color clr = LABEL_COLOR) {
    if(!m_initialized) return false;
    
    string labelName;
    if(!CreateLabel(labelName, text, x, y, clr)) return false;
    
    ArrayResize(m_infoLabels, m_labelCount + 1);
    m_infoLabels[m_labelCount] = labelName;
    m_labelCount++;
    
    return true;
}

//+------------------------------------------------------------------+
//| Update information label                                          |
//+------------------------------------------------------------------+
bool CChartVisualizer::UpdateInfoLabel(int index, string text) {
    if(!m_initialized || index < 0 || index >= m_labelCount) return false;
    
    return ObjectSetText(m_infoLabels[index], text);
}

//+------------------------------------------------------------------+
//| Clear all information labels                                      |
//+------------------------------------------------------------------+
void CChartVisualizer::ClearInfoLabels() {
    for(int i = 0; i < m_labelCount; i++) {
        ObjectDelete(0, m_infoLabels[i]);
    }
    
    ArrayResize(m_infoLabels, 0);
    m_labelCount = 0;
}

//+------------------------------------------------------------------+
//| Show trade status                                                 |
//+------------------------------------------------------------------+
void CChartVisualizer::ShowTradeStatus(string status, bool isActive) {
    if(!m_initialized) return;
    
    color statusColor = isActive ? clrGreen : clrGray;
    
    // Update or create status label
    if(m_labelCount > 0) {
        UpdateInfoLabel(0, status);
        ObjectSet(m_infoLabels[0], OBJPROP_COLOR, statusColor);
    }
    else {
        AddInfoLabel(status, 10, 10, statusColor);
    }
}

//+------------------------------------------------------------------+
//| Show level progress                                               |
//+------------------------------------------------------------------+
void CChartVisualizer::ShowLevelProgress(int current, int target) {
    if(!m_initialized) return;
    
    string progress = "Level: " + IntegerToString(current) + "/" + 
                     IntegerToString(target);
    
    if(m_labelCount > 1) {
        UpdateInfoLabel(1, progress);
    }
    else {
        AddInfoLabel(progress, 10, 30);
    }
}

//+------------------------------------------------------------------+
//| Show profit information                                           |
//+------------------------------------------------------------------+
void CChartVisualizer::ShowProfitInfo(double current, double target) {
    if(!m_initialized) return;
    
    string profit = "Profit: " + DoubleToString(current, 2) + "/" +
                   DoubleToString(target, 2);
    
    color profitColor = current >= 0 ? clrGreen : clrRed;
    
    if(m_labelCount > 2) {
        UpdateInfoLabel(2, profit);
        ObjectSet(m_infoLabels[2], OBJPROP_COLOR, profitColor);
    }
    else {
        AddInfoLabel(profit, 10, 50, profitColor);
    }
}

//+------------------------------------------------------------------+
//| Remove all visual objects                                         |
//+------------------------------------------------------------------+
void CChartVisualizer::RemoveAllObjects() {
    if(!m_initialized) return;
    
    // Remove position lines
    ObjectDelete(0, m_entryLine);
    ObjectDelete(0, m_stopLossLine);
    
    for(int i = 0; i < ArraySize(m_takeProfitLines); i++) {
        ObjectDelete(0, m_takeProfitLines[i]);
    }
    ArrayResize(m_takeProfitLines, 0);
    
    // Remove labels
    ClearInfoLabels();
    
    // Reset object counter
    m_objectCounter = 0;
}
