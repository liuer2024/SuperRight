import AppKit

/// Ghostty 在 Info.plist 里声明了可处理 `public.directory`（把文件夹当文档打开），
/// 所以把目录 URL「作为文档」交给它即可在该目录开一个新终端。
///
/// 注意：不能用 `--working-directory` 或 `-e cd ...` 传参——沙盒里的扩展通过
/// NSWorkspace 启动别的 App 时命令行参数会被系统丢弃，导致 Ghostty 回退到家目录。
/// 「作为文档打开」走 LaunchServices 文档机制，配合扩展的文件访问例外即可正常工作。
struct GhosttyLauncher: TerminalLauncher {
    let id = "ghostty"
    let displayName = "Ghostty"
    let bundleID = "com.mitchellh.ghostty"

    func open(directory: URL) {
        openByHandingFolder(directory: directory)
    }

    /// Ghostty 用 `-e /bin/zsh -c "<命令>"` **内联**执行命令——不涉及任何脚本文件，
    /// 所以不会被隔离标记触发「允许执行脚本」确认框。
    /// 注意：必须由非沙盒进程（helper）调用，命令行参数才不会被系统丢弃。
    func runServerCommand(_ command: String) {
        guard let app = appURL else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.arguments = ["-e", "/bin/zsh", "-c", command]
        config.createsNewApplicationInstance = true
        config.activates = true
        NSWorkspace.shared.openApplication(at: app, configuration: config)
    }
}
