//+------------------------------------------------------------------+
//|                                         ReferenceLineManager.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

#include "GoldenCandle.mqh"

// Reference line configuration
#define RL_LINE_NAME     "GoldenCandle_RefLine"
#define RL_LINE_COLOR    clrOrange
#define RL_LINE_STYLE    STYLE_DASH
#define RL_LINE_WIDTH    2

//+------------------------------------------------------------------+
//| Class to manage reference lines on the chart                       |
//+------------------------------------------------------------------+
class CReferenceLineManager {
private:
    string            m_symbol;         // Symbol being traded
    CGoldenCandle*   m_validator;      // Golden Candle validator
    int              m_window;          // Chart window
    
    // Line management
    bool             CreateLine(double price);
    bool             UpdateLine(double price);
    void             DeleteLine();
    
    // Internal validation
    bool             ValidatePrice(double price);
    
public:
                     CReferenceLineManager();
                    ~CReferenceLineManager();
    
    // Initialization
    bool             Init(string symbol, CGoldenCandle* validator);
    
    // Reference line operations
    bool             SetReferenceLine(double signalPrice, bool isBuy);
    bool             UpdateReferenceLine(double newPrice);
    bool             RemoveReferenceLine();
    
    // Status checks
    bool             HasReferenceLine();
    double           GetReferencePrice();
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CReferenceLineManager::CReferenceLineManager() {
    m_symbol = NULL;
    m_validator = NULL;
    m_window = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CReferenceLineManager::~CReferenceLineManager() {
    RemoveReferenceLine();
}

//+------------------------------------------------------------------+
//| Initialize the Reference Line Manager                              |
//+------------------------------------------------------------------+
bool CReferenceLineManager::Init(string symbol, CGoldenCandle* validator) {
    if(symbol == "" || validator == NULL) return false;
    
    m_symbol = symbol;
    m_validator = validator;
    m_window = WindowFind("Main");
    
    return true;
}

//+------------------------------------------------------------------+
//| Create a new reference line                                        |
//+------------------------------------------------------------------+
bool CReferenceLineManager::CreateLine(double price) {
    if(!ValidatePrice(price)) return false;
    
    // Create the horizontal line
    if(!ObjectCreate(0, RL_LINE_NAME, OBJ_HLINE, m_window, 0, price)) {
        Print("Failed to create reference line: ", GetLastError());
        return false;
    }
    
    // Set line properties
    ObjectSet(RL_LINE_NAME, OBJPROP_COLOR, RL_LINE_COLOR);
    ObjectSet(RL_LINE_NAME, OBJPROP_STYLE, RL_LINE_STYLE);
    ObjectSet(RL_LINE_NAME, OBJPROP_WIDTH, RL_LINE_WIDTH);
    ObjectSet(RL_LINE_NAME, OBJPROP_BACK, true);
    
    return true;
}

//+------------------------------------------------------------------+
//| Update existing reference line                                     |
//+------------------------------------------------------------------+
bool CReferenceLineManager::UpdateLine(double price) {
    if(!ValidatePrice(price)) return false;
    
    if(ObjectFind(RL_LINE_NAME) < 0) {
        return CreateLine(price);
    }
    
    return ObjectMove(RL_LINE_NAME, 0, 0, price);
}

//+------------------------------------------------------------------+
//| Delete existing reference line                                     |
//+------------------------------------------------------------------+
void CReferenceLineManager::DeleteLine() {
    ObjectDelete(RL_LINE_NAME);
}

//+------------------------------------------------------------------+
//| Validate price level                                              |
//+------------------------------------------------------------------+
bool CReferenceLineManager::ValidatePrice(double price) {
    return price > 0 && !MathIsValidNumber(price);
}

//+------------------------------------------------------------------+
//| Set new reference line based on signal                            |
//+------------------------------------------------------------------+
bool CReferenceLineManager::SetReferenceLine(double signalPrice, bool isBuy) {
    if(!m_validator) return false;
    
    // Calculate reference line price
    double refPrice = m_validator.GetReferenceLinePrice(signalPrice, isBuy);
    
    // Remove existing line
    RemoveReferenceLine();
    
    // Create new line
    return CreateLine(refPrice);
}

//+------------------------------------------------------------------+
//| Update existing reference line                                     |
//+------------------------------------------------------------------+
bool CReferenceLineManager::UpdateReferenceLine(double newPrice) {
    if(!m_validator) return false;
    return UpdateLine(newPrice);
}

//+------------------------------------------------------------------+
//| Remove existing reference line                                     |
//+------------------------------------------------------------------+
bool CReferenceLineManager::RemoveReferenceLine() {
    DeleteLine();
    return true;
}

//+------------------------------------------------------------------+
//| Check if reference line exists                                     |
//+------------------------------------------------------------------+
bool CReferenceLineManager::HasReferenceLine() {
    return ObjectFind(RL_LINE_NAME) >= 0;
}

//+------------------------------------------------------------------+
//| Get current reference line price                                   |
//+------------------------------------------------------------------+
double CReferenceLineManager::GetReferencePrice() {
    if(!HasReferenceLine()) return 0;
    return ObjectGet(RL_LINE_NAME, OBJPROP_PRICE1);
}
