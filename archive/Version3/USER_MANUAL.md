# GoldenCandle EA v3.0 - User Manual

## Introduction

GoldenCandle EA is a professional forex trading Expert Advisor that implements the Golden Candle strategy with advanced risk management and market analysis features. This manual will guide you through the setup, configuration, and operation of the EA.

## Quick Start Guide

1. **Installation**
   - Copy the `EA_Framework` folder to your MT4's `MQL4` directory
   - Restart MetaTrader 4
   - Drag the EA onto your desired chart

2. **Initial Setup**
   - Configure basic parameters (risk, timeframe, etc.)
   - Enable automated trading in MT4
   - Verify the EA is running (check "Experts" tab)

3. **Basic Operation**
   - Monitor the EA status in the chart corner
   - Check the "Experts" tab for activity
   - Review the "Journal" for detailed logs

## Parameter Configuration

### General Settings

| Parameter | Description | Default | Range |
|-----------|-------------|---------|--------|
| EAName | EA identifier | "GoldenCandle EA" | - |
| MagicNumber | Trade identifier | 202508 | > 0 |
| OperatingTimeframe | Trading timeframe | PERIOD_H1 | Any MT4 timeframe |
| EnableTrading | Enable/disable trading | true | true/false |

### Money Management Settings

| Parameter | Description | Default | Range |
|-----------|-------------|---------|--------|
| BaseRiskPercent | Base risk per trade | 1.0 | 0.1-5.0 |
| MaxRiskPercent | Maximum risk per trade | 2.0 | 0.1-10.0 |
| MaxDailyRisk | Maximum daily risk | 5.0 | 1.0-20.0 |
| MaxDrawdown | Maximum allowed drawdown | 20.0 | 5.0-50.0 |
| DailyProfitTarget | Daily profit target | 3.0 | 0.5-10.0 |

### Strategy Settings

| Parameter | Description | Default | Range |
|-----------|-------------|---------|--------|
| BodyToWickRatio | Body to wick ratio | 2.0 | 1.0-5.0 |
| MinCandleSize | Minimum candle size | 10.0 | 5.0-50.0 |
| MaxCandleSize | Maximum candle size | 100.0 | 50.0-200.0 |
| MinVolumeMultiplier | Volume requirement | 1.5 | 1.0-3.0 |
| TrendPeriod | Trend analysis period | 50 | 20-100 |
| MomentumPeriod | Momentum period | 14 | 5-30 |

## Understanding the Interface

### Status Display

The EA displays real-time information in the chart corner:

```
GoldenCandle EA Status
==================
Trading State: ACTIVE
State Reason: Normal operation

Performance Metrics
==================
Daily Profit: 125.50
Current Drawdown: 1.25%
Max Drawdown: 3.45%

Open Position
==================
Type: BUY
Profit: 25.75
SL: 1.2345
TP: 1.2456
```

### Trading States

1. **ACTIVE**
   - Normal trading operation
   - All systems functioning

2. **SUSPENDED**
   - Temporary trading halt
   - Usually due to risk limits

3. **STOPPED**
   - Trading completely stopped
   - Requires manual restart

4. **ERROR**
   - System error detected
   - Check journal for details

## Trading Rules

### Entry Conditions

The EA enters trades when:
1. Golden Candle pattern is detected
2. Volume confirms the pattern
3. Trend aligns with the signal
4. Risk parameters are satisfied

### Exit Conditions

Positions are closed when:
1. Take profit is reached
2. Stop loss is hit
3. Pattern reversal occurs
4. Risk limits are exceeded

## Risk Management

### Position Sizing

The EA calculates position size based on:
1. Account balance
2. Risk percentage
3. Stop loss distance
4. Market volatility

### Risk Controls

Multiple risk layers are implemented:
1. Per-trade risk limits
2. Daily risk limits
3. Drawdown control
4. Market condition filters

## Performance Monitoring

### Daily Statistics

Monitor daily performance:
1. Profit/Loss
2. Win rate
3. Average trade
4. Maximum drawdown

### Long-term Statistics

Track long-term metrics:
1. Monthly performance
2. Risk-adjusted returns
3. Maximum drawdown
4. Recovery factor

## Optimization

### Strategy Tester

Use MT4's Strategy Tester to:
1. Optimize parameters
2. Test different timeframes
3. Validate performance
4. Check robustness

### Parameter Guidelines

When optimizing:
1. Start with default values
2. Change one parameter at a time
3. Test on different pairs
4. Verify results on demo

## Troubleshooting

### Common Issues

1. **EA Not Trading**
   - Check if trading is enabled
   - Verify parameter values
   - Check journal for errors

2. **Unexpected Trades**
   - Review entry conditions
   - Check risk settings
   - Verify signal parameters

3. **Performance Issues**
   - Monitor system resources
   - Check network connection
   - Verify data feed

### Error Messages

| Error | Description | Solution |
|-------|-------------|----------|
| E001 | Initialization failed | Check settings |
| E002 | Invalid parameters | Review parameters |
| E003 | Trading error | Check journal |
| E004 | System error | Restart EA |

## Best Practices

1. **Testing**
   - Always test on demo first
   - Start with small positions
   - Monitor performance daily

2. **Risk Management**
   - Never override risk limits
   - Monitor drawdown closely
   - Keep detailed records

3. **Maintenance**
   - Update parameters regularly
   - Backup settings
   - Keep EA updated

## Support

For assistance:
1. Check this manual
2. Review error logs
3. Contact support team

## Disclaimer

Trading forex carries substantial risk. This EA is provided as-is with no guarantees. Always:
- Use proper risk management
- Test thoroughly
- Never risk more than you can afford to lose

---

Copyright © 2025. All rights reserved.
