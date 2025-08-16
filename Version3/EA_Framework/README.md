# EA Framework - Golden Candle EA

This document outlines the complete framework structure for the Golden Candle EA, designed with modularity, maintainability, and extensibility in mind.

## Framework Overview

The framework is divided into two main categories:
1. **Immutable Components** - Core technical components that remain constant across different EA implementations
2. **Flexible Components** - Strategy-specific components that can be customized per client requirements

## Directory Structure

```
EA_Framework/
├── Base/           # Immutable base components
├── Technical/      # Immutable technical components
├── Strategy/       # Flexible strategy components
└── UI/            # Flexible UI components
```

## Detailed Component Structure

### Base Components [IMMUTABLE]

These components provide the foundational framework and utilities.

#### Constants (`Constants.mqh`)
- **TradeConstants**: Trading-related constants
- **ErrorCodes**: System-wide error codes
- **TimeConstants**: Time-related constants
- **LimitConstants**: System limitation constants

#### Enums (`Enums.mqh`)
- **TradeEnums**: Trading-related enumerations
- **StateEnums**: State management enumerations
- **SignalEnums**: Signal-related enumerations
- **ErrorEnums**: Error classification enumerations

#### Structures (`Structures.mqh`)
- **TradeStructs**: Trading-related structures
- **SignalStructs**: Signal data structures
- **StateStructs**: State management structures
- **ConfigStructs**: Configuration structures

#### Terminal Management (`TerminalManager.mqh`)
- **BuildValidator**: MT4/MT5 version compatibility
- **MemoryLimiter**: Memory usage management
- **ThreadController**: Thread safety management
- **DLLValidator**: DLL availability validation

#### State Management (`StateManager.mqh`)
- **TradingState**: Current trading state
- **StrategyState**: Strategy execution state
- **RecoveryState**: System recovery state
- **PersistentStorage**: State persistence

#### Integrity Management (`IntegrityManager.mqh`)
- **DataValidator**: Data integrity validation
- **ChecksumCalculator**: Data checksum verification
- **StateVerifier**: State integrity checking
- **BackupManager**: Data backup management

#### Event Management (`EventManager.mqh`)
- **EventDispatcher**: Event routing
- **EventQueue**: Event queuing system
- **SignalProcessor**: Signal handling
- **CallbackHandler**: Callback management

#### License Management (`LicenseManager.mqh`)
- **LicenseValidator**: License validation
- **ExpirationHandler**: License expiration
- **UserAuthentication**: User verification
- **FeatureControl**: Feature access control

#### Documentation (`Documentation.mqh`)
- **APIDocumentation**: API documentation
- **ErrorCatalog**: Error code documentation
- **ConfigGuide**: Configuration guide
- **TroubleshootingGuide**: Troubleshooting documentation

### Technical Components [IMMUTABLE]

These components handle specific technical aspects of the EA.

#### Market Data Management (`MarketDataManager.mqh`)
- **TickProcessor**: Tick data processing
- **PriceNormalizer**: Price normalization
- **SpreadValidator**: Spread validation
- **GapDetector**: Price gap detection

#### Broker Management (`BrokerManager.mqh`)
- **SymbolValidator**: Symbol validation
- **SwapCalculator**: Swap calculation
- **CommissionHandler**: Commission handling
- **ServerTimeManager**: Server time synchronization

#### Signal Calculation (`SignalCalculator.mqh`)
- **EMACalculator**: EMA calculations
- **PSARCalculator**: Parabolic SAR calculations
- **CandleAnalyzer**: Candle pattern analysis
- **IndicatorCache**: Indicator value caching

#### Order Handling (`OrderHandler.mqh`)
- **OrderValidator**: Order validation
- **OrderExecutor**: Order execution
- **OrderModifier**: Order modification
- **OrderSynchronizer**: Order synchronization

#### Safety Management (`SafetyManager.mqh`)
- **SlippageGuard**: Slippage protection
- **RequoteHandler**: Requote handling
- **SpreadProtector**: Spread protection
- **ExecutionValidator**: Execution validation

#### Risk Validation (`RiskValidator.mqh`)
- **MarginCalculator**: Margin calculation
- **ExposureMonitor**: Exposure monitoring
- **DrawdownTracker**: Drawdown tracking
- **EquityGuard**: Equity protection

[... continued in next sections]
