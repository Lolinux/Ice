# Ice 27 本地正式构建

版本：0.12.0-macos27.local2（1329），Apple Silicon / macOS 27。

本版采用 Release 优化编译，基于 Ice 社区 PR #997 的 macOS 27 适配，
补充原生折叠区域、图标坐标和分组、拖动、权限签名连续性及弹窗定位修复。
它是本机使用的修改版，不是上游官方发行版。

## 安装和使用

退出已运行的 Ice，将 Ice 27.app 放到用户目录下的 Applications 文件夹，
然后打开。请只运行一份 Ice。已安装时直接覆盖更新，保留所有设置。
启动时自动展开并读取系统原生收缩区域，恢复图标分组和图片后再隐藏；无需先打开布局设置。

沿用测试版的内部应用标识及本机固定签名，以保留偏好设置和隐私授权。
应用显示名称改为 Ice 27。更新权限仍由 macOS 最终判断。
本机已配置的签名无需重新生成；不要删除本地签名密钥。

## 功能与限制

- 支持读取菜单栏图标、拖动排列、隐藏/展开和 Ice Bar。
- 可移动的第三方面板对齐菜单栏 Ice 按钮下方，并限制在屏幕工作区内。
- State 等应用的初始动画可能仍有短暂跳动；不支持移动的系统菜单保持原位置。
- macOS 27 上部分功能仍停用：搜索、悬停/滚轮展开、自动重新隐藏、图标间距及应用菜单隐藏。
- 多显示器尚未实机验证。
- 关闭上游自动更新，避免本地修复版被覆盖。

此包使用本机开发证书签名，没有 Apple Developer ID 公证，供当前机器使用。
没有在其他机器上验证，也不应当作已公证的公开发行包分发。

## 源码和构建

源码：https://github.com/Lolinux/Ice
分支：codex/macos27-public
上游基础：https://github.com/jordanbaird/Ice/pull/997
授权：随包 LICENSE；上游作者和项目署名保持不变。

构建：bash Scripts/package-release.sh
测试：bash Scripts/test-macos27.sh
签名材料留在本机的 Library/Application Support/IceLocalDevelopmentSigning，
不包含在安装包、源码仓库或测试输出中。
