//+------------------------------------------------------------------+
//|                                                   RunTests.mq4 |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property version   "3.0"
#property strict

#include "../Tests/ComponentTests.mqh"

//+------------------------------------------------------------------+
//| Script program start function                                      |
//+------------------------------------------------------------------+
void OnStart() {
    Print("\nStarting GoldenCandle EA v3.0 Test Suite");
    Print("=====================================\n");
    
    // Create and run component tests
    CComponentTests* tests = new CComponentTests(true);
    tests.RunAllTests();
    delete tests;
    
    Print("\nTest Suite Complete");
    Print("=====================================");
}
