import AppKit

// superRightHelper：无界面的后台小助手（非沙盒）。
// 扩展把「要服务的目录」写入 App Group 的 requests/，然后唤起本程序。
// 本程序读取这些请求，用默认终端启动 http-server，然后退出。
// 因为不在沙盒里，可以用 -e 直接把命令传给终端（不走脚本文件），所以不会触发
// Ghostty 的「允许执行脚本」确认弹窗。

let fm = FileManager.default

guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupID) else {
    exit(0)
}

let requestsDir = container.appendingPathComponent("requests", isDirectory: true)

let requests = ((try? fm.contentsOfDirectory(at: requestsDir, includingPropertiesForKeys: nil)) ?? [])
    .filter { $0.pathExtension == "txt" }

let terminal = AppConfig.defaultTerminal

for request in requests {
    guard let raw = try? String(contentsOf: request, encoding: .utf8) else { continue }
    try? fm.removeItem(at: request)   // 消费掉请求

    let dir = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    var isDir: ObjCBool = false
    guard !dir.isEmpty, fm.fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue else { continue }

    // 以内联命令交给终端执行（不落地脚本文件，避开隔离标记导致的确认弹窗）。
    terminal.runServerCommand(HTTPServer.command(for: dir))
}

// 给 NSWorkspace 一点时间把启动请求派发出去，然后退出。
RunLoop.current.run(until: Date().addingTimeInterval(1.5))
exit(0)
