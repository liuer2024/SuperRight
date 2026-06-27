import SwiftUI
import AppKit
import FinderSync

struct SettingsView: View {
    @State private var selectedID = AppConfig.defaultTerminalID
    @State private var showMenuIcons = AppConfig.showMenuIcons
    @State private var enableHttpServer = AppConfig.enableHttpServer

    /// 只展示当前机器上实际装了的终端。
    private let terminals = TerminalRegistry.installed

    var body: some View {
        VStack(spacing: 0) {
            header

            Form {
                Section("默认终端") {
                    if terminals.isEmpty {
                        Label("未检测到受支持的终端，请先安装 Ghostty / iTerm2 等。",
                              systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(terminals, id: \.id) { term in
                            terminalRow(term)
                        }
                    }
                }

                Section("菜单") {
                    Toggle(isOn: $showMenuIcons) {
                        Label("在右键菜单项前显示图标", systemImage: "square.grid.2x2")
                    }
                    .onChange(of: showMenuIcons) { _, newValue in
                        AppConfig.showMenuIcons = newValue
                    }

                    Toggle(isOn: $enableHttpServer) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("显示「用 http-server 打开」")
                                Text("在所选文件夹启动本地静态服务器并打开浏览器")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "network")
                        }
                    }
                    .onChange(of: enableHttpServer) { _, newValue in
                        AppConfig.enableHttpServer = newValue
                    }
                }

                Section("扩展") {
                    LabeledContent {
                        Button("打开扩展设置") {
                            FIFinderSyncController.showExtensionManagementInterface()
                        }
                    } label: {
                        Label("启用访达扩展", systemImage: "puzzlepiece.extension.fill")
                    }
                    Text("首次使用需要在「系统设置 → 隐私与安全性 → 扩展 → 访达扩展」里勾选 superRight。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 460, height: 540)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.22), Color(white: 0.08)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.42, green: 0.93, blue: 0.56),
                                         Color(red: 0.18, green: 0.78, blue: 0.44)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                )
                .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 3) {
                Text("superRight")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                Text("在 Finder 右键菜单里用你喜欢的终端打开文件夹")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    // MARK: - 终端行

    private func terminalRow(_ term: TerminalLauncher) -> some View {
        Button {
            selectedID = term.id
            AppConfig.defaultTerminalID = term.id
        } label: {
            HStack(spacing: 11) {
                Image(nsImage: appIcon(for: term))
                    .resizable()
                    .frame(width: 24, height: 24)
                Text(term.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                if term.id == selectedID {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 取终端 App 的真实图标，取不到时回退到系统终端符号。
    private func appIcon(for term: TerminalLauncher) -> NSImage {
        if let url = term.appURL {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSImage(systemSymbolName: "terminal", accessibilityDescription: nil) ?? NSImage()
    }
}

#Preview {
    SettingsView()
}
