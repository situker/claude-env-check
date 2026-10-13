# Claude 环境检查

Windows 环境复核脚本及配套 130 问通用清单。作者：司徒K。

本仓库公开脚本、使用说明、通用检查步骤和离线测试。清单不含作者的历史操作记录；真实运行报告、账号资料、代理配置、备份和文章审核记录不入库。

| 平台 | 当前内容 | 验证情况 |
|---|---|---|
| Windows | PowerShell 自检脚本，对应第 1–108 问 | Windows PowerShell 5.1 与 PowerShell 7 的离线合成测试通过；不代表真实环境全部验收 |
| macOS | 轻量自检设计，对应第 109–130 问 | 尚未实现或做 Mac 真机验收，参见 [Mac 方案](macos/README.md) |

## Windows 使用

下载仓库后，在仓库根目录打开 PowerShell，先阅读 [Windows 说明](docs/windows.md) 和源码，再运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\claude-env-check.ps1
```

默认只做有限的本地读取，并在 windows 目录创建一份新的匿名报告。要主动访问 README 列明的检测网站，在命令末尾加 -Online：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\claude-env-check.ps1 -Online
```

报告按第 1–108 问显示，和 [完整清单](docs/checklist.md) 对应。Mac 第 109–130 问仍人工复核。

脚本不改变代理、防火墙、账号或系统配置，不删除缓存，不自动判定 PASS。联网只观察当前 PowerShell 的网络路径，不代表 Claude 专用代理、浏览器或其他应用的实际路径。

## 目录

```text
windows/                 Windows 自检脚本
macos/                   Mac 自检设计与后续实现位置
docs/checklist.md        完整 130 问复核清单
docs/windows.md          Windows 参数、输出和检查范围
tests/                   离线测试与运行说明
CHANGELOG.md             版本记录
```

[测试说明](tests/README.md)中的测试使用虚构数据，不执行真实系统检查或联网。目前没有自动运行的 GitHub Actions。

## 维护

- 检查逻辑与题号保持对应。调整题目顺序时，正文、清单和报告展示同步更新。
- INFO、WARN、UNKNOWN、MANUAL 各有含义；配置存在不等于有效，连接成功不等于账号可用。
- 不提交真实报告、代理地址、节点、配置、邮箱、凭据、个人路径或私人文件。忽略规则只是防误提交措施，提交前仍需看暂存内容。
- Mac 有脚本后，先在测试环境验证，再由本人在实际 Mac 上验收；测试记录分别标明合成测试、系统检查和应用功能测试。
- 公有仓库可供文章读者查看源码和下载。使用前先阅读说明与源码，不把代码更新视为本机检查已经完成。

沿用现有 MIT 许可证，见 [LICENSE](LICENSE)。
