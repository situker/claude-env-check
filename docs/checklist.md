# 通用环境复核清单（1–130）

本清单对应 Windows 报告第 1–108 问，macOS 第 109–130 问目前人工核验。它是检查模板，不包含作者或任何真实设备的检查结果。

- 复核优先级只表示检查顺序，不是账号风险分。
- PowerShell/zsh 代码块为有限只读检查；text 代码块为人工说明。逐项阅读，不要整篇批量执行。
- 未执行、证据不足、权限不足和读取失败均不能当成通过。配置存在、出口连通，也不能证明账号状态或所有程序的网络路径。
- 命令不应输出真实 IP、端口、路径、账号、凭据、私人文件数量或自定义名称；不要把原始配置或运行记录上传到仓库。
- 需要断网、重启、登录、模型请求或恢复备份的场景，只能由本人另行安排，本清单不执行这些动作。
- macOS 中的只读命令尚未完成 Mac 真机验收。读取失败转人工检查，不要求提权来凑结果。

INFO 为有限观察，WARN 为需核查的问题，UNKNOWN 为证据不足，MANUAL 为需人工确认。脚本不自动输出 PASS；人工 PASS 也只能覆盖已声明且证据充分的范围。

## 网络出口与 IP（8）

### 1. [ ] 公网 IPv4 / 国家 / ASN

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：本地查看实际使用地区及主体资格，并与官方支持范围逐项比对；私下查看出口地理信息。报告只记支持/不支持/未知，不记录 IP、ASN、城市或节点信息。
```

判断依据：实际使用地区和适用主体资格符合官方支持范围；非 CN 出口不等于合规。无法确认则 UNKNOWN。

### 2. [ ] 多源 IP 检测是否一致

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：先声明测试的是主网络还是专用通道；仅在相同路径下私下对比多个检测源，报告只记一致/不一致/未知。
```

判断依据：相同声明路径的多源结果可相互解释；分流导致不同出口需核验，不自动判泄漏。

### 3. [ ] IPv6 优先出口是否与 IPv4 分叉

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：分别核验指定通道的 IPv4 和 IPv6 路径；双栈检测网址返回 IPv4 不能证明没有 IPv6。未测试的协议族记 UNKNOWN。
```

判断依据：指定通道的 IPv4/IPv6 均符合声明策略；没有可测试 IPv6 基线时，IPv6 故障保护记未验收。

### 4. [ ] curl.exe -4 出口

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：私下核验 curl 的 IPv4 实际路径；同时确认显式代理变量是否生效，不能把它当作 Claude 进程的出口证据。
```

判断依据：与预期策略一致。

### 5. [ ] curl.exe -6 是否直出

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：私下核验 IPv6 连接路径及失败原因；仅超时不能证明断线阻断有效，未能排除站点故障记 UNKNOWN。
```

判断依据：指定通道未出现违反策略的 IPv6 直连；失败原因不明为 UNKNOWN，正常代理 IPv6 成功不自动告警。

### 6. [ ] 本机 IPv6 绑定/全局地址

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  $checkBindings = @(Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction Stop)
  $checkAddresses = @(Get-NetIPAddress -AddressFamily IPv6 -ErrorAction Stop)
  [pscustomobject]@{
    IPv6BindingEnabled = [bool]($checkBindings | Where-Object Enabled)
    NonLocalIPv6AddressPresent = [bool]($checkAddresses | Where-Object { $_.IPAddress -notmatch '^(fe80:|::1$|fd|fc)' })
  }
} catch { 'UNKNOWN: IPv6 status unavailable' }
```

判断依据：无意外全局 IPv6 或已覆盖。

### 7. [ ] Claude 是否固定出口（区分主网络）

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：在本机私下查看专用代理配置，核对单一出站及是否存在选择器、自动切换或直连回退；不复制节点内容。
```

判断依据：专用配置仅一个固定出站，无选择器/自动换出口。

### 8. [ ] 注册国与日常出口叙事

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：仅将注册与日常使用地区作为用户自述记录；是否允许使用以实际所在地和官方主体资格规则为准。
```

判断依据：注册国与出口国关系只作 INFO；不替代实际所在地及官方主体资格核验。

## DNS（6）

### 9. [ ] 系统 DNS 服务器

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  $checkDns = @(Get-DnsClientServerAddress -ErrorAction Stop)
  [pscustomobject]@{ DnsServerConfigured = [bool]($checkDns | Where-Object { $_.ServerAddresses }) }
} catch { 'UNKNOWN: DNS settings unavailable' }
```

判断依据：DNS 实际路径符合已声明策略；是否由代理接管须有证据，不仅凭服务器类型判断泄露。

### 10. [ ] 关键域名解析

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：私下验证关键服务域名的解析结果和代理规则；报告只记可解析/失败/未知，不输出真实解析地址。
```

判断依据：服务域名能够按预期解析；保留地址或 Fake-IP 仅作 INFO，实际出口另验。

### 11. [ ] 服务端视角 DNS 地理

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：第三方 DNS 检测仅作辅助；结合代理解析配置核验，报告只记符合预期/不符/未知，不保存原始响应。
```

判断依据：与策略预期相符。

### 12. [ ] Windows DoH

平台：Windows

- **复核优先级：** 低

核验方法：

```powershell
try {
  $checkDoh = @(Get-DnsClientDohServerAddress -ErrorAction Stop)
  [pscustomobject]@{ WindowsDohEntriesPresent = ($checkDoh.Count -gt 0) }
} catch { 'UNKNOWN: DoH status unavailable' }
```

判断依据：独立 DoH 与代理策略不存在已证实的冲突；无法判断时记录 UNKNOWN。

### 13. [ ] （手动）浏览器 DNS 泄露

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：在浏览器中私下进行 DNS 路径核验；报告仅记录是否符合指定策略。检测网页可接收访问者出口信息。
```

判断依据：与预期一致。

### 14. [ ] Claude 域 DNS 是否跟随代理

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：将域名规则与实际 DNS/连接证据对应起来；只看到规则或解析成功不能认定已走目标出口。
```

判断依据：规则存在且出口符合预期。

## 环境变量与 WinINET（7）

### 15. [ ] WinINET ProxyEnable

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  $checkWininet = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop
  if ($null -eq $checkWininet.ProxyEnable) { 'UNKNOWN: ProxyEnable unavailable' }
  else { [pscustomobject]@{ SystemProxyEnabled = [bool]$checkWininet.ProxyEnable; PacConfigured = [bool]$checkWininet.AutoConfigURL } }
} catch { 'UNKNOWN: system proxy settings unavailable' }
```

判断依据：系统代理状态符合声明架构；与 TUN 并用是否冲突需实测，不仅凭开关判通过或失败。

### 16. [ ] WinHTTP 代理

平台：Windows

- **复核优先级：** 低

核验方法：

```text
# MANUAL：在本机私下查看 WinHTTP 设置；报告只记直连/显式代理/未知，不输出地址。
```

判断依据：记录。

### 17. [ ] 各层 HTTP(S)_PROXY

平台：Windows

- **复核优先级：** 高

核验方法：

```powershell
try {
  foreach ($checkScope in 'Process','User','Machine') {
    $checkProxyValues = @('HTTP_PROXY','HTTPS_PROXY','ALL_PROXY' | ForEach-Object { [Environment]::GetEnvironmentVariable($_,$checkScope) } | Where-Object { $_ })
    [pscustomobject]@{
      Scope = $checkScope
      ProxyValuePresent = ($checkProxyValues.Count -gt 0)
      SocksSchemePresent = [bool]($checkProxyValues | Where-Object { $_ -match '^socks' })
      NoProxyPresent = [bool][Environment]::GetEnvironmentVariable('NO_PROXY',$checkScope)
    }
  }
} catch { 'UNKNOWN: proxy environment unavailable' }
```

判断依据：确认最终生效的 HTTP_PROXY/HTTPS_PROXY 指向预期 HTTP(S) 代理；NO_PROXY 单独核验，不能只认某一层 settings。

### 18. [ ] 是否误用 SOCKS

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：仅检查 Claude Code 的显式代理接口是否使用受支持的 HTTP(S) 方式；不要扫描并否定其他应用的 SOCKS 使用。
```

判断依据：Claude Code 显式代理使用受支持的 HTTP(S) 接口；其直接 SOCKS 接口不受支持。其他应用或代理内部协议另论。

### 19. [ ] BASE_URL / API Key

平台：Windows

- **复核优先级：** 高

核验方法：

```powershell
try {
  foreach ($checkScope in 'Process','User','Machine') {
    [pscustomobject]@{
      Scope = $checkScope
      BaseUrlPresent = [bool][Environment]::GetEnvironmentVariable('ANTHROPIC_BASE_URL',$checkScope)
      ApiKeyPresent = [bool][Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY',$checkScope)
      AuthTokenPresent = [bool][Environment]::GetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN',$checkScope)
    }
  }
} catch { 'UNKNOWN: authentication environment unavailable' }
```

判断依据：认证与端点来源清楚且获准使用；官方支持的组织网关或云平台按对应文档核验，未知来源待核实。

### 20. [ ] 断线是否直连

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：先阅读已有失败测试证据；本清单不自动关闭网络、改代理或注入故障。缺少受控测试证据记 MANUAL/UNKNOWN。
```

判断依据：Claude 专用失败不得回落公网直连。

### 21. [ ] NO_PROXY 误排除

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：私下检查最终生效的 NO_PROXY 绕过名单；报告仅记是否意外排除服务域名，不输出完整名单。
```

判断依据：不含 anthropic/claude 误伤项。

## 主网络：TUN 与规则分流（11）

### 22. [ ] 代理客户端进程

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  $checkProcesses = @(Get-Process -ErrorAction Stop)
  [pscustomobject]@{ ExpectedProxyProcessPresent = [bool]($checkProcesses | Where-Object { $_.ProcessName -match '^(v2rayN|xray|sing-box|clash|mihomo)$' }) }
} catch { 'UNKNOWN: process status unavailable' }
```

判断依据：预期组件运行，且没有证实的路由冲突；出现多个进程不自动判失败。

### 23. [ ] TUN 是否 Up

平台：Windows

- **复核优先级：** 高

核验方法：

```powershell
try {
  $checkTun = @(Get-NetAdapter -IncludeHidden -ErrorAction Stop | Where-Object { $_.Name -match 'tun|sing|meta' -or $_.InterfaceDescription -match 'tun|wintun|sing' })
  [pscustomobject]@{ CandidateTunFound = ($checkTun.Count -gt 0); CandidateTunUp = [bool]($checkTun | Where-Object Status -eq 'Up') }
} catch { 'UNKNOWN: adapter status unavailable' }
```

判断依据：存在 Up 的 TUN。

### 24. [ ] 默认 IPv4 路由

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  $checkRoutes = @(Get-NetRoute -AddressFamily IPv4 -ErrorAction Stop)
  [pscustomobject]@{ DefaultIPv4RoutePresent = [bool]($checkRoutes | Where-Object DestinationPrefix -eq '0.0.0.0/0') }
} catch { 'UNKNOWN: IPv4 route status unavailable' }
```

判断依据：与模式预期一致。

### 25. [ ] IPv6 默认路由

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  $checkRoutes = @(Get-NetRoute -AddressFamily IPv6 -ErrorAction Stop)
  [pscustomobject]@{ DefaultIPv6RoutePresent = [bool]($checkRoutes | Where-Object DestinationPrefix -eq '::/0') }
} catch { 'UNKNOWN: IPv6 route status unavailable' }
```

判断依据：无意外 ::/0。

### 26. [ ] 规则分流与 DIRECT 边界

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：分别查看主网络与专用通道配置；记录策略结论，不复制配置文件或节点细节。
```

判断依据：主网络接受规则分流；专用无 DIRECT。

### 27. [ ] （手动）自动切换 vs 专用固定

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：在客户端与专用配置中私下核对自动切换范围；报告只记哪种路径是否允许切换。
```

判断依据：专用固定；主网络可跟随。

### 28. [ ] TUN IPv6 是否关闭

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  $checkTunBindings = @(Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction Stop | Where-Object { $_.Name -match 'tun|sing|meta' })
  [pscustomobject]@{ CandidateTunBindingFound = ($checkTunBindings.Count -gt 0); CandidateTunIPv6Enabled = [bool]($checkTunBindings | Where-Object Enabled) }
} catch { 'UNKNOWN: TUN binding status unavailable' }
```

判断依据：应用设置、接口状态及实际流量与声明的 IPv6 策略一致；仅绑定状态不足以通过。

### 29. [ ] 系统代理停用

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：参见第 15 问；不输出停用后仍残留的代理字符串。
```

判断依据：系统代理状态符合已声明架构；本次历史方案未以其作为主入口。

### 30. [ ] Git 失效本地代理

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：在本机私下核验 Git 配置作用域与代理是否有效；报告只记是否存在失效配置，不输出端口或地址。
```

判断依据：未设置或指向仍监听端口。

### 31. [ ] Claude 域名优先代理生效

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：私下对照规则命中与目标服务实际连接证据；检测网站出口不能自动代表 Claude 相关域名。
```

判断依据：命中且出口符合预期。

### 32. [ ] （手动）开机自动接管

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：在客户端设置中查看开机接管状态；只记录现状，是否启用是个人操作选择。
```

判断依据：开机接管状态符合本人选择，记录为 INFO；该开关本身不是防封标准。

## 三端出口一致性（6）

### 33. [ ] Node HTTPS 出口

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：先查本机 Node 启动选项、受支持的内置代理功能或显式代理实现；再私下核验实际路径。只报告结论，不输出版本、参数或 IP。
```

判断依据：已确认该 Node 进程的有效代理方式及实际路径；不能以它代替 Claude EXE 的验收。

### 34. [ ] WSL 出口

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：仅在确实使用 WSL 时，另行人工核验 WSL 内的代理与出口；本清单不自动启动 WSL。
```

判断依据：若用 WSL 跑 Claude 须另验；默认未覆盖。

### 35. [ ] （手动）浏览器出口

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：对浏览器访问 Claude 相关域名的实际路径单独验收；普通检测站出口仅为辅助，不代表所有网页。
```

判断依据：与主网络 Claude 优先代理预期一致。

### 36. [ ] Claude Code 实际代理

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：在 Claude Code 内人工查看状态；仅记录有效代理是否符合目标。不得把命令行参数形式的 /status 当作无副作用的自动查询。
```

判断依据：仅确认 Claude Code 的有效代理状态及已实际完成的联网检查；登录、聊天和模型请求须另有证据。

### 37. [ ] （手动）Claude 桌面端

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：查看已有桌面登录、聊天、内嵌 Code 的独立验收记录；没有记录则待验收，本清单不登录或发送模型请求。
```

判断依据：未完整验收前不得 PASS。

### 38. [ ] PowerShell 与 curl 一致性

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：对照 PowerShell、curl 的有效代理和同路径结果；不将其中任何一项自动推广到 Claude 进程。
```

判断依据：符合声明的接管模式。

## 时区 / 语言 / 区域（6）

### 39. [ ] 系统时区

平台：Windows

- **复核优先级：** 信息项

核验方法：

```powershell
try { [pscustomobject]@{ InfoTimezoneSingapore = ((Get-TimeZone -ErrorAction Stop).Id -eq 'Singapore Standard Time') } }
catch { 'UNKNOWN: timezone unavailable' }
```

判断依据：时区仅作 INFO，按真实使用需要设置；不以新加坡、美国或其他时区判防封通过。

### 40. [ ] 区域 / locale

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：私下查看地区与语言设置；仅在排错确有需要时记录泛化结论，不复制完整 locale 列表。
```

判断依据：记录即可。

### 41. [ ] 用户语言列表

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：Windows 用户语言列表和浏览器语言分别核验；只作 INFO，不因含中文扣分。
```

判断依据：系统与浏览器语言只作 INFO；不因中文或与出口不一致判失败。

### 42. [ ] 是否必须对齐美国 IP 时区

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：无需为了匹配出口国家调整时区；记录为个人偏好 INFO。
```

判断依据：不要求把系统时区对齐出口国家；仅作 INFO。

### 43. [ ] 是否必须改成美国时区

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：参见第 39 问/第 42 问；不把美国或新加坡时区作为防封门槛。
```

判断依据：不要求使用美国或新加坡时区；仅作 INFO。

### 44. [ ] 中文字体 / Chrome 资料

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：如需证明未修改，人工对照变更记录或用户确认；仅现有字体/浏览器资料存在不能证明从未修改。
```

判断依据：资料与字体按批准范围保留；未删除不构成账号安全保证。是否未改需有历史证据。

## 浏览器的单独核验（5）

### 45. [ ] （手动）WebRTC 泄露

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：按浏览器使用范围私下检查 WebRTC 行为；只报告与网络策略是否一致，不输出候选地址或检测页面原文。
```

判断依据：无真 IP 泄露为佳；本轮未以改指纹为主轴。

### 46. [ ] （手动）定位权限

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：在浏览器站点权限中私下查看定位权限；仅记录相关站点是否获准，不输出地理位置。
```

判断依据：定位权限符合本人使用需求；本项只记录权限，不作为封号原因判定。

### 47. [ ] （手动）浏览器时区/语言强行对齐

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：分别确认浏览器与系统设置；语言和时区仅作 INFO，不作为账号安全证明。
```

判断依据：不要求为防封修改语言或强行对齐时区；只作 INFO。

### 48. [ ] （手动）指纹浏览器专窗

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：仅记录是否需要独立浏览器资料配置；不用指纹浏览器不构成失败，不导出指纹明细。
```

判断依据：是否使用独立浏览器资料配置只作 INFO；不用指纹浏览器不构成失败。

### 49. [ ] （手动）邮件链接环境

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：由用户确认链接打开方式；不要为了检查而打开真实认证链接或复制邮件中的令牌。
```

判断依据：受控环境打开为佳。

## Claude Code（8）

### 50. [ ] CLI 是否可用

平台：Windows

- **复核优先级：** 低

核验方法：

```powershell
try {
  $checkCli = Get-Command claude -ErrorAction Stop
  [pscustomobject]@{ CliEntryPresent = [bool]$checkCli }
} catch [System.Management.Automation.CommandNotFoundException] { 'INFO: CliEntryPresent=False' }
catch { 'UNKNOWN: CLI lookup failed' }
```

判断依据：CLI 入口存在且来源可核验；是否能完整运行需另验。共享报告不写安装路径或精确版本。

### 51. [ ] settings.json env

平台：Windows

- **复核优先级：** 高

核验方法：

```powershell
try {
  $checkSettingsText = Get-Content (Join-Path $env:USERPROFILE '.claude\settings.json') -Raw -ErrorAction Stop
  if (-not $checkSettingsText.TrimStart().StartsWith('{')) { throw 'Invalid JSON root shape' }
  $checkSettings = $checkSettingsText | ConvertFrom-Json -ErrorAction Stop
  if ($null -eq $checkSettings -or $checkSettings.GetType().FullName -ne 'System.Management.Automation.PSCustomObject') { throw 'JSON root is not an object' }
  $checkEnvPresent = $checkSettings.PSObject.Properties.Name -contains 'env'
  if ($checkEnvPresent -and ($null -eq $checkSettings.env -or $checkSettings.env.GetType().FullName -ne 'System.Management.Automation.PSCustomObject')) { throw 'JSON env is not an object' }
  if (-not $checkEnvPresent) { throw 'JSON env is absent; proxy settings need manual review' }
  foreach ($checkName in 'HTTP_PROXY','HTTPS_PROXY') {
    $checkValue = $checkSettings.env.$checkName
    $checkUri = $null
    $checkValid = [bool]$checkValue -and [uri]::TryCreate([string]$checkValue,[UriKind]::Absolute,[ref]$checkUri)
    [pscustomobject]@{ Field = $checkName; Present = [bool]$checkValue; HttpScheme = ($checkValid -and $checkUri.Scheme -in @('http','https')) }
  }
  $checkBypass = [string]$checkSettings.env.NO_PROXY
  [pscustomobject]@{ NoProxyPresent = [bool]$checkBypass; ServiceBypassNeedsReview = ($checkBypass -match 'anthropic|claude|\*') }
} catch { 'UNKNOWN: user settings unavailable or invalid' }
```

判断依据：HTTP_PROXY/HTTPS_PROXY 为预期代理地址，NO_PROXY 为独立绕过名单；按有效设置层级核验，其他配置语义保持。

### 52. [ ] BASE_URL 是否中转

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：按官方直连、受支持云平台、经授权的组织网关或未知来源分类；不输出完整端点。未知来源须人工核实。
```

判断依据：官方端点、受支持云平台或经授权组织网关均按相应文档核验；未知来源待核实，非官方域名不自动判违规。

### 53. [ ] 订阅与 API Key 混用

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  [pscustomobject]@{
    CredentialFilePresent = (Test-Path (Join-Path $env:USERPROFILE '.claude\.credentials.json') -PathType Leaf -ErrorAction Stop)
    ProcessApiKeyPresent = [bool][Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','Process')
  }
} catch { 'UNKNOWN: authentication presence check failed' }
```

判断依据：清楚当前生效的认证和计费来源；多种凭据存在不自动等于混用或违规。

### 54. [ ] MCP 键名

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  $checkConfigText = Get-Content (Join-Path $env:USERPROFILE '.claude.json') -Raw -ErrorAction Stop
  if (-not $checkConfigText.TrimStart().StartsWith('{')) { throw 'Invalid JSON root shape' }
  $checkConfig = $checkConfigText | ConvertFrom-Json -ErrorAction Stop
  if ($null -eq $checkConfig -or $checkConfig.GetType().FullName -ne 'System.Management.Automation.PSCustomObject') { throw 'JSON root is not an object' }
  [pscustomobject]@{ UserMcpConfigurationPresent = [bool]$checkConfig.mcpServers }
} catch { 'UNKNOWN: user MCP configuration unavailable' }
```

判断依据：MCP 的来源、权限与网络方式符合使用范围；名称含路由或反代不足以判断违规。

### 55. [ ] （手动）第三方 OAuth 外接

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：人工区分官方原版 Claude Code 的宿主环境，与自行接收/保存/转交 Claude.ai 凭据的第三方客户端。
```

判断依据：不把 Claude.ai 凭据交给自行收集、存储或中转这些凭据的第三方客户端；原版 CLI 的第三方宿主按官方条件判断。

### 56. [ ] （手动）多账号切换工具

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：审阅切换工具如何处理凭据及是否符合账号条款；不要导出 Session 或以工具存在直接判违规。
```

判断依据：工具的凭据处理、使用者及用途符合适用条款；无法确认时待核验。

### 57. [ ] （手动）/status

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：参见第 36 问；在交互界面查看，报告只记录代理/认证状态的结论，不复制完整状态页。
```

判断依据：交互状态中有效代理符合第 85 问；仅状态显示不能代替实际联网和功能验收。

## 第三方工具（5）

### 58. [ ] 第三方路由/反代目录

平台：两端通用

- **复核优先级：** 高

核验方法：

```text
# MANUAL：原则两端通用。Windows/Mac 均在用户知情范围内人工审阅已安装工具与认证方式，不扫描并打印目录名；目录存在不证明违规。
```

判断依据：按认证实现判断；目录存在不构成违规证据。第三方自建客户端不得收集、存储或中转 Claude.ai 凭据。

### 59. [ ] 全局 npm 相关包

平台：两端通用

- **复核优先级：** 高

核验方法：

```text
# MANUAL：原则两端通用。私下审阅相关 npm 工具的真实认证实现；不运行会把全局包名和版本写入共享报告的列表命令。
```

判断依据：核验相关工具是否自行处理订阅凭据或仅运行原版 CLI；不能凭 npm 包名判违规。

### 60. [ ] 编辑器扩展认证

平台：两端通用

- **复核优先级：** 高

核验方法：

```text
# MANUAL：原则两端通用。Windows/Mac 均在编辑器扩展页面查看发布者和登录方式；官方 Claude Code 扩展与第三方客户端分别判断。
```

判断依据：官方 Claude Code 扩展在 VS Code/Cursor 中可用受支持订阅登录；第三方客户端按其授权认证方式另行核验。

### 61. [ ] 相关进程

平台：两端通用

- **复核优先级：** 中

核验方法：

```powershell
# Windows；Mac 在活动监视器中按同一原则人工检查，不复制进程列表。
try {
  $checkProcesses = @(Get-Process -ErrorAction Stop)
  [pscustomobject]@{ RelatedProcessPresent = [bool]($checkProcesses | Where-Object { $_.ProcessName -match 'claude|ccr|opencode|relay' }) }
} catch { 'UNKNOWN: process status unavailable' }
```

判断依据：运行组件均有明确用途与授权；仅进程名称不足以判断是否违规。

### 62. [ ] （手动）Cursor/Cline 设置

平台：两端通用

- **复核优先级：** 高

核验方法：

```text
# MANUAL：原则两端通用。在编辑器设置人工确认正在使用官方扩展还是第三方客户端，再依据其受支持的认证方式判断。
```

判断依据：先区分官方扩展、原版 CLI 宿主和第三方自建客户端，再核验各自受支持的认证方式。

## 多设备 / 共享（3）

### 63. [ ] 远控软件

平台：两端通用

- **复核优先级：** 中

核验方法：

```powershell
# Windows；Mac 在活动监视器中按同一原则人工核验，不复制进程列表。
try {
  $checkProcesses = @(Get-Process -ErrorAction Stop)
  [pscustomobject]@{ KnownRemoteControlProcessPresent = [bool]($checkProcesses | Where-Object { $_.ProcessName -match 'anydesk|teamviewer|todesk|sunlogin|rustdesk' }) }
} catch { 'UNKNOWN: process status unavailable' }
```

判断依据：确认实际使用者符合账户条款；远程控制本人设备不自动等于共享账号。

### 64. [ ] 多操作系统用户的凭据隔离

平台：两端通用

- **复核优先级：** 低

核验方法：

```text
# MANUAL：Windows 用账户设置、Mac 用用户与群组设置私下核验账户隔离；不输出本机用户名、数量或目录。
```

判断依据：不同操作系统用户的凭据按权限隔离；Windows/Mac 分别检查，不公开本机用户信息。

### 65. [ ] （手动）多人多端

平台：两端通用

- **复核优先级：** 高

核验方法：

```text
# MANUAL：原则两端通用。由本人确认使用者及设备范围，并分别核验适用环境；不把多设备或出口变化直接等同违规。
```

判断依据：使用者与使用方式符合适用条款；多设备或出口不一致不能单独推定账号违规。

## 日常资产备份（4）

### 66. [ ] ~/.claude 体量

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  [pscustomobject]@{ LocalProjectDirectoryPresent = (Test-Path (Join-Path $env:USERPROFILE '.claude\projects') -PathType Container -ErrorAction Stop) }
} catch { 'UNKNOWN: source directory check failed' }
```

判断依据：有资产则有备份策略。

### 67. [ ] 备份/git 排除密钥

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：在本地人工检查备份策略和已跟踪内容是否包含凭据；仅有 .git 或 .gitignore 不能证明排除成功。
```

判断依据：有明确备份策略并核验已跟踪内容；私有仓库也不能自动视为适合保存凭据。

### 68. [ ] （手动）CLAUDE.md 私有远端

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：人工核验远端访问权限与内容范围；不输出 remote URL、用户名或仓库路径。远端备份非本清单强制要求。
```

判断依据：如选择远端备份，权限和内容范围已核验；不要求所有人必须建立私有远端。

### 69. [ ] （手动）备份排除密钥

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：人工检查当前跟踪内容及历史提交是否包含凭据；仅检查忽略规则不够。发现泄露后另行处理，本清单不轮换或推送。
```

判断依据：凭据不在远端。

## 账号与支付（4）

### 70. [ ] （手动）邮箱与邮件环境

平台：两端通用

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：原则两端通用。由用户确认邮箱控制权与认证链接处理方式；报告不写邮箱地址或账户信息。
```

判断依据：正规邮箱；受控打开链接。

### 71. [ ] （手动）账单国 vs 出口国

平台：两端通用

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：原则两端通用。核验真实账单信息及支付方要求；账单国与出口国是否一致只作 INFO，不作为官方封号评分。
```

判断依据：账单资料真实并符合服务/支付方要求；账单国与出口国一致不是官方封号评分标准。

### 72. [ ] （手动）发卡国 vs 账单国

平台：两端通用

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：原则两端通用。按支付方和服务条款核验真实发卡/账单信息；不输出卡号、账单地址或发行机构信息。
```

判断依据：按服务及支付方要求提供真实资料；发卡国与账单国关系需按支付情形核验，不作防封风险评分。

### 73. [ ] （手动）订阅渠道

平台：两端通用

- **复核优先级：** 中

核验方法：

```text
# MANUAL：原则两端通用。私下核验实际订阅渠道、适用退款流程和条款；不输出订单号、金额或账户资料。
```

判断依据：已知实际渠道对应的退款流程与适用条款；不得把退款或不退款写成对所有渠道和个案的保证。

## 整理环境前资料保全（5）

### 74. [ ] 本机原始数据保全并校验

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：人工读取原始备份范围清单及校验日志，核对来源和副本的覆盖范围；全量与抽检分开记录，只写结论与匿名证据编号。
```

判断依据：备份范围与原件/副本有明确对应且校验记录可复核；全量校验与抽检分别标注，抽检不能证明全量完整。

### 75. [ ] 官网 ZIP/manifest 哈希

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：在本机私下逐一配对原件和副本，使用同一哈希算法比较；只记一致/不一致/未知，不打印文件名、路径、哈希值或数量。
```

判断依据：原件与副本逐一配对并完成同算法哈希比较；仅文件存在、大小相同或目录列表不足以通过。

### 76. [ ] 可读版误当原件

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：在本机私下确认原件仍保留及可读版来源；记录是否能追溯，不读取或转发会话正文。
```

判断依据：不以可读版替代原件。

### 77. [ ] （手动）第二介质

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：人工核对独立介质上的副本及校验记录；没有证据写未验收，不能从本机多个目录推断已有第二介质。
```

判断依据：有独立介质副本及对应校验证据才记已验收；未做与未验收分别记录，不凭本机副本推断。

### 78. [ ] （手动）深读迁移尾项

平台：Windows

- **复核优先级：** 低

核验方法：

```text
# MANUAL：人工核对已整理与待整理范围；共享报告仅写部分完成/未完成，不写会话标题或具体数量。
```

判断依据：知情；未完成不冒充完成。

## 旧账号可回滚隔离（6）

### 79. [ ] 约定的账号/权益缓存字段

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  $checkConfigText = Get-Content (Join-Path $env:USERPROFILE '.claude.json') -Raw -ErrorAction Stop
  if (-not $checkConfigText.TrimStart().StartsWith('{')) { throw 'Invalid JSON root shape' }
  $checkConfig = $checkConfigText | ConvertFrom-Json -ErrorAction Stop
  if ($null -eq $checkConfig -or $checkConfig.GetType().FullName -ne 'System.Management.Automation.PSCustomObject') { throw 'JSON root is not an object' }
  $checkKeys = 'oauthAccount','orgModelDefaultCache','modelAccessCache','cachedExtraUsageDisabledReason','passesEligibilityCache','s1mAccessCache'
  [pscustomobject]@{ AnyTargetFieldPresent = [bool]($checkKeys | Where-Object { $checkConfig.PSObject.Properties.Name -contains $_ }) }
} catch { 'UNKNOWN: target-field check failed' }
```

判断依据：约定字段状态符合范围，且有前后证据支持其他语义未变；无基线只记录现状，不能宣称未改。

### 80. [ ] userID/machineID 未轮换

平台：Windows

- **复核优先级：** 低

核验方法：

```powershell
try {
  $checkConfigText = Get-Content (Join-Path $env:USERPROFILE '.claude.json') -Raw -ErrorAction Stop
  if (-not $checkConfigText.TrimStart().StartsWith('{')) { throw 'Invalid JSON root shape' }
  $checkConfig = $checkConfigText | ConvertFrom-Json -ErrorAction Stop
  if ($null -eq $checkConfig -or $checkConfig.GetType().FullName -ne 'System.Management.Automation.PSCustomObject') { throw 'JSON root is not an object' }
  [pscustomobject]@{ UserIdPresent = [bool]$checkConfig.userID; MachineIdPresent = [bool]$checkConfig.machineID }
} catch { 'UNKNOWN: identifier presence check failed' }
```

判断依据：与历史保护副本比较一致才可确认未轮换；仅字段存在只能记录现状，无基线为 UNKNOWN。

### 81. [ ] 隔离可回滚

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：人工核对隔离映射、原件、审计记录及恢复步骤；仅目录存在不算验收，不扫描磁盘寻找私人目录。
```

判断依据：原件、隔离映射、审计及恢复步骤相互对应；仅有隔离目录不能认定可回滚。

### 82. [ ] （手动）浏览器退出与令牌

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：由用户确认官方会话管理结果；本地退出不能证明服务端所有令牌失效，不为了复核重新登录旧号。
```

判断依据：按用户确认与官方会话管理证据记录退出范围；本机退出不能证明服务端所有令牌已失效。

### 83. [ ] 缓存再生误判

平台：Windows

- **复核优先级：** 低

核验方法：

```text
# MANUAL：结合第 79 问和既定保留范围判断缓存再生；无需追求目录为空，不读取缓存内的认证内容。
```

判断依据：约定字段仍不在则无需零缓存反复清理。

### 84. [ ] Cowork 服务知情

平台：Windows

- **复核优先级：** 低

核验方法：

```powershell
try {
  $checkServices = @(Get-Service -ErrorAction Stop | Where-Object { $_.Name -match 'Cowork' })
  if ($checkServices.Count -eq 0) { 'UNKNOWN: matching service not found' }
  else {
    [pscustomobject]@{
      MatchedServicePresent = $true
      AllMatchedServicesRunning = -not [bool]($checkServices | Where-Object Status -ne 'Running')
      AllMatchedServicesAutomatic = -not [bool]($checkServices | Where-Object StartType -ne 'Automatic')
    }
  }
} catch { 'UNKNOWN: service status unavailable' }
```

判断依据：记录；网络保护另案。

## 断线保护：专用固定出口（10）

### 85. [ ] settings 指向本机 HTTP 代理

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：私下分别核验有效 HTTP_PROXY/HTTPS_PROXY 代理地址和 NO_PROXY 绕过名单；只报格式/范围是否符合预期，不输出值。
```

判断依据：HTTP_PROXY/HTTPS_PROXY 指向预期本机 HTTP 代理；NO_PROXY 是绕过名单，须单独确认未误排除 Claude 相关域名。

### 86. [ ] 专用端口监听

平台：Windows

- **复核优先级：** 中

核验方法：

```powershell
try {
  $checkSettingsText = Get-Content (Join-Path $env:USERPROFILE '.claude\settings.json') -Raw -ErrorAction Stop
  if (-not $checkSettingsText.TrimStart().StartsWith('{')) { throw 'Invalid JSON root shape' }
  $checkSettings = $checkSettingsText | ConvertFrom-Json -ErrorAction Stop
  if ($null -eq $checkSettings -or $checkSettings.GetType().FullName -ne 'System.Management.Automation.PSCustomObject') { throw 'JSON root is not an object' }
  $checkEnvPresent = $checkSettings.PSObject.Properties.Name -contains 'env'
  if ($checkEnvPresent -and ($null -eq $checkSettings.env -or $checkSettings.env.GetType().FullName -ne 'System.Management.Automation.PSCustomObject')) { throw 'JSON env is not an object' }
  if (-not $checkEnvPresent) { throw 'JSON env is absent; proxy settings need manual review' }
  $checkUri = [uri]$checkSettings.env.HTTPS_PROXY
  if (-not $checkUri.IsAbsoluteUri -or $checkUri.Scheme -notin @('http','https') -or -not $checkUri.IsLoopback) { 'UNKNOWN: expected local HTTP proxy not found' }
  else {
    $checkListeners = @(Get-NetTCPConnection -State Listen -ErrorAction Stop)
    [pscustomobject]@{ ConfiguredPortHasListener = [bool]($checkListeners | Where-Object { $_.LocalPort -eq $checkUri.Port }) }
  }
} catch { 'UNKNOWN: listener status unavailable' }
```

判断依据：需使用时目标端点监听且访问范围符合预期；按需启动可接受，单纯端口开放不足以证明可用。

### 87. [ ] （手动）专用配置无 DIRECT

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：私下核对专用配置的出站与回退策略；不复制配置、协议参数或节点标识。
```

判断依据：无 DIRECT、无自动直连回退。

### 88. [ ] 防火墙按 Claude EXE 阻断

平台：Windows

- **复核优先级：** 高

核验方法：

```powershell
try {
  $checkRules = @(Get-NetFirewallRule -Direction Outbound -ErrorAction Stop | Where-Object { $_.DisplayName -match 'Claude|egress' })
  [pscustomobject]@{
    CandidateRulePresent = ($checkRules.Count -gt 0)
    EnabledOutboundBlockPresent = [bool]($checkRules | Where-Object { $_.Enabled -eq 'True' -and $_.Action -eq 'Block' })
  }
} catch { 'UNKNOWN: firewall rule status unavailable' }
```

判断依据：所需应用的规则已启用，出站阻断动作及地址/配置文件范围正确；仅存在同名规则不能通过。

### 89. [ ] 回环保留未误伤

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：核对回环与非回环地址范围，以及已有实测证据；只读过滤器不能单独证明真实流量行为。
```

判断依据：规则范围保留所需回环并阻断目标非回环路径；须有对应实测证据，不能仅看过滤器判通过。

### 90. [ ] （手动）假端口/无代理失败

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：人工核对受控故障测试记录，区分正常代理、不可用端口、代理未启动及协议族；本清单不注入故障、不改环境或登录。
```

判断依据：受控失败测试覆盖已声明场景且未出现禁止的直连成功；缺少测试证据为未验收，超时不能单独证明阻断有效。

### 91. [ ] （手动）受保护启动入口

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：人工审阅受保护入口是否先检查所需条件再启动；报告不输出脚本路径或内容，不执行入口来代替审阅。
```

判断依据：存在；不必永久改 PATH。

### 92. [ ] EXE 路径覆盖当前安装

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：私下核对当前实际执行入口与有效防火墙规则是否一一覆盖；规则路径存在不证明新安装入口已覆盖。
```

判断依据：当前实际运行入口与有效规则一一对应，并有声明范围内的验收证据；路径存在不等于覆盖完整。

### 93. [ ] （手动）回滚知晓

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：只阅读回滚说明和备份证据；报告记录是否具备限定范围回滚说明，不执行回滚。
```

判断依据：先退出 Claude→管理员 PowerShell→只回滚本工具规则与三代理字段。

### 94. [ ] 专用代理开机自启

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：私下查看计划任务、服务和启动项中与该代理相关的状态；只报是否符合个人启动策略，不列名称或路径。
```

判断依据：启动方式符合本人选择，记录为 INFO；不开机自启不是普遍防封要求。

## 服务器配套（2）

### 95. [ ] （手动/SSH）VPS 持久关 IPv6

平台：远程 Linux VPS

- **复核优先级：** 中

核验方法：

```text
# MANUAL：远程 Linux 项：仅对有权访问的主机私下读取当前值、持久配置和既有重启验收记录；本清单不发起 SSH、不修改服务器。
```

判断依据：当前 IPv6 状态与持久配置符合预期；重启后效果须单独验收，无重启证据不得声称已验证。

### 96. [ ] （手动）重装是否自动换 IP

平台：远程 Linux VPS

- **复核优先级：** 低

核验方法：

```text
# MANUAL：远程 Linux 项：根据服务商地址分配方式与前后记录判断；报告只记是否变化，不输出服务器地址。
```

判断依据：地址是否变化取决于服务商分配方式；重装或改协议不保证换 IP。

## 覆盖边界与未完成（6）

### 97. [ ] （手动）Chrome 网页版

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：人工确认浏览器流量不属于 Claude EXE 规则的覆盖范围；是否要额外验收由使用范围决定。
```

判断依据：知情：EXE 规则不覆盖浏览器。

### 98. [ ] （手动）Cowork VM

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：参见第 84 问；Cowork VM 的网络路径须另行核验，服务运行不代表受网络规则保护。
```

判断依据：未覆盖网络保护。

### 99. [ ] （手动）WSL/SSH

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：参见第 34 问；若通过 WSL 或远程 SSH 运行，须按实际运行主机单独核验。
```

判断依据：未覆盖。

### 100. [ ] （手动）独立 MCP/子进程

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：私下核验独立 MCP 与子进程的网络方式；父进程规则不能自动证明子进程已覆盖。
```

判断依据：知情：父规则不自动继承。

### 101. [ ] （手动）升级重核 EXE

平台：Windows

- **复核优先级：** 高

核验方法：

```text
# MANUAL：参见第 92 问；升级后重新核对实际入口与有效规则。仅路径检查不能替代规则和故障测试。
```

判断依据：升级后重新核对实际入口、有效规则及覆盖范围；缺失时不得声称受保护入口可用。

### 102. [ ] （手动）不得声称全域零泄漏

平台：Windows

- **复核优先级：** 中

核验方法：

```text
# MANUAL：检查报告是否超出已验证的应用、协议族、域名和故障情形；未知覆盖必须写清。
```

判断依据：不得声称所有应用/DNS/故障零泄漏。

## 刻意未做与已撤回（6）

### 103. [ ] 未做 HTTPS 解密/MITM

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：依据变更记录或本人确认核验是否安装过解密证书；不导出本机证书列表，不把未安装当作不封保证。
```

判断依据：是否部署解密证书按实际需要与记录核验；本方案未采用，不把未安装当作防封通过。

### 104. [ ] 未开代理开机自动接管

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：参见第 32 问；保持与本人启动策略一致，只作现状记录。
```

判断依据：启动策略符合本人选择；作为 INFO 记录，不作为防封评分。

### 105. [ ] 刻意保留工作资产

平台：Windows

- **复核优先级：** 低

核验方法：

```text
# MANUAL：依据保护范围与前后证据核验资产保留；只报告是否完整/未知，不列私人项目或技能名。
```

判断依据：资产仍在。

### 106. [ ] （手动）已撤回 PATH 包装

平台：Windows

- **复核优先级：** 低

核验方法：

```text
# MANUAL：私下比较历史 PATH 与当前配置、入口使用方式；不打印 PATH。无历史基线只记 UNKNOWN。
```

判断依据：有历史基线与当前配置对比才能确认 PATH 已恢复；仅未发现包装入口不足以证明。

### 107. [ ] （手动）旧独立栈清理边界

平台：Windows

- **复核优先级：** 低

核验方法：

```text
# MANUAL：仅对已声明的旧独立工具检查卸载记录；不扩大到全盘扫描，不删除主客户端自带组件。
```

判断依据：知情：非全盘删除证明；v2rayN 内置 sing-box 必须保留。

### 108. [ ] 未轮换设备标识/未清语言字体

平台：Windows

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：分别参见第 41 问/第 44 问/第 80 问；有历史基线才能确认未改，缺基线记未知，不以当前存在作证明。
```

判断依据：设备标识与语言/字体分别按历史基线核验；缺记录只写现状或 UNKNOWN，不据此判防封通过。

## Mac 实操（16）

### 109. [ ] Mac 这次做了什么、没做什么（与 Windows 区分）

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：先确定本次授权的本端范围与历史记录覆盖范围；Windows 和远程 Linux 的验收结论不得沿用到 Mac。
```

判断依据：本轮范围明确且平台分开；历史验收自述不能代替本轮原始证据核验。

### 110. [ ] 先保全资料了吗

平台：Mac

- **复核优先级：** 高

核验方法：

```text
# MANUAL：Mac：人工核对备份映射、原件/副本配对、批准范围及校验记录；仅查看源目录或文件数量不能证明备份完成。
```

判断依据：批准范围、原件/副本映射及校验记录可对应；只能声称已验证的范围，源文件存在不等于备份完成。

### 111. [ ] 技能链接入口与共用技能是否可用

平台：Mac

- **复核优先级：** 中

核验方法：

```zsh
if [[ ! -d "$HOME/.claude/skills" || ! -r "$HOME/.claude/skills" || ! -x "$HOME/.claude/skills" ]]; then
  print -r -- 'UNKNOWN: skill entry unavailable'
else
  check_link_found=false
  check_target_unavailable=false
  for check_link in "$HOME/.claude/skills"/*(ND@); do
    check_link_found=true
    [[ -e "$check_link" ]] || check_target_unavailable=true
  done
  print -r -- "INFO: LinkFound=$check_link_found TargetUnavailable=$check_target_unavailable"
fi
```

判断依据：入口存在且可读，目标逐项检查成功；无输出、目录缺失或读取失败均不能判全部可用。

### 112. [ ] Claude Code 是否已官方退出旧登录

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：在 Claude Code 交互界面查看登录状态；不把版本命令当作退出证明，也不为复核重新登录旧号。
```

判断依据：旧账号已用官方方式退出。

### 113. [ ] Claude Desktop 是否回到登录页

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：人工观察 Desktop 是否停留在登录页；只记录页面状态，不截图或转发账号信息。
```

判断依据：显示登录页。

### 114. [ ] 浏览器是否只处理了 Claude 站点数据

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：依据已批准清理范围和操作记录，核验 Chrome/Safari 仅处理相关站点；不输出站点数据或浏览器资料。
```

判断依据：只清 Claude 相关登录与站点数据；未重置整个浏览器或系统钥匙串。

### 115. [ ] 缓存是否可回退隔离而非删除

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：人工核对隔离映射、原位置、目标位置、恢复方法和保护项校验记录；目录列表不能证明可恢复，不执行恢复。
```

判断依据：隔离映射、原件、恢复方法与保护项证据完整；目录存在或缓存消失不能证明可恢复。

### 116. [ ] 系统时区是否新加坡、自动时区关闭

平台：Mac

- **复核优先级：** 信息项

核验方法：

```zsh
if check_zone=$(readlink /etc/localtime 2>/dev/null); then
  case "$check_zone" in
    */Asia/Singapore) print -r -- 'INFO: TimezoneSingapore=True' ;;
    *) print -r -- 'INFO: TimezoneSingapore=False' ;;
  esac
else
  print -r -- 'UNKNOWN: timezone unavailable'
fi
if check_auto=$(defaults read /Library/Preferences/com.apple.timezone.auto Active 2>/dev/null); then
  case "$check_auto" in
    0) print -r -- 'INFO: AutomaticTimezone=False' ;;
    1) print -r -- 'INFO: AutomaticTimezone=True' ;;
    *) print -r -- 'UNKNOWN: automatic timezone value unrecognized' ;;
  esac
else
  print -r -- 'UNKNOWN: automatic timezone unavailable; inspect System Settings'
fi
```

判断依据：时区与自动时区状态按个人需要记录为 INFO；不以特定时区判防封通过，读不到记 UNKNOWN。

### 117. [ ] 自动校时是否保留

平台：Mac

- **复核优先级：** 信息项

核验方法：

```zsh
if check_time=$(/usr/sbin/systemsetup -getusingnetworktime 2>/dev/null); then
  case "$check_time" in
    'Network Time: On') print -r -- 'INFO: NetworkTimeEnabled=True' ;;
    'Network Time: Off') print -r -- 'INFO: NetworkTimeEnabled=False' ;;
    *) print -r -- 'UNKNOWN: network time status unavailable; inspect System Settings' ;;
  esac
else
  print -r -- 'UNKNOWN: network time status unavailable; inspect System Settings'
fi
```

判断依据：自动校时状态符合本人需要；只记录 INFO，不输出服务器信息。

### 118. [ ] 系统地区与语言是否保持原样

平台：Mac

- **复核优先级：** 信息项

核验方法：

```text
# MANUAL：Mac：根据操作记录或本人确认判断是否改动地区/语言；无历史基线不能只凭当前值证明未改。
```

判断依据：是否改动须根据历史记录或本人确认；当前地区/语言仅作 INFO，不作为防封门槛。

### 119. [ ] 小火箭是否导入已有节点并保留原配置

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：在代理应用本地私下核对节点参数、原配置保留情况及回退副本；报告不输出节点、协议参数、版本或数量。
```

判断依据：导入参数与获准配置一致，并有原配置/回退副本对应证据；不披露节点或协议参数。

### 120. [ ] 出口国家是否为预期

平台：Mac

- **复核优先级：** 高

核验方法：

```text
# MANUAL：Mac：分别核验本次测试通道的出口国家与 IPv6 测试范围；报告只写符合/不符/未知，不输出 IP 或原始响应。
```

判断依据：本次明确测试的路径与预期出口相符；实际使用资格另核验，IPv6 未测范围必须保留未知。

### 121. [ ] Google 连通（204）

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：私下核验 Google 连通测试结果；共享报告只记预期响应/失败/未知，不能据此认定 Claude 已可用。
```

判断依据：Google 连通测试取得预期响应；仅证明该次目标连接，不代表 Claude 登录或模型请求可用。

### 122. [ ] 测试时是否没有显式 HTTP/SOCKS 代理

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：私下同时核对代理环境变量、系统代理及应用自身设置；报告只写有/无/未知，不运行原样打印 env/scutil 输出的命令。
```

判断依据：明确环境变量、系统代理和应用自身代理的状态；没有显式代理变量不能单独证明全部流量走 VPN/TUN。

### 123. [ ] Claude 网络诊断与浏览器实开

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：分别记录 Claude 网络诊断、Safari 打开 Google、Claude 页面和登录/模型请求的验收范围；未做的项目保持未验收。
```

判断依据：分别写明诊断目标、浏览器打开的站点及实际成功范围；打开 Google 不能替代 Claude 登录或模型请求验收。

### 124. [ ] CCBaga 是否只审阅未执行预设

平台：Mac

- **复核优先级：** 低

核验方法：

```text
# MANUAL：Mac：根据源码审阅与操作记录确认是否执行预设；不安装或运行清理工具进行反证。
```

判断依据：只审阅源码与手册，按精确方案手动处理。

## Mac 未验收与边界（6）

### 125. [ ] 断线阻断（kill switch）

平台：Mac

- **复核优先级：** 高

核验方法：

```text
# MANUAL：Mac：先核验是否已有或另行部署断线阻断及其验收记录；没有证据写未验收，不断开网络来自动测试。
```

判断依据：专用断线阻断及实际故障效果均须独立证据；当前为未验收。

### 126. [ ] 开机自动连接

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：查看现有登录项与应用设置只能记录配置状态；没有启动场景验收记录，自动连接效果仍未验收。
```

判断依据：未取得证据前保持未验收；配置存在与开机实际连接效果分开判断。

### 127. [ ] 所有应用是否都走代理

平台：Mac

- **复核优先级：** 高

核验方法：

```text
# MANUAL：Mac：没有逐应用证据时保持全应用覆盖未验收；已有某个应用成功不能推广到全部应用。
```

判断依据：未取得证据前保持未验收；仅能陈述已有单应用测试范围。

### 128. [ ] 完整 DNS / IPv6 防泄漏

平台：Mac

- **复核优先级：** 高

核验方法：

```text
# MANUAL：Mac：没有完整 DNS/IPv6 覆盖与故障测试证据时保持未验收；现状列表不能证明防泄漏。
```

判断依据：未取得证据前保持未验收；现状记录不能证明完整 DNS/IPv6 防泄漏。

### 129. [ ] 网盘同步

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：Mac：由用户私下定位网盘副本，再核验同步完成与内容一致；报告不输出网盘位置和私人文件信息。
```

判断依据：网盘位置、同步完成状态与内容一致性未核验前，保持未验收。

### 130. [ ] 短时复测≠长期稳定；不承诺结果

平台：Mac

- **复核优先级：** 中

核验方法：

```text
# MANUAL：检查文案中的保证性表述；禁止把短时测试、旧报告或未知项写成长期稳定或账号结果承诺。
```

判断依据：不写零痕迹、全程零断网、账号已恢复、不会封号。

## 官方参考（核对日期：2026-10-13）

- [Anthropic 支持范围](https://www.anthropic.com/supported-countries)：实际使用地区与实体注册、总部、所有权/控制等资格边界。
- [Claude Code 网络配置](https://code.claude.com/docs/en/network-config)：HTTP(S) 代理与 NO_PROXY；SOCKS 限制针对 Claude Code 显式代理接口。
- [Claude Code 设置](https://code.claude.com/docs/en/settings)：多层设置及有效配置应依当前官方优先级核验。
- [Claude Code 合规边界](https://code.claude.com/docs/en/legal-and-compliance)：区分第三方凭据处理客户端与运行原版 Claude Code 的宿主场景。
- [官方 VS Code/Cursor 扩展](https://code.claude.com/docs/en/vs-code)：官方扩展可使用受支持的订阅登录。
- [Claude Code 组织网关](https://code.claude.com/docs/en/llm-gateway)：经授权网关不能仅因端点非官方域名而被判违规。
- [Node 内置代理支持](https://nodejs.org/api/http.html#built-in-proxy-support)：代理支持受运行环境、启用方式和实现影响。
- [Claude 付费计划退款](https://support.claude.com/en/articles/12386328-request-a-refund-for-a-paid-claude-plan)：按实际渠道、资格与条款核验，不替代个案结果。

官方资料支持通用规则，不提供任何具体机器的验收结论。
