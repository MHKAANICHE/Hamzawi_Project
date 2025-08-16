# GoldenCandle EA Framework v3.0

## Overview

Version 3.0 of the GoldenCandle EA introduces a completely redesigned, modular framework that emphasizes reliability, maintainability, and performance. This document provides technical details about the framework's architecture and implementation.

## Framework Architecture

### Base Components

1. **StateManager (`StateManager.mqh`)**
   - Trading state management
   - Configuration persistence
   - Error handling
   - Performance metrics

2. **Constants (`Constants.mqh`)**
   - Trading constants
   - Default parameters
   - System limits
   - Error codes

3. **Enums (`Enums.mqh`)**
   - Trading states
   - Signal types
   - Market conditions
   - Order types

4. **Structures (`Structures.mqh`)**
   - Data structures
   - Configuration objects
   - Trading information
   - Statistics containers

### Technical Components

1. **SignalManager (`SignalManager.mqh`)**
   - Signal generation
   - Pattern recognition
   - Indicator management
   - Signal validation

2. **TradeManager (`TradeManager.mqh`)**
   - Order execution
   - Position management
   - Trade monitoring
   - Error handling

3. **MoneyManager (`MoneyManager.mqh`)**
   - Risk calculation
   - Position sizing
   - Account protection
   - Performance tracking

### Strategy Components

1. **StrategyBase (`StrategyBase.mqh`)**
   - Base strategy framework
   - Common functionality
   - Event handling
   - Data management

2. **GoldenCandleStrategy (`GoldenCandleStrategy.mqh`)**
   - Pattern implementation
   - Entry/exit rules
   - Signal processing
   - Parameter management

### Expert Advisor

**GoldenCandleEA (`GoldenCandleEA.mq4`)**
- Component coordination
- Main trading logic
- User interface
- Event processing

## Technical Details

### Signal Generation

The signal generation process involves:

1. **Pattern Recognition**
   ```cpp
   bool IsGoldenCandle(int index) {
       double bodySize = MathAbs(close - open);
       double totalWick = upperWick + lowerWick;
       return bodySize / totalWick >= bodyToWickRatio;
   }
   ```

2. **Volume Analysis**
   ```cpp
   bool IsVolumeValid(int index) {
       double avgVolume = CalculateAverageVolume(volumePeriod);
       return currentVolume >= avgVolume * minVolumeMultiplier;
   }
   ```

3. **Trend Confirmation**
   ```cpp
   bool IsTrendValid(int index) {
       double strength = CalculateTrendStrength(index);
       return strength >= trendStrength;
   }
   ```

### Risk Management

Risk management is implemented at multiple levels:

1. **Position Level**
   ```cpp
   double CalculatePositionSize(double stopLoss) {
       double risk = AccountBalance() * (riskPercent / 100.0);
       double pointValue = MarketInfo(symbol, MODE_POINT);
       return NormalizeLots(risk / (stopLoss * pointValue));
   }
   ```

2. **Account Level**
   ```cpp
   bool ValidateRisk(double riskAmount) {
       if(riskAmount > maxDailyRisk) return false;
       if(currentDrawdown > maxDrawdown) return false;
       return true;
   }
   ```

### Trade Execution

Trade execution follows a strict process:

1. **Entry Validation**
   ```cpp
   bool ValidateEntry(ENUM_ORDER_TYPE type) {
       if(!IsTradeAllowed()) return false;
       if(!ValidateSignal()) return false;
       if(!ValidateRisk()) return false;
       return true;
   }
   ```

2. **Position Opening**
   ```cpp
   bool OpenPosition(ENUM_ORDER_TYPE type, double lots) {
       double sl = CalculateStopLoss(type);
       double tp = CalculateTakeProfit(type);
       return ExecuteOrder(type, lots, sl, tp);
   }
   ```

## Integration Guide

### Adding New Components

1. Create new component class:
   ```cpp
   class CNewComponent {
       private:
           // Private members
       public:
           bool Init();
           void Deinit();
           // Public interface
   };
   ```

2. Register in main EA:
   ```cpp
   CNewComponent* m_newComponent;
   m_newComponent = new CNewComponent();
   if(!m_newComponent.Init()) return false;
   ```

### Implementing New Strategies

1. Inherit from base strategy:
   ```cpp
   class CNewStrategy : public CStrategyBase {
       public:
           virtual bool CheckEntryConditions();
           virtual bool CheckExitConditions();
   };
   ```

2. Implement required methods:
   ```cpp
   bool CNewStrategy::CheckEntryConditions() {
       // Strategy-specific implementation
   }
   ```

## Testing Framework

### Component Testing

Test each component individually:
```cpp
void TestSignalManager() {
    CSignalManager* signalManager = new CSignalManager();
    Assert(signalManager.Init());
    // Add test cases
}
```

### Integration Testing

Test component interaction:
```cpp
void TestStrategyIntegration() {
    CGoldenCandleStrategy* strategy = new CGoldenCandleStrategy();
    Assert(strategy.Init(Symbol(), PERIOD_H1, signalManager, moneyManager));
    // Test interaction
}
```

## Performance Optimization

1. **Memory Management**
   - Use dynamic arrays efficiently
   - Clear unused indicators
   - Manage object lifecycle

2. **Processing Optimization**
   - Cache frequently used values
   - Minimize indicator recalculation
   - Use efficient data structures

## Troubleshooting

Common issues and solutions:

1. **Initialization Failures**
   - Check component dependencies
   - Verify parameter values
   - Check log for errors

2. **Trading Issues**
   - Verify signal generation
   - Check risk calculations
   - Monitor state management

## Future Development

Planned enhancements:

1. **Framework Extensions**
   - Multiple strategy support
   - Advanced risk models
   - Machine learning integration

2. **Performance Improvements**
   - Optimized calculations
   - Enhanced caching
   - Reduced memory usage

## Version Control

The framework uses semantic versioning:
- Major: Breaking changes
- Minor: New features
- Patch: Bug fixes

## Contributing

Development guidelines:

1. **Code Style**
   - Follow MQL4 conventions
   - Use clear naming
   - Document changes

2. **Testing**
   - Write unit tests
   - Perform integration tests
   - Test on demo account

## Support

For technical support:
1. Check documentation
2. Review error logs
3. Contact development team

---

Copyright © 2025. All rights reserved.
