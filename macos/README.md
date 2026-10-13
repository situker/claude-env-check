# Mac 轻量自检方案

当前是设计说明，尚无可运行的 Mac 自检脚本，也没有 Mac 真机验收结论。

## 首版形式

建议使用 macOS 自带 zsh，提供一个命令行脚本。先下载并阅读源码，再从终端运行；不依赖 Homebrew、Python 或 jq，不需要 sudo。

默认离线，只读取有限状态并新建一份匿名报告。报告固定显示第 109–130 问，分别标为 INFO、WARN、UNKNOWN 或 MANUAL，不把 22 行报告称作“22 项自动验收”。

## 能自动读取的部分

| 题号 | 计划检查 | 限制 |
|---|---|---|
| 111 | 技能入口、直接符号链接的本地目标是否可访问 | 不执行技能，不读技能正文；链接存在不能证明功能可用 |
| 116 | 当前时区的有限线索 | 自动时区开关仍人工确认；读不到则 UNKNOWN |
| 122 | 当前进程代理变量是否设置，以及系统代理开关 | 只输出固定状态，不输出地址、端口、凭据、PAC 地址或绕过名单；不能证明 TUN 或全部应用的实际路由 |

第 117 问的自动校时先人工查看。Apple 的 systemsetup 使用说明要求 sudo，首版不为读取这一项申请管理员权限，也不依赖未公开的偏好设置键保证兼容。

后续可增加显式 --online 模式，只访问说明中列出的固定测试站点，验证当前命令行的基本连通性。联网服务会看到请求来源；测试成功不代表 Claude 登录、聊天或模型调用成功。

## 保留人工核验

- 备份完整性、恢复步骤和网盘同步。
- CLI、桌面端和浏览器的登录状态。
- 节点导入、原配置保留情况。
- 断线阻断、开机自动连接、全部应用的路由。
- DNS/IPv6 完整防泄漏和长期稳定性。
- 账号是否恢复、是否能继续使用。

这些项目需要各自证据，不能由目录存在、开关开启或一次网络请求推断。

## 验证顺序

先用虚构输入验证解析、编号和输出脱敏，再在真实 Mac 上以普通用户验证。报告创建权限、中文目录、缺失命令、读取失败等情况都要检查；Apple Silicon 与 Intel 的适用情况按实际测试记录，不提前宣称全部支持。

后续实现不会清缓存、退出登录、改代理、调整时间、修改钥匙串或安装工具。

## 官方资料

- [Apple：终端的默认 shell](https://support.apple.com/en-ie/guide/terminal/trml113/mac)
- [zsh：启动文件](https://zsh.sourceforge.io/Doc/Release/Files.html)。-f 也不意味着跳过系统 /etc/zshenv。
- [Apple：scutil 手册](https://github.com/apple-oss-distributions/configd/blob/main/scutil.tproj/scutil.8)
- [Apple：systemsetup 使用说明](https://support.apple.com/en-asia/guide/remote-desktop/apd95406b8d/mac)
- [Apple：日期与时间设置](https://support.apple.com/en-ie/guide/mac-help/mchlp2996/mac)
