# Production audit — 2026-09-06

Follow-up: the owner approved immediate rendering of the confirmed ORB during
an open higher-timeframe chart bar. The host-close policy described below is
historical and superseded by [the timing update](validation/2026-09-06-immediate-orb.md)
and current SPEC. Earlier check counts and source hashes apply only to that audit.
The follow-up also records owner-reported compilation and 60m/ORB15 reload
acceptance for the authorized v1.1.0 Git delivery; broader audit coverage remains open.

Status: BLOCKED on exact-candidate native and operational validation. Local
remediation and independent source review are complete. Publication is NOT
PERFORMED. Scope: the existing ORB indicator, its tests, contracts, validation
evidence and publication preparation. No strategy conversion or new trading model.

## Baseline and preservation

- Discovered checkout: `E:\_STORAGE\Codex\Projects\ORB`. The former
  `D:\Documents\ChatGPT\ORB` path no longer exists.
- Baseline HEAD: `bc274e6ef85d770bd4288127d5a91b067139fa40`, branch `master`.
- Verified remote: `https://github.com/yulien92/ORB.git`; remote default `master`
  points to the same baseline. GitHub reports public visibility and push access.
- Four pre-existing intentional edits incremented the indicator to 1.1.0 in
  source, README, changelog and tests. Reviewed and preserved separately in
  commit `0f882af`; there were no staged or untracked files at discovery.
- Baseline working-source SHA-256:
  `7C280CE9C9F40BF4B81E82A5147A70B1EA96A0D547BE4C843ACE8C6A277126A5`.
- Baseline checks: PowerShell 7 `./tests/Invoke-StaticContracts.ps1`: 54 PASS,
  0 FAIL; `git diff --check` PASS. Git reported LF/CRLF conversion warnings.
- No repository SPEC, AGENTS, CI, dependency manifest, generated source,
  license, imports or active hooks found. Global owner instructions apply.
- GitHub open issue/PR search returned no results. No mandated Issue/PR workflow
  was found. Audit branch: `codex/production-audit-2026-09-06`.
- Available: local PowerShell, Git, authenticated GitHub connector, official
  documentation browsing, two genuine independent reviewers. Obsidian retrieval
  and Codex internal-browser automation are not exposed in this session.
- Unavailable: verified TradingView authentication/control, exact-source Pine
  compilation, replay, live alerts and Profiler. No baseline chart outputs or
  timings were captured. The owner requires the internal browser exclusively.

## Reconciliation decisions

The owner requires the rectangle on standard time-based intraday charts above
five minutes, with signals disabled there. The selected 15/30-minute 09:30
exchange-timezone candle defines the range. Preserve this mathematical contract.
Calendar-day resets follow the README intent, not the session-day implementation.
Full intrabar breakout history is not requested on charts above five minutes;
a persistent confirmed ORB snapshot can therefore use one LTF sample per chart
bar without introducing arrays. Higher-chart visibility timing must be explicit.

## Findings ledger

| ID / classification / severity | Location and reproduction | Expected / impact / cause | Fix and verification | Status |
| --- | --- | --- | --- | --- |
| ORB-A01 CONFIRMED DEFECT P1 | ORB request used `lookahead_on` when ChartTF > ORBTF. SPY RTH 720m + ORB15 samples the reset at 09:30 on every historical bar. | Rectangle available after range completion; first-intrabar sampling can omit it. Historical and realtime selection differ. | Last LTF snapshot with host-close observation; confirmed HTF mapping retained. S01/M02 and independent source review PASS. | FIXED locally; N03 pending |
| ORB-A02 CONFIRMED DEFECT P2 | Friday's last available source candle is 09:30; next source candle Monday 04:00. Reset was followed by accepting Friday `time[1]`. | No Monday range before its opening. Missing same-day validation restored stale prices. | Source date, full duration and available OHLC validated; stale consumer dates rejected. S01/M01 PASS. | FIXED locally; N04 pending |
| ORB-A03 CONFIRMED DEFECT P2 | Both resets used `time("D")`, while README promised exchange-calendar days. Overnight daily sessions begin in the evening. | Reset at first observed chart/source bar of a new calendar date. | Explicit exchange date keys; midnight/evening/month/year/DST cases. S01/M01 PASS. | FIXED locally; O01 pending |
| ORB-A04 CONFIRMED DEFECT P2 | Independently inverted both Pine breakout comparisons in memory; all 54 tests still passed. | Tests must reject wrong inequalities. Fixture helper tested itself; patterns checked only the availability prefix. | Removed duplicated breakout helper, evaluated production predicates with an allowlisted parser, added ten negative mutation controls. M03 PASS. | FIXED and locally verified |
| ORB-A05 CONFIRMED DEFECT P2 | README claimed current compilation and 53 tests; evidence source predates v1.1.0. Historical transfer check removed all whitespace, including semantic indentation. | Exact-candidate evidence and accurate counts. Whitespace-stripped hash is insufficient equivalence proof. | Corrected historical interpretation; exact candidate hash and independent blocked gates recorded. `.gitattributes` fixes LF reproducibility. | FIXED documentation; native evidence still blocked |
| ORB-A06 VERIFIED LIMITATION P2 | No controllable internal browser/Profiler or observed live session. | Required release checks must execute; static checks cannot establish native behavior. | Complete local checks and provide precise native matrix. | BLOCKED externally |
| ORB-A07 VERIFIED LIMITATION P3 | No license; only owner attribution and root commit establish provenance. | Publication mode, rights and licensing must be confirmed by owner. | Preserve attribution; prepare ASCII publication title and explain owner decisions. | Owner publication prerequisite |
| ORB-A08 SUSPECTED RISK P2 | Nondivisor 2/3/4m host bars cross 5m source boundaries. | Confirm historical/realtime/reload event timing against identical source candles. No native observation establishes a defect. | Retain promised support; require aligned native boundary tests before readiness. | BLOCKED native test |
| ORB-A09 CONFIRMED DEFECT P2 | Same-date gap: last observed source close09:55, next chart bar12:00. Changed source timestamp could trigger an old crossing; no interval/age predicate existed. | No actionable stale or cross-gap close comparison. | `signalTimesAreValid` checks duration, adjacency, post-ORB date and observation age. S01 and M03 guard-mutation suppression PASS. | FIXED locally; native gap test pending |

## Review coverage

Independent initial passes covered temporal/data correctness and
tests/documentation/resources/publication. A fresh third reviewer checked final
Pine, source-bound tests and SPEC against the baseline and independently ran
57 static + 51 temporal checks, finding no unresolved confirmed source defect.
The coordinator reconciled the final documentation mismatch. Full results and
blocked cases are in [validation](validation/2026-09-06-production-audit.md).
No performance gain is claimed without Profiler data. Financial
model fitting, volume validity, cross-symbol joins, databases, server auth and
third-party dependencies are not applicable to this single-symbol OHLC script.

Intentional timing change: on ChartTF > ORBTF, the first rectangle waits for the
host bar to close (60m ORB15 at10:30 RTH; 720m at session close). The range prices
remain those of the confirmed 09:30 candle. Existing next-source-bar signal
observation can miss a session's final close; this is now explicitly documented,
not represented as guaranteed exact-close alert coverage. Faster intrabar
rendering or a redesigned close-event engine would be separate feature work.

Simplifications: removed the obsolete new-range transition dependency, the
duplicated breakout test implementation and unnecessary per-update price/color
setters. Kept necessary label state and date validation. No new dependencies,
libraries, generated Pine variants, CI system or licensing choices were added.

## Git and release closure

All in-scope work is intended for `codex/production-audit-2026-09-06` on the
verified existing `origin`, never the default branch. Final synchronization is
verified after push against `refs/heads/codex/production-audit-2026-09-06` and
reported with HEAD/upstream hashes and ahead/behind counts in the final response.
No repository Issue/PR workflow or CI was configured; none was bypassed. No PR,
merge, release tag or publication is implied by committing this audit.

## Official references

Verified 2026-09-06; explanations are applied to this source, not universal
non-repainting guarantees:

- https://www.tradingview.com/pine-script-docs/concepts/other-timeframes-and-data/
- https://www.tradingview.com/pine-script-docs/faq/other-data-and-timeframes/
- https://www.tradingview.com/pine-script-docs/language/execution-model/
- https://www.tradingview.com/pine-script-docs/concepts/repainting/
- https://www.tradingview.com/pine-script-docs/concepts/bar-states/
- https://www.tradingview.com/pine-script-docs/concepts/time/
- https://www.tradingview.com/pine-script-docs/concepts/alerts/
- https://www.tradingview.com/pine-script-docs/writing/profiling-and-optimization/
- https://www.tradingview.com/pine-script-docs/writing/limitations/
- https://www.tradingview.com/pine-script-docs/writing/publishing/
- https://www.tradingview.com/support/solutions/43000590599-script-publishing-rules/
- https://learn.chatgpt.com/docs/agent-configuration/agents-md
