import Foundation

enum HTTPServer {
    static let port = 8080

    /// 生成「在指定目录启动静态服务器」的 shell 命令体（不含 shebang，可直接喂给 `zsh -c`）。
    /// 关键：以内联命令的形式交给终端执行，**不落地成脚本文件**，从而避免沙盒隔离标记
    /// 触发 Ghostty 的「允许执行脚本」确认框。
    /// 显式设置 PATH 以保证找得到 http-server，并在 http-server / npx / python3 间回退。
    static func command(for directoryPath: String) -> String {
        let safeDir = directoryPath.replacingOccurrences(of: "'", with: "'\\''")
        return """
        export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
        cd '\(safeDir)' || exit 1
        PORT=\(port)
        URL="http://localhost:$PORT"
        echo "superRight · 静态服务器"
        echo "目录: $(pwd)"
        echo "地址: $URL   (按 Ctrl+C 停止)"
        echo
        ( sleep 1; open "$URL" ) &
        if command -v http-server >/dev/null 2>&1; then
          exec http-server -p "$PORT" -c-1 .
        elif command -v npx >/dev/null 2>&1; then
          exec npx --yes http-server -p "$PORT" -c-1 .
        else
          exec python3 -m http.server "$PORT"
        fi
        """
    }
}
