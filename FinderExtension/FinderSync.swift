import Cocoa
import FinderSync
import Darwin

/// Finder Sync 扩展的主类。Finder 会按 Info.plist 里的
/// NSExtensionPrincipalClass 加载它，并在右键时调用 `menu(for:)`。
class FinderSync: FIFinderSync {

    override init() {
        super.init()
        // 监听整个磁盘，这样在任意目录右键都能出菜单。
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // MARK: - 菜单构建

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")

        // 是否在菜单项前显示图标（可在 App 设置里切换）。
        let showIcons = AppConfig.showMenuIcons

        // 注：Finder 不渲染扩展菜单的原生分隔线（Apple API 限制），用字符假线又和系统不统一，
        // 所以不加分隔线，直接列出菜单项。
        let primary = AppConfig.defaultTerminal
        let openItem = NSMenuItem(
            title: "在 \(primary.displayName) 打开",
            action: #selector(openInDefault(_:)),
            keyEquivalent: ""
        )
        if showIcons {
            openItem.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)
        }
        menu.addItem(openItem)

        // 复制路径（子菜单：绝对 / 相对）
        let copyItem = NSMenuItem(title: "复制绝对/相对路径", action: nil, keyEquivalent: "")
        if showIcons {
            copyItem.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
        }

        let copySubmenu = NSMenu(title: "")
        let absItem = NSMenuItem(title: "绝对路径", action: #selector(copyAbsolutePath(_:)), keyEquivalent: "")
        let relItem = NSMenuItem(title: "相对路径", action: #selector(copyRelativePath(_:)), keyEquivalent: "")
        copySubmenu.addItem(absItem)
        copySubmenu.addItem(relItem)
        copyItem.submenu = copySubmenu
        menu.addItem(copyItem)

        // 用 http-server 打开（可在设置里开关）
        if AppConfig.enableHttpServer {
            let httpItem = NSMenuItem(
                title: "用 http-server 打开",
                action: #selector(openWithHTTPServer(_:)),
                keyEquivalent: ""
            )
            if showIcons {
                httpItem.image = NSImage(systemSymbolName: "network", accessibilityDescription: nil)
            }
            menu.addItem(httpItem)
        }

        return menu
    }

    // MARK: - 动作

    @objc func openInDefault(_ sender: AnyObject?) {
        let term = AppConfig.defaultTerminal
        targetDirectories().forEach { term.open(directory: $0) }
    }

    @objc func copyAbsolutePath(_ sender: AnyObject?) {
        copyToPasteboard(targetItemPaths())
    }

    @objc func copyRelativePath(_ sender: AnyObject?) {
        copyToPasteboard(targetItemPaths().map(relativeToHome(_:)))
    }

    @objc func openWithHTTPServer(_ sender: AnyObject?) {
        guard let dir = targetDirectories().first else { return }
        startHTTPServer(in: dir)
    }

    // MARK: - http-server

    /// 沙盒扩展不能执行命令、也不能给终端传参。所以改为：
    /// 1) 把「要服务的目录」写进 App Group 的 requests/（纯数据文件）；
    /// 2) 唤起非沙盒的 superRightHelper，由它用 -e 把命令直接交给终端启动服务器。
    private func startHTTPServer(in directory: URL) {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupID)
        else { return }

        let reqDir = container.appendingPathComponent("requests", isDirectory: true)
        try? FileManager.default.createDirectory(at: reqDir, withIntermediateDirectories: true)
        let reqURL = reqDir.appendingPathComponent("\(UUID().uuidString).txt")
        guard (try? directory.path.write(to: reqURL, atomically: true, encoding: .utf8)) != nil else { return }

        launchHelper()
    }

    /// 唤起内置的非沙盒小助手。优先按 Bundle ID 找，找不到则按相对主 App 的路径找。
    private func launchHelper() {
        // 优先用随 App 一起安装的内嵌 helper，找不到再按 Bundle ID 回退。
        let url = helperURL()
            ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.smiler.superRight.Helper")
        guard let helper = url else { return }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        NSWorkspace.shared.openApplication(at: helper, configuration: config)
    }

    /// 助手内嵌在 superRight.app/Contents/Resources/superRightHelper.app。
    private func helperURL() -> URL? {
        let mainApp = Bundle.main.bundleURL
            .deletingLastPathComponent()   // PlugIns
            .deletingLastPathComponent()   // Contents
            .deletingLastPathComponent()   // superRight.app
        let helper = mainApp.appendingPathComponent("Contents/Resources/superRightHelper.app")
        return FileManager.default.fileExists(atPath: helper.path) ? helper : nil
    }

    // MARK: - 工具

    /// 把多行文本写入剪贴板（空则不动）。
    private func copyToPasteboard(_ lines: [String]) {
        guard !lines.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(lines.joined(separator: "\n"), forType: .string)
    }

    /// 把绝对路径转成相对家目录的写法：/Users/你/... → ~/...
    /// 不在家目录下的路径保持绝对路径不变。
    private func relativeToHome(_ path: String) -> String {
        let home = realHomePath()
        if path == home { return "~" }
        if path.hasPrefix(home + "/") { return "~" + path.dropFirst(home.count) }
        return path
    }

    /// 真实的用户家目录。注意：沙盒里 `NSHomeDirectory()` 会指向沙盒容器，
    /// 所以用 getpwuid 拿系统真实家目录（/Users/你）。
    private func realHomePath() -> String {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            let path = String(cString: dir)
            if !path.isEmpty { return path }
        }
        return NSHomeDirectory()
    }

    /// 计算应该打开的目录列表：
    /// - 选中了文件/文件夹 → 文件夹用自身，文件取其所在目录（去重）
    /// - 没选中（在窗口/桌面空白处右键）→ targetedURL 本身就是当前文件夹，直接用
    private func targetDirectories() -> [URL] {
        let controller = FIFinderSyncController.default()

        // 有选中项的情况。
        if let selected = controller.selectedItemURLs(), !selected.isEmpty {
            var seen = Set<String>()
            return selected
                .map(directory(for:))
                .filter { seen.insert($0.path).inserted }
        }

        // 没有选中项：当前所在文件夹本身。
        if let target = controller.targetedURL() {
            return [target]
        }

        return []
    }

    /// 复制路径用：和「打开终端」不同，这里要的是**选中项本身**的路径
    /// （文件就给文件路径，不取所在目录）。
    /// - 选中了文件/文件夹 → 各自的完整路径（多选则每行一个）
    /// - 没选中（空白处右键）→ 当前所在文件夹的路径
    private func targetItemPaths() -> [String] {
        let controller = FIFinderSyncController.default()

        if let selected = controller.selectedItemURLs(), !selected.isEmpty {
            return selected.map(\.path)
        }
        if let target = controller.targetedURL() {
            return [target.path]
        }
        return []
    }

    /// 把一个 URL 解析成「目录」：是文件夹就用它自己，是文件就用所在目录。
    /// 用文件系统属性判断，而不是看路径末尾有没有 "/"（后者不可靠，会把无斜杠的
    /// 文件夹误判成文件，从而错误地取到上一级目录）。
    private func directory(for url: URL) -> URL {
        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory
            ?? url.hasDirectoryPath
        return isDirectory ? url : url.deletingLastPathComponent()
    }
}
