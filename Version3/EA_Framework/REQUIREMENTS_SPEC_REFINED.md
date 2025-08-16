# GoldenCandle EA - Refined Requirements Specification

## 1. Trading System Core

### 1.1 Market Parameters
- **Primary Instrument**: BTCUSD
- **Timeframe**: M1 (1-minute)
- **Execution Type**: Pending Orders
- **Trading Hours**: 24/5
- **Broker Requirements**:
  * 5-digit pricing
  * Minimum spread requirements
  * Adequate liquidity

### 1.2 Technical Indicators
#### 1.2.1 Parabolic SAR
- **Parameters**:
  * Step: 0.001 (fixed)
  * Maximum: 0.2 (fixed)
  * Color: Orange
- **Functionality**:
  * Primary trend direction indicator
  * Direction change detection
  * Price crossover validation

#### 1.2.2 Moving Average System (MQLTA-MACA)
- **Fast MA Configuration**:
  * Period: 1
  * Shift: 0
  * Method: Exponential (EMA)
  * Applied Price: Close
- **Slow MA Configuration**:
  * Period: 3
  * Shift: 1
  * Method: Exponential (EMA)
  * Applied Price: Close
- **Visual Signals**:
  * Up Signal: Yellow/OrangeRed arrow
  * Down Signal: Magenta arrow

## 2. Entry System

### 2.1 Primary Entry Conditions (SAR-Based)
1. **Trigger Requirements**:
   - SAR direction changes from down to up
   - Price crosses above new SAR point
   - SAR point must be below price
2. **Validation Rules**:
   - No continuous SAR setup allowed
   - No existing open positions
   - Golden Candle size must be valid

### 2.2 Secondary Entry Conditions (MA-Based)
1. **Trigger Requirements**:
   - MQLTA-MACA generates up arrow
   - No existing open positions
   - Golden Candle size must be valid
2. **Entry Point Calculation**:
   - Base: Closing price of signal candle
   - Offset: +3500 points from base

### 2.3 Golden Candle Specifications
- **Base Size**: 10,000 points
- **Entry Level**: 35% (3,500 points)
- **Validation Method**: Equal range distribution
- **Reference Line Placement**: Entry level above signal

## 3. Position Management

### 3.1 Order Specifications
- **Order Type**: Pending Buy Orders only
- **Maximum Positions**: One active trade at a time
- **Entry Price**: Reference line level
- **Initial Stop Loss**: 10,000 points

### 3.2 Stop Loss Management
- **Initial Placement**: -10,000 points from entry
- **Dynamic Adjustments**:
  1. Move to breakeven when price reaches 3rd target
  2. Move to 1st level when price reaches 6th target
- **Trailing Stop**: Not implemented

### 3.3 Take Profit Structure
- **Multiple TP Levels**: Based on R:R ratio
- **Level Calculation**: SL distance × R:R ratio
- **Profit Taking**: Partial closure at each level

## 4. Money Management System

### 4.1 Position Sizing Framework
#### 4.1.1 Basic Structure (Levels 1-6)
- **Lot Size**: 0.01
- **Risk:Reward Progression**:
  1. Level 1: R:R = 1:2
  2. Level 2: R:R = 1:3
  3. Level 3: R:R = 1:4
  4. Level 4: R:R = 1:5
  5. Level 5: R:R = 1:6
  6. Level 6: R:R = 1:7

#### 4.1.2 Advanced Structure (Levels 7-25)
- **Lot Size Progression**:
  * Levels 7-10: 0.02 (split orders)
  * Levels 11-12: 0.03 (split orders)
  * Levels 13-14: 0.04 (split orders)
  * Levels 15-16: 0.05 (split orders)
  * Level 17: 0.06 (split orders)
  * Level 18: 0.07 (split orders)
  * Level 19: 0.08 (split orders)
  * Level 20: 0.09 (split orders)
  * Level 21: 0.10 (split orders)
  * Level 22: 0.12 (split orders)
  * Level 23: 0.14 (split orders)
  * Level 24: 0.16 (split orders)
  * Level 25: 0.18 (split orders)

### 4.2 Risk Management Rules
- **Maximum Loss per Trade**: Based on SL distance
- **Position Size Limits**: Based on account balance
- **Level Progression**: Sequential or manual skip
- **Account Protection**: Maximum drawdown limits

## 5. User Interface Requirements

### 5.1 Trading Controls
#### 5.1.1 Input Controls
- Lot size input box
- Level selection control
- System pause/resume button
- Manual level skip function

#### 5.1.2 Display Elements
- Current trading level
- Active position details
- System status indicator
- Risk/Reward display

### 5.2 Visual Elements
#### 5.2.1 Chart Objects
- Reference line (entry level)
- Stop loss level line
- Take profit level lines
- Current position marker

#### 5.2.2 Information Display
- Current level status
- Position size details
- Risk/Reward ratios
- Profit targets

## 6. Special Conditions

### 6.1 Reference Line Updates
- **Update Triggers**:
  * New MQLTA-MACA signal
  * No open position
  * Market in ranging condition
- **Update Rules**:
  * New reference price calculation
  * Previous line removal
  * Visual update notification

### 6.2 Safety Mechanisms
- **Trade Protection**:
  * Single trade enforcement
  * Invalid entry prevention
  * Risk limit monitoring
- **System Protection**:
  * Error handling
  * Connection monitoring
  * Data validation

## 7. System Parameters

### 7.1 Configurable Inputs
- **Technical Parameters**:
  * Indicator settings
  * Entry level calculation
  * Stop loss distance
  * Take profit levels

- **Money Management**:
  * Starting lot size
  * Maximum lot size
  * Risk percentage limits
  * Account protection levels

### 7.2 Fixed Parameters
- **SAR Settings**:
  * Step value
  * Maximum value
  * Color settings

- **MA Settings**:
  * Period values
  * Shift values
  * Calculation methods

## 8. Performance Requirements

### 8.1 Execution Speed
- **Order Processing**: < 100ms
- **Signal Detection**: Real-time
- **UI Updates**: < 500ms refresh

### 8.2 Reliability
- **Uptime**: 99.9%
- **Error Rate**: < 0.1%
- **Data Accuracy**: 100%

This refined specification provides exact requirements for implementation while maintaining alignment with the EA_Framework architecture.
