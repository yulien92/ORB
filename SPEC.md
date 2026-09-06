# ORB behavioral contract — candidate 1.1.0

This contract reconciles the owner's visual-only requirement, existing formulas,
and the 2026-09-06 audit. The canonical source is `ORB_Opening_Range_Box.pine`.
Purpose: show a single confirmed opening range and optional close-crossing
context for a trader. No orders, sizing, profitability model, or strategy signals
are implemented. Technical release readiness remains subject to the validation
matrix; supporting a context in code is not evidence that it passed runtime QA.

## Inputs and units

| Input | Default | Supported values / meaning |
| --- | --- | --- |
| Opening range timeframe | 15 minutes | 15 or 30 minutes |
| Fill color | RGB(54,9,164), transparency 85 | Pine color |
| Border color | RGB(54,9,164) | Pine color |
| Border width | 1 | Integer 1–5, drawing width |
| Dynamic right border spacing | 3 | Integer 0–100 chart-bar durations |
| Enable upper breakout alert | true | Controls upper alert only |
| Enable lower breakout alert | true | Controls lower alert only |
| Show test markers | false | Controls marker drawings only |

Prices are absolute symbol OHLC prices, not percentages or returns. No rounding,
normalization, `nz()` substitution or proxy data is applied. Timestamp arithmetic
uses milliseconds. Display settings do not change the calculation or the other
alert direction. Changing an input reloads Pine, recreating drawings from data.

## Symbol, session and date contract

The intended workflow is liquid equities with a 09:30 exchange-local opening,
especially SPY. Data uses `syminfo.tickerid`, including the chart's inherited
session/adjustment context. No regular/extended session override is introduced.
Use standard time-based intraday charts only. Non-standard charts, ticks and
daily-or-higher timeframes stop with a diagnostic. A missing volume series is
irrelevant: volume is never used.

Other instruments can calculate a range only if their selected session/feed
provides a complete 15/30-minute candle whose opening timestamp is exactly
09:30 in `syminfo.timezone`. This is not a universal exchange-opening detector.
For example, CME 09:30 is exchange-local, not automatically 09:30 New York.
Chart display timezone does not alter Pine's exchange-timezone calculations.
DST is handled by the exchange timezone; no fixed UTC offset is assumed.

Day identity is `year(timestamp)*10000 + month(timestamp)*100 + dayofmonth(timestamp)`
in the exchange timezone. Reset happens on the first observed chart/source bar
whose opening date changes. Overnight daily-session boundaries such as 18:00 do
not themselves reset a same-calendar-day ORB. There is no wall-clock timer when
the feed does not update, and a chart bar spanning midnight cannot create an
extra historical chart observation at midnight. Cross-date snapshots fail closed.

## Range acquisition and observation

The opening high/low are exactly `high[1]` / `low[1]` of the complete selected
09:30 source candle. It must have the current source calendar date, non-missing
ordered high/low and `time_close[1]-time[1] == selected minutes*60000`.
Values are first published on a subsequent source candle. Partial opening
candles, sparse startup without that candle, missing data and a previous day's
09:30 candle do not create a range. The high/low then persist for that date.
Pine OHLC cannot prove tick-by-tick data completeness inside an otherwise complete
timestamp interval or diagnose feed entitlements/transport latency.

| Request | Context and expression | Mapping / timing |
| --- | --- | --- |
| ORB snapshot | Chart ticker; selected 15/30m; `[time, confirmedHigh, confirmedLow, openingTime]` from `f_openingRange()` | `gaps_off`. ChartTF <= ORBTF: `lookahead_on`, confirmed prior prices. ChartTF > ORBTF: `lookahead_off`, last available LTF snapshot. A valid range can draw while the chart bar is open. |
| 5m signal data | Chart ticker; 5m; `[time[1], time_close[1], time_close[2], close[1], close[2]]` | `gaps_off`, `lookahead_on`. Signal engine enabled only at ChartTF <= 5m. Above 5m its sampled values are never actionable. |

The LTF request needs a persistent confirmed range snapshot, not every intrabar
event. Therefore two scalar tuple requests are sufficient; no intrabar arrays or
alternative calculation engine are introduced. Source confirmation comes from
the prior-candle offsets, not `barstate.isconfirmed`.

On every supported chart, draw on the first update receiving the confirmed range.
For a realtime 60m chart, ORB15 can therefore appear on the first update after
09:45 and ORB30 after 10:00, without waiting for 10:30. Prices remain those of
the completed opening candle. Pine rollback can recreate the uncommitted box
on each update from that snapshot; do not add `varip` or a one-shot tick latch.
Historical bars execute with their last mapped LTF snapshot, not every past tick;
reloading reconstructs the range but cannot prove its original intrabar appearance.
Nondivisor chart intervals may have different host detection bars/latency;
the mandatory native test compares source event timestamps and confirmed prices.

An available consumer range must have the chart opening date for both opening
and requested timestamp, and its end cannot exceed the chart closing timestamp.
`na` means unavailable, never zero. At most one box exists. It is removed on a
new chart date or invalid range; a valid snapshot can recreate a missing box
without requiring a one-bar transition pulse. Box prices are fixed at creation.
Only the right edge changes: `time_close + spacing*(time_close-time)`.
Spacing means elapsed bar-duration units, not actual future trading candles
across weekends/session breaks. The left edge is the 09:30 source opening time,
so the rectangle spans time before its availability; it is not an entry signal.

## Breakouts and markers

For valid data, upper crossing is `C > H and P <= H`; lower crossing is
`C < L and P >= L`, where C/P are consecutive confirmed 5m closes. Equality
with the border is not a breakout. Remaining outside does not repeatedly cross.
A jump from the other side of the entire range can cross the relevant border;
P need not be between both borders. Flat ranges (`H == L`) are allowed.

Both predicates also require: ChartTF <= 5m; a changed confirmed source timestamp;
an available range; present closes; a complete 300000ms current source candle;
preceding close time equal to current opening time; current opening at/after
the ORB end on the chart date; source close no later than chart close; and
chart opening minus source close below 300000ms. This prevents pre-range,
cross-gap, previous-date and stale-observation signals. Missing data suppresses
the event rather than inventing a bridging close.

The offset request observes a closed 5m candle on a subsequent source candle.
It is not guaranteed to alert at that candle's exact close. With no subsequent
source/host update in the same eligible date (including the final RTH candle),
that close may never generate an event. No deferred prior-date alerts are sent.
Use TradingView's Once Per Bar frequency to avoid repeated tick notifications
while the same predicate is true on an open chart bar. Once Per Bar Close adds
host-bar latency. Delivery is a separate server-side gate, not demonstrated by
evaluating a boolean or Bar Replay. Existing alert snapshots need recreation.

Optional triangles use the confirmed source candle's OPENING timestamp with
abovebar/belowbar placement. They are retrospective annotations, not proof that
the event was known at that timestamp. Each chart date's labels are managed and
deleted on the next observed date; their visibility does not control alerts.
The signal timestamp stays fixed; provider historical revisions can still alter
results after reload. No absolute non-repainting or performance guarantee is made.

## Status and resource budget

An orange status cell is always visible for visual-only mode (ChartTF > 5m)
and for an unavailable range. It says active only if a box actually exists,
and otherwise reports that a complete opening range is unavailable. It is cleared when
the full engine has a valid range; that does not assert live server delivery or
complete feed quality. There are no extra user settings for these safeguards.

Budget: 2 request contexts, 9 tuple elements, 2 alert plot counts, 1 box,
1 table, up to 200 retained label IDs. Only the daily label cleanup loops.
On a normal 24h date, fewer than 171 post-ORB 5m slots are eligible; even a
25h DST date is below 200. Pine's runtime/compiled memory/time limits still need
native tests. Removed repeated box color/price setters are a structural reduction
in calls, not a measured speedup. No imported libraries or dependencies.

## Critical traceability and acceptance

Implementation references use unique identifiers to survive line movement.
L/S/M are local source/math checks; N/O/P are native/operational/Profiler cases
in `validation/2026-09-06-production-audit.md`.

| Requirement | Implementation | Evidence / acceptance |
| --- | --- | --- |
| R1 Complete confirmed 09:30 range, 15/30m | `f_openingRange`, `previousBarIsOpening` | S01/M01 and N02: exact candle high/low, no partial/pre-close value |
| R2 Rectangle on all supported intraday TF | `chartAboveOpeningRange`, request mapping, `newConfirmedRange` | S01/M02 and N03: first available confirmed snapshot; native 60/720m intrabar persistence/reload remains required |
| R3 No >5m actionable signals | `fiveMinuteSignalsAvailable`, both breakouts | S01/M03 mutation controls and N03: neither direction triggers |
| R4 No stale prior-date or cross-gap values | `f_calendarDay`, `rangeIsAvailable`, `signalTimesAreValid` | S01/M01 and N04/O01: reset/wait, no old event |
| R5 Exact crossing inequalities | `upperBreakout`, `lowerBreakout` | M03: source-bound fixtures and comparator mutation rejection; N05 for real candles |
| R6 Current-date marker lifecycle | `signalLabels`, `chartNewDay` | S01 and O01/O02: replay/reload/live cleanup and source timestamp placement |
| R7 Explicit invalid/degraded status | runtime guards, `signalStatusTable` | S01/M03 and N03/N06: correct error/wait/active text |
| R8 Alerts independent of display | `alertcondition`, `showSignalMarkers` | S01/M03 and O03: direction toggles and notification delivery |
| R9 Reproducible distribution | single canonical file, version, docs | L01 and N01: clean-checkout tests and exact-byte Pine compilation |
| R10 Practical resource/UI behavior | single box/table, bounded daily labels | P01/N06: three comparable Profiler runs and light/dark layout |

Open native gates remain BLOCKED, not assumed passes. See AUDIT.md for resolved
defects and publication prerequisites.
