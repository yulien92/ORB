# Immediate confirmed ORB — 2026-09-06

Status: local implementation verified; owner reports successful TradingView
compilation and functional acceptance of ORB15 on a 60m chart, including correct
high/low and persistence after reload. Owner-authorized commit, push and v1.1.0
tag proceed on this basis. TradingView publication remains manual by the owner.

## Candidate

- Canonical source: `ORB_Opening_Range_Box.pine`, unpublished version 1.1.0.
- SHA-256, UTF-8 without BOM, LF:
  `0C5334B327FDADA3B0F4C1D78B34CFCA05C8A60133B8DEC0C898A0D56194C3E6`.
- Base commit: `62c43a41ef0a4740beb1177220934eb9d6e25c95`.
- Working branch: `codex/production-audit-2026-09-06`.
- Owner-approved change: draw the confirmed opening candle's high/low on the
  first available update, even when the higher-timeframe chart bar is open.

Removed only the additional host-confirmation gate and its obsolete status
message. The confirmed `high[1]` / `low[1]` source, contextual lookahead, date/data
guards, box lifecycle and >5m visual-only signal policy are unchanged. No new
request, intrabar array, `varip`, dependency or alternate Pine file was added.

## Executed local checks

- Regression RED: revised static suite against the base Pine source produced
  55 PASS / 3 FAIL: host-close gate, delayed creation predicate, obsolete message.
- GREEN: `tests/Invoke-StaticContracts.ps1`: 58 PASS / 0 FAIL.
- `tests/Invoke-TemporalContracts.ps1`: 51 PASS / 0 FAIL, including the existing
  ten negative comparator/guard mutation controls.
- `git diff --check`: PASS.

These checks inspect source structure and restricted predicates/models. They do
not execute Pine, model rollback, or prove realtime availability/alert delivery.

## Owner-reported native acceptance

The owner reports manually updating the indicator in TradingView and successful
compilation. In response to the specific 1-hour chart / 15-minute ORB check, the
owner also confirms correct HIGH/LOW and unchanged levels after reload.
These are owner-reported passes, not direct agent observations. The editor's
bytes/hash, symbol/feed, test date and session were not independently captured.
The local source hash above identifies the delivered artifact, not a measured
hash of the TradingView buffer. No Pine changes were made after this acceptance.

This closes the focused manual acceptance requested before Git/tag delivery.
It does not prove exact 09:45 realtime appearance, ORB30/720m coverage, all replay
cases, uninterrupted live rollover, server alert delivery or Profiler results.

## Agent access and remaining coverage

The owner reports TradingView open in the project's internal browser. This
session's callable tools expose neither browser control nor `node_repl`, which
the installed Computer Use skill requires. Resource discovery also exposes no
browser session. An open tab alone therefore does not establish agent control.
No external browser, private API or alternative desktop automation was used.
No TradingView editor buffer, layout, script or alert was changed by the agent.

1. Compile these exact source bytes in an isolated unpublished Pine copy.
2. On SPY with the same feed/session, compare ORB15/ORB30 against the completed
   09:30 source candle; test 5m, 15m, 60m and 720m chart contexts.
3. On an open higher-timeframe chart bar, verify appearance on the first update
   receiving the completed ORB: after 09:45 for ORB15, after 10:00 for ORB30.
   Confirm fixed high/low, one visible box through later ticks, and matching
   levels after reload. Historical host-bar stepping is not an intrabar test.
4. Confirm waiting before the range closes, no stale prior-date rectangle, and
   no actionable 5m signals above 5m. Other still-open operational gates are
   recorded in the [prior audit](2026-09-06-production-audit.md).

This record supersedes that audit's host-close timing policy and candidate hash,
not its historical observations. The broader audit matrix remains incomplete;
the Git tag records owner-accepted delivery, not exhaustive native certification.
