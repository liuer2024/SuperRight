import Foundation
import Darwin

enum HelperRequestStore {
    static let requestsDirectoryName = "requests"
    static let extensionBundleID = "com.smiler.superRight.FinderExtension"

    static func writableRequestsDirectory() -> URL? {
        if let appGroupDirectory = appGroupRequestsDirectory() {
            return appGroupDirectory
        }

        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("superRight", isDirectory: true)
            .appendingPathComponent(requestsDirectoryName, isDirectory: true)
    }

    static func readableRequestsDirectories() -> [URL] {
        var seen = Set<String>()
        return [
            appGroupRequestsDirectory(),
            extensionContainerRequestsDirectory(),
            userApplicationSupportRequestsDirectory()
        ]
        .compactMap { $0 }
        .filter { seen.insert($0.path).inserted }
    }

    private static func appGroupRequestsDirectory() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupID)?
            .appendingPathComponent(requestsDirectoryName, isDirectory: true)
    }

    private static func extensionContainerRequestsDirectory() -> URL? {
        URL(fileURLWithPath: realHomePath(), isDirectory: true)
            .appendingPathComponent("Library/Containers", isDirectory: true)
            .appendingPathComponent(extensionBundleID, isDirectory: true)
            .appendingPathComponent("Data/Library/Application Support/superRight", isDirectory: true)
            .appendingPathComponent(requestsDirectoryName, isDirectory: true)
    }

    private static func userApplicationSupportRequestsDirectory() -> URL? {
        URL(fileURLWithPath: realHomePath(), isDirectory: true)
            .appendingPathComponent("Library/Application Support/superRight", isDirectory: true)
            .appendingPathComponent(requestsDirectoryName, isDirectory: true)
    }

    private static func realHomePath() -> String {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            let path = String(cString: dir)
            if !path.isEmpty { return path }
        }
        return NSHomeDirectory()
    }
}
