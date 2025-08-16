//+------------------------------------------------------------------+
//|                                               UIManager.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// UI Constants
#define UI_PANEL_NAME        "GoldenCandlePanel"
#define UI_BACKGROUND_COLOR  clrWhite
#define UI_TEXT_COLOR        clrBlack
#define UI_BUTTON_COLOR      C'200,200,200'
#define UI_PANEL_WIDTH       200
#define UI_PANEL_HEIGHT      300
#define UI_BUTTON_HEIGHT     25
#define UI_SPACING           5

//+------------------------------------------------------------------+
//| User Interface Manager Class                                       |
//+------------------------------------------------------------------+
class CUIManager {
private:
    string         m_symbol;
    int           m_window;
    bool          m_initialized;
    
    // Panel elements
    string         m_panelName;
    string         m_lotSizeInput;
    string         m_levelDisplay;
    string         m_statusDisplay;
    string         m_pauseButton;
    string         m_skipButton;
    
    // Internal handlers
    void          CreatePanel();
    void          CreateInputs();
    void          CreateButtons();
    void          CreateDisplays();
    
    // Element positioning
    int           GetNextY(int &currentY, int height);
    
public:
                  CUIManager();
                 ~CUIManager();
    
    // Initialization
    bool          Init(string symbol);
    
    // UI Updates
    void          UpdateLevel(int level);
    void          UpdateStatus(string status);
    void          UpdateLotSize(double lots);
    
    // UI State
    double        GetLotSize();
    bool          IsPaused();
    
    // Event handlers
    bool          OnChartEvent(const int id, const long &lparam,
                             const double &dparam, const string &sparam);
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CUIManager::CUIManager() {
    m_symbol = NULL;
    m_window = 0;
    m_initialized = false;
    
    m_panelName = UI_PANEL_NAME;
    m_lotSizeInput = m_panelName + "_LotSize";
    m_levelDisplay = m_panelName + "_Level";
    m_statusDisplay = m_panelName + "_Status";
    m_pauseButton = m_panelName + "_Pause";
    m_skipButton = m_panelName + "_Skip";
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CUIManager::~CUIManager() {
    ObjectDelete(m_panelName);
    ObjectDelete(m_lotSizeInput);
    ObjectDelete(m_levelDisplay);
    ObjectDelete(m_statusDisplay);
    ObjectDelete(m_pauseButton);
    ObjectDelete(m_skipButton);
}

//+------------------------------------------------------------------+
//| Initialize the UI Manager                                          |
//+------------------------------------------------------------------+
bool CUIManager::Init(string symbol) {
    if(symbol == "") return false;
    
    m_symbol = symbol;
    m_window = 0;
    
    CreatePanel();
    CreateInputs();
    CreateButtons();
    CreateDisplays();
    
    m_initialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Create main UI panel                                              |
//+------------------------------------------------------------------+
void CUIManager::CreatePanel() {
    ObjectCreate(0, m_panelName, OBJ_RECTANGLE_LABEL, m_window, 0, 0);
    ObjectSet(m_panelName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSet(m_panelName, OBJPROP_XDISTANCE, UI_PANEL_WIDTH);
    ObjectSet(m_panelName, OBJPROP_YDISTANCE, 0);
    ObjectSet(m_panelName, OBJPROP_XSIZE, UI_PANEL_WIDTH);
    ObjectSet(m_panelName, OBJPROP_YSIZE, UI_PANEL_HEIGHT);
    ObjectSet(m_panelName, OBJPROP_BGCOLOR, UI_BACKGROUND_COLOR);
    ObjectSet(m_panelName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSet(m_panelName, OBJPROP_COLOR, UI_TEXT_COLOR);
}

//+------------------------------------------------------------------+
//| Create input controls                                             |
//+------------------------------------------------------------------+
void CUIManager::CreateInputs() {
    int y = UI_SPACING;
    
    // Lot size input
    ObjectCreate(0, m_lotSizeInput, OBJ_EDIT, m_window, 0, 0);
    ObjectSet(m_lotSizeInput, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSet(m_lotSizeInput, OBJPROP_XDISTANCE, UI_PANEL_WIDTH - UI_SPACING);
    ObjectSet(m_lotSizeInput, OBJPROP_YDISTANCE, GetNextY(y, UI_BUTTON_HEIGHT));
    ObjectSet(m_lotSizeInput, OBJPROP_XSIZE, UI_PANEL_WIDTH - 2*UI_SPACING);
    ObjectSet(m_lotSizeInput, OBJPROP_YSIZE, UI_BUTTON_HEIGHT);
    ObjectSetText(m_lotSizeInput, "0.01");
}

//+------------------------------------------------------------------+
//| Create button controls                                            |
//+------------------------------------------------------------------+
void CUIManager::CreateButtons() {
    int y = UI_SPACING + UI_BUTTON_HEIGHT + UI_SPACING;
    
    // Pause button
    ObjectCreate(0, m_pauseButton, OBJ_BUTTON, m_window, 0, 0);
    ObjectSet(m_pauseButton, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSet(m_pauseButton, OBJPROP_XDISTANCE, UI_PANEL_WIDTH - UI_SPACING);
    ObjectSet(m_pauseButton, OBJPROP_YDISTANCE, GetNextY(y, UI_BUTTON_HEIGHT));
    ObjectSet(m_pauseButton, OBJPROP_XSIZE, UI_PANEL_WIDTH - 2*UI_SPACING);
    ObjectSet(m_pauseButton, OBJPROP_YSIZE, UI_BUTTON_HEIGHT);
    ObjectSetText(m_pauseButton, "Pause");
    ObjectSet(m_pauseButton, OBJPROP_BGCOLOR, UI_BUTTON_COLOR);
    
    // Skip level button
    ObjectCreate(0, m_skipButton, OBJ_BUTTON, m_window, 0, 0);
    ObjectSet(m_skipButton, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSet(m_skipButton, OBJPROP_XDISTANCE, UI_PANEL_WIDTH - UI_SPACING);
    ObjectSet(m_skipButton, OBJPROP_YDISTANCE, GetNextY(y, UI_BUTTON_HEIGHT));
    ObjectSet(m_skipButton, OBJPROP_XSIZE, UI_PANEL_WIDTH - 2*UI_SPACING);
    ObjectSet(m_skipButton, OBJPROP_YSIZE, UI_BUTTON_HEIGHT);
    ObjectSetText(m_skipButton, "Skip Level");
    ObjectSet(m_skipButton, OBJPROP_BGCOLOR, UI_BUTTON_COLOR);
}

//+------------------------------------------------------------------+
//| Create display elements                                           |
//+------------------------------------------------------------------+
void CUIManager::CreateDisplays() {
    int y = UI_SPACING + 2*(UI_BUTTON_HEIGHT + UI_SPACING);
    
    // Level display
    ObjectCreate(0, m_levelDisplay, OBJ_LABEL, m_window, 0, 0);
    ObjectSet(m_levelDisplay, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSet(m_levelDisplay, OBJPROP_XDISTANCE, UI_PANEL_WIDTH - UI_SPACING);
    ObjectSet(m_levelDisplay, OBJPROP_YDISTANCE, GetNextY(y, 20));
    ObjectSetText(m_levelDisplay, "Level: 1");
    
    // Status display
    ObjectCreate(0, m_statusDisplay, OBJ_LABEL, m_window, 0, 0);
    ObjectSet(m_statusDisplay, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSet(m_statusDisplay, OBJPROP_XDISTANCE, UI_PANEL_WIDTH - UI_SPACING);
    ObjectSet(m_statusDisplay, OBJPROP_YDISTANCE, GetNextY(y, 20));
    ObjectSetText(m_statusDisplay, "Status: Ready");
}

//+------------------------------------------------------------------+
//| Calculate next Y position                                         |
//+------------------------------------------------------------------+
int CUIManager::GetNextY(int &currentY, int height) {
    int y = currentY;
    currentY += height + UI_SPACING;
    return y;
}

//+------------------------------------------------------------------+
//| Update current level display                                      |
//+------------------------------------------------------------------+
void CUIManager::UpdateLevel(int level) {
    if(!m_initialized) return;
    ObjectSetText(m_levelDisplay, "Level: " + IntegerToString(level));
}

//+------------------------------------------------------------------+
//| Update status display                                             |
//+------------------------------------------------------------------+
void CUIManager::UpdateStatus(string status) {
    if(!m_initialized) return;
    ObjectSetText(m_statusDisplay, "Status: " + status);
}

//+------------------------------------------------------------------+
//| Update lot size input                                             |
//+------------------------------------------------------------------+
void CUIManager::UpdateLotSize(double lots) {
    if(!m_initialized) return;
    ObjectSetText(m_lotSizeInput, DoubleToString(lots, 2));
}

//+------------------------------------------------------------------+
//| Get current lot size                                              |
//+------------------------------------------------------------------+
double CUIManager::GetLotSize() {
    if(!m_initialized) return 0.01;
    return StringToDouble(ObjectGetString(0, m_lotSizeInput, OBJPROP_TEXT));
}

//+------------------------------------------------------------------+
//| Check if system is paused                                         |
//+------------------------------------------------------------------+
bool CUIManager::IsPaused() {
    if(!m_initialized) return false;
    return ObjectGetString(0, m_pauseButton, OBJPROP_TEXT) == "Resume";
}

//+------------------------------------------------------------------+
//| Handle chart events                                               |
//+------------------------------------------------------------------+
bool CUIManager::OnChartEvent(const int id, const long &lparam,
                           const double &dparam, const string &sparam) {
    if(!m_initialized) return false;
    
    // Handle button clicks
    if(id == CHARTEVENT_OBJECT_CLICK) {
        if(sparam == m_pauseButton) {
            string text = ObjectGetString(0, m_pauseButton, OBJPROP_TEXT);
            ObjectSetText(m_pauseButton, text == "Pause" ? "Resume" : "Pause");
            return true;
        }
        else if(sparam == m_skipButton) {
            // Skip level logic handled by main EA
            return true;
        }
    }
    
    return false;
}
