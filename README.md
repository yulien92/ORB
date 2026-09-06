# ORB Opening Range Box

`ORB_Opening_Range_Box.pine` is the canonical Pine Script v6 source for the
ORB Opening Range Box indicator by Yulien. It draws a confirmed 15-minute or
30-minute opening range beginning at 09:30 in the symbol's exchange timezone
and exposes confirmed five-minute close-crossing alerts.

Current indicator version: `1.1.0` (unpublished audit candidate).

Technical readiness: **BLOCKED** on exact-source TradingView compilation and
the native/operational matrix in [validation](validation/2026-09-06-production-audit.md).
The repository source is not automatically synchronized with TradingView.

## Installation and upgrade

1. Open the single canonical file `ORB_Opening_Range_Box.pine` from the intended
   repository branch. There is no generated or alternate publication source.
2. In TradingView's Pine Editor, create an isolated working copy, paste the entire
   file preserving indentation, and compile/add it to a test chart.
3. Check the visible version and remove obsolete test instances only after
   identifying them. A GitHub push does not update a saved TradingView script.
4. When adopting a verified update, recreate the owner's configured alerts from
   the updated source and inputs. Existing server alerts store the older snapshot.

Do not publish the current candidate until its release blockers are closed.

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
mode. Use a chart timeframe of five minutes or lower for the complete signal
engine. This avoids both an unnecessary full-script failure and
silently incomplete breakout monitoring.

When the chart timeframe exceeds the selected ORB timeframe, the **new rectangle
waits for the chart candle to close** so the last confirmed source snapshot can
be used consistently. For example, ORB15 on regular-session 60m first appears at
10:30; on a one-candle-per-session chart it waits until that chart candle closes.
The panel explicitly reports a waiting range rather than claiming a box is active.
The 15m chart with ORB15 remains visual-only for signals, but does not use this
extra higher-chart close gate.

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
- The range and marker lifecycle reset on the first observed bar of each new
  exchange-calendar date, rather than an overnight daily-session boundary.
- Prior-day marker labels are deleted even when the indicator remains loaded
  continuously across the day transition.

Opening candles must have the complete selected duration and the correct date.
Signals require a full five-minute candle, consecutive source timestamps and
an available same-date range. Missing or stale data does not become zero or a
valid-looking signal. A symbol/session without a complete 09:30 exchange-local
candle remains unavailable; 09:30 is not necessarily that market's true opening.

ORB requests select `lookahead_on` for same/higher source timeframes and
`lookahead_off` for lower source timeframes. Requested prices come from prior
confirmed bars. These are data-handling rules, not an absolute guarantee against
provider revisions or host detection-time differences. The full timing contract,
input defaults, formulas and acceptance criteria are in [SPEC.md](SPEC.md).

## Alerts and Bar Replay

The script exposes two independent `alertcondition()` selectors:

- `ORB — Upper 5M breakout`
- `ORB — Lower 5M breakout`

Both conditions remain false in visual-only mode. To keep exact five-minute
monitoring while viewing a higher-timeframe chart, create the TradingView alert
from a supported chart timeframe first. TradingView runs that saved alert using
the symbol, timeframe, source, and inputs captured when it was created.

Date/data validation applies to both signals and labels. Alerts become eligible
again when the next date's own opening range is available. The five-minute
request observes a closed candle on a subsequent source candle: the last close
before a data/session gap may not emit an event. It is not an exact-close timer.
Choose **Once Per Bar** to avoid repeated notifications on ticks of the same
chart bar; **Once Per Bar Close** adds host-bar latency.

Markers are drawn at the source five-minute candle's opening time after its
close has been observed. They mark past candles and must not be interpreted as
signals available at the displayed opening timestamp. No existing owner alert
or live webhook was created, modified, or tested by this audit.

TradingView server alerts require realtime market data. Bar Replay can be used
to inspect the rectangle and marker behavior, but it does not prove server-side
alert delivery. Delete and recreate configured TradingView alerts after source
code or input changes because an alert stores a snapshot of the script and its
settings.

## Local validation

Run the dependency-free local checks from PowerShell 7 (`pwsh`):

```powershell
& '.\tests\Invoke-StaticContracts.ps1'
& '.\tests\Invoke-TemporalContracts.ps1'
git diff --check
```

The static suite checks source structure and fixtures. The temporal suite
evaluates restricted production breakout expressions and rejects deliberate
comparator/guard mutations. Its separate calendar and mapping examples are
explicitly models. Neither suite executes Pine or replaces its compiler.

## Evidence gates

These gates are independent and must be reported separately:

| Gate | Current status |
| --- | --- |
| Local static and deterministic contracts | Final results recorded in the current validation document |
| Pine v6 compilation in TradingView | BLOCKED for the exact candidate: internal-browser automation unavailable |
| Standard 5-minute supported-mode activation | BLOCKED for the current source |
| Standard 15/60/720-minute visual-only activation | BLOCKED for the current source; rectangle isolation required |
| Bar Replay marker behavior | BLOCKED for the current source |
| Uninterrupted live day-rollover cleanup | BLOCKED: not observed |
| Live server alert delivery | BLOCKED: not observed; existing alerts untouched |
| Profiler and light/dark UI | BLOCKED: no native access or measurements |
| TradingView cloud save/publication | Not performed |

Passing local contracts is not evidence that any TradingView runtime,
publication, or live-alert gate passed.

See the [`validation`](validation/) directory for revision-specific TradingView
runtime evidence and its limitations.

## Publication preparation (not published)

Suggested ASCII publication title: **ORB Opening Range Box by Yulien**.

Draft description: This indicator draws the high and low of the complete
09:30 exchange-local 15- or 30-minute candle. Standard time-based intraday
charts above five minutes offer a visual-only rectangle, with chart-close
observation when the chart is larger than the opening-range timeframe. Charts
up to five minutes can expose confirmed close-crossing alert conditions and
optional retrospective markers. Missing opening data suppresses the range;
source gaps suppress unsafe crossings. Alert detection needs a subsequent data
update and does not guarantee a notification for a session's final candle.
This is market context, with no trade execution or promised investment returns.

The owner must confirm publication mode, rights/provenance and licensing before
distribution. The repository has no LICENSE file; author attribution is retained.
TradingView's open-source default does not select a license for this repository.
Use the [changelog](CHANGELOG.md) for draft release notes and [audit](AUDIT.md)
for remediation, sources and outstanding release gates. Publication and release
tags require separate authorization.
