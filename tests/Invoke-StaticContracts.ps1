[CmdletBinding()]
param(
    [string]$SourcePath = (Join-Path $PSScriptRoot '..\ORB_Opening_Range_Box.pine')
)

$ErrorActionPreference = 'Stop'
$script:Passed = 0
$script:Failed = 0
$repositoryRoot = Split-Path $PSScriptRoot -Parent

function Test-Contract {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [bool]$Condition,

        [string]$Detail = ''
    )

    if ($Condition) {
        $script:Passed++
        Write-Host "PASS: $Name"
        return
    }

    $script:Failed++
    $suffix = if ($Detail) { " - $Detail" } else { '' }
    Write-Host "FAIL: $Name$suffix" -ForegroundColor Red
}

function Test-Regex {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Pattern
    )

    Test-Contract -Name $Name -Condition ([regex]::IsMatch(
        $Text,
        $Pattern,
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )) -Detail "Expected pattern: $Pattern"
}

function Test-NoRegex {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$Pattern
    )

    Test-Contract -Name $Name -Condition (-not [regex]::IsMatch(
        $Text,
        $Pattern,
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )) -Detail "Forbidden pattern: $Pattern"
}

function Get-ExpectedOrbMode {
    param(
        [bool]$ChartIsStandard,
        [bool]$ChartIsIntraday,
        [bool]$ChartIsTick,
        [int]$ChartSeconds
    )

    if (-not $ChartIsStandard -or -not $ChartIsIntraday -or $ChartIsTick) {
        return 'Invalid'
    }

    if ($ChartSeconds -le 300) {
        return 'Full'
    }

    return 'VisualOnly'
}

if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
    throw "Pine source not found: $SourcePath"
}

$sourceBytes = [System.IO.File]::ReadAllBytes($SourcePath)
$strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
$source = $strictUtf8.GetString($sourceBytes)
$codeOnly = [regex]::Replace($source, '(?m)//.*$', '')

Test-Contract -Name 'Source is UTF-8 without a BOM' -Condition (
    $sourceBytes.Length -lt 3 -or
    -not ($sourceBytes[0] -eq 0xEF -and $sourceBytes[1] -eq 0xBB -and $sourceBytes[2] -eq 0xBF)
)
Test-NoRegex -Name 'Source contains no Unicode replacement characters' -Text $source -Pattern ([string][char]0xFFFD)
Test-NoRegex -Name 'Source contains no trailing whitespace' -Text $source -Pattern '[ \t]+$'
Test-Regex -Name 'Pine version remains v6' -Text $source -Pattern '^//@version=6\r?$'
Test-Regex -Name 'Opening range choices remain 15 and 30 minutes' -Text $codeOnly -Pattern 'options\s*=\s*\["15",\s*"30"\]'

$requestSecurityCount = [regex]::Matches($codeOnly, 'request\.security\s*\(').Count
Test-Contract -Name 'Exactly two request.security calls remain' -Condition ($requestSecurityCount -eq 2) -Detail "Found $requestSecurityCount"
Test-NoRegex -Name 'No lower-timeframe array request is introduced' -Text $codeOnly -Pattern 'request\.security_lower_tf\s*\('
Test-Regex -Name 'Opening range publishes only confirmed high and low values' -Text $codeOnly -Pattern 'confirmedHigh\s*:=\s*high\[1\][\s\S]*confirmedLow\s*:=\s*low\[1\]'
Test-Regex -Name 'ORB mapping selects last LTF snapshot and confirmed HTF snapshot' -Text $codeOnly -Pattern 'lookahead\s*=\s*chartAboveOpeningRange\s*\?\s*barmerge\.lookahead_off\s*:\s*barmerge\.lookahead_on'
Test-NoRegex -Name 'Confirmed ORB drawing does not wait for chart-bar confirmation' -Text $codeOnly -Pattern 'barstate\.isconfirmed|rangeObservationReady'
Test-Regex -Name 'Five-minute request carries confirmed prices and interval endpoints' -Text $codeOnly -Pattern 'expression\s*=\s*\[time\[1\],\s*time_close\[1\],\s*time_close\[2\],\s*close\[1\],\s*close\[2\]\]'
Test-Regex -Name 'Five-minute tuple assignment stays on one line' -Text $codeOnly -Pattern '^\[closedFiveMinuteTime, closedFiveMinuteCloseTime, precedingFiveMinuteCloseTime, closedFiveMinuteClose, precedingFiveMinuteClose\] = request\.security\('
Test-Regex -Name 'Opening candle cannot restore a previous calendar day' -Text $codeOnly -Pattern 'f_calendarDay\(time\[1\]\)\s*==\s*requestedDay'
Test-Regex -Name 'Opening candle must span the complete selected range' -Text $codeOnly -Pattern 'time_close\[1\]\s*-\s*time\[1\]\s*==\s*openingRangeDurationMs'
Test-NoRegex -Name 'Calendar resets do not use daily session bar boundaries' -Text $codeOnly -Pattern 'time\("D"\)'
Test-Regex -Name 'Calendar key includes year month and day' -Text $codeOnly -Pattern 'year\(barTime\)\s*\*\s*10000\s*\+\s*month\(barTime\)\s*\*\s*100\s*\+\s*dayofmonth\(barTime\)'
Test-Regex -Name 'Missing rectangle can be recreated immediately from a valid snapshot' -Text $codeOnly -Pattern 'newConfirmedRange\s*=\s*rangeIsAvailable\s+and\s+na\(orbBox\)'
Test-NoRegex -Name 'Status does not advertise an obsolete chart-close wait' -Text $source -Pattern 'rectangle waits for chart-bar close'
Test-Regex -Name 'Consumer range belongs to the chart calendar date' -Text $codeOnly -Pattern 'f_calendarDay\(rangeOpeningTime\)\s*==\s*chartDay\s+and\s+f_calendarDay\(requestedTime\)\s*==\s*chartDay'
Test-Regex -Name 'Signal interval is complete and adjacent to the preceding candle' -Text $codeOnly -Pattern 'closedFiveMinuteCloseTime\s*-\s*closedFiveMinuteTime\s*==\s*fiveMinuteDurationMs\s+and\s+precedingFiveMinuteCloseTime\s*==\s*closedFiveMinuteTime'
Test-Regex -Name 'Signals start after ORB end on the chart calendar date' -Text $codeOnly -Pattern 'closedFiveMinuteTime\s*>=\s*rangeOpeningTime\s*\+\s*openingRangeDurationMs\s+and\s+f_calendarDay\(closedFiveMinuteTime\)\s*==\s*chartDay'
Test-Regex -Name 'Signals cannot use future or stale observation timestamps' -Text $codeOnly -Pattern 'closedFiveMinuteCloseTime\s*<=\s*time_close\s+and\s+time\s*-\s*closedFiveMinuteCloseTime\s*<\s*fiveMinuteDurationMs'

Test-Regex -Name 'Standard chart types are required' -Text $codeOnly -Pattern 'chart\.is_standard'
Test-Regex -Name 'Intraday chart timeframes are required' -Text $codeOnly -Pattern 'timeframe\.isintraday'
Test-Regex -Name 'Tick timeframes are explicitly rejected' -Text $codeOnly -Pattern 'timeframe\.isticks'
Test-Regex -Name 'Rectangle context is independent of chart duration' -Text $codeOnly -Pattern 'bool\s+supportedChartContext\s*=\s*chart\.is_standard\s+and\s+timeframe\.isintraday\s+and\s+not\s+timeframe\.isticks'
Test-Regex -Name 'Five-minute signal engine is capped at five minutes' -Text $codeOnly -Pattern 'fiveMinuteSignalsAvailable\s*:=\s*timeframe\.in_seconds\(\)\s*<=\s*timeframe\.in_seconds\("5"\)'
Test-Regex -Name 'Invalid time-based contexts stop with a diagnostic' -Text $codeOnly -Pattern 'if\s+not\s+timeframe\.isintraday\s+or\s+timeframe\.isticks\s*\r?\n\s+runtime\.error\s*\('
Test-NoRegex -Name 'Higher timeframes no longer stop the rectangle' -Text $codeOnly -Pattern 'ORB requires a time-based intraday chart with a timeframe of 5 minutes or lower\.'
Test-Regex -Name 'Visual-only mode has a warning table' -Text $codeOnly -Pattern 'var\s+table\s+signalStatusTable\s*=\s*table\.new\s*\('
Test-Regex -Name 'Visual-only warning names the unavailable signals' -Text $source -Pattern 'Visual-only mode: 5M alerts and markers are unavailable'
Test-Regex -Name 'Unavailable range is visibly distinguished from an active box' -Text $source -Pattern 'not na\(orbBox\)\s*\?\s*"ORB rectangle active"\s*:\s*"ORB unavailable:'
Test-Regex -Name 'Status table updates only on the last chart bar' -Text $codeOnly -Pattern 'if\s+barstate\.islast'
Test-Regex -Name 'Full mode clears warning only with a valid range' -Text $codeOnly -Pattern 'if\s+fiveMinuteSignalsAvailable\s+and\s+rangeIsAvailable\s*\r?\n\s+table\.clear\s*\(signalStatusTable'

Test-Regex -Name 'Indicator reserves capacity for managed signal labels' -Text $codeOnly -Pattern 'max_labels_count\s*=\s*200'
Test-Regex -Name 'Signal label IDs are retained for lifecycle management' -Text $codeOnly -Pattern 'var\s+array<label>\s+signalLabels\s*=\s*array\.new<label>\(\)'
Test-Regex -Name 'Prior-day labels are explicitly deleted' -Text $codeOnly -Pattern 'label\.delete\s*\('
Test-Regex -Name 'Deleted label IDs are removed from the array' -Text $codeOnly -Pattern 'array\.clear\s*\(signalLabels\)'
Test-Regex -Name 'Upper markers use managed labels' -Text $codeOnly -Pattern 'label\.style_triangleup'
Test-Regex -Name 'Lower markers use managed labels' -Text $codeOnly -Pattern 'label\.style_triangledown'
Test-NoRegex -Name 'Immutable plotshape markers are no longer used' -Text $codeOnly -Pattern 'plotshape\s*\('
Test-NoRegex -Name 'Marker lifecycle no longer depends on last_bar_time' -Text $codeOnly -Pattern '\blast_bar_time\b'
Test-Regex -Name 'Upper breakout fails closed when five-minute signals are unavailable' -Text $codeOnly -Pattern 'bool\s+upperBreakout\s*=\s*\(\s*\r?\n\s+fiveMinuteSignalsAvailable\s+and'
Test-Regex -Name 'Lower breakout fails closed when five-minute signals are unavailable' -Text $codeOnly -Pattern 'bool\s+lowerBreakout\s*=\s*\(\s*\r?\n\s+fiveMinuteSignalsAvailable\s+and'

$alertConditionCount = [regex]::Matches($codeOnly, 'alertcondition\s*\(').Count
Test-Contract -Name 'Both public alert conditions remain' -Condition ($alertConditionCount -eq 2) -Detail "Found $alertConditionCount"
Test-Regex -Name 'Upper alert remains independent of marker visibility' -Text $codeOnly -Pattern 'condition\s*=\s*enableUpperAlert\s+and\s+upperBreakout'
Test-Regex -Name 'Lower alert remains independent of marker visibility' -Text $codeOnly -Pattern 'condition\s*=\s*enableLowerAlert\s+and\s+lowerBreakout'

$modeFixtures = @(
    @{ Name = 'Standard one-minute chart'; Expected = 'Full'; Arguments = @{ ChartIsStandard = $true; ChartIsIntraday = $true; ChartIsTick = $false; ChartSeconds = 60 } }
    @{ Name = 'Standard five-minute chart'; Expected = 'Full'; Arguments = @{ ChartIsStandard = $true; ChartIsIntraday = $true; ChartIsTick = $false; ChartSeconds = 300 } }
    @{ Name = 'Standard fifteen-minute chart'; Expected = 'VisualOnly'; Arguments = @{ ChartIsStandard = $true; ChartIsIntraday = $true; ChartIsTick = $false; ChartSeconds = 900 } }
    @{ Name = 'Standard sixty-minute chart'; Expected = 'VisualOnly'; Arguments = @{ ChartIsStandard = $true; ChartIsIntraday = $true; ChartIsTick = $false; ChartSeconds = 3600 } }
    @{ Name = 'Daily chart'; Expected = 'Invalid'; Arguments = @{ ChartIsStandard = $true; ChartIsIntraday = $false; ChartIsTick = $false; ChartSeconds = 86400 } }
    @{ Name = 'Tick chart'; Expected = 'Invalid'; Arguments = @{ ChartIsStandard = $true; ChartIsIntraday = $true; ChartIsTick = $true; ChartSeconds = 0 } }
    @{ Name = 'Non-standard chart'; Expected = 'Invalid'; Arguments = @{ ChartIsStandard = $false; ChartIsIntraday = $true; ChartIsTick = $false; ChartSeconds = 900 } }
)

foreach ($fixture in $modeFixtures) {
    $arguments = $fixture.Arguments
    $actual = Get-ExpectedOrbMode @arguments
    Test-Contract -Name "Mode fixture: $($fixture.Name)" -Condition ($actual -eq $fixture.Expected) -Detail "Expected $($fixture.Expected), got $actual"
}

$readmePath = Join-Path $repositoryRoot 'README.md'
$changelogPath = Join-Path $repositoryRoot 'CHANGELOG.md'
Test-Contract -Name 'README documents the supported chart contract' -Condition (
    (Test-Path -LiteralPath $readmePath -PathType Leaf) -and
    (Select-String -LiteralPath $readmePath -Quiet -SimpleMatch 'Visual-only mode') -and
    (Select-String -LiteralPath $readmePath -Quiet -SimpleMatch 'five-minute alerts and markers are disabled')
)
Test-Contract -Name 'README separates TradingView runtime evidence' -Condition (
    (Test-Path -LiteralPath $readmePath -PathType Leaf) -and
    (Select-String -LiteralPath $readmePath -Quiet -SimpleMatch 'Pine v6 compilation in TradingView') -and
    (Select-String -LiteralPath $readmePath -Quiet -SimpleMatch 'Live server alert delivery')
)
Test-Contract -Name 'Indicator identifies release version 1.1.0' -Condition (
    $source.Contains('// Version: 1.1.0') -and
    $source.Contains('title = "ORB Opening Range Box v1.1.0 — by Yulien"') -and
    $source.Contains('shorttitle = "ORB Box v1.1.0"')
)
Test-Contract -Name 'Changelog records release 1.1.0 hardening' -Condition (
    (Test-Path -LiteralPath $changelogPath -PathType Leaf) -and
    (Select-String -LiteralPath $changelogPath -Quiet -SimpleMatch '## [1.1.0] - 2026-09-04') -and
    (Select-String -LiteralPath $changelogPath -Quiet -SimpleMatch 'synthetic non-standard-chart')
)

Write-Host ''
Write-Host "Static contracts: $script:Passed passed, $script:Failed failed"

if ($script:Failed -gt 0) {
    exit 1
}
