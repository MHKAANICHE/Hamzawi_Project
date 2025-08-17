//+------------------------------------------------------------------+
//|                                         GoldenCandleTests.mq4 |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

#include "../Include/GoldenCandle.mqh"
#include "../Include/ReferenceLineManager.mqh"

//+------------------------------------------------------------------+
//| Test Golden Candle Validation                                      |
//+------------------------------------------------------------------+
bool TestGoldenCandleValidation() {
    CGoldenCandle gc;
    if(!gc.Init(Symbol())) {
        PrintFormat("Failed to initialize Golden Candle validator");
        return false;
    }
    
    // Test 1: Valid candle size
    bool test1 = gc.ValidateCandle(1.0000, 1.1000, 1.0000, 1.0500);
    PrintFormat("Test 1 - Valid candle size: %s", test1 ? "PASS" : "FAIL");
    
    // Test 2: Invalid candle (too small)
    bool test2 = !gc.ValidateCandle(1.0000, 1.0010, 1.0000, 1.0005);
    PrintFormat("Test 2 - Invalid small candle: %s", test2 ? "PASS" : "FAIL");
    
    // Test 3: Entry level calculation (Buy)
    double entryLevel = gc.CalculateEntryLevel(1.0000, true);
    bool test3 = MathAbs(entryLevel - 1.0350) < 0.0001;
    PrintFormat("Test 3 - Buy entry level: %s", test3 ? "PASS" : "FAIL");
    
    // Test 4: Entry level calculation (Sell)
    entryLevel = gc.CalculateEntryLevel(1.0000, false);
    bool test4 = MathAbs(entryLevel - 0.9650) < 0.0001;
    PrintFormat("Test 4 - Sell entry level: %s", test4 ? "PASS" : "FAIL");
    
    // Test 5: Entry level validation
    bool test5 = gc.ValidateEntryLevel(1.0350, 1.0360);
    PrintFormat("Test 5 - Entry level validation: %s", test5 ? "PASS" : "FAIL");
    
    return test1 && test2 && test3 && test4 && test5;
}

//+------------------------------------------------------------------+
//| Test Reference Line Management                                     |
//+------------------------------------------------------------------+
bool TestReferenceLineManager() {
    CGoldenCandle gc;
    if(!gc.Init(Symbol())) return false;
    
    CReferenceLineManager rlm;
    if(!rlm.Init(Symbol(), &gc)) {
        PrintFormat("Failed to initialize Reference Line Manager");
        return false;
    }
    
    // Test 1: Create reference line
    bool test1 = rlm.SetReferenceLine(1.0000, true);
    PrintFormat("Test 1 - Create reference line: %s", test1 ? "PASS" : "FAIL");
    
    // Test 2: Check reference line exists
    bool test2 = rlm.HasReferenceLine();
    PrintFormat("Test 2 - Reference line exists: %s", test2 ? "PASS" : "FAIL");
    
    // Test 3: Update reference line
    bool test3 = rlm.UpdateReferenceLine(1.0500);
    PrintFormat("Test 3 - Update reference line: %s", test3 ? "PASS" : "FAIL");
    
    // Test 4: Get reference price
    double refPrice = rlm.GetReferencePrice();
    bool test4 = MathAbs(refPrice - 1.0500) < 0.0001;
    PrintFormat("Test 4 - Get reference price: %s", test4 ? "PASS" : "FAIL");
    
    // Test 5: Remove reference line
    bool test5 = rlm.RemoveReferenceLine() && !rlm.HasReferenceLine();
    PrintFormat("Test 5 - Remove reference line: %s", test5 ? "PASS" : "FAIL");
    
    return test1 && test2 && test3 && test4 && test5;
}

//+------------------------------------------------------------------+
//| Script program start function                                      |
//+------------------------------------------------------------------+
void OnStart() {
    PrintFormat("\n=== Starting Golden Candle System Tests ===\n");
    
    bool gcTests = TestGoldenCandleValidation();
    PrintFormat("\nGolden Candle Validation Tests: %s", gcTests ? "PASSED" : "FAILED");
    
    bool rlmTests = TestReferenceLineManager();
    PrintFormat("\nReference Line Manager Tests: %s", rlmTests ? "PASSED" : "FAILED");
    
    PrintFormat("\n=== Test Suite Complete ===\n");
}
