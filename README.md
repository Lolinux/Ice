<div align="center">
    <img src="Ice/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="160" height="160" alt="Ice icon">
    <h1>Ice — macOS 27 community fixes</h1>
    <p>非官方 macOS 27 兼容修复分支 · Unofficial compatibility fork</p>
</div>

本仓库在 [Ice](https://github.com/jordanbaird/Ice) 和社区
[macOS 27 适配 PR #997](https://github.com/jordanbaird/Ice/pull/997) 的基础上，
补充菜单栏原生收缩、图标排列、弹窗定位及重启恢复修复。
这是社区维护的实验分支，不是 Ice 官方发行版。

This fork builds on upstream Ice and the community macOS 27 work in PR #997.
It adds fixes for native overflow, item geometry, popup positioning and restart
recovery. It is experimental and is not an official Ice release.

## 修复内容 / Changes

Additional changes in this fork, dated **2026-09-20–2026-09-21**:

- **图标识别和分组**：使用 MenuBarAgent 当前实际显示的坐标，避免隐藏图标的旧坐标导致识别、分组错误。
- **拖动排列**：操作前展开系统收缩区域并验证坐标；向空分组移动时读取最新边界。
- **弹窗定位**：从 Ice Bar 打开的、支持移动的第三方面板对齐菜单栏 Ice 按钮下方。
- **退出重开恢复**：启动时先读取系统收缩区域、恢复图标分组和图片，再隐藏菜单栏，无需手动进入 Menu Bar Layout。
- **本地构建签名**：复用本机开发签名，减少反复构建引起的隐私授权失效；禁用本地版本的上游自动更新。

The fixes use live hosted geometry, validate native drag targets, position
new movable popups below Ice, and discover/capture overflow items before hiding
them at launch. Local builds reuse a persistent signing identity.

## 下载 / Download

[**Ice 27 · 0.12.0-macos27.1（预发布）**](https://github.com/Lolinux/Ice/releases/tag/v0.12.0-macos27.1)

提供 DMG、ZIP、对应源码和 SHA-256 校验文件，仅面向 Apple Silicon / macOS 27。
安装包使用自签名开发证书，**没有 Apple Developer ID 签名或公证**，下载后可能被系统拦截。
尚未在全新机器上验证；也可以按下面的方法自行构建。

## 构建 / Build

当前构建脚本面向 **Apple Silicon + macOS 27 + 完整 Xcode 27**。
iOS SDK 和模拟器不需要安装。本分支未在 Intel 或其他系统版本上验证。

```sh
git clone --branch codex/macos27-public https://github.com/Lolinux/Ice.git
cd Ice
bash Scripts/test-macos27.sh
bash Scripts/package-release.sh
```

输出文件位于 `build/release/`。调试构建使用 `bash Scripts/build-debug.sh`。

第一次构建时，签名脚本会在当前用户的
`~/Library/Application Support/IceLocalDevelopmentSigning` 创建本地开发证书和专用钥匙串，
后续构建复用。签名材料不在仓库内，也不随安装包分发。不同机器上的签名身份不同。

The first build creates a local signing identity; later builds on that Mac
reuse it. Generated apps are **not Developer ID notarized**. The [experimental release](https://github.com/Lolinux/Ice/releases/tag/v0.12.0-macos27.1)
provides Apple Silicon binaries and matching source. Downloaded builds may be
blocked by Gatekeeper and have not been validated on a clean Mac. Existing
privacy permissions are ultimately managed by macOS.

- [构建、签名与测试说明 / Build and verification](Scripts/LOCAL-MACOS27.md)
- [中文使用说明与限制](Scripts/RELEASE-NOTES.zh-CN.md)
- [上游 macOS 27 实现说明 / Upstream architecture](MACOS27.md)

## 安装与权限 / Installation

退出其他 Ice 实例，将本机生成的 `Ice 27.app` 放到 `~/Applications/` 后打开。
首次使用需要在 macOS 系统设置中授予辅助功能和屏幕录制权限，分别用于菜单栏交互和图标截图。
请只运行一份 Ice。

内部应用标识保留为 `com.jordanbaird.Ice.macos27debug`，用于延续已有本地版本的设置和权限。
因此系统权限列表可能仍显示旧名称 “Ice 27 Debug”。更换签名身份后可能需要重新授权。

## 验证范围与已知限制 / Validation and limitations

- 在 Apple Silicon、macOS 27.0（26A428）、Xcode 27 环境测试。
- 10 组独立测试通过，覆盖坐标匹配、边界、动态标识、图像处理和弹窗位置等。
- 实机验证过图标排列、隐藏/展开、弹窗定位及多次退出重开；当前测试布局的 10 个隐藏图标能够自动恢复。
- 启动恢复可能短暂展开系统菜单栏；系统自动隐藏菜单栏或全屏状态下不自动执行这一步。
- 第三方应用控制弹窗的初始动画，State 等应用仍可能短暂跳动；系统菜单或不支持移动的窗口保持原位置。
- macOS 27 上搜索、悬停/滚轮展开、自动重新隐藏、图标间距及应用菜单隐藏仍停用。
- 多显示器、Intel、其他系统版本及全新机器安装尚未实机验证。

Runtime testing is currently limited to one Apple Silicon Mac. Third-party
popup animations and non-movable system menus remain outside this fork's
control. See the linked notes before building or reporting a problem.

报告问题时请提供系统版本、构建版本和复现步骤；截图中请遮挡私人信息。
针对本分支的问题请在本仓库提交，而不是把修改版的问题当作官方发行版的问题。

## 来源与许可证 / Credits and license

- Original Ice: [Jordan Baird and contributors](https://github.com/jordanbaird/Ice).
- Community macOS 27 foundation: [PR #997](https://github.com/jordanbaird/Ice/pull/997),
  based here on commit `c3df598f36100b0500fd159a1cfd9ac5d2dc2525`, including its macOS 26 prerequisites.
- Earlier macOS 27 work: [PR #980](https://github.com/jordanbaird/Ice/pull/980), as credited in the upstream architecture notes.
- Additional fixes and local build tooling: this fork, maintained at [Lolinux/Ice](https://github.com/Lolinux/Ice).

保留原作者和贡献者署名，继续使用 [GNU GPLv3](LICENSE)。
[原版 README](README.upstream.md) 保留供参考，其中的安装链接和功能列表描述的是上游项目。
Upstream history and attribution are preserved; modifications remain licensed
under GPLv3. See [LICENSE](LICENSE).
