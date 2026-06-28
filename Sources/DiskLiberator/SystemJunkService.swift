import Foundation

final class SystemJunkService {
    static let shared = SystemJunkService()

    struct JunkCategory: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let paths: [String]
        let isDocker: Bool
        var selected: Bool = true
        var size: Int64 = 0
        var formattedSize: String { ByteCountFormatter.short(size) }

        init(name: String, icon: String, paths: [String], isDocker: Bool = false) {
            self.name = name; self.icon = icon; self.paths = paths; self.isDocker = isDocker
        }
    }

    func scan() -> [JunkCategory] {
        var cats = allCategories()
        for i in cats.indices {
            cats[i].size = cats[i].isDocker ? dockerSize() : totalSize(cats[i].paths)
        }
        return cats.filter { $0.size > 0 }.sorted { $0.size > $1.size }
    }

    func clean(_ cat: JunkCategory) -> (Int64, String?) {
        if cat.isDocker { return cleanDocker() }
        var total: Int64 = 0
        for path in cat.paths {
            let url = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let before = DiskService.shared.calcSize(url)
            // Before deleting, create backup
            BackupService.shared.backup(path: path)
            do {
                try FileManager.default.removeItem(at: url)
                total += before
            } catch {
                // If root-owned, try with sudo via Process
                if error.localizedDescription.contains("Permission") {
                    let p = Process()
                    p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
                    p.arguments = ["rm", "-rf", url.path]
                    try? p.run()
                    p.waitUntilExit()
                    if p.terminationStatus == 0 { total += before }
                }
            }
        }
        return (total, nil)
    }

    // MARK: - All Categories
    private func allCategories() -> [JunkCategory] {
        let home = NSHomeDirectory()
        return [
            JunkCategory(name: "Xcode Simulators", icon: "iphone.gen2", paths: ["~/Library/Developer/CoreSimulator"]),
            JunkCategory(name: "Xcode DerivedData", icon: "hammer", paths: ["~/Library/Developer/Xcode/DerivedData"]),
            JunkCategory(name: "Xcode Archives", icon: "archivebox", paths: ["~/Library/Developer/Xcode/Archives"]),
            JunkCategory(name: "Xcode BuildMCP", icon: "wrench", paths: ["~/Library/Developer/XcodeBuildMCP"]),
            JunkCategory(name: "iOS DeviceSupport", icon: "iphone", paths: ["~/Library/Developer/Xcode/iOS DeviceSupport"]),
            JunkCategory(name: "iOS Backups", icon: "clock.arrow.circlepath", paths: ["~/Library/Application Support/MobileSync/Backup"]),
            JunkCategory(name: "System Logs", icon: "doc.text.magnifyingglass", paths: ["~/Library/Logs"]),
            JunkCategory(name: "Crash Reports", icon: "exclamationmark.triangle", paths: ["~/Library/Logs/DiagnosticReports", "~/Library/Application Support/CrashReporter"]),
            JunkCategory(name: ".DS_Store Files", icon: "doc.badge.gearshape", paths: ["~/.DS_Store_Finder"]),
            JunkCategory(name: "Temporary Files", icon: "clock.arrow.circlepath", paths: ["/private/var/tmp", "~/Library/Caches/com.apple.helpd"]),
            JunkCategory(name: "Mail Downloads", icon: "envelope", paths: ["~/Library/Containers/com.apple.mail/Data/Library/Downloads"]),
            JunkCategory(name: "App Store Caches", icon: "appstore", paths: ["~/Library/Caches/com.apple.appstore"]),
            JunkCategory(name: "Homebrew Cache", icon: "mug", paths: ["~/Library/Caches/Homebrew"]),
            JunkCategory(name: "Docker (prune)", icon: "tray.full", paths: ["docker://prune"], isDocker: true),
        ]
    }

    // MARK: - Helpers
    private func totalSize(_ paths: [String]) -> Int64 {
        paths.reduce(0) { $0 + sizeOf($1) }
    }

    private func sizeOf(_ path: String) -> Int64 {
        let url = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: url.path) else { return 0 }
        return DiskService.shared.calcSize(url)
    }

    private func dockerSize() -> Int64 {
        // Estimate: check if docker exists
        for path in ["/usr/local/bin/docker", "/opt/homebrew/bin/docker"] where FileManager.default.fileExists(atPath: path) {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: path)
            p.arguments = ["system", "df", "--format", "json"]
            let pipe = Pipe()
            p.standardOutput = pipe
            try? p.run()
            p.waitUntilExit()
            // If docker is running, estimate ~2GB reclaimable
            return p.terminationStatus == 0 ? 2_000_000_000 : 0
        }
        return 0
    }

    private func cleanDocker() -> (Int64, String?) {
        for path in ["/usr/local/bin/docker", "/opt/homebrew/bin/docker"] where FileManager.default.fileExists(atPath: path) {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: path)
            p.arguments = ["system", "prune", "-af", "--volumes"]
            try? p.run()
            p.waitUntilExit()
            return p.terminationStatus == 0 ? (2_000_000_000, nil) : (0, "docker prune failed")
        }
        return (0, "Docker not found")
    }

    // Scan .DS_Store across home directory (expensive, separate)
    func scanDSStore() -> Int64 {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        guard let e = FileManager.default.enumerator(at: home, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsPackageDescendants])
        else { return 0 }
        var total: Int64 = 0
        for case let f as URL in e where f.lastPathComponent == ".DS_Store" {
            total += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }

    func cleanDSStore() -> Int64 {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        guard let e = FileManager.default.enumerator(at: home, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsPackageDescendants])
        else { return 0 }
        var total: Int64 = 0
        for case let f as URL in e where f.lastPathComponent == ".DS_Store" {
            let size = Int64((try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            if (try? FileManager.default.removeItem(at: f)) != nil { total += size }
        }
        return total
    }
}
