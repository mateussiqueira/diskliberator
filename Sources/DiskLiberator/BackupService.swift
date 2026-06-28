import Foundation

final class BackupService {
    static let shared = BackupService()
    private let fm = FileManager.default

    private var backupRoot: URL {
        let base = URL(fileURLWithPath: "/Volumes/BACKUP/.diskliberator-snapshots")
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    struct BackupResult {
        let path: String
        let backupPath: String
        let sizeBytes: Int64
        let timestamp: Date
        let success: Bool
        let error: String?

        var formattedSize: String { ByteCountFormatter.short(sizeBytes) }
    }

    /// Creates a compressed tar backup of a path before cleanup
    func backup(path: String) -> BackupResult {
        let url = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
        guard fm.fileExists(atPath: url.path) else {
            return BackupResult(path: path, backupPath: "", sizeBytes: 0, timestamp: Date(), success: true, error: "Path does not exist, skipping backup")
        }

        let dateStr = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let safeName = url.lastPathComponent.replacingOccurrences(of: "/", with: "_")
        let backupURL = backupRoot.appendingPathComponent("\(safeName)_\(dateStr).tar.gz")

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        p.arguments = ["-czf", backupURL.path, "-C", url.deletingLastPathComponent().path, url.lastPathComponent]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice

        do {
            try p.run()
            p.waitUntilExit()
            guard p.terminationStatus == 0 else {
                return BackupResult(path: path, backupPath: "", sizeBytes: 0, timestamp: Date(), success: false, error: "tar failed with code \(p.terminationStatus)")
            }
            let size = (try? backupURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap(Int64.init) ?? 0
            return BackupResult(path: path, backupPath: backupURL.path, sizeBytes: size, timestamp: Date(), success: true, error: nil)
        } catch {
            return BackupResult(path: path, backupPath: "", sizeBytes: 0, timestamp: Date(), success: false, error: error.localizedDescription)
        }
    }

    /// List all backups
    func listBackups() -> [BackupResult] {
        guard let contents = try? fm.contentsOfDirectory(at: backupRoot, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey], options: .skipsHiddenFiles)
        else { return [] }
        return contents.compactMap { url in
            guard let r = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]),
                  let size = r.fileSize.flatMap(Int64.init),
                  let date = r.creationDate
            else { return nil }
            return BackupResult(path: url.lastPathComponent, backupPath: url.path, sizeBytes: size, timestamp: date, success: true, error: nil)
        }.sorted { $0.timestamp > $1.timestamp }
    }

    /// Restore from a backup
    func restore(backupPath: String) -> Bool {
        let url = URL(fileURLWithPath: backupPath)
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        p.arguments = ["-xzf", url.path, "-C", "/"]
        do {
            try p.run()
            p.waitUntilExit()
            return p.terminationStatus == 0
        } catch { return false }
    }

    /// Remove old backups, keep last N
    func prune(keep: Int = 10) {
        let all = listBackups()
        if all.count <= keep { return }
        for backup in all.dropFirst(keep) {
            try? fm.removeItem(atPath: backup.backupPath)
        }
    }

    var totalBackupSize: Int64 {
        listBackups().reduce(0) { $0 + $1.sizeBytes }
    }

    var backupCount: Int {
        listBackups().count
    }
}
