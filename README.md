# ORB Opening Range Box

`ORB_Opening_Range_Box.pine` is the canonical Pine Script v6 source for the
ORB Opening Range Box indicator by Yulien. It draws a confirmed 15-minute or
30-minute opening range beginning at 09:30 in the symbol's exchange timezone
and exposes confirmed five-minute close-crossing alerts.

Current indicator version: `1.1.0`.

This indicator provides market context. It is not an automatic trade-entry or
trade-exit system.

## Supported chart context

The ORB rectangle supports:

- standard chart types that use actual market OHLC prices;
- time-based intraday charts; and
- any intraday chart timeframe.

The complete indicator, including its five-minute alert and marker engine,
supports chart timeframes of five minutes or lower.

### Visual-only mode

On a chart timeframe above five minutes, the rectangle remains active while
five-minute alerts and markers are disabled. A visible warning identifies this
mode and directs the user to a chart timeframe of five minutes or lower for the
complete signal engine. This avoids both an unnecessary full-script failure and
silently incomplete breakout monitoring.

The script still stops with a clear runtime error on daily or higher
timeframes, tick charts, and non-standard chart types such as Heikin-Ashi,
Renko, Kagi, Line Break, Range, and Point & Figure.

## Calculation contract

- The opening range is the high and low of the 09:30 bar in the selected
  15-minute or 30-minute context.
- The range becomes available only after that opening bar is closed.
- An upper breakout requires a new confirmed five-minute close above the range
  high and the preceding five-minute close at or below the range high.
- A lower breakout is the symmetric condition below the range low.
- A close exactly on a range boundary is not a breakout.
- The range and marker lifecycle reset on each new exchange-calendar day.
- Prior-day marker labels are deleted even when the indicator remains loaded
  continuously across the day transition.

The requested price values use prior confirmed bars with explicit
`barmerge.lookahead_on`. The lookahead setting does not expose future prices in
this implementation because all requested prices are offset by `[1]` or `[2]`.

## Alerts and Bar Replay

The script exposes two independent `alertcondition()` selectors:

- `ORB — Upper 5M breakout`
- `ORB — Lower 5M breakout`

Both conditions remain false in visual-only mode. To keep exact five-minute
monitoring while viewing a higher-timeframe chart, create the TradingView alert
from a supported chart timeframe first. TradingView runs that saved alert using
the symbol, timeframe, source, and inputs captured when it was created.

The current-day rule applies only to visual marker labels. It does not disable
alerts in future sessions.

TradingView server alerts require realtime market data. Bar Replay can be used
to inspect the rectangle and marker behavior, but it does not prove server-side
alert delivery. Delete and recreate configured TradingView alerts after source
code or input changes because an alert stores a snapshot of the script and its
settings.

## Local validation

Run the dependency-free static and deterministic contracts from PowerShell:

```powershell
& '.\tests\Invoke-StaticContracts.ps1'
```

The suite verifies UTF-8 integrity, request topology, confirmed-price offsets,
supported-context guards, managed marker lifecycle, alert preservation, and
boundary-condition fixtures.

## Evidence gates

These gates are independent and must be reported separately:

| Gate | Current status |
| --- | --- |
| Local static and deterministic contracts | Passed: 53 tests |
| Pine v6 compilation in TradingView | Passed for an executable-equivalent test buffer; byte-level and normalized hashes are recorded in `validation/2026-09-04-tradingview-visual-only.md` |
| Standard 5-minute supported-mode activation | Passed: indicator active and visual-only warning cleared; no breakout event was forced |
| Standard 15-minute visual-only activation | Passed: warning visible without a runtime error; rectangle output was not isolated from the pre-existing ORB instance |
| Bar Replay marker behavior | Not yet verified for this revision |
| Uninterrupted live day-rollover cleanup | Not yet verified for this revision |
| Live server alert delivery | Not yet verified for this revision |
| TradingView cloud save/publication | Not performed |

Passing local contracts is not evidence that any TradingView runtime,
publication, or live-alert gate passed.

See the [`validation`](validation/) directory for revision-specific TradingView
runtime evidence and its limitations.
