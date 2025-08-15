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
int ShowInputDialog(uchar &buffer[], int bufferLen);
#import

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Call the DLL on init for demo
  uchar buffer[256];
  ArrayInitialize(buffer, 0);
  int res = ShowInputDialog(buffer, 256);
  string userInput = CharArrayToString(buffer);
  if(res == 1)
  {
    Comment("OK clicked. Input: ", userInput);
    Print("OK clicked. Input: ", userInput);
  }
  else
  {
    Comment("Cancel clicked.");
    Print("Cancel clicked.");
  }
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
