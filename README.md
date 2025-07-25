

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hamzawi_Project - MT4 Expert Advisor</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: linear-gradient(135deg, #e3f0ff 0%, #f8f9fa 100%);
            color: #1a2233;
            margin: 0; padding: 0;
        }
        .container {
            max-width: 900px;
            margin: 40px auto;
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 4px 24px #0002;
            padding: 36px 40px 32px 40px;
            position: relative;
        }
        .header-graphic {
            width: 100%;
            height: 120px;
            background: linear-gradient(90deg, #2a5d9f 0%, #6ec6ff 100%);
            border-radius: 12px 12px 0 0;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 24px;
        }
        .header-graphic img {
            height: 70px;
            margin-right: 24px;
        }
        .header-title {
            color: #fff;
            font-size: 2.5em;
            font-weight: 700;
            letter-spacing: 1px;
            text-shadow: 0 2px 8px #0003;
        }
        h2 {
            color: #2a5d9f;
            border-bottom: 2px solid #e0e0e0;
            padding-bottom: 6px;
            margin-top: 36px;
        }
        h3 { color: #1b3a5c; margin-top: 28px; }
        ul, ol { margin-left: 24px; }
        .feature-list li { margin-bottom: 8px; }
        .section { margin-bottom: 36px; }
        .note {
            background: #eaf6ff;
            border-left: 5px solid #2a5d9f;
            padding: 14px 22px;
            margin: 20px 0;
            border-radius: 8px;
            font-size: 1.08em;
        }
        code {
            background: #f4f4f4;
            padding: 2px 7px;
            border-radius: 4px;
            font-size: 1.01em;
        }
        .footer {
            color: #888;
            font-size: 1em;
            margin-top: 48px;
            text-align: center;
        }
        .section-icon {
            font-size: 1.3em;
            margin-right: 8px;
            vertical-align: middle;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 12px;
            margin-bottom: 12px;
        }
        th, td {
            padding: 7px 10px;
            border: 1px solid #e0e0e0;
            text-align: left;
        }
        th {
            background: #f4f8ff;
            color: #2a5d9f;
        }
        tr:nth-child(even) { background: #f8fbff; }
        tr:nth-child(odd) { background: #fff; }
        @media (max-width: 700px) {
            .container { padding: 10px; }
            .header-title { font-size: 1.5em; }
        }
    </style>
</head>
<body>
<div class="container">
    <div class="header-graphic">
        <img src="https://img.icons8.com/ios-filled/100/ffffff/robot-2.png" alt="EA Icon"/>
        <span class="header-title">Hamzawi_Project</span>
    </div>
    <div class="section">
        <h2><span class="section-icon">📈</span>Overview</h2>
        <p>
            <strong>Hamzawi_Project</strong> is a professional Expert Advisor (EA) for <b>MetaTrader 4 (MT4)</b> that automates trading based on a custom strategy provided by the client.<br>
            The EA leverages Parabolic SAR, two Exponential Moving Averages, and a user-defined <b>Golden Candle</b> to determine trade entries, exits, and risk management.<br>
        </p>
    </div>
    <div class="section">
        <h2><span class="section-icon">✨</span>Key Features</h2>
        <ul class="feature-list">
            <li>Customizable lot size, Parabolic SAR, and Moving Average parameters</li>
            <li>Golden Candle input for dynamic entry and stop loss calculation</li>
            <li>Automated buy/sell logic based on indicator signals</li>
            <li>Dynamic stop loss, take profit, and trailing stop system</li>
            <li>Visual chart levels for entry, stop loss, and profit targets</li>
            <li>Lot progression table for risk management</li>
            <li>Comprehensive logging for all technical actions and errors</li>
            <li>Visual Golden Candle highlighting on the chart</li>
        </ul>
    </div>
    <div class="section">
        <h2><span class="section-icon">🛠️</span>How to Use</h2>
        <ol>
            <li>Place the EA file (<code>GoldenCandleEA.mq4</code>) in your MT4 <code>Experts</code> directory.</li>
            <li>Restart MetaTrader 4 and attach the EA to your desired chart.</li>
            <li>Configure the input parameters as needed:
                <ul>
                    <li>Lot size</li>
                    <li>Parabolic SAR settings</li>
                    <li>Moving Average settings</li>
                    <li>Golden Candle size</li>
                </ul>
            </li>
            <li>The EA will automatically execute trades and manage positions according to the strategy rules.</li>
        </ol>
    </div>
    <div class="section">
        <h2><span class="section-icon">📋</span>Requirements</h2>
        <ul>
            <li>MetaTrader 4 platform</li>
            <li>The provided PDF (<code>EA Forex.pdf</code>) contains the original client requirements and strategy details.</li>
        </ul>
    </div>
    <div class="section">
        <h2><span class="section-icon">📚</span>Documentation</h2>
        <p>See <code>Technical_Documentation.md</code> for a detailed technical description of the EA logic and implementation.</p>
    </div>
    <div class="section">
        <h2><span class="section-icon">📝</span>Critique &amp; Compliance Review</h2>
        <h3>1. Explicitness of Client Requirements</h3>
        <ul>
            <li><b>a. Golden Candle Logic</b>
                <ul>
                    <li>✔️ The EA detects Golden Candles using Parabolic SAR and price action, as specified.</li>
                    <li>✔️ It only starts trading after the first Golden Candle appears, as now required.</li>
                    <li>✔️ It draws a rectangle on the chart for each Golden Candle, making detection explicit.</li>
                </ul>
            </li>
            <li><b>b. Entry Logic</b>
                <ul>
                    <li>✔️ Entry is only allowed after a Golden Candle appears.</li>
                    <li>✔️ Both Buy and Sell entries are handled, with correct calculation of entry, SL, and TP.</li>
                    <li>✔️ EMA cross entries are implemented, with fallback to ATR if GoldenCandleSize is not set.</li>
                </ul>
            </li>
            <li><b>c. Lot Progression</b>
                <ul>
                    <li>✔️ Lot progression table is implemented and capped.</li>
                    <li>✔️ Lot index advances on SL, resets on TP, and is logged.</li>
                </ul>
            </li>
            <li><b>d. Chart Visuals</b>
                <ul>
                    <li>✔️ Entry, SL, and profit levels are drawn on the chart.</li>
                    <li>✔️ Golden Candle rectangles are drawn for visual verification.</li>
                </ul>
            </li>
            <li><b>e. Logging and Debugging</b>
                <ul>
                    <li>✔️ All key actions (setup, entry, exit, errors, SL/TP adjustments, waiting for Golden Candle) are logged to a CSV file and the Experts tab.</li>
                    <li>✔️ SL/TP distance and StopLevel fallback are logged for broker compliance.</li>
                </ul>
            </li>
            <li><b>f. Robustness</b>
                <ul>
                    <li>✔️ OrderSend is retried up to 3 times.</li>
                    <li>✔️ SL/TP are adjusted if too close to price, with fallback if StopLevel is zero.</li>
                    <li>✔️ MagicNumber is used for trade identification.</li>
                </ul>
            </li>
            <li><b>g. User Adjustability</b>
                <ul>
                    <li>✔️ All key parameters are extern and user-adjustable.</li>
                </ul>
            </li>
        </ul>
        <h3>2. Areas for Improvement or Clarification</h3>
        <ul>
            <li><b>a. Golden Candle Detection</b><br>
                The EA only looks for the most recent Golden Candle (from shift=1). If multiple Golden Candles appear in history, only the latest is considered for entry. This is generally correct, but if the client wants to trade every Golden Candle, a loop or queue would be needed.
            </li>
            <li><b>b. EMA Cross Logic</b><br>
                EMA cross entries are allowed on every bar after the first Golden Candle, not just immediately after a Golden Candle. If the client wants EMA cross entries only when a Golden Candle is present, this logic should be tightened.
            </li>
            <li><b>c. Trade Management</b><br>
                The EA only manages one trade at a time (<code>inTrade</code> flag). If the client wants multiple simultaneous trades (e.g., grid or scaling), this would need to be expanded.
            </li>
            <li><b>d. Persistent State</b><br>
                The <code>goldenCandleAppeared</code> flag is not persistent across EA restarts or chart reloads. If the EA is restarted, it will re-detect the first Golden Candle. If true persistence is required, this should be saved to a file or GlobalVariable.
            </li>
            <li><b>e. Market Gaps and Slippage</b><br>
                There is no explicit handling for market gaps or slippage. This is typical for most EAs, but if the client wants extra safety, additional checks could be added.
            </li>
            <li><b>f. Parameter Change Logging</b><br>
                The EA logs the initial setup, but does not log if the user changes parameters during runtime. If this is required, periodic or event-driven logging of parameter changes should be added.
            </li>
            <li><b>g. Error Handling</b><br>
                The EA logs errors, but does not halt or alert the user if repeated errors occur. For unattended use, consider adding alerts or more robust error recovery.
            </li>
        </ul>
        <h3>3. Documentation and Transparency</h3>
        <ul>
            <li>✔️ The EA is well-instrumented for verification: all key events are logged, and chart objects make the logic visible.</li>
            <li>✔️ The code is readable and parameters are explicit.</li>
            <li>❓ If the client wants a user manual or more detailed in-code comments, this could be expanded.</li>
        </ul>
        <h3>4. Summary Table</h3>
        <table style="width:100%;border-collapse:collapse;">
            <tr style="background:#f4f4f4;"><th style="text-align:left;padding:4px;">Requirement</th><th style="text-align:left;padding:4px;">Status</th><th style="text-align:left;padding:4px;">Comment</th></tr>
            <tr><td>Golden Candle detection</td><td>✔️</td><td>Fully implemented, visual and logged</td></tr>
            <tr><td>Entry/exit logic</td><td>✔️</td><td>All rules present, robust</td></tr>
            <tr><td>Lot progression</td><td>✔️</td><td>Table, capping, and logging</td></tr>
            <tr><td>Chart visuals</td><td>✔️</td><td>Entry, SL, TP, Golden Candle rectangles</td></tr>
            <tr><td>Logging</td><td>✔️</td><td>All key actions, errors, and setup logged</td></tr>
            <tr><td>Robustness (retry, SL/TP, fallback)</td><td>✔️</td><td>OrderSend retry, SL/TP adjust, StopLevel fallback</td></tr>
            <tr><td>User adjustability</td><td>✔️</td><td>All key params are extern</td></tr>
            <tr><td>EMA cross logic</td><td>⚠️</td><td>May need tightening if only allowed after Golden Candle</td></tr>
            <tr><td>Multi-trade support</td><td>❌</td><td>Only one trade at a time</td></tr>
            <tr><td>Persistent state</td><td>⚠️</td><td>Not persistent across restarts</td></tr>
            <tr><td>Parameter change logging</td><td>⚠️</td><td>Only initial setup logged</td></tr>
            <tr><td>Error handling/alerts</td><td>⚠️</td><td>Logs errors, but no user alert or halt on repeated failure</td></tr>
        </table>
        <div class="note">
            <b>Conclusion:</b> The EA is robust, explicit, and covers nearly all client requirements. The only possible gaps are in EMA cross logic timing, multi-trade support, persistent state, and parameter change logging. If the client needs any of these, further refinement is recommended.
        </div>
        <p style="margin-top:18px;">Let me know if you want to address any of these points or need a more detailed review!</p>
    </div>
        <div class="footer">
            &copy; 2025 Moh Hamzawi. All rights reserved.<br>
            <span style="font-size:0.95em;">Developed by MHKAANICHE.<br>For support or questions, please refer to the project documentation.</span>
        </div>
    </div>
</div>
</body>
</html>
