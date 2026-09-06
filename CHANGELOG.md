# Changelog

All notable user-visible changes to the ORB Opening Range Box are documented in
this file.

## Unreleased — production audit (2026-09-06)

These changes prepare the 1.1.0 candidate. They are not a TradingView publication
or a tagged release. Exact-candidate native verification remains blocked.

### Fixed

- Select the last confirmed ORB snapshot when the chart exceeds the selected
  opening-range timeframe, preventing historical first-intrabar range loss.
- Reject old-date, partial or missing-price opening candles and stale/gapped
  five-minute crossings. Reset using exchange-calendar dates consistently.
- Recreate a missing rectangle from an available range without a one-bar pulse.
- Distinguish an unavailable/waiting range from an active rectangle in the panel.
- Bind breakout tests to production predicates and prove sensitivity to mutated
  comparisons/removed guards. Correct stale and unsupported validation claims.

### Changed

- Above the selected ORB timeframe, a new rectangle is accepted at chart-bar
  close. For ORB15 on a 60m RTH chart this means 10:30, not 09:45.
- Range prices/colors are set at box creation; only the dynamic right edge needs
  subsequent updates. No measured speedup is claimed.

### Upgrade notes

- Preserve the visible 1.1.0 identity assigned on 2026-09-04. Copy the canonical
  file into an isolated Pine Editor buffer for testing; GitHub does not update
  saved TradingView scripts. Recreate alerts when adopting the final version.
- The existing next-source-bar alert observation policy can omit a session's
  last candle when no eligible later update occurs; this limitation is now explicit.

## [1.1.0] - 2026-09-04

### Added

- Explicit fail-closed diagnostics for unsupported chart types and timeframes.
- A visible visual-only status warning on chart timeframes above five minutes.
- Dependency-free static contracts and deterministic breakout fixtures.
- A documented support matrix and separate validation evidence gates.

### Changed

- Standard time-based intraday charts above five minutes now keep the ORB
  rectangle active while disabling five-minute alerts and markers.

### Fixed

- Prevented incomplete five-minute signal evaluation on chart timeframes above
  five minutes.
- Prevented opening ranges and alerts from using synthetic non-standard-chart
  prices.
- Replaced immutable signal plots with managed labels so prior-day markers can
  be deleted during an uninterrupted realtime day transition.
