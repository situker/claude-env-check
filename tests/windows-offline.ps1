# Portable offline regression tests. Only repository source and synthetic inputs are read.
# Test addresses use loopback, documentation ranges, or .invalid names.
# User-info, query strings and the canary below are fabricated rejection fixtures.
[CmdletBinding()]
param(
    [string]$ScriptPath = ''
)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ScriptPath)) {
    $ScriptPath = Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'windows/claude-env-check.ps1'
}
$tokens = $null; $parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$parseErrors)
if (@($parseErrors).Count) { throw 'Production source is unavailable or failed to parse; nothing was loaded.' }
$functions = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false))

# Deliberately exclude the production entry point and all configuration/network/report I/O.
$requiredFunctions = @(
    'Get-ChecklistDefinitions', 'Get-SafeMessageCatalog', 'Test-LoopbackProxyUri',
    'Get-NoProxyAssessment', 'ConvertFrom-InspectionJson', 'Get-FirewallAssessment',
    'Get-ProbeAssessment', 'Get-ExecutionPlan', 'Format-ReportLines',
    'Set-ChecklistResult', 'Invoke-LocalObservation', 'Set-PresenceObservation'
)
$declarations = @(
    foreach ($name in $requiredFunctions) {
        $matches = @($functions | Where-Object Name -eq $name)
        if ($matches.Count -ne 1) { throw 'Reviewed helper definitions no longer match the test harness.' }
        $matches[0].Extent.Text
    }
)
$inspectionMatches = @($functions | Where-Object Name -eq 'Invoke-ClaudeEnvInspection')
if ($inspectionMatches.Count -ne 1) { throw 'Reviewed inspection definition is missing or ambiguous.' }
$inspectionSource = $inspectionMatches[0].Extent.Text
$commandNames = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object { $_.GetCommandName() })

# A fresh runspace keeps loaded declarations and test state out of the caller.
$testContext = {
    param([string[]]$Declarations, [string]$InspectionSource, [string[]]$CommandNames)
    $ErrorActionPreference = 'Stop'
    $script:blockedOperationCount = 0
    $blockedCommands = @(
        'Get-Content', 'Get-ItemProperty', 'Get-ChildItem', 'Get-Process', 'Get-Service',
        'Get-Command', 'Test-Path', 'Get-NetAdapter', 'Get-NetAdapterBinding',
        'Get-NetIPAddress', 'Get-NetRoute', 'Get-NetTCPConnection',
        'Get-DnsClientServerAddress', 'Get-DnsClientDohServerAddress',
        'Get-NetFirewallRule', 'Get-NetFirewallApplicationFilter', 'Get-NetFirewallAddressFilter',
        'Invoke-RestMethod', 'Invoke-WebRequest', 'Resolve-DnsName', 'Test-NetConnection',
        'Read-InspectionJsonFile', 'Invoke-NetworkObservation', 'Invoke-ClaudeEnvInspection',
        'Write-InspectionReport', 'Out-File', 'Set-Content', 'Add-Content',
        'Start-Process', 'node', 'npm', 'claude', 'wsl', 'curl', 'git', 'netsh'
    )
    foreach ($blockedCommand in $blockedCommands) {
        Set-Item -Path ('Function:{0}' -f $blockedCommand) -Value {
            $script:blockedOperationCount++
            throw 'A real inspection, external application or I/O operation was blocked by the offline harness.'
        }
    }
    foreach ($declaration in $Declarations) { . ([scriptblock]::Create($declaration)) }

$script:failures = New-Object System.Collections.Generic.List[string]
$script:checks = 0
function Assert-Case([bool]$Condition, [string]$Name) {
    $script:checks++
    if ($Condition) { Write-Output "PASS $Name" }
    else { Write-Output "FAIL $Name"; $script:failures.Add($Name) }
}
$canary = 'SENSITIVE_CANARY_9F4Q'

Assert-Case (Test-LoopbackProxyUri -Value 'http://127.0.0.1:32123') 'Loopback HTTP with explicit port accepted'
Assert-Case (Test-LoopbackProxyUri -Value 'https://[::1]:32123') 'Loopback HTTPS IPv6 with explicit port accepted'
$invalidUris = @(
    '', 'http://127.0.0.1', 'http://localhost', 'socks5://127.0.0.1:32123',
    'http://203.0.113.42:32123', 'http://127.0.0.1.evil.invalid:32123',
    'http://fixture:fixture@127.0.0.1:32123', 'http://127.0.0.1:0',
    'http://127.0.0.1:65536', 'http://127.0.0.1:32123/private',
    'http://127.0.0.1:32123?secret=value', 'http://127.0.0.1:32123#secret',
    'http://evil.invalid/path:32123', 'http://fixture:32123@evil.invalid'
)
for ($i = 0; $i -lt $invalidUris.Count; $i++) {
    Assert-Case (-not (Test-LoopbackProxyUri -Value $invalidUris[$i])) ('Unsafe or invalid proxy URI rejected #{0}' -f ($i + 1))
}
foreach ($entry in @('*', 'claude.ai', '.anthropic.com', 'localhost,api.anthropic.com', '*.claude.ai')) {
    $assessment = Get-NoProxyAssessment -Value $entry -ReadSucceeded:$true
    Assert-Case ($assessment.Status -ne 'PASS' -and $assessment.Status -eq 'WARN') 'Service bypass or wildcard is a warning'
}
$assessment = Get-NoProxyAssessment -Value '' -ReadSucceeded:$false
Assert-Case ($assessment.Status -eq 'UNKNOWN') 'Failed NO_PROXY read is unknown'
$assessment = Get-NoProxyAssessment -Value '' -ReadSucceeded:$true
Assert-Case ($assessment.Status -eq 'MANUAL') 'Empty NO_PROXY is not treated as completed acceptance'

$goodJson = ConvertFrom-InspectionJson -Text '{"env":{"HTTP_PROXY":"http://127.0.0.1:32123"}}' -Exists:$true -ReadSucceeded:$true
Assert-Case ($goodJson.State -eq 'OK') 'Valid JSON object is available for inspection'
$badJsons = @('', '{', '{"env":', 'null', '[]', '[{}]', '1', '"text"')
for ($i = 0; $i -lt $badJsons.Count; $i++) {
    $json = ConvertFrom-InspectionJson -Text $badJsons[$i] -Exists:$true -ReadSucceeded:$true
    Assert-Case ($json.State -eq 'ERROR') ('Empty or malformed JSON is an error #{0}' -f ($i + 1))
}
$json = ConvertFrom-InspectionJson -Text '{}' -Exists:$true -ReadSucceeded:$false
Assert-Case ($json.State -eq 'ERROR') 'Unreadable configuration is an error'
$json = ConvertFrom-InspectionJson -Text '' -Exists:$false -ReadSucceeded:$true
Assert-Case ($json.State -eq 'MISSING') 'Missing configuration is distinguished from valid empty object'

# Extract only the reviewed settings-assessment statements, not the inspection
# function or any reads. Its inputs and row state below are entirely synthetic.
$inspection = $InspectionSource
$settingsStart = $inspection.IndexOf('$proxyCode =')
$settingsEnd = $inspection.IndexOf('$bypass =', $settingsStart)
if ($settingsStart -lt 0 -or $settingsEnd -lt 0) { throw 'Settings assessment extraction no longer matches reviewed source.' }
$settingsAssessmentOnly = [scriptblock]::Create($inspection.Substring($settingsStart, $settingsEnd - $settingsStart))
$envFixtures = @(
    [pscustomobject]@{ Text='{}'; Expected='MANUAL' },
    [pscustomobject]@{ Text='{"env":null}'; Expected='MANUAL' },
    [pscustomobject]@{ Text='{"env":{}}'; Expected='MANUAL' },
    [pscustomobject]@{ Text='{"env":"text"}'; Expected='UNKNOWN' },
    [pscustomobject]@{ Text='{"env":1}'; Expected='UNKNOWN' },
    [pscustomobject]@{ Text='{"env":[]}'; Expected='UNKNOWN' },
    [pscustomobject]@{ Text='{"env":[{}]}'; Expected='UNKNOWN' }
)
for ($i = 0; $i -lt $envFixtures.Count; $i++) {
    $settings = ConvertFrom-InspectionJson -Text $envFixtures[$i].Text -Exists:$true -ReadSucceeded:$true
    $lookup = @{}
    foreach ($row in (Get-ChecklistDefinitions)) { $lookup[$row.Id] = $row }
    $bypassValues = New-Object System.Collections.Generic.List[object]
    & $settingsAssessmentOnly
    Assert-Case ($lookup['H2'].Status -eq $envFixtures[$i].Expected -and $lookup['P1'].Status -eq $envFixtures[$i].Expected) ('Missing or non-object env cannot claim successful proxy setup #{0}' -f ($i + 1))
}

$ruleCases = @(
    @(),
    @([pscustomobject]@{Enabled=$true;Action='Allow';Direction='Outbound';DisplayName=$canary}),
    @([pscustomobject]@{Enabled=$false;Action='Block';Direction='Outbound';DisplayName=$canary}),
    @([pscustomobject]@{Enabled='False';Action='Block';Direction='Outbound';DisplayName=$canary}),
    @([pscustomobject]@{Enabled=$true;Action='Block';Direction='Inbound';DisplayName=$canary}),
    @([pscustomobject]@{Enabled=$true;Action='Block';Direction='Outbound';DisplayName=$canary})
)
for ($i = 0; $i -lt $ruleCases.Count; $i++) {
    $fw = Get-FirewallAssessment -Rules $ruleCases[$i] -ReadSucceeded:$true
    Assert-Case ($fw.Status -ne 'PASS') ('Firewall presence alone never grants PASS #{0}' -f ($i + 1))
}
$fw = Get-FirewallAssessment -Rules @() -ReadSucceeded:$false
Assert-Case ($fw.Status -eq 'UNKNOWN') 'Unreadable firewall is unknown'

$missingCommand = Invoke-LocalObservation { throw (New-Object System.Management.Automation.CommandNotFoundException 'Synthetic missing command.') }
Assert-Case (-not $missingCommand.Succeeded) 'Missing-command exception cannot become a successful observation'
$lookup = @{}
foreach ($row in (Get-ChecklistDefinitions)) { $lookup[$row.Id] = $row }
Set-PresenceObservation -Rows $lookup -Id 'H1' -Observation $missingCommand
Assert-Case ($lookup['H1'].Status -eq 'UNKNOWN') 'Missing CLI command is reported as unknown'

$probe = Get-ProbeAssessment -Succeeded:$true -Address '203.0.113.42'
Assert-Case ($probe.State -eq 'OK') 'Successful synthetic IPv4 response is parsed'
$probe = Get-ProbeAssessment -Succeeded:$true -Address '2001:db8::42'
Assert-Case ($probe.State -eq 'OK') 'Successful synthetic IPv6 response is parsed'
foreach ($entry in @('', 'ERR', $canary, '999.999.999.999', '1', '127.1')) {
    $probe = Get-ProbeAssessment -Succeeded:$true -Address $entry
    Assert-Case ($probe.State -eq 'ERROR') 'Invalid network response cannot count as a successful probe'
}
$probe = Get-ProbeAssessment -Succeeded:$false -Address '203.0.113.42'
Assert-Case ($probe.State -eq 'ERROR') 'Network failure stays failure despite a supplied address'

$definitions = @(Get-ChecklistDefinitions)
Assert-Case ($definitions.Count -eq 108) 'Windows definitions cover all 108 Windows/common IDs'
$expectedCounts = [ordered]@{ A=8; B=6; C=7; D=11; E=6; F=6; G=5; H=8; I=5; J=3; K=4; L=4; M=5; N=6; P=10; Q=2; R=6; S=6 }
$expectedIds = @($expectedCounts.Keys | ForEach-Object { $group = $_; 1..$expectedCounts[$group] | ForEach-Object { '{0}{1}' -f $group, $_ } })
Assert-Case (($definitions.Id -join ',') -eq ($expectedIds -join ',')) 'Windows/common IDs cover the expected 108 questions in order, including L1-L4'
Assert-Case (@($definitions | Where-Object Status -eq 'PASS').Count -eq 0) 'Unexecuted defaults cannot grant PASS'
$safeLines = @(Format-ReportLines -Rows $definitions -Online:$false)
Assert-Case ($safeLines.Count -gt 0) 'Default sanitized report can be formatted'
foreach ($row in $definitions) {
    $row.Item = $canary
    $row.Message = $canary
    $row | Add-Member -NotePropertyName Raw -NotePropertyValue $canary -Force
}
$redacted = (@(Format-ReportLines -Rows $definitions -Online:$false) -join "`n")
Assert-Case (-not $redacted.Contains($canary)) 'Raw Item / Message / extra fields never enter formatted output'
foreach ($field in @('Id','Status','Code')) {
    $row = (Get-ChecklistDefinitions)[0]
    $row.$field = $canary
    $resultText = ''; $rejected = $false
    try { $resultText = (@(Format-ReportLines -Rows @($row) -Online:$false) -join "`n") }
    catch { $rejected = $true; $resultText = $_.Exception.Message }
    Assert-Case (-not $resultText.Contains($canary)) ('Malformed report {0} cannot echo sensitive input' -f $field)
    Assert-Case $rejected ('Malformed report {0} is rejected' -f $field)
}

$plan = @(Get-ExecutionPlan -Online:$false)
Assert-Case ($plan.Count -eq 0) 'Default execution plan has no network work'
$onlinePlan = @(Get-ExecutionPlan -Online:$true)
Assert-Case ($onlinePlan.Count -gt 0) 'Explicit online execution has a bounded probe plan'
$forbiddenCommands = @($commandNames | Where-Object { $_ -match '^(node|npm|claude|wsl|curl|git|netsh)(\.exe|\.cmd|\.ps1)?$' })
Assert-Case ($forbiddenCommands.Count -eq 0) 'Production source does not invoke external app commands'
# Numbering regression: fixed definitions supply display numbers and order.
$numberDefinitions = @(Get-ChecklistDefinitions)
$numberExpected = @(1..108)
Assert-Case (($numberDefinitions.Number -join ',') -eq ($numberExpected -join ',')) 'Trusted definitions map internal IDs to consecutive display numbers'
$numberLines = @(Format-ReportLines -Rows $numberDefinitions -Online:$false)
$numberDataLines = @($numberLines | Where-Object { $_ -match '^\d+\s+\|' })
$numberActual = @($numberDataLines | ForEach-Object { [int]([regex]::Match($_, '^\d+').Value) })
Assert-Case ($numberDataLines.Count -eq 108) 'Report renders exactly 108 numbered rows'
Assert-Case (($numberActual -join ',') -eq ($numberExpected -join ',')) 'Default report displays questions 1 through 108 in order'
Assert-Case (@($numberLines | Where-Object { $_ -match '^[A-Z]\d+\s+\|' }).Count -eq 0) 'Report row labels no longer expose legacy letter IDs'
$numberSpoofed = @(Get-ChecklistDefinitions)
foreach ($row in $numberSpoofed) { $row.Number = $canary }
$numberSpoofedLines = @(Format-ReportLines -Rows $numberSpoofed -Online:$false)
Assert-Case (($numberSpoofedLines -join "`n") -ceq ($numberLines -join "`n")) 'Runtime display-number text cannot override trusted numbering or leak canary'
foreach ($row in $numberSpoofed) { $row.Number = 9001 }
Assert-Case ((@(Format-ReportLines -Rows $numberSpoofed -Online:$false) -join "`n") -ceq ($numberLines -join "`n")) 'Runtime numeric display-number spoofing is ignored'
[Array]::Reverse($numberSpoofed)
Assert-Case ((@(Format-ReportLines -Rows $numberSpoofed -Online:$false) -join "`n") -ceq ($numberLines -join "`n")) 'Report order follows trusted definitions even when input rows are reordered'
$numberOnline = @(Format-ReportLines -Rows (Get-ChecklistDefinitions) -Online:$true)
$numberOnlineValues = @($numberOnline | Where-Object { $_ -match '^\d+\s+\|' } | ForEach-Object { [int]([regex]::Match($_, '^\d+').Value) })
Assert-Case (($numberOnlineValues -join ',') -eq ($numberExpected -join ',')) 'Online-mode formatting uses the same consecutive numbers without executing probes'
$numberDuplicate = @(Get-ChecklistDefinitions)
$numberDuplicate[1].Id = $numberDuplicate[0].Id
$numberRejected = $false
try { [void](Format-ReportLines -Rows $numberDuplicate) } catch { $numberRejected = $true }
Assert-Case $numberRejected 'Duplicate internal IDs remain rejected'
$numberIncomplete = @(Get-ChecklistDefinitions)[0..106]
$numberRejected = $false
try { [void](Format-ReportLines -Rows $numberIncomplete) } catch { $numberRejected = $true }
Assert-Case $numberRejected 'Incomplete report remains rejected'

if ($script:blockedOperationCount -ne 0) { throw 'Offline boundary was violated; an operation was blocked.' }
Write-Output ('Engine={0}; Checks={1}; Failures={2}; ProductionEntryPointExecuted=False; RealConfigurationRead=False; NetworkUsed=False' -f $PSVersionTable.PSVersion.Major, $script:checks, $script:failures.Count)
if ($script:failures.Count) { throw 'Offline regression checks failed.' }
}

$runner = [PowerShell]::Create()
try {
    [void]$runner.AddScript($testContext.ToString()).AddArgument($declarations).AddArgument($inspectionSource).AddArgument($commandNames)
    $results = $runner.Invoke()
    foreach ($result in $results) { Write-Output $result }
    # Expected, caught rejection exceptions can set HadErrors even with an empty error stream.
    # Require a completed invocation, no unhandled errors and the complete passing summary.
    $completedSummary = @($results | Where-Object { [string]$_ -match '^Engine=\d+; Checks=83; Failures=0; ProductionEntryPointExecuted=False; RealConfigurationRead=False; NetworkUsed=False$' })
    if ($runner.InvocationStateInfo.State -ne [System.Management.Automation.PSInvocationState]::Completed -or $runner.Streams.Error.Count -ne 0 -or $completedSummary.Count -ne 1) {
        Write-Output 'FAIL: offline harness failed; inspect test labels and reviewed source assumptions.'
        exit 1
    }
} finally {
    $runner.Dispose()
}
