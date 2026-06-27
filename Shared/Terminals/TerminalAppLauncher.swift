import AppKit

/// 系统自带 Terminal.app，把文件夹当文档打开即可在该目录开新窗口。
struct TerminalAppLauncher: TerminalLauncher {
    let id = "apple-terminal"
    let displayName = "终端 (Terminal)"
    let bundleID = "com.apple.Terminal"

    func open(directory: URL) {
        openByHandingFolder(directory: directory)
    }
}
