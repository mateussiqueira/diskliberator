import Foundation

final class MigrationService {
    static let shared = MigrationService()

    enum Error: LocalizedError {
        case notFound(String), isSymlink(String), rsyncFailed(String), backupFailed(String)

        var errorDescription: String? {
            switch self {
            case .notFound(let p): return "Source not found: \(p)"
            case .isSymlink(let p): return "Already a symlink: \(p)"
            case .rsyncFailed(let m): return "rsync: \(m)"
            case .backupFailed(let m): return "Backup: \(m)"
            }
        }
    }

    func migrate(source: URL, dest: URL, onProgress: ((Double) -> Void)? = nil) async throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: source.path) else { throw Error.notFound(source.path) }
        if (try? source.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true {
            throw Error.isSymlink(source.path)
        }

        try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)

        // Progressive rsync with progress reporting
        let pipe = Pipe()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/rsync")
        proc.arguments = ["-a", "--delete", "--info=progress2", source.appendingPathComponent("").path, dest.path]
        proc.standardOutput = pipe
        proc.standardError = pipe

        var lastReport = Date.distantPast
        pipe.fileHandleForReading.readabilityHandler = { h in
            let data = h.availableData
            guard !data.isEmpty, let s = String(data: data, encoding: .utf8) else { return }
            // rsync progress: "1,234,567 50% ..."
            if let percent = Self.parseProgress(s), Date().timeIntervalSince(lastReport) > 0.5 {
                lastReport = Date()
                onProgress?(percent)
            }
        }

        try proc.run()
        proc.waitUntilExit()
        pipe.fileHandleForReading.readabilityHandler = nil

        guard proc.terminationStatus == 0 else {
            let err = (try? pipe.fileHandleForReading.readToEnd()).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            throw Error.rsyncFailed("exit \(proc.terminationStatus) \(err)")
        }

        onProgress?(1.0)

        // Backup original and create symlink
        let backup = source.deletingLastPathComponent()
            .appendingPathComponent(".\(source.lastPathComponent).dlbackup")
        if fm.fileExists(atPath: backup.path) { try fm.removeItem(at: backup) }
        try fm.moveItem(at: source, to: backup)
        try fm.createSymbolicLink(at: source, withDestinationURL: dest)
    }

    private static func parseProgress(_ s: String) -> Double? {
        guard let match = s.range(of: "(\\d+\\.?\\d*)%", options: .regularExpression) else { return nil }
        return Double(s[match].dropLast())
    }
}
