import Foundation

final class AppUninstallService {
    static let shared = AppUninstallService()

    struct InstalledApp: Identifiable {
        let id = UUID()
        let name: String
        let bundleURL: URL
        let version: String
        let appSize: Int64
        let supportSize: Int64
        let cacheSize: Int64
        let prefSize: Int64
        let totalSize: Int64
        var selected: Bool = false

        var formattedTotal: String { ByteCountFormatter.short(totalSize) }
        var formattedApp: String { ByteCountFormatter.short(appSize) }
        var formattedSupport: String { ByteCountFormatter.short(supportSize) }

        var supportPaths: [URL] {
            [FileManager.homeDir.appendingPathComponent("Library/Application Support/\(name)"),
             FileManager.homeDir.appendingPathComponent("Library/Caches/\(name)"),
             FileManager.homeDir.appendingPathComponent("Library/Preferences/\(name)"),
             FileManager.homeDir.appendingPathComponent("Library/Preferences/\(bundleURL.lastPathComponent.replacingOccurrences(of: ".app", with: "").replacingOccurrences(of: " ", with: ""))"),
             FileManager.homeDir.appendingPathComponent("Library/Preferences/\(bundleURL.deletingPathExtension().lastPathComponent).plist"),
             FileManager.homeDir.appendingPathComponent("Library/Saved Application State/\(bundleURL.deletingPathExtension().lastPathComponent)"),
             FileManager.homeDir.appendingPathComponent("Library/Containers/\(bundleURL.deletingPathExtension().lastPathComponent)")]
        }
    }

    static let fm = FileManager.default

    func scanApps() -> [InstalledApp] {
        let appDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "\(NSHomeDirectory())/Applications"),
        ]
        var apps: [InstalledApp] = []

        for dir in appDirs {
            guard let contents = try? Self.fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isApplicationKey], options: .skipsHiddenFiles)
            else { continue }
            for app in contents where app.pathExtension == "app" {
                guard let info = parseInfoPlist(app) else { continue }
                let name = info.name
                let version = info.version
                let appSize = DiskService.shared.calcSize(app)
                let support = FileManager.homeDir.appendingPathComponent("Library/Application Support/\(name)")
                let caches = FileManager.homeDir.appendingPathComponent("Library/Caches/\(name)")
                let prefs = FileManager.homeDir.appendingPathComponent("Library/Preferences/\(name)")
                let supportSize = (try? Self.fm.attributesOfItem(atPath: support.path)).flatMap { ($0[.size] as? Int64) } ?? 0
                let cacheSize = (try? Self.fm.attributesOfItem(atPath: caches.path)).flatMap { ($0[.size] as? Int64) } ?? 0
                let prefSize = (try? Self.fm.attributesOfItem(atPath: prefs.path)).flatMap { ($0[.size] as? Int64) } ?? 0

                apps.append(InstalledApp(
                    name: name, bundleURL: app, version: version,
                    appSize: appSize, supportSize: supportSize + cacheSize + prefSize,
                    cacheSize: cacheSize, prefSize: prefSize,
                    totalSize: appSize + supportSize + cacheSize + prefSize
                ))
            }
        }
        return apps.sorted { $0.totalSize > $1.totalSize }
    }

    func uninstall(app: InstalledApp) -> (Bool, String?) {
        // Backup support files first
        // Then remove app bundle
        do {
            // Remove app
            try Self.fm.removeItem(at: app.bundleURL)

            // Remove support files
            for path in app.supportPaths {
                if Self.fm.fileExists(atPath: path.path) {
                    try? Self.fm.removeItem(at: path)
                }
            }

            // Remove specific preference files
            let prefDir = FileManager.homeDir.appendingPathComponent("Library/Preferences")
            if let prefs = try? Self.fm.contentsOfDirectory(at: prefDir, includingPropertiesForKeys: nil) {
                for p in prefs where p.lastPathComponent.hasPrefix(app.name) || p.lastPathComponent.contains(app.bundleURL.deletingPathExtension().lastPathComponent) {
                    try? Self.fm.removeItem(at: p)
                }
            }

            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private struct AppInfo {
        let name: String
        let version: String
    }

    private func parseInfoPlist(_ appURL: URL) -> AppInfo? {
        let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else { return nil }
        return AppInfo(
            name: dict["CFBundleDisplayName"] as? String ?? dict["CFBundleName"] as? String ?? appURL.deletingPathExtension().lastPathComponent,
            version: dict["CFBundleShortVersionString"] as? String ?? dict["CFBundleVersion"] as? String ?? "?"
        )
    }
}

extension FileManager {
    static let homeDir = URL(fileURLWithPath: NSHomeDirectory())
    var homeDir2: URL { Self.homeDir }
}
