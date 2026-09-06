[CmdletBinding()]
param(
    [string]$SourcePath = (Join-Path $PSScriptRoot '..\ORB_Opening_Range_Box.pine')
)

# These tests inspect and evaluate a deliberately small subset of Pine expressions.
# They are not a Pine compiler, request.security emulator, or runtime substitute.
$ErrorActionPreference = 'Stop'
$script:Passed = 0
$script:Failed = 0
$guards = @('fiveMinuteSignalsAvailable', 'newConfirmedFiveMinuteCandle',
    'rangeIsAvailable', 'signalTimesAreValid')
$prices = @('closedFiveMinuteClose', 'precedingFiveMinuteClose', 'rangeHigh', 'rangeLow')

function Test-Case([string]$Name, [bool]$Condition) {
    if ($Condition) {
        $script:Passed++
        Write-Host "PASS: $Name"
    } else {
        $script:Failed++
        Write-Host "FAIL: $Name" -ForegroundColor Red
    }
}

function Get-Predicate([string]$Text, [string]$Name) {
    $matchesFound = [regex]::Matches($Text, "(?m)^bool\s+$Name\s*=\s*\(([^()]*)\)")
    if ($matchesFound.Count -ne 1) { throw "Expected one simple $Name predicate." }
    $clauses = @($matchesFound[0].Groups[1].Value.Trim() -split '\s+and\s+')
    foreach ($clause in $clauses) {
        if ($guards -contains $clause) { continue }
        if ($clause -notmatch '^([A-Za-z]+)\s*(>=|<=|>|<)\s*([A-Za-z]+)$') {
            throw "Unsupported predicate clause: $clause"
        }
        if ($prices -notcontains $Matches[1] -or $prices -notcontains $Matches[3]) {
            throw "Unsupported price identifier in: $clause"
        }
    }
    return ,$clauses
}

function Invoke-Predicate([string[]]$Clauses, [hashtable]$Values) {
    foreach ($clause in $Clauses) {
        if ($guards -contains $clause) {
            if (-not $Values[$clause]) { return $false }
            continue
        }
        if ($clause -notmatch '^([A-Za-z]+)\s*(>=|<=|>|<)\s*([A-Za-z]+)$') {
            throw "Unsupported predicate clause: $clause"
        }
        $left = [double]$Values[$Matches[1]]
        $right = [double]$Values[$Matches[3]]
        $result = switch ($Matches[2]) {
            '>' { $left -gt $right }
            '<' { $left -lt $right }
            '>=' { $left -ge $right }
            '<=' { $left -le $right }
        }
        if (-not $result) { return $false }
    }
    return $true
}

function New-Fixture([string]$Name, [double]$Current, [double]$Previous,
    [string]$Expected, [string]$DisabledGuard = '') {
    $values = @{
        closedFiveMinuteClose = $Current; precedingFiveMinuteClose = $Previous
        rangeHigh = 100; rangeLow = 90
        fiveMinuteSignalsAvailable = $true; newConfirmedFiveMinuteCandle = $true
        rangeIsAvailable = $true; signalTimesAreValid = $true
    }
    if ($DisabledGuard) { $values[$DisabledGuard] = $false }
    return @{ Name = $Name; Values = $values; Expected = $Expected }
}

function Get-Direction([string[]]$Upper, [string[]]$Lower, [hashtable]$Values) {
    $up = Invoke-Predicate $Upper $Values
    $down = Invoke-Predicate $Lower $Values
    if ($up -and $down) { return 'Both' }
    if ($up) { return 'Upper' }
    if ($down) { return 'Lower' }
    return 'None'
}

$fixtures = @(
    (New-Fixture 'Upper crossing from boundary' 101 100 'Upper')
    (New-Fixture 'Upper crossing from inside' 101 95 'Upper')
    (New-Fixture 'Upper equality is not a crossing' 100 99 'None')
    (New-Fixture 'Already above upper boundary' 102 101 'None')
    (New-Fixture 'Lower crossing from boundary' 89 90 'Lower')
    (New-Fixture 'Lower crossing from inside' 89 95 'Lower')
    (New-Fixture 'Lower equality is not a crossing' 90 91 'None')
    (New-Fixture 'Already below lower boundary' 88 89 'None')
    (New-Fixture 'Inside range' 95 94 'None')
)
foreach ($guard in $guards) {
    $fixtures += New-Fixture "Upper suppressed by $guard" 101 100 'None' $guard
    $fixtures += New-Fixture "Lower suppressed by $guard" 89 90 'None' $guard
}

$utf8 = [System.Text.UTF8Encoding]::new($false, $true)
$source = $utf8.GetString([System.IO.File]::ReadAllBytes($SourcePath))
# The selected expressions must contain only known identifiers, conjunctions,
# and comparisons. No source text is executed as PowerShell or shell code.
$upper = Get-Predicate $source 'upperBreakout'
$lower = Get-Predicate $source 'lowerBreakout'
foreach ($guard in $guards) {
    Test-Case "Upper production predicate retains $guard" ($upper -contains $guard)
    Test-Case "Lower production predicate retains $guard" ($lower -contains $guard)
}
foreach ($fixture in $fixtures) {
    $actual = Get-Direction $upper $lower $fixture.Values
    Test-Case "Source predicate: $($fixture.Name)" ($actual -eq $fixture.Expected)
}

# Negative controls prove that the tests are sensitive to production mutations.
$mutations = @(
    @{ Name = 'Upper comparison inversion'; From = 'closedFiveMinuteClose > rangeHigh'; To = 'closedFiveMinuteClose < rangeHigh' }
    @{ Name = 'Lower comparison inversion'; From = 'closedFiveMinuteClose < rangeLow'; To = 'closedFiveMinuteClose > rangeLow' }
    @{ Name = 'Upper equality incorrectly accepted'; From = 'closedFiveMinuteClose > rangeHigh'; To = 'closedFiveMinuteClose >= rangeHigh' }
    @{ Name = 'Lower equality incorrectly accepted'; From = 'closedFiveMinuteClose < rangeLow'; To = 'closedFiveMinuteClose <= rangeLow' }
    @{ Name = 'Upper prior boundary incorrectly excluded'; From = 'precedingFiveMinuteClose <= rangeHigh'; To = 'precedingFiveMinuteClose < rangeHigh' }
    @{ Name = 'Lower prior boundary incorrectly excluded'; From = 'precedingFiveMinuteClose >= rangeLow'; To = 'precedingFiveMinuteClose > rangeLow' }
)
foreach ($guard in $guards) {
    $mutations += @{ Name = "Removed $guard"; From = "$guard and"; To = '' }
}
foreach ($mutation in $mutations) {
    $mutant = $source.Replace($mutation.From, $mutation.To)
    $rejected = $false
    if ($mutant -ne $source) {
        $mutantUpper = Get-Predicate $mutant 'upperBreakout'
        $mutantLower = Get-Predicate $mutant 'lowerBreakout'
        foreach ($fixture in $fixtures) {
            if ((Get-Direction $mutantUpper $mutantLower $fixture.Values) -ne $fixture.Expected) {
                $rejected = $true
                break
            }
        }
    }
    Test-Case "Mutation rejected: $($mutation.Name)" $rejected
}

# Independent mapping examples, not execution of request.security. A persistent
# ORB value becomes available after the first 15-minute intrabar. Selecting only
# the first sample misses it; selecting the last confirmed sample retains it.
foreach ($chartMinutes in @(60, 720)) {
    # A 720m SPY RTH chart bar is truncated to 390 minutes: 26 source bars.
    $sampleCount = if ($chartMinutes -eq 720) { 26 } else { 4 }
    $samples = @($null) + @(1..($sampleCount - 1) | ForEach-Object { 100 })
    Test-Case "Mapping model ${chartMinutes}m: first sample misses new ORB" ($null -eq $samples[0])
    Test-Case "Mapping model ${chartMinutes}m: last sample retains new ORB" ($samples[-1] -eq 100)
}

# Independent calendar/data examples complement the source-bound structural
# guards in StaticContracts. These synthetic cases do not execute Pine or claim
# provider/session coverage. DateTime inputs represent exchange-local wall time.
function Test-OpeningModel([datetime]$Open, [datetime]$Close, [datetime]$Observed,
    [int]$Minutes, $High, $Low) {
    return ($Open.Date -eq $Observed.Date -and $Open.TimeOfDay.TotalMinutes -eq 570 -and
        ($Close - $Open).TotalMinutes -eq $Minutes -and $Close -le $Observed -and
        $null -ne $High -and $null -ne $Low -and
        -not [double]::IsNaN($High) -and -not [double]::IsNaN($Low) -and $High -ge $Low)
}
$openingModels = @(
    @{ Name = 'Valid 15m'; Close = '2026-08-28T09:45'; Minutes = 15; High = 100; Low = 90; Expected = $true }
    @{ Name = 'Valid 30m'; Close = '2026-08-28T10:00'; Minutes = 30; High = 100; Low = 90; Expected = $true }
    @{ Name = 'Partial 14m'; Close = '2026-08-28T09:44'; Minutes = 15; High = 100; Low = 90; Expected = $false }
    @{ Name = 'Friday source observed Monday'; Close = '2026-08-28T09:45'; Minutes = 15; High = 100; Low = 90; Expected = $false; Observed = '2026-08-31T04:00' }
    @{ Name = 'Missing high'; Close = '2026-08-28T09:45'; Minutes = 15; High = $null; Low = 90; Expected = $false }
    @{ Name = 'NaN low'; Close = '2026-08-28T09:45'; Minutes = 15; High = 100; Low = [double]::NaN; Expected = $false }
    @{ Name = 'Inverted prices'; Close = '2026-08-28T09:45'; Minutes = 15; High = 90; Low = 100; Expected = $false }
)
foreach ($model in $openingModels) {
    $observed = if ($model.ContainsKey('Observed')) { $model.Observed } else { '2026-08-28T10:00' }
    $valid = Test-OpeningModel '2026-08-28T09:30' $model.Close $observed $model.Minutes $model.High $model.Low
    Test-Case "Opening model: $($model.Name)" ($valid -eq $model.Expected)
}
Test-Case 'Calendar model: evening session change preserves calendar date' (
    ([datetime]'2026-08-28T17:00').Date -eq ([datetime]'2026-08-28T18:00').Date)
Test-Case 'Calendar model: midnight resets within overnight session' (
    ([datetime]'2026-08-28T23:59').Date -ne ([datetime]'2026-08-29T00:00').Date)
Test-Case 'Calendar model: month rollover distinguishes dates' (
    ([datetime]'2026-08-31T23:59').Date -ne ([datetime]'2026-09-01T00:00').Date)
Test-Case 'Calendar model: year rollover distinguishes dates' (
    ([datetime]'2026-12-31T23:59').Date -ne ([datetime]'2027-01-01T00:00').Date)
$newYork = [TimeZoneInfo]::FindSystemTimeZoneById('Eastern Standard Time')
$winterOpen = [datetime]'2026-01-15T09:30'
$summerOpen = [datetime]'2026-07-15T09:30'
Test-Case 'Calendar model: New York 09:30 is 14:30 UTC winter and 13:30 UTC summer' (
    [TimeZoneInfo]::ConvertTimeToUtc($winterOpen, $newYork).ToString('HH:mm') -eq '14:30' -and
    [TimeZoneInfo]::ConvertTimeToUtc($summerOpen, $newYork).ToString('HH:mm') -eq '13:30' -and
    $winterOpen.TimeOfDay -eq $summerOpen.TimeOfDay)

Write-Host "Temporal contracts: $script:Passed passed, $script:Failed failed"
if ($script:Failed -gt 0) { exit 1 }
