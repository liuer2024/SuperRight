import AppKit

/// 一个「终端启动器」抽象。
/// 新增一款终端 = 新写一个实现这个协议的类型，然后在 `TerminalRegistry.all` 里登记一行。
protocol TerminalLauncher {
    /// 稳定的标识符，用于存配置（不要随便改，改了用户的默认选择会丢）。
    var id: String { get }
    /// 显示在菜单/设置界面里的名字。
    var displayName: String { get }
    /// App 的 Bundle Identifier，用来检测是否已安装。
    var bundleID: String { get }
    /// 在指定目录打开该终端。
    func open(directory: URL)

    /// 在该终端里执行一段 shell 命令（用于「用 http-server 打开」）。
    /// Ghostty 会重写为用 `-e` 内联执行（不落地文件，避开隔离标记与确认框）。
    func runServerCommand(_ command: String)
}

extension TerminalLauncher {
    /// 该终端是否已安装。
    var isInstalled: Bool { appURL != nil }

    /// 已安装时返回 App 的位置。
    var appURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    /// 多数终端（Terminal.app / iTerm2 等）能直接把「文件夹」当文档打开，
    /// 在该目录起一个新的 shell 会话。这里提供一个通用实现。
    func openByHandingFolder(directory: URL) {
        guard let app = appURL else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.open([directory], withApplicationAt: app, configuration: config)
    }

    /// 默认实现（Terminal.app / iTerm2 等）：这些终端不能内联执行命令，
    /// 落地成一个临时 .command 再用文档方式打开。注意：若由沙盒责任链上的进程写出，
    /// 该文件可能带隔离标记；Ghostty 走内联重写路径，不受影响。
    func runServerCommand(_ command: String) {
        guard let app = appURL else { return }
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("superright-serve-\(UUID().uuidString).command")
        let script = "#!/bin/zsh\n" + command + "\n"
        guard (try? script.write(to: scriptURL, atomically: true, encoding: .utf8)) != nil else { return }
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.open([scriptURL], withApplicationAt: app, configuration: config)
    }
}
