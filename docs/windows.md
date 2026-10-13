# claude-env-check

Windows 环境复核脚本，版本 `v3.2-reviewfix`。对应数字编号正文与清单的第 1–108 问；这些项目以 Windows 为主，也包含通用原则及远端 Linux 人工项。Mac 的第 109–130 问需手工复核，本仓库没有 Mac 自动验收脚本。

作者：司徒K。

## 对应清单

[完整复核清单：第 1–130 问](checklist.md)。脚本对应第 1–108 问；Mac 第 109–130 问继续人工复核。配套文章仍在本人审核，审核稿不随本仓库上传。

## 运行方式

先阅读源码。从仓库根目录进入 windows 目录，再打开 Windows PowerShell 运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\claude-env-check.ps1
```

若使用已安装的 PowerShell 7：

```powershell
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File .\claude-env-check.ps1
```

`-ExecutionPolicy Bypass` 仅影响新进程及其子会话，不持久修改当前用户或系统执行策略，也不能覆盖组织组策略。不要为运行本脚本修改组织策略。

默认仅做有限的本地读取，不执行联网探测。需要第三方出口与 DNS 观察时，明确加上 `-Online`：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\claude-env-check.ps1 -Online
```

本脚本只有 `-Online` 这一业务参数，没有显示原值或导出原始配置的模式。PowerShell 通用参数仍由引擎提供；不要开启调试跟踪或终端转录来收集配置读取过程。

成功后，在脚本同目录查看 `claude-env-report-时间戳-随机后缀.txt`。报告用 UTF-8 编码，每次创建新文件，不覆盖旧报告。正常完成退出码为 `0`；整体检查或写文件失败返回 `1`，只显示固定错误说明。失败时可能留下不完整的新文件，不能当成完整报告。

## 状态怎么读

- `INFO`：成功获得局部观察，不表示环境安全、地区合规或账号安全。
- `WARN`：发现需要复核的候选问题，不代表已经证明违规或泄漏。
- `UNKNOWN`：命令缺失、权限不足、读取/解析/联网失败等导致证据不足。
- `MANUAL`：需要人工复核，或本脚本明确不自动执行该项。

本版不自动输出 `PASS`。成功生成的报告按第 1–108 问连续显示，题号覆盖不等于自动检查或人工验收完成。内部仍保留原 A1–S6 ID 供检测逻辑使用；显示题号和顺序取自脚本中的固定定义，不采用运行时记录自带的题号。

自动读取包括：本机网络地址与路由候选、DNS/DoH 配置、WinINET 标志、相关环境变量的存在性、部分进程/网卡/目录候选、CLI 命令是否可发现、用户级 Claude 配置中的候选字段，以及有效策略存储中的防火墙候选规则。输出只包含固定说明，不输出实际 IP、端口、账号、凭据片段、私有路径、已安装版本、数量或自定义名称。

用户级 `settings.json` 不是最终有效配置。项目、受管设置、启动环境等优先级仍需根据当前官方文档和实际会话复核；`NO_PROXY` 按绕过列表处理。合法回环代理 URI 只证明语法符合本脚本约束，不能证明端口在监听或请求经过它。防火墙按显示名称发现候选，名称不同可能漏检；找到已启用的出站阻断候选，也不能证明程序、Profile、地址范围及所有子进程都受到保护。

Node、WSL、npm、Claude CLI、curl、Git 和 netsh 都不会被本脚本启动，`-Online` 也不会启用它们。相应运行时、浏览器、桌面应用、远端服务器、故障测试、备份、邮箱与账单等项目明确保留为手工复核。不采集 Windows 用户数量，不递归扫描会话文件或遍历备份盘符。CLI 仅使用 `Get-Command` 发现，不执行版本命令。

## 联网与写入边界

`-Online` 会通过当前 PowerShell 默认网络路径依次访问这些固定 HTTPS 地址：

- `https://ipinfo.io/json`
- `https://api.ipify.org`
- `https://api64.ipify.org`
- `https://edns.ip-api.com/json`

第三方可观察到请求来源和请求元数据。脚本不会向这些服务发送本地配置、凭据或报告内容；不会打印原始响应、地址或错误文本。每个请求设置 `TimeoutSec 10`，但系统 DNS 和网络栈可能使实际等待更长，这不是整个脚本的严格总时限。失败记为 `UNKNOWN`。出口一致只能说明这些默认路径探测的观察一致，不能代替专用代理、浏览器或其他运行时的验收。

脚本不主动修改注册表、系统/用户环境变量、代理、DNS、防火墙、服务、账号配置或执行策略，不删除文件、不上传报告。显式落盘仅为同目录的新报告；本地读取和可选联网仍可能产生操作系统或网络服务自身的访问记录，不作“零痕迹”承诺。

## 兼容性与验收范围

源码面向 Windows PowerShell 5.1 与 Windows 上的 PowerShell 7。NetTCPIP、DnsClient、NetAdapter、NetSecurity 等系统模块随 Windows 版本和安装环境而异；缺失或读取失败会标为 `UNKNOWN`，不会当作通过。先以普通用户运行；脚本不会自动请求提权，权限不足的项目保留为待核。

本轮验证包括两个 PowerShell 引擎的静态语法解析和离线合成数据测试，不代表已在所有 Windows 版本、权限、网络或真实账户环境中完成运行验收。不要将报告当作账户状态、地区资格或防泄漏证明。

## 使用边界

以 Anthropic 当前官方支持地区与服务条款为准；本工具不帮助绕过限制，也不保证账号不被封。第三方检测结果不是官方风控评分。清理缓存、改变配置或得到局部观察，都不能证明账号恢复、服务端令牌失效或所有路径已受保护。

## License

[MIT](../LICENSE) © 司徒K
