//+------------------------------------------------------------------+
//|                                                         EA.mq4   |
//|                       Golden Candle EA V3 (Starter)             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, YourName"
#property link      "https://www.mql5.com"
#property version   "3.00"
#property strict

//+------------------------------------------------------------------+
//| Import the DLL function                                          |
//+------------------------------------------------------------------+
#import "PopupDLL.dll"
int ShowBootstrapDialog();
#import

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Call the DLL on init for demo
  int result = ShowBootstrapDialog();
  Print("Dialog result: ", result);
  return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }
//+------------------------------------------------------------------+
void OnTick()
  {
   // No trading logic for this demo
  }
//+------------------------------------------------------------------+
