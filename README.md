# superRight

在 macOS Finder 右键菜单里，用你喜欢的终端（Ghostty / iTerm2 / Terminal…）打开文件夹。

技术栈：**Swift + SwiftUI（宿主 App）+ FinderSync 扩展（NSMenu）+ App Group 共享配置**。

## 工程结构

```
superRight/
├── project.yml                       # XcodeGen 配置，用它生成 .xcodeproj
├── build-install.sh                  # 一键：构建 → 安装到 /Applications → 启用扩展
├── App/                              # 宿主 App（SwiftUI 设置界面）
│   ├── superRightApp.swift
│   ├── SettingsView.swift            # 选默认终端 + 一键打开扩展设置
│   ├── Info.plist
│   └── superRight.entitlements       # 沙盒 + App Group
├── FinderExtension/                  # 右键菜单本体
│   ├── FinderSync.swift              # 单个「在 <默认终端> 打开」菜单项
│   ├── Info.plist                    # 声明 FinderSync 扩展点
│   └── FinderExtension.entitlements  # 沙盒 + App Group + 文件读取例外
└── Shared/                           # 两端共用
    ├── TerminalLauncher.swift        # 终端启动器协议
    ├── TerminalRegistry.swift        # 登记 + 检测已安装
    ├── AppConfig.swift               # App Group 配置读写
    └── Terminals/                    # Ghostty / iTerm2 / Terminal 三个实现
```

## 前置要求

- **完整的 Xcode**（仅命令行工具无法构建 app-extension）。
- XcodeGen：`brew install xcodegen`
- Apple ID（免费个人账号即可本地签名运行）。

## 构建与安装

```bash
./build-install.sh
```

首次使用后，在弹出的设置窗口点「打开扩展设置」→ 勾选 **superRight**，然后右键任意文件夹即可。

手动方式：`xcodegen generate && open superRight.xcodeproj`，在 Xcode 里 ⌘R。

## 工作原理（几个关键点 / 踩过的坑）

1. **必须沙盒**：Finder 扩展不开沙盒，系统直接拒绝注册/加载。
2. **沙盒禁止传参**：沙盒里的扩展通过 `NSWorkspace` 启动终端时，命令行参数（如 `--working-directory`、`-e`）会被系统丢弃，终端会回退到家目录。所以**不能用传参的方式指定目录**。
3. **改用「文档方式」打开**：把目录 URL 作为「文档」交给终端（`NSWorkspace.open([dir], withApplicationAt:)`）。Ghostty / iTerm2 / Terminal 都在 Info.plist 里声明了可处理 `public.directory`，会在该目录开新终端。
4. **需要文件访问例外**：沙盒默认无权访问任意目录，需在扩展的 entitlements 里加
   `com.apple.security.temporary-exception.files.absolute-path.read-only = [ "/" ]`，
   否则「文档方式」会报「没有权限打开」。
5. **代价：不能上架 App Store**。temporary-exception 这类例外不被 App Store 接受，只能用 **Developer ID 直接分发**（这也是 OpenInTerminal 等同类工具的通行做法）。

> 调试技巧：扩展是常驻进程，改完代码光 `killall Finder` 不够，要
> `pkill -f FinderExtension` 杀掉扩展进程，系统才会用新二进制重新拉起。
> `build-install.sh` 已包含这一步。

## 配置 / 定制

- **默认终端**：在 App 设置界面选；存在 App Group 的 UserDefaults，扩展实时读取。
- **加一款新终端**：在 `Shared/Terminals/` 新建一个实现 `TerminalLauncher` 的类型，
  在 `TerminalRegistry.all` 里加一行。能处理 `public.directory` 的终端，`open` 里调
  `openByHandingFolder(directory:)` 即可。
- **改占位符**（换成你自己的）：`project.yml` 的 `DEVELOPMENT_TEAM`；三处
  `group.com.smiler.superRight`（两个 .entitlements + `AppConfig.swift` 要一致）；
  `com.smiler.*` Bundle ID 前缀。

## 正式分发（给别人用）

本地用 Apple Development 签名即可。要分发给别人，需用 **Developer ID** 签名 + **公证**：

```bash
codesign --deep --options runtime --sign "Developer ID Application: ..." superRight.app
xcrun notarytool submit ... && xcrun stapler staple superRight.app
# 再用 create-dmg 打包，或发布到 Homebrew Cask
```

## 开源协议 / License

本项目基于 [MIT 协议](LICENSE) 开源。
