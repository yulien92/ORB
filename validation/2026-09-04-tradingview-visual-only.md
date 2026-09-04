# TradingView visual-only validation — 2026-09-04

## Revision under test

- Canonical source: `ORB_Opening_Range_Box.pine`
- Canonical source SHA-256:
  `C99717A9C19F07E5FB03691CF48BAEF53FABAEB51CB61E14583D882350EAD04C`
- TradingView test-buffer SHA-256:
  `99202751E8DE508F879BB43E7D0E4488E074C7120BEEE5FB1A49E456190C18EC`
- Executable-normalized SHA-256 for both sources:
  `70686CA6CF3E0D6AD49A1D70A41CB76AE8F5EEA20926EC3DC2C137B4FEAC7C35`
- Pine language: v6
- Symbol used: AMEX:SPY
- Chart type used: standard candles
- Browser surface: Codex in-app browser

The TradingView test buffer differed from the canonical file only in comments
and whitespace introduced while transferring the source. Removing line
comments and whitespace from each source produced the same normalized length
of 5,271 characters and the same executable-normalized SHA-256 above.

## Observed evidence

| Gate | Result | Observation |
| --- | --- | --- |
| Pine compilation and update | Passed | TradingView compiled the executable-equivalent source and updated the temporary `ORB Box` instance without a compiler error. |
| Standard 15-minute visual-only activation | Passed | The updated indicator stayed active without the former runtime error and displayed the orange `ORB rectangle active` warning that five-minute alerts and markers were unavailable. |
| Standard 5-minute supported-mode activation | Passed | Returning the chart to five minutes removed the visual-only warning and kept the indicator active without a runtime error. |
| Chart restoration | Passed | The chart was restored to five minutes after validation. |
| Temporary test cleanup | Passed | The user removed the temporary ORB instance after validation. The pre-existing ORB instance remained. |
| Pine Editor cleanup | Passed with limitation | The editor was returned from the temporary ORB buffer to the saved `RSP/SPY Normalized Relative Strength` script. TradingView did not reopen the older unsaved `Phase 7` recent-item buffer. |
| Cloud save/publication | Not performed | The ORB test buffer was not saved or published. |

## Evidence not established by this run

- No breakout event was forced, so marker absence and alert non-delivery were
  not independently observed on the 15-minute chart. Their suppression remains
  covered by the local contracts and the shared `fiveMinuteSignalsAvailable`
  gate in the executable source.
- A pre-existing ORB instance was also visible during the test, so the
  rectangle itself could not be visually attributed to the temporary updated
  instance in isolation. The updated instance's no-error state and its unique
  visual-only warning were observed directly.
- The displayed opening-range prices were not independently cross-checked
  against source candles.
- Bar Replay marker placement and cleanup were not exercised.
- An uninterrupted live exchange-calendar day transition was not observed.
- Realtime TradingView server-alert delivery was not exercised.
- No cloud-save or publication claim is made.

Local static tests, TradingView compilation, chart-timeframe runtime behavior,
replay behavior, live rollover, alert delivery, and publication are independent
gates. A pass in one gate does not imply a pass in another.
