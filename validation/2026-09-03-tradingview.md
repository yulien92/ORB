# TradingView validation — 2026-09-03

## Revision under test

- Source: `ORB_Opening_Range_Box.pine`
- SHA-256: `83F7D0B07BB46B6033E2831B1A067ACEA5A99B8BB5028A520BFFA233FA047DEE`
- Pine language: v6
- Symbol used: AMEX:SPY
- Chart type used: standard candles

## Observed evidence

| Gate | Result | Observation |
| --- | --- | --- |
| Pine compilation and insertion | Passed | TradingView accepted the source and inserted `ORB Box` on the chart without a compiler error. |
| Supported host chart | Passed | The inserted indicator remained active after the chart was returned to five minutes. |
| Higher-timeframe fail-closed guard | Passed | Changing the host chart to 15 minutes produced a user-defined runtime error for the inserted indicator. |
| Cloud save/publication | Not performed | The source remained in an isolated untitled Pine Editor buffer and was not saved or published. |

## Evidence not established by this run

- The displayed opening-range prices were not independently cross-checked
  against source candles.
- Bar Replay marker placement and cleanup were not exercised.
- An uninterrupted live exchange-calendar day transition was not observed.
- Realtime TradingView server-alert delivery was not exercised.
- No cloud-save or publication claim is made.

Local static tests, TradingView compilation, runtime behavior, replay behavior,
live rollover, alert delivery, and publication are independent gates. A pass in
one gate does not imply a pass in another.
