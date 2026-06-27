import AppKit

/// iTerm2 能把文件夹当文档打开，在该目录开新窗口/标签页。
struct ITermLauncher: TerminalLauncher {
    let id = "iterm2"
    let displayName = "iTerm2"
    let bundleID = "com.googlecode.iterm2"

    func open(directory: URL) {
        openByHandingFolder(directory: directory)
    }
}
