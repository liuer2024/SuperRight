import AppKit

// superRightHelper：无界面的后台小助手（非沙盒）。
// 扩展把请求写入 requests/，然后唤起本程序。
// 本程序读取这些请求，用默认终端打开目录或启动 http-server，然后退出。

let fm = FileManager.default

let requests = HelperRequestStore.readableRequestsDirectories()
    .flatMap { (try? fm.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)) ?? [] }
    .filter { $0.pathExtension == "txt" }

let terminal = AppConfig.defaultTerminal

for request in requests {
    guard let raw = try? String(contentsOf: request, encoding: .utf8) else { continue }
    try? fm.removeItem(at: request)   // 消费掉请求

    let parsed = parseRequest(raw)
    let dir = parsed.directory
    var isDir: ObjCBool = false
    guard !dir.isEmpty, fm.fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue else { continue }

    switch parsed.action {
    case "open":
        terminal.open(directory: URL(fileURLWithPath: dir, isDirectory: true))
    case "serve":
        terminal.runServerCommand(HTTPServer.command(for: dir))
    default:
        continue
    }
}

// 给 NSWorkspace 一点时间把启动请求派发出去，然后退出。
RunLoop.current.run(until: Date().addingTimeInterval(1.5))
exit(0)

private func parseRequest(_ raw: String) -> (action: String, directory: String) {
    let lines = raw
        .split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        .map(String.init)

    guard lines.count == 2 else {
        return ("serve", raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    let action = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
    let directory = lines[1].trimmingCharacters(in: .whitespacesAndNewlines)
    return (action, directory)
}
