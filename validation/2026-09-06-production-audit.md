# Production audit validation — 2026-09-06

Historical candidate record. The subsequent [immediate ORB update](2026-09-06-immediate-orb.md)
supersedes this source hash and N03's host-close timing expectation. Other
unexecuted native/operational procedures remain applicable; no passes transfer
automatically to the new source.

Technical verdict: **BLOCKED**. Local checks pass; exact-source Pine-native and
operational release checks have not run. Publication: **NOT PERFORMED**.

## Candidate and environment

- Single source: `ORB_Opening_Range_Box.pine`, displayed version 1.1.0, Pine v6.
- Candidate SHA-256 (UTF-8 without BOM, LF):
  `87C5C8801E2B38C9F45C9BCAE772BF8DCACDFEB2060EE65D1B2B77255DC5833B`.
- Baseline commit: `bc274e6ef85d770bd4288127d5a91b067139fa40`.
- Pre-existing version-only work was separately preserved in `0f882af`.
- Windows host; tests use PowerShell 7.6.5 with no installed test dependencies.
- `.gitattributes` pins LF for Pine/PowerShell/Markdown so a Windows checkout
  preserves the candidate's exact source bytes. No whitespace-stripped hash is
  used as a compilation or semantic equivalence claim.
- No controllable Codex internal-browser tool is exposed. Authentication,
  Pine Editor, chart/replay and Profiler access could not be verified. The owner
  requires the internal browser exclusively; external browser automation was not
  substituted. No TradingView source, layout or existing alert was modified.
- No project CI workflow exists; GitHub API returned `total_count: 0` for
  workflows and `protected: false` for default branch `master`. No bypass used.

## Executed local evidence

All rows below were executed 2026-09-06 against the candidate above unless a
baseline/reproduction revision is explicitly named. Models use synthetic data;
they are not historical market performance or Pine executions.

| ID | Command / procedure and dataset | Expected | Observed / status |
| --- | --- | --- | --- |
| B01 | Baseline working source; `pwsh -NoProfile -File tests/Invoke-StaticContracts.ps1` | Establish prior checks | 54 PASS, 0 FAIL; PASS baseline only |
| B02 | Independent reviewer inverted both current-price comparators in baseline source in memory | A meaningful test should reject inversion | Old suite still 54 PASS; CONFIRMED false positive, remediated below |
| B03 | New restricted-predicate suite's first 35 checks, applied in memory to `git show 0f882af:ORB_Opening_Range_Box.pine` | Reject absent temporal guards | 30 PASS / 5 FAIL (expected RED); final suite below adds further cases |
| S01 | `pwsh -NoProfile -File tests/Invoke-StaticContracts.ps1` | Source structure, requests, offsets, dates, guards, version and docs valid | 57 PASS / 0 FAIL |
| M01 | `pwsh -NoProfile -File tests/Invoke-TemporalContracts.ps1`; opening/calendar model cases | Valid 15/30m accepted; partial14m, Friday-to-Monday, null/NaN and inverted range rejected; evening/midnight/month/year keys and DST distinguished | PASS; part of 51 total below |
| M02 | Same command; independent 60m (4 samples) and 720m RTH (26 samples) ORB15 mapping examples | First snapshot is unavailable; last retains high100 | PASS; model illustrates mapping consequence, does not execute requests |
| M03 | Same command; restricted parser reads actual `upperBreakout` / `lowerBreakout` conjunctions; H100/L90 and C/P boundary cases | Exact equality/non-crossing/suppression cases match; ten comparator/guard mutations rejected | 51 total PASS / 0 FAIL across M01–M03 |
| L01 | `git diff --check`; PowerShell parser; relative Markdown link targets; strict UTF-8 source decode | No whitespace/parser/link errors | PASS; no Pine compiler claim |
| L02 | `git worktree add --detach <temporary-path> e4b3a20`; rerun both suites; compare source SHA-256; `git status --porcelain=v1 --untracked-files=all` | Same candidate bytes and test results without local untracked/ignored dependencies | PASS: 57 static + 51 temporal, matching SHA-256, empty status; clean temporary checkout removed without force |
| R01 | Fresh independent review of `git diff bc274e6`, source, tests and SPEC; reviewer reran S01/M03 | No unaddressed confirmed source defect | PASS at source-review layer; native blockers remain |

Numerical predicates use exact integer fixture values (H100/L90, C101/100/89/90)
to distinguish strict from inclusive boundaries without floating tolerance.
Pine-native candle comparison should use the same feed/session and timestamps,
with absolute price tolerance at most one `syminfo.mintick` to account for UI
display rounding; raw script/source values should match exactly. A larger
difference is investigated, not normalized away. Event timestamps must match
exactly; differing host detection bars on nondivisor intervals are recorded.

The final local scripts contain no source execution via `Invoke-Expression`.
Only allowlisted conjunctions, identifiers and price comparisons are parsed.
The temporal guard internals are structurally checked; calendar/mapping models
cannot validate Pine request scheduling, rollback, feed completeness or delivery.

## Required native and operational matrix

All rows are **BLOCKED / UNEXECUTED** for this candidate because internal-browser
control is unavailable. These are acceptance procedures, not generated passes.
Use an isolated unpublished copy with the exact hash above and a chart on which
its rectangle can be attributed to that copy alone. Record screenshot/log path,
source hash, actual symbol/feed, session, interval, date range and every setting.
Preserve unrelated editor buffers and owner layouts; restore the test changes.

| ID | UI procedure / settings / representative dataset | Expected result |
| --- | --- | --- |
| N01 | Paste exact source preserving indentation into isolated Pine Editor; compile and add | No compiler errors or unexplained critical warnings; visible 1.1.0 identity |
| N02 | AMEX:SPY RTH, historical week 2026-08-24 to 2026-08-28; ORB15 and ORB30, charts1/5/15m; inspect source09:30 candle and next source bar | Range equals completed candle high/low; no incomplete range; supported5m mode and 15m visual-only status |
| N03 | Same SPY sessions with chart30/60/240/720m; both ORB inputs; reload and step to chart close | Correct single box appears when last snapshot is accepted; 60m ORB15 at10:30; 720m at session close; both signal predicates disabled |
| N04 | SPY extended/RTH; sparse-history start after09:30; symbol with no09:30 source candle; Friday-to-Monday gap; representative US early close and holiday | Missing range is visibly unavailable; prior-date data never reinstates a new-date range; partial source bar rejected |
| N05 | SPY charts1/2/3/4/5m and an available seconds interval around09:45/10:00 and actual upper/lower crossings; compare source timestamps before/after reload | Same eligible source-event identities/price comparisons; record possible host detection latency differences; no duplicates or open-source prices |
| N06 | Supported chart plus Heikin-Ashi/Renko/tick/1D rejection; light/dark; narrow/wide screen; width1/5, spacing0/100, both ORB inputs, all marker/alert toggles | Clear error/degradation, visible warnings, no overlay confusion or setting-dependent math; bounded drawings |
| O01 | Replay and later uninterrupted real updates across an exchange-calendar date change; overnight symbol where daily session rolls at18:00; dates around DST/month/year rollover | Labels/box clear at first observed new-calendar-date bar; evening session alone does not reset; same-date predicates remain valid |
| O02 | Replay range build and crossings, reload at aligned timestamps; inspect marker placement | No forward prices; markers retrospectively mark source opening time; no implication they existed at that opening |
| O03 | With separate owner authorization, create isolated test alerts on <=5m; test direction toggles and Once Per Bar; observe real notification and logs | Predicate truth and actual delivery recorded separately; no repeated tick notification; document final-session no-next-update limitation |
| P01 | Native Profiler, three baseline and three candidate runs on identical SPY history/session/TF/inputs, including markers-on worst case; retain output dependence | Record raw run measurements and runtime warnings; no regression/resource failure; do not invent an improvement percentage |

Baseline Profiler comparison must use `0f882af` and candidate data with identical
settings. No baseline or final measurements exist yet. Do not wait indefinitely
for live markets: schedule/authorize an appropriate later session separately.
Bar Replay alone cannot close O01 uninterrupted-live or O03 server-delivery gates.

## Resource assessment

Source inventory: two request contexts, nine tuple elements, two alert plot
counts, one box, one table and a 200-label declaration. Collections retain label
IDs for one chart calendar date. There are no full-history scans or libraries.
Only the right edge is updated on an existing box; unchanged colors/price setters
were removed. This is a structural reduction in calls, not a timed optimization.

Official limits verified 2026-09-06: 40 unique requests (64 Ultimate), 127 tuple
elements, 64 plot counts, 500 box/label IDs and 100000 collection elements.
This inventory is below those count ceilings; actual account runtime, compiled
size, memory and request data availability remain native checks. Loop/total
runtime cannot be inferred from operation counts. No speedup or byte-allocation
claim is made. Sources are linked in [AUDIT.md](../AUDIT.md).

## Readiness and publication

Current local work addresses the confirmed source/test/documentation defects.
Required native/operational/Profiler evidence is still blocked, so the technical
verdict remains BLOCKED. There is no public release, tag or TradingView save or
publication from this audit. The owner also needs to confirm publication mode,
rights/provenance and licensing; these are distinct from the native blockers.

Git closure is verified separately against the actual remote ref in the final
report. The source hash above remains the stable test association across
documentation-only commits; a report does not embed its own final commit hash.

The clean-checkout source/test revision is
`e4b3a20ccb97140710934448d409105f37664737`; subsequent evidence-only changes do
not change the tested Pine or test scripts. Source and test files were scanned
with the staged diff for credential patterns and reviewed for accidental private
or generated content before commit. No credentials were found.
