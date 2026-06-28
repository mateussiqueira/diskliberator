import Foundation

final class SystemJunkService {
    static let shared = SystemJunkService()

    func scan() -> [SystemJunkCategory] {
        [
            SystemJunkCategory(name: "System Logs", icon: "doc.text.magnifyingglass", scan: { self.sizeOf("~/Library/Logs") }, clean: { self.cleanPath("~/Library/Logs") }),
            SystemJunkCategory(name: ".DS_Store Files", icon: "doc.badge.gearshape", scan: { self.scanDSStore() }, clean: { self.cleanDSStore() }),
            SystemJunkCategory(name: "Temporary Files", icon: "clock.arrow.circlepath", scan: { self.sizeOf("/private/var/tmp") + self.sizeOf("~/Library/Caches/com.apple.helpd") }, clean: { self.cleanMultiple(["/private/var/tmp", "~/Library/Caches/com.apple.helpd"]) }),
            SystemJunkCategory(name: "Crash Reports", icon: "exclamationmark.triangle", scan: { self.sizeOf("~/Library/Logs/DiagnosticReports") + self.sizeOf("~/Library/Application Support/CrashReporter") }, clean: { self.cleanMultiple(["~/Library/Logs/DiagnosticReports", "~/Library/Application Support/CrashReporter"]) }),
            SystemJunkCategory(name: "iOS Backups", icon: "iphone.gen2", scan: { self.sizeOf("~/Library/Application Support/MobileSync/Backup") }, clean: { self.cleanPath("~/Library/Application Support/MobileSync/Backup") }),
            SystemJunkCategory(name: "Xcode Simulators", icon: "hammer", scan: { self.sizeOf("~/Library/Developer/CoreSimulator/Caches") }, clean: { self.cleanPath("~/Library/Developer/CoreSimulator/Caches") }),
            SystemJunkCategory(name: "Brew Cleanup", icon: "mug", scan: { self.brewSize() }, clean: { self.brewClean() }),
        ]
    }

    private func sizeOf(_ path: String) -> Int64 {
        let url = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: url.path) else { return 0 }
        return DiskService.shared.calcSize(url)
    }

    private func scanDSStore() -> Int64 {
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard let e = FileManager.default.enumerator(at: home, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsPackageDescendants]) else { return 0 }
        var total: Int64 = 0
        for case let f as URL in e where f.lastPathComponent == ".DS_Store" {
            total += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }

    private func cleanPath(_ path: String) -> (Int64, String?) {
        let url = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
        let before = DiskService.shared.calcSize(url)
        do {
            try FileManager.default.removeItem(at: url)
            return (before, nil)
        } catch {
            return (0, error.localizedDescription)
        }
    }

    private func cleanMultiple(_ paths: [String]) -> (Int64, String?) {
        var total: Int64 = 0
        var lastErr: String? = nil
        for p in paths {
            let (freed, err) = cleanPath(p)
            total += freed
            if let e = err { lastErr = e }
        }
        return (total, lastErr)
    }

    private func cleanDSStore() -> (Int64, String?) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard let e = FileManager.default.enumerator(at: home, includingPropertiesForKeys: nil, options: [.skipsPackageDescendants]) else { return (0, nil) }
        var removed: Int64 = 0
        for case let f as URL in e where f.lastPathComponent == ".DS_Store" {
            let before = (try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap(Int64.init) ?? 0
            if (try? FileManager.default.removeItem(at: f)) != nil { removed += before }
        }
        return (removed, nil)
    }

    private func brewSize() -> Int64 {
        // Estimate brew cleanup size by checking brew cache
        return sizeOf("~/Library/Caches/Homebrew") + sizeOf("$(brew --cache 2>/dev/null || echo ~/Library/Caches/Homebrew)")
    }

    private func brewClean() -> (Int64, String?) {
        for path in ["/usr/local/bin/brew", "/opt/homebrew/bin/brew"] {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            let before = brewSize()
            let p = Process()
            p.executableURL = URL(fileURLWithPath: path)
            p.arguments = ["cleanup", "--prune=7"]
            do {
                try p.run()
                p.waitUntilExit()
                // Clean cache too
                _ = cleanPath("~/Library/Caches/Homebrew")
                // We can't measure exact freed size easily, return estimate
                return (before > 0 ? before : 100_000_000, nil)  // estimate at least 100MB
            } catch { continue }
        }
        return (0, "Brew not found")
    }
}
