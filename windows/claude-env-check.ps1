# claude-env-check v3.2-reviewfix
# Windows inspection. No persistent settings are changed.
# Network probes require -Online. No external runtimes are started.
# Reports contain only allowlisted text, never runtime values.
[CmdletBinding()]
param([switch]$Online)

function Get-ChecklistDefinitions {
    $definitions = @'
A1|Public exit metadata|Online probes are disabled; review region eligibility against current official policy.
A2|Exit comparison|Online probes are disabled; equal exits do not establish dedicated-proxy coverage.
A3|IPv6-preferred exit|Online probes are disabled; IPv6 availability alone is not a leak finding.
A4|curl IPv4 exit|MANUAL: curl is not started; compare its effective route separately.
A5|curl IPv6 exit|MANUAL: curl is not started; compare its effective route separately.
A6|Local IPv6 addresses|Local address inspection is unavailable.
A7|Dedicated fixed exit|MANUAL: inspect the dedicated configuration and its actual exit.
A8|Registration and daily region|MANUAL: historical registration details do not establish current eligibility.
B1|Configured DNS servers|Local DNS configuration inspection is unavailable.
B2|Platform DNS resolution|MANUAL: inspect the intended application path; no DNS query is issued here.
B3|Remote DNS observation|Online probes are disabled; a remote DNS observation is not a browser leak test.
B4|Windows DoH configuration|Local DoH configuration inspection is unavailable.
B5|Browser DNS|MANUAL: inspect the actual browser context and keep raw results private.
B6|Proxy DNS rule coverage|MANUAL: inspect rules in the intended application path.
C1|WinINET proxy setting|Local WinINET configuration inspection is unavailable.
C2|WinHTTP proxy|MANUAL: no external system command is started to read this setting.
C3|Proxy environment presence|Environment inspection is unavailable; values are never printed.
C4|Proxy environment scheme|Environment inspection is unavailable; this is not an effective-config check.
C5|Endpoint and credential presence|Environment inspection is unavailable; values are never printed.
C6|Direct fallback behavior|MANUAL: perform a scoped failure test without login or model requests.
C7|NO_PROXY bypass candidates|MANUAL: review effective bypass settings in all configuration layers.
D1|Proxy process candidates|Local process inspection is unavailable; names do not prove routing.
D2|TUN adapter candidates|Local adapter inspection is unavailable; names do not prove routing.
D3|Default IPv4 routes|Local route inspection is unavailable.
D4|Default IPv6 routes|Local route inspection is unavailable.
D5|Split routing boundaries|MANUAL: inspect main and dedicated configurations separately.
D6|Automatic exit switching|MANUAL: inspect the intended client configuration.
D7|TUN IPv6 binding candidates|Local adapter-binding inspection is unavailable.
D8|System proxy setting|The WinINET observation does not identify the effective application route.
D9|Git proxy settings|MANUAL: Git is not started; inspect all applicable configuration separately.
D10|Platform domain routing|MANUAL: validate rules in the intended application path.
D11|Proxy startup behavior|MANUAL: inspect startup settings; the script does not change them.
E1|Node HTTPS exit|MANUAL: Node is not started.
E2|WSL exit|MANUAL: WSL is not started; starting it may run its configured boot actions.
E3|Browser exit|MANUAL: verify the actual browser context.
E4|Claude Code effective proxy|MANUAL: review current status and applicable configuration precedence.
E5|Desktop application acceptance|MANUAL: perform application-specific acceptance; no completion is implied.
E6|PowerShell and curl comparison|MANUAL: curl is not started; cross-runtime consistency is unverified.
F1|Timezone|MANUAL: no timezone value is collected and no timezone is scored as safe.
F2|Region and locale|MANUAL: no locale value is collected and no locale is scored as safe.
F3|Language settings|MANUAL: no language list is collected and no language is scored as safe.
F4|Timezone and exit relationship|MANUAL: do not infer account eligibility from timezone comparisons.
F5|Timezone changes|MANUAL: this script does not recommend a particular timezone.
F6|Fonts and browser data|MANUAL: do not erase working assets based on this report.
G1|WebRTC|MANUAL: inspect the actual browser context.
G2|Geolocation permission|MANUAL: inspect the actual browser permission state.
G3|Browser timezone and language|MANUAL: browser-specific settings are not inspected.
G4|Browser profile tools|MANUAL: tool presence does not establish account safety.
G5|Mail link opening context|MANUAL: inspect the actual link-opening application.
H1|Claude CLI discovery|Local command discovery is unavailable; the CLI is not executed.
H2|User settings proxy candidates|User settings inspection is unavailable; final effective configuration is unverified.
H3|API endpoint source|MANUAL: review all endpoint sources without publishing their values.
H4|Credential-source coexistence|Credential-presence inspection is unavailable; credential contents are not read.
H5|MCP configuration presence|Account-file inspection is unavailable; custom names are never printed.
H6|Third-party OAuth use|MANUAL: inspect actual authorization use against current official terms.
H7|Account switching tools|MANUAL: directory presence is not proof of actual tool use.
H8|Interactive status|MANUAL: review the intended session without sharing credentials.
I1|Third-party directory candidates|Local directory inspection is unavailable; names are never printed.
I2|Global package inspection|MANUAL: npm and other package managers are not started.
I3|Editor authentication|MANUAL: extension presence does not identify authentication mode.
I4|Related process candidates|Local process inspection is unavailable; names are never printed.
I5|Third-party tool authentication|MANUAL: inspect actual authentication against current official terms.
J1|Remote-access process candidates|Process inspection is unavailable; presence does not prove account sharing.
J2|Windows user profiles|MANUAL: no user-profile enumeration or user count is collected.
J3|Account sharing|MANUAL: confirm actual use and applicable terms.
K1|Local session assets|MANUAL: no recursive session scan, file count or size is collected.
K2|Backup secret exclusions|MANUAL: repository presence does not prove secrets are excluded.
K3|Project remote backup|MANUAL: validate the intended private backup without publishing its location.
K4|Backup secret handling|MANUAL: inspect exclusions and existing history separately.
L1|Mailbox and mail context|MANUAL: inspect the intended mailbox and link-opening context.
L2|Billing and access region|MANUAL: verify genuine billing facts and current official eligibility requirements.
L3|Card and billing information|MANUAL: verify genuine payment details without publishing them.
L4|Subscription channel|MANUAL: verify the legitimate subscription channel and current terms.
M1|Original local asset preservation|MANUAL: verify originals and backup integrity; backup directories are not scanned.
M2|Export integrity|MANUAL: compare the intended original export and its copy locally.
M3|Readable export vs original|MANUAL: preserve the original export as evidence.
M4|Second backup medium|MANUAL: verify the other medium; no completion is implied.
M5|Migration backlog|MANUAL: track outstanding work; no completion is implied.
N1|Account cache field presence|Account-file inspection is unavailable; absence does not prove logout.
N2|Identifier field presence|Account-file inspection is unavailable; presence does not prove identifiers were never changed.
N3|Reversible isolation|MANUAL: inspect the planned rollback; isolation directories are not enumerated.
N4|Browser logout and server tokens|MANUAL: local files cannot establish server-side token invalidation.
N5|Cache recreation|MANUAL: cache recreation alone does not establish an old login.
N6|Cowork service awareness|MANUAL: inspect the relevant service without changing it.
P1|Loopback proxy candidates|User settings inspection is unavailable; only URI syntax can be inspected here.
P2|Dedicated listener|MANUAL: no connection attempt is made to a local proxy port.
P3|Dedicated configuration rules|MANUAL: inspect the intended configuration without publishing node details.
P4|Outbound firewall candidates|Firewall inspection is unavailable; names alone do not prove coverage.
P5|Firewall address and loopback behavior|MANUAL: inspect effective filters and scoped behavior; addresses are not printed.
P6|Fail-closed behavior|MANUAL: perform a scoped failure test without login or model requests.
P7|Protected launch entry|MANUAL: inspect the actual launch path without publishing it.
P8|Current executable coverage|MANUAL: compare effective filters with the executable and its child processes.
P9|Rollback procedure|MANUAL: document a scoped rollback before changing protection.
P10|Dedicated proxy startup|MANUAL: inspect startup settings; the script does not change them.
Q1|Server IPv6 configuration|MANUAL: inspect the server separately; no SSH session is opened.
Q2|Server reinstall and address|MANUAL: verify provider behavior; reinstalling alone does not prove an address change.
R1|Browser coverage|MANUAL: desktop executable rules do not establish browser coverage.
R2|Cowork VM coverage|MANUAL: validate the VM network separately.
R3|WSL and SSH coverage|MANUAL: validate these separately; they are not started here.
R4|MCP and child-process coverage|MANUAL: validate each relevant process separately.
R5|Post-upgrade coverage|MANUAL: recheck executable coverage after changes.
R6|Scope boundary|No universal leak-prevention or account-safety guarantee is provided.
S1|TLS interception changes|MANUAL: no certificate installation or interception configuration is performed.
S2|Automatic takeover|MANUAL: no startup configuration is changed.
S3|Working assets|No working assets are deleted or migrated by this script.
S4|PATH wrapper state|MANUAL: wrapper state is not inferred from command discovery.
S5|Old-stack cleanup|MANUAL: no packages, processes or directories are removed.
S6|Identifiers and fonts|No device identifier, language or font setting is changed by this script.
'@
    $questionNumber = 0
    foreach ($line in ($definitions -split '\r?\n')) {
        $parts = $line -split '\|', 3
        $questionNumber++
        [pscustomobject]@{ Id = $parts[0]; Number = $questionNumber; Item = $parts[1]; Status = 'MANUAL'; Code = 'DEFAULT'; Message = $parts[2] }
    }
}

function Get-SafeMessageCatalog {
    @{
        UNKNOWN = 'The inspection did not obtain valid evidence; no successful result is inferred.'
        PRESENT = 'A candidate is present; values and names are withheld. Presence does not establish effective behavior.'
        ABSENT = 'No candidate was observed in this limited inspection; other sources still require review.'
        PROXY_ON = 'The inspected WinINET flag is enabled. Application routing still requires review.'
        PROXY_OFF = 'The inspected WinINET flag is disabled. Application routing still requires review.'
        ENV_PRESENT = 'Relevant environment variables are present. Values are withheld; effective configuration requires review.'
        ENV_ABSENT = 'No relevant variable was observed in inspected scopes; other layers still require review.'
        PROXY_SCHEME = 'A SOCKS or unrecognized proxy value needs review against current client support and effective configuration.'
        PROXY_REFERENCE = 'Proxy observations are reference only; application precedence is unresolved.'
        BYPASS_REVIEW = 'MANUAL: no bypass value was observed here; review effective settings in all layers.'
        BYPASS_PRESENT = 'A bypass list is present; values are withheld. Effective behavior requires manual review.'
        BYPASS_RISK = 'A wildcard, platform-domain or malformed bypass candidate needs review; raw values are withheld.'
        SETTINGS_MISSING = 'The inspected user settings file is absent; other configuration sources may apply.'
        SETTINGS_ENV_ABSENT = 'No env object is present in inspected user settings; other sources may apply.'
        PROXY_MISSING = 'User settings do not provide both proxy candidates; effective configuration remains unverified.'
        PROXY_INVALID = 'A proxy candidate fails the strict loopback URI check; raw values are withheld.'
        PROXY_VALID = 'Both candidates have strict loopback URI syntax. Precedence, listener and routing remain unverified.'
        CREDENTIAL_REVIEW = 'Multiple credential-source candidates coexist; inspect actual authentication without sharing secrets.'
        CREDENTIAL_UNKNOWN = 'Local presence observations cannot identify the active authentication method.'
        JSON_MISSING = 'The inspected account file is absent; server-side login and other sources remain unverified.'
        CACHE_PRESENT = 'A selected cache field is present. This does not identify the active account or token state.'
        CACHE_ABSENT = 'Selected fields were absent in a successfully parsed object. This does not establish logout.'
        ID_PRESENT = 'Expected identifier fields are present. Values and history are not inspected or printed.'
        ID_INCOMPLETE = 'Expected identifier fields were not all observed. This does not establish that they were changed.'
        FIREWALL_NONE = 'No enabled outbound blocking candidate was found. Names alone do not establish protection.'
        FIREWALL_CANDIDATE = 'An enabled outbound blocking candidate exists. Effective program, profile and address coverage remain unverified.'
        PROBE_OK = 'A valid external address observation was received. Values are withheld; eligibility is not scored.'
        EXITS_SAME = 'Valid default-path observations agree. Dedicated proxy and other applications remain unverified.'
        EXITS_DIFFER = 'Valid default-path observations differ; inspect routing privately. Addresses are withheld.'
        V6_OBSERVED = 'The default-path dual-stack probe observed IPv6. This alone does not establish a leak.'
        V4_OBSERVED = 'The default-path dual-stack probe observed IPv4. This does not exclude IPv6 elsewhere.'
        DNS_OBSERVED = 'A remote DNS observation was received. Browser and dedicated-path behavior remain unverified.'
    }
}

function Test-LoopbackProxyUri {
    param([object]$Value)
    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value)) { return $false }
    $uri = $null
    if (-not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri)) { return $false }
    if ($uri.Scheme -notin @('http', 'https') -or -not $uri.IsLoopback) { return $false }
    if ($uri.UserInfo -or $uri.Query -or $uri.Fragment -or $uri.AbsolutePath -ne '/') { return $false }
    if ($Value -notmatch '\Ahttps?://(?:127\.0\.0\.1|\[::1\]|localhost):([1-9][0-9]{0,4})/?\z') { return $false }
    return ([int]$Matches[1] -le 65535 -and $uri.Port -gt 0)
}

function Get-NoProxyAssessment {
    param([object]$Value, [bool]$ReadSucceeded = $true)
    if (-not $ReadSucceeded) { return [pscustomobject]@{ Status = 'UNKNOWN'; Code = 'UNKNOWN' } }
    if ($null -eq $Value -or ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value))) {
        return [pscustomobject]@{ Status = 'MANUAL'; Code = 'BYPASS_REVIEW' }
    }
    if ($Value -isnot [string] -or $Value -match '\*|claude|anthropic|://|@') {
        return [pscustomobject]@{ Status = 'WARN'; Code = 'BYPASS_RISK' }
    }
    # NO_PROXY is a list, never a proxy URL. It is never echoed.
    return [pscustomobject]@{ Status = 'MANUAL'; Code = 'BYPASS_PRESENT' }
}

function ConvertFrom-InspectionJson {
    param([string]$Text, [bool]$Exists = $true, [bool]$ReadSucceeded = $true)
    if (-not $ReadSucceeded) { return [pscustomobject]@{ State = 'ERROR'; Data = $null } }
    if (-not $Exists) { return [pscustomobject]@{ State = 'MISSING'; Data = $null } }
    try {
        if ([string]::IsNullOrWhiteSpace($Text) -or -not $Text.TrimStart().StartsWith('{')) { throw 'Invalid input.' }
        $data = ConvertFrom-Json -InputObject $Text -ErrorAction Stop
        if ($data -isnot [pscustomobject] -and $data -isnot [System.Collections.IDictionary]) { throw 'Invalid input.' }
        return [pscustomobject]@{ State = 'OK'; Data = $data }
    } catch { return [pscustomobject]@{ State = 'ERROR'; Data = $null } }
}

function Get-FirewallAssessment {
    param([object[]]$Rules, [bool]$ReadSucceeded = $true)
    if (-not $ReadSucceeded) { return [pscustomobject]@{ Status = 'UNKNOWN'; Code = 'UNKNOWN' } }
    foreach ($rule in $Rules) {
        if ([string]$rule.Enabled -eq 'True' -and [string]$rule.Action -eq 'Block' -and [string]$rule.Direction -eq 'Outbound') {
            return [pscustomobject]@{ Status = 'INFO'; Code = 'FIREWALL_CANDIDATE' }
        }
    }
    return [pscustomobject]@{ Status = 'WARN'; Code = 'FIREWALL_NONE' }
}

function Get-ProbeAssessment {
    param([bool]$Succeeded, [object]$Address)
    $parsed = $null
    if (-not $Succeeded -or $Address -isnot [string]) {
        return [pscustomobject]@{ State = 'ERROR'; Address = $null }
    }
    $candidate = $Address.Trim()
    $v4Text = $candidate -match '\A(?:0|[1-9][0-9]{0,2})(?:\.(?:0|[1-9][0-9]{0,2})){3}\z'
    $v6Text = $candidate.Contains(':') -and $candidate -match '\A[0-9A-Fa-f:.]+\z'
    if ($candidate.Length -gt 45 -or (-not $v4Text -and -not $v6Text) -or -not [Net.IPAddress]::TryParse($candidate, [ref]$parsed)) {
        return [pscustomobject]@{ State = 'ERROR'; Address = $null }
    }
    return [pscustomobject]@{ State = 'OK'; Address = $parsed.ToString() }
}

function Get-ExecutionPlan {
    param([switch]$Online)
    if ($Online) {
        [pscustomobject]@{ Id = 'metadata'; Uri = 'https://ipinfo.io/json' }
        [pscustomobject]@{ Id = 'ipv4'; Uri = 'https://api.ipify.org' }
        [pscustomobject]@{ Id = 'dual'; Uri = 'https://api64.ipify.org' }
        [pscustomobject]@{ Id = 'dns'; Uri = 'https://edns.ip-api.com/json' }
    }
}

function Format-ReportLines {
    param([object[]]$Rows, [switch]$Online)
    $orderedDefinitions = @(Get-ChecklistDefinitions)
    $definitions = @{}
    foreach ($definition in $orderedDefinitions) { $definitions[$definition.Id] = $definition }
    $messages = Get-SafeMessageCatalog
    $output = New-Object System.Collections.Generic.List[string]
    $output.Add('claude-env-check v3.2-reviewfix')
    $output.Add('Scope: Windows observations only. No account-safety certification. Mac checks are manual.')
    $output.Add('Credentials, addresses, ports, private paths, installed versions, custom names and counts are withheld.')
    if ($Online) { $output.Add('Online probes enabled: external services observe request source and metadata.') }
    else { $output.Add('Online probes disabled. External runtimes are not started.') }
    $output.Add('INFO: limited observation; WARN: review needed; UNKNOWN: unavailable evidence; MANUAL: not automatically accepted.')
    $seen = @{}
    $renderedRows = @{}
    foreach ($row in $Rows) {
        if ($row.Id -isnot [string] -or -not $definitions.ContainsKey($row.Id) -or $seen.ContainsKey($row.Id)) { throw 'Invalid report data.' }
        if ($row.Status -isnot [string] -or $row.Status -notin @('INFO', 'WARN', 'UNKNOWN', 'MANUAL')) { throw 'Invalid report data.' }
        if ($row.Code -eq 'DEFAULT') { $message = $definitions[$row.Id].Message }
        elseif ($row.Code -is [string] -and $messages.ContainsKey($row.Code)) { $message = $messages[$row.Code] }
        else { throw 'Invalid report data.' }
        # Runtime Number/Item/Message values are deliberately ignored.
        $renderedRows[$row.Id] = '{0,-4} | {1,-42} | {2,-7} | {3}' -f $definitions[$row.Id].Number, $definitions[$row.Id].Item, ([string]$row.Status).ToUpperInvariant(), $message
        $seen[$row.Id] = $true
    }
    if ($seen.Count -ne $definitions.Count) { throw 'Incomplete report data.' }
    foreach ($definition in $orderedDefinitions) { $output.Add($renderedRows[$definition.Id]) }
    return $output.ToArray()
}

function Set-ChecklistResult {
    param([hashtable]$Rows, [string]$Id, [string]$Status, [string]$Code)
    $Rows[$Id].Status = $Status
    $Rows[$Id].Code = $Code
}

function Read-InspectionJsonFile {
    param([string]$Path)
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction Stop)) { return (ConvertFrom-InspectionJson -Exists $false) }
        return (ConvertFrom-InspectionJson -Text (Get-Content -LiteralPath $Path -Raw -ErrorAction Stop))
    } catch { return (ConvertFrom-InspectionJson -ReadSucceeded $false) }
}

function Invoke-LocalObservation {
    param([scriptblock]$Read)
    try { return [pscustomobject]@{ Succeeded = $true; Data = @(& $Read 3>$null 4>$null 5>$null 6>$null) } }
    catch { return [pscustomobject]@{ Succeeded = $false; Data = @() } }
}

function Set-PresenceObservation {
    param([hashtable]$Rows, [string]$Id, [object]$Observation)
    if (-not $Observation.Succeeded) { Set-ChecklistResult $Rows $Id 'UNKNOWN' 'UNKNOWN' }
    elseif (@($Observation.Data).Count -gt 0) { Set-ChecklistResult $Rows $Id 'INFO' 'PRESENT' }
    else { Set-ChecklistResult $Rows $Id 'INFO' 'ABSENT' }
}

function Invoke-NetworkObservation {
    param([string]$Uri)
    try {
        $data = Invoke-RestMethod -Uri $Uri -TimeoutSec 10 -ErrorAction Stop -WarningAction SilentlyContinue -Verbose:$false -Debug:$false
        return [pscustomobject]@{ Succeeded = $true; Data = $data }
    } catch { return [pscustomobject]@{ Succeeded = $false; Data = $null } }
}

function Invoke-ClaudeEnvInspection {
    param([switch]$Online)
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'This inspection requires Windows.' }
    $rows = @(Get-ChecklistDefinitions)
    $lookup = @{}
    foreach ($row in $rows) { $lookup[$row.Id] = $row }
    $userRoot = [Environment]::GetFolderPath('UserProfile')
    if ([string]::IsNullOrWhiteSpace($userRoot)) { throw 'User configuration location is unavailable.' }

    Set-PresenceObservation $lookup 'A6' (Invoke-LocalObservation { Get-NetIPAddress -AddressFamily IPv6 -ErrorAction Stop | Where-Object { $_.IPAddress -notmatch '^(fe80|::1|fd|fc)' } })
    Set-PresenceObservation $lookup 'B1' (Invoke-LocalObservation { Get-DnsClientServerAddress -ErrorAction Stop | Where-Object { $_.ServerAddresses } })
    Set-PresenceObservation $lookup 'B4' (Invoke-LocalObservation { Get-DnsClientDohServerAddress -ErrorAction Stop })
    $wininet = Invoke-LocalObservation { Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop }
    foreach ($id in @('C1', 'D8')) {
        if (-not $wininet.Succeeded -or $wininet.Data.Count -ne 1 -or $null -eq $wininet.Data[0].ProxyEnable) { Set-ChecklistResult $lookup $id 'UNKNOWN' 'UNKNOWN' }
        elseif ($wininet.Data[0].ProxyEnable -eq 1) { Set-ChecklistResult $lookup $id 'INFO' 'PROXY_ON' }
        elseif ($wininet.Data[0].ProxyEnable -eq 0) { Set-ChecklistResult $lookup $id 'INFO' 'PROXY_OFF' }
        else { Set-ChecklistResult $lookup $id 'UNKNOWN' 'UNKNOWN' }
    }

    $envOK = $true; $proxySeen = $false; $schemeRisk = $false; $authSeen = $false; $apiKeySeen = $false
    $bypassValues = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($scope in @('Process', 'User', 'Machine')) {
            foreach ($name in @('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY')) {
                $value = [Environment]::GetEnvironmentVariable($name, $scope)
                if (-not [string]::IsNullOrWhiteSpace($value)) {
                    $proxySeen = $true
                    if ($value -notmatch '\Ahttps?://') { $schemeRisk = $true }
                }
            }
            $bypassValues.Add([Environment]::GetEnvironmentVariable('NO_PROXY', $scope))
            foreach ($name in @('ANTHROPIC_BASE_URL', 'ANTHROPIC_API_KEY', 'ANTHROPIC_AUTH_TOKEN')) {
                $value = [Environment]::GetEnvironmentVariable($name, $scope)
                if (-not [string]::IsNullOrWhiteSpace($value)) { $authSeen = $true; if ($name -eq 'ANTHROPIC_API_KEY') { $apiKeySeen = $true } }
            }
        }
    } catch { $envOK = $false }
    foreach ($id in @('C3', 'C4', 'C5')) { Set-ChecklistResult $lookup $id 'UNKNOWN' 'UNKNOWN' }
    if ($envOK) {
        Set-ChecklistResult $lookup 'C3' 'INFO' $(if ($proxySeen) { 'ENV_PRESENT' } else { 'ENV_ABSENT' })
        Set-ChecklistResult $lookup 'C4' $(if ($schemeRisk) { 'WARN' } else { 'INFO' }) $(if ($schemeRisk) { 'PROXY_SCHEME' } else { 'PROXY_REFERENCE' })
        Set-ChecklistResult $lookup 'C5' 'INFO' $(if ($authSeen) { 'ENV_PRESENT' } else { 'ENV_ABSENT' })
    }
    $processes = Invoke-LocalObservation { Get-Process -ErrorAction Stop }
    foreach ($pair in @(@('D1', 'v2rayN|xray|sing-box|clash|mihomo|verge'), @('I4', 'claude|ccr|opencode|relay'), @('J1', 'anydesk|teamviewer|todesk|sunlogin|rustdesk'))) {
        Set-PresenceObservation $lookup $pair[0] ([pscustomobject]@{ Succeeded = $processes.Succeeded; Data = @($processes.Data | Where-Object { $_.ProcessName -match $pair[1] }) })
    }
    Set-PresenceObservation $lookup 'D2' (Invoke-LocalObservation { Get-NetAdapter -IncludeHidden -ErrorAction Stop | Where-Object { ($_.Name -match 'tun|sing|meta' -or $_.InterfaceDescription -match 'tun|wintun|sing') -and $_.Status -eq 'Up' } })
    Set-PresenceObservation $lookup 'D3' (Invoke-LocalObservation { Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop })
    Set-PresenceObservation $lookup 'D4' (Invoke-LocalObservation { Get-NetRoute -DestinationPrefix '::/0' -ErrorAction Stop })
    Set-PresenceObservation $lookup 'D7' (Invoke-LocalObservation { Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction Stop | Where-Object { $_.Name -match 'tun|sing|meta' -and $_.Enabled } })
    Set-PresenceObservation $lookup 'H1' (Invoke-LocalObservation { Get-Command -Name claude -ErrorAction Stop })

    $settings = Read-InspectionJsonFile (Join-Path $userRoot '.claude\settings.json')
    $proxyCode = 'UNKNOWN'; $proxyStatus = 'UNKNOWN'; $settingsEnvOK = $true
    if ($settings.State -eq 'MISSING') { $proxyCode = 'SETTINGS_MISSING'; $proxyStatus = 'MANUAL' }
    elseif ($settings.State -eq 'OK') {
        if ($null -eq $settings.Data.env) { $proxyCode = 'SETTINGS_ENV_ABSENT'; $proxyStatus = 'MANUAL' }
        elseif ($settings.Data.env -isnot [pscustomobject] -and $settings.Data.env -isnot [System.Collections.IDictionary]) { $settingsEnvOK = $false }
        else {
            $hp = $settings.Data.env.HTTP_PROXY; $hsp = $settings.Data.env.HTTPS_PROXY
            $bypassValues.Add($settings.Data.env.NO_PROXY)
            if ($null -eq $hp -or $null -eq $hsp -or $hp -eq '' -or $hsp -eq '') { $proxyCode = 'PROXY_MISSING'; $proxyStatus = 'MANUAL' }
            elseif ((Test-LoopbackProxyUri $hp) -and (Test-LoopbackProxyUri $hsp)) { $proxyCode = 'PROXY_VALID'; $proxyStatus = 'INFO' }
            else { $proxyCode = 'PROXY_INVALID'; $proxyStatus = 'WARN' }
            if ($settings.Data.env.ANTHROPIC_API_KEY) { $apiKeySeen = $true }
        }
    }
    foreach ($id in @('H2', 'P1')) { Set-ChecklistResult $lookup $id $proxyStatus $proxyCode }
    $bypass = [pscustomobject]@{ Status = 'MANUAL'; Code = 'BYPASS_REVIEW' }
    foreach ($value in $bypassValues) {
        $assessment = Get-NoProxyAssessment $value
        if ($assessment.Status -eq 'WARN') { $bypass = $assessment; break }
        if ($assessment.Code -eq 'BYPASS_PRESENT') { $bypass = $assessment }
    }
    if ((-not $envOK -or $settings.State -eq 'ERROR' -or -not $settingsEnvOK) -and $bypass.Status -ne 'WARN') { $bypass = Get-NoProxyAssessment -ReadSucceeded $false }
    Set-ChecklistResult $lookup 'C7' $bypass.Status $bypass.Code
    try {
        $credentialExists = Test-Path -LiteralPath (Join-Path $userRoot '.claude\.credentials.json') -PathType Leaf -ErrorAction Stop
        if (-not $envOK -or $settings.State -eq 'ERROR' -or -not $settingsEnvOK) { Set-ChecklistResult $lookup 'H4' 'UNKNOWN' 'UNKNOWN' }
        elseif ($apiKeySeen -and $credentialExists) { Set-ChecklistResult $lookup 'H4' 'WARN' 'CREDENTIAL_REVIEW' }
        else { Set-ChecklistResult $lookup 'H4' 'MANUAL' 'CREDENTIAL_UNKNOWN' }
    } catch { Set-ChecklistResult $lookup 'H4' 'UNKNOWN' 'UNKNOWN' }

    $account = Read-InspectionJsonFile (Join-Path $userRoot '.claude.json')
    foreach ($id in @('H5', 'N1', 'N2')) {
        if ($account.State -eq 'ERROR') { Set-ChecklistResult $lookup $id 'UNKNOWN' 'UNKNOWN' }
        elseif ($account.State -eq 'MISSING') { Set-ChecklistResult $lookup $id 'MANUAL' 'JSON_MISSING' }
    }
    if ($account.State -eq 'OK') {
        Set-ChecklistResult $lookup 'H5' 'INFO' $(if ($null -ne $account.Data.mcpServers) { 'PRESENT' } else { 'ABSENT' })
        $cacheSeen = $false
        foreach ($name in @('oauthAccount', 'orgModelDefaultCache', 'modelAccessCache', 'cachedExtraUsageDisabledReason', 'passesEligibilityCache', 's1mAccessCache')) { if ($account.Data.PSObject.Properties.Name -contains $name) { $cacheSeen = $true } }
        Set-ChecklistResult $lookup 'N1' 'INFO' $(if ($cacheSeen) { 'CACHE_PRESENT' } else { 'CACHE_ABSENT' })
        $identifiersPresent = ($account.Data.PSObject.Properties.Name -contains 'userID') -and ($account.Data.PSObject.Properties.Name -contains 'machineID')
        Set-ChecklistResult $lookup 'N2' 'INFO' $(if ($identifiersPresent) { 'ID_PRESENT' } else { 'ID_INCOMPLETE' })
    }
    Set-PresenceObservation $lookup 'I1' (Invoke-LocalObservation {
        foreach ($name in @('.claude-code-router', '.ccr', '.claude-relay', '.opencode', '.cline', '.roo', '.continue')) {
            if (Test-Path -LiteralPath (Join-Path $userRoot $name) -PathType Container -ErrorAction Stop) { $true }
        }
    })
    $firewall = Invoke-LocalObservation { Get-NetFirewallRule -PolicyStore ActiveStore -Direction Outbound -ErrorAction Stop | Where-Object { $_.DisplayName -match 'Claude|egress' } }
    $assessment = Get-FirewallAssessment -Rules $firewall.Data -ReadSucceeded $firewall.Succeeded
    Set-ChecklistResult $lookup 'P4' $assessment.Status $assessment.Code

    $network = @{}
    foreach ($probe in (Get-ExecutionPlan -Online:$Online)) { $network[$probe.Id] = Invoke-NetworkObservation $probe.Uri }
    if ($Online) {
        $metadata = Get-ProbeAssessment -Succeeded $network.metadata.Succeeded -Address $network.metadata.Data.ip
        $v4 = Get-ProbeAssessment -Succeeded $network.ipv4.Succeeded -Address $network.ipv4.Data
        $dual = Get-ProbeAssessment -Succeeded $network.dual.Succeeded -Address $network.dual.Data
        Set-ChecklistResult $lookup 'A1' $(if ($metadata.State -eq 'OK') { 'INFO' } else { 'UNKNOWN' }) $(if ($metadata.State -eq 'OK') { 'PROBE_OK' } else { 'UNKNOWN' })
        if ($metadata.State -ne 'OK' -or $v4.State -ne 'OK') { Set-ChecklistResult $lookup 'A2' 'UNKNOWN' 'UNKNOWN' }
        elseif ($metadata.Address -eq $v4.Address) { Set-ChecklistResult $lookup 'A2' 'INFO' 'EXITS_SAME' }
        else { Set-ChecklistResult $lookup 'A2' 'WARN' 'EXITS_DIFFER' }
        if ($dual.State -ne 'OK') { Set-ChecklistResult $lookup 'A3' 'UNKNOWN' 'UNKNOWN' }
        else { Set-ChecklistResult $lookup 'A3' 'INFO' $(if ($dual.Address -match ':') { 'V6_OBSERVED' } else { 'V4_OBSERVED' }) }
        $remoteDns = Get-ProbeAssessment -Succeeded $network.dns.Succeeded -Address $network.dns.Data.dns.ip
        Set-ChecklistResult $lookup 'B3' $(if ($remoteDns.State -eq 'OK') { 'INFO' } else { 'UNKNOWN' }) $(if ($remoteDns.State -eq 'OK') { 'DNS_OBSERVED' } else { 'UNKNOWN' })
    }
    return (Format-ReportLines -Rows $rows -Online:$Online)
}

function Write-InspectionReport {
    param([string[]]$Lines, [string]$Directory)
    $reportName = 'claude-env-report-{0}-{1}.txt' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'), ([Guid]::NewGuid().ToString('N').Substring(0, 8))
    $reportPath = Join-Path $Directory $reportName
    $stream = $null; $writer = $null
    try {
        $stream = [IO.File]::Open($reportPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $writer = [IO.StreamWriter]::new($stream, [Text.UTF8Encoding]::new($false))
        foreach ($line in $Lines) { $writer.WriteLine($line) }
        $writer.Flush()
    } finally {
        if ($null -ne $writer) { $writer.Dispose() }
        elseif ($null -ne $stream) { $stream.Dispose() }
    }
}

try {
    $reportLines = @(Invoke-ClaudeEnvInspection -Online:$Online)
    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { throw 'The script directory is unavailable.' }
    Write-InspectionReport -Lines $reportLines -Directory $PSScriptRoot
    foreach ($line in $reportLines) { Write-Host $line }
    Write-Host 'Report saved beside this script using a timestamped filename. No raw values are included.'
    exit 0
} catch {
    [Console]::Error.WriteLine('Inspection or report writing failed. No complete report is confirmed; any file from this run may be partial. No error details are printed.')
    exit 1
}
