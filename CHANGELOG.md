# Changelog

All notable user-visible changes to the ORB Opening Range Box are documented in
this file.

## Unreleased

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
