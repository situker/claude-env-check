# Windows 离线测试

在仓库根目录运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\windows-offline.ps1
pwsh -NoProfile -File .\tests\windows-offline.ps1
```

默认从测试文件所在位置定位 `../windows/claude-env-check.ps1`，不依赖当前工作目录。`-ScriptPath` 可指定另一份待审阅的脚本；不会执行该脚本的主入口。

测试先解析生产脚本的 AST，再在独立 PowerShell runspace 中加载列明的判断函数，并只提取代理设置的内存判断片段。真实配置读取、网络探测、报告写入和外部应用入口不会加载；常见系统读取与联网命令在测试上下文内设有拦截。测试不是运行不可信代码的安全沙箱，调整生产函数或提取边界后仍需审阅测试。

共 **83 项检查**，覆盖代理 URL、NO_PROXY、异常 JSON、配置缺失、防火墙状态、网络响应解析、108 个 Windows/通用题目、匿名报告和连续编号。保留原本 84 项中的可重复回归检查，仅移除依赖历史备份的“此次修改只改了编号和格式化函数”比较，因为它不适用于独立仓库。

测试数据全部为人工构造。地址使用回环地址、文档保留范围 `203.0.113.0/24`、`2001:db8::/32` 或 `.invalid` 域名；类似用户名、密码、查询参数的字符串只是拒绝测试用例，不是真实凭据。测试不会向这些地址发请求。

结果只输出到控制台，不生成报告或日志文件。成功结束时输出 `Checks=83; Failures=0`，且主入口、真实配置读取、联网均为 `False`；失败返回非零退出码。兼容性应分别在 Windows PowerShell 5.1 和 PowerShell 7 上验证。
