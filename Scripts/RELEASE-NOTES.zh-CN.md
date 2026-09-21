# Ice 27 社区修复版（预发布）

版本：0.12.0-macos27.1（1330） · Apple Silicon / macOS 27 · 2026-09-21。

基于原版 Ice 和社区 PR #997，采用 Release 优化编译。
这是非官方社区版本，不是原作者发行版。

## 本次修复

- 修复系统原生收缩区域中图标的坐标与分组识别。
- 拖动前验证实际显示位置，改善跨分组、空分组移动。
- 从 Ice Bar 打开的可移动第三方面板对齐菜单栏 Ice 按钮下方。
- 修复退出重开后部分图标消失：启动时恢复系统收缩图标及图片，再进入隐藏状态。
- 复用本地开发签名，保持已有本地构建的身份连续性；关闭上游自动更新。

## 下载内容

- `Ice-27-0.12.0-macos27.1-arm64.dmg`：磁盘映像，含应用、许可证和本说明。
- `Ice-27-0.12.0-macos27.1-arm64.zip`：相同应用及说明的 ZIP，二选一即可。
- `Ice-27-0.12.0-macos27.1-source.zip`：本次发行对应源码，含构建脚本和测试。
- `SHA256SUMS.txt`：附件的 SHA-256 校验值。

## 安装、签名与权限

退出其他 Ice 实例，解压 ZIP 或打开 DMG，将 `Ice 27.app` 放到 `~/Applications/` 后打开。
首次使用需本人在系统设置中授予辅助功能和屏幕录制权限，分别用于菜单栏交互与图标截图。
请只运行一份 Ice。已使用本项目 local2 构建的用户可以替换应用；设置和应用标识保持一致。

**本安装包使用自签名开发证书，没有 Apple Developer ID 签名或 Apple 公证。**
只在开发使用的 Apple Silicon Mac 上验证过，没有完成全新机器的下载、安装验证。
macOS Gatekeeper 可能拦截下载的程序，不能保证像已公证应用一样直接打开。
如不希望使用未公证的预发布包，可以下载源码并用完整 Xcode 27 在本机构建。
安装包中不包含私钥、签名钥匙串或密码。不同签名身份可能需要重新授权，权限由 macOS 决定。

内部应用标识沿用 `com.jordanbaird.Ice.macos27debug`，系统权限列表可能仍显示旧名称 “Ice 27 Debug”。
启动恢复可能短暂展开菜单栏，无需手动访问 Menu Bar Layout。

## 验证范围与限制

- 10 组独立测试通过；功能代码延续已验证的 local2 修复。
- 实机验证环境：Apple Silicon、macOS 27.0（26A428）、Xcode 27。
- 验证过图标排列、隐藏/展开、弹窗定位，以及退出重开后恢复全部 10 个测试布局中的隐藏图标。
- State 等第三方弹窗的初始动画仍可能短暂跳动；不支持移动的系统菜单保持原位置。
- 搜索、悬停/滚轮展开、自动重新隐藏、图标间距及应用菜单隐藏在 macOS 27 上仍停用。
- 系统自动隐藏菜单栏或全屏状态下不自动执行启动展开。
- 多显示器、Intel、其他系统版本及全新机器安装尚未实机验证。

## 源码、构建与许可证

发行源码：https://github.com/Lolinux/Ice/tree/v0.12.0-macos27.1
上游原项目：https://github.com/jordanbaird/Ice
社区适配基础：https://github.com/jordanbaird/Ice/pull/997

在源码根目录运行：

```sh
bash Scripts/test-macos27.sh
bash Scripts/package-release.sh
```

构建脚本第一次运行会创建本机签名身份，后续构建复用；输出在 `build/release/`。
签名材料保存在 `~/Library/Application Support/IceLocalDevelopmentSigning`，不会随包分发。
保留原作者与贡献者署名，修改继续遵循随包提供的 GNU GPLv3（见 `LICENSE`）。
