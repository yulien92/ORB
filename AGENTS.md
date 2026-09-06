# ORB maintenance

- Canonical publication source: `ORB_Opening_Range_Box.pine`, Pine v6. Keep the
  script self-contained; there is no generated copy or dependency installation.
- Read `SPEC.md` for behavior, `AUDIT.md` for findings, and the latest dated
  validation file before changing timing or declaring release readiness.
- Preserve owner edits and attribution. Use `codex/` working branches. Commit
  and normal push only when authorized; never merge, tag or publish implicitly.
- Existing verification commands (PowerShell 7):

  ```powershell
  & .\tests\Invoke-StaticContracts.ps1
  & .\tests\Invoke-TemporalContracts.ps1
  git diff --check
  ```

- Source pattern checks and restricted-expression/model tests are not Pine
  compilation or request/execution/rollback emulation. Keep mutation controls.
- Preserve confirmed price offsets, explicit context-dependent ORB lookahead,
  calendar date and source interval validation, independent display/alert controls,
  and >5m visual-only behavior. Do not silently restore first-intrabar sampling.
- Draw a confirmed range on the first available update, without waiting for
  host-bar close. Test realtime 60/720m rollback/reload separately from historical
  mapping; test 2/3/4m source-boundary timing rather than assuming it.
- Use the owner's Codex internal browser exclusively for TradingView tests.
  Compile exact candidate bytes in an unpublished copy, preserve unrelated editor
  buffers/layouts, and record the source hash, dataset, settings and observations.
- Keep local checks, Pine compile/runtime, replay, live rollover, delivered alerts,
  Profiler, Git synchronization and actual publication as distinct evidence gates.
- No invented speedups, absolute non-repainting claims, new license or public
  release. Unavailable native checks block readiness, not safe local remediation.
