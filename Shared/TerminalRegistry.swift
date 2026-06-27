import Foundation

/// 所有支持的终端登记处。
/// 想加一款新终端：实现 `TerminalLauncher`，然后在 `all` 里加一行即可。
enum TerminalRegistry {
    static let all: [TerminalLauncher] = [
        GhosttyLauncher(),
        ITermLauncher(),
        TerminalAppLauncher(),
        // 以后可继续加：WarpLauncher(), KittyLauncher(), WezTermLauncher() ...
    ]

    /// 当前机器上实际装了的终端。
    static var installed: [TerminalLauncher] {
        all.filter { $0.isInstalled }
    }

    static func launcher(for id: String) -> TerminalLauncher? {
        all.first { $0.id == id }
    }
}
