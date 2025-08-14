// GoldenCandleEA_Interface.h
// Function signatures for MT4 <-> DLL communication

#ifdef __cplusplus
extern "C" {
#endif

// GUI
void ShowSettingsDialog();
void ShowTradeMonitor();
void ShowAlert(const char* message);

// Technical/Strategy
int CheckGoldenCandle(double high, double low, double minSize, double maxSize);
int CheckEMACross(double* prices, int len);

// Money Management
void UpdateLotProgression(int result);
double GetNextLotSize();

// Alerts
void SendUserAlert(const char* message);

#ifdef __cplusplus
}
#endif
