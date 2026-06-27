import Foundation

/// 宿主 App 和 Finder 扩展是两个独立进程，靠 App Group 共享配置。
/// 注意：`appGroupID` 必须和两个 target 的 entitlements 里的 App Group 完全一致。
enum AppConfig {
    static let appGroupID = "group.com.smiler.superRight"

    private static let defaultTerminalKey = "defaultTerminalID"
    private static let showMenuIconsKey = "showMenuIcons"
    private static let enableHttpServerKey = "enableHttpServer"

    /// 取 App Group 的 UserDefaults。如果 App Group 没配好（比如没有签名团队），
    /// 这里会是 nil，所有读写自动降级为返回默认值 / 静默丢弃。
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// 用户选择的默认终端 id，默认 Ghostty。
    static var defaultTerminalID: String {
        get { defaults?.string(forKey: defaultTerminalKey) ?? GhosttyLauncher().id }
        set { defaults?.set(newValue, forKey: defaultTerminalKey) }
    }

    /// 解析成具体的启动器；找不到（比如终端被卸载了）时回退到 Ghostty。
    static var defaultTerminal: TerminalLauncher {
        TerminalRegistry.launcher(for: defaultTerminalID) ?? GhosttyLauncher()
    }

    /// 右键菜单项是否显示图标。默认开启。
    static var showMenuIcons: Bool {
        get { defaults?.object(forKey: showMenuIconsKey) as? Bool ?? true }
        set { defaults?.set(newValue, forKey: showMenuIconsKey) }
    }

    /// 是否显示「用 http-server 打开」菜单项。默认开启。
    static var enableHttpServer: Bool {
        get { defaults?.object(forKey: enableHttpServerKey) as? Bool ?? true }
        set { defaults?.set(newValue, forKey: enableHttpServerKey) }
    }
}
