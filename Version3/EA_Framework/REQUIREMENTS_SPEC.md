# GoldenCandle EA Framework - Client Requirements Specification

## 1. Market Configuration

### Trading Environment
- Primary Market: BTCUSD
- Default Timeframe: M1 (1-minute chart)
- Trading Direction: Both Buy and Sell (bidirectional)

### Technical Indicators
1. **Parabolic SAR**
   - Step: 0.001
   - Maximum: 0.2
   - Style: Orange
   - Function: Primary trend direction indicator

2. **Moving Average Crossover (MQLTA-MACA)**
   - Fast MA:
     * Period: 1
     * Shift: 0
     * Method: Exponential
     * Price: Close
   - Slow MA:
     * Period: 3
     * Shift: 1
     * Method: Exponential
     * Price: Close
   - Visual Alerts:
     * Up arrows: Yellow/OrangeRed
     * Down arrows: Magenta

## 2. Trading Strategy

### Entry Conditions
1. **Primary Entry (Parabolic SAR Based)**
   - Trigger: SAR direction change
   - Entry Rules:
     * SAR switches from downtrend to uptrend
     * Price crosses above the new SAR point
     * SAR dot must be below price
   - Validation:
     * No continuous SAR setup (must be direction change)
     * Golden Candle size validation

2. **Secondary Entry (MQLTA-MACA Based)**
   - Trigger: Moving Average crossover
   - Entry Rules:
     * Arrow signal appears
     * Previous trade must be closed
     * Golden Candle size validation

### Golden Candle Configuration
- Base Size: 10,000 points
- Entry Level: 35% of base size (3,500 points)
- Reference Line: Placed at entry level above signal candle
- Validation Method: Fibonacci-based equal ranges

## 3. Position Management

### Order Types
- Primary: Pending Orders
- Entry Price: Based on reference line level
- Maximum Positions: One trade at a time

### Stop Loss Management
- Initial Stop Loss: 10,000 points
- Dynamic Adjustment:
  * Move to breakeven at 3rd target level (30,000 points)
  * Move to 1st level at 6th target level

## 4. Money Management

### Position Sizing System
- Base Lot Size: 0.01
- Progressive Lot Size Increase
- Maximum Lot Size: 0.18 (at 25th attempt)

### Risk:Reward Structure
1. **First 6 Attempts (0.01 lots)**
   - Entry 1: R:R = 1:2
   - Entry 2: R:R = 1:3
   - Entry 3: R:R = 1:4
   - Entry 4: R:R = 1:5
   - Entry 5: R:R = 1:6
   - Entry 6: R:R = 1:7

2. **Progressive Structure**
   - Entry 7-10: 0.02 lots (split into R:R combinations)
   - Entry 11-12: 0.03 lots
   - Entry 13-14: 0.04 lots
   - Entry 15-16: 0.05 lots
   - Entry 17: 0.06 lots
   - Entry 18: 0.07 lots
   - Entry 19: 0.08 lots
   - Entry 20: 0.09 lots
   - Entry 21: 0.10 lots
   - Entry 22: 0.12 lots
   - Entry 23: 0.14 lots
   - Entry 24: 0.16 lots
   - Entry 25: 0.18 lots

## 5. User Interface Requirements

### Trading Controls
- Lot size input box
- System pause/resume control
- Manual level skip functionality (e.g., 9 to 13)
- Trade status display
- Current level indicator

### Visual Elements
- Reference line display
- Stop loss/Take profit levels
- Current position information
- Entry level markers
- Risk:Reward ratio display

## 6. Special Conditions

### Reference Line Updates
- Update reference line on new MQLTA-MACA signal if:
  * No position is open
  * Signal appears during ranging market

### Safety Features
- Single trade at a time enforcement
- Manual override capabilities
- Clear visual confirmation of levels
- System state indicators

## 7. Optimization Parameters

### Configurable Inputs
- Indicator parameters
- Golden Candle size
- Entry level percentage
- Stop loss distance
- Take profit levels
- Lot size progression
- Risk:Reward ratios

### Risk Management
- Maximum lot size limits
- Progressive position sizing
- Dynamic stop loss adjustment
- Multiple take profit levels

This specification aligns with the EA_Framework architecture and provides a clear structure for implementation while maintaining all client requirements.
