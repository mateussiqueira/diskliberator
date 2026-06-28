import Foundation

struct DiskItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let isDir: Bool
    let isSymlink: Bool

    var formattedSize: String { ByteCountFormatter.short(size) }
    var icon: String {
        if isSymlink { return "arrow.triangle.branch" }
        if !isDir { return "doc" }
        if name == "node_modules" { return "cube.box.fill" }
        if name == ".git" { return "arrow.triangle.branch" }
        return "folder.fill"
    }
    var detail: String { url.path }
}

struct VolumeInfo: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let total: Int64
    let free: Int64
    let used: Int64

    var usage: Double { total > 0 ? Double(used) / Double(total) : 0 }
    var freeFormatted: String { ByteCountFormatter.short(free) }
    var usedFormatted: String { ByteCountFormatter.short(used) }
    var totalFormatted: String { ByteCountFormatter.short(total) }

    static func all() -> [VolumeInfo] {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: .skipHiddenVolumes)
        else { return [] }

        return urls.compactMap { url in
            guard let r = try? url.resourceValues(forKeys: Set(keys)),
                  let name = r.volumeName,
                  let total = r.volumeTotalCapacity.flatMap({ Int64(exactly: $0) }),
                  let free = r.volumeAvailableCapacityForImportantUsage.flatMap({ Int64(exactly: $0) })
            else { return nil }
            return VolumeInfo(url: url, name: name, total: total, free: free, used: total - free)
        }
        .filter { $0.url.path != "/System/Volumes/Data" && $0.url.path != "/System/Volumes/Update" && $0.name != "Recovery" }
    }

    var isInternal: Bool { !url.path.hasPrefix("/Volumes") }
}

struct MigrationTask: Identifiable {
    let id = UUID()
    let source: URL
    let label: String
    var size: Int64 = 0
    var status: Status = .pending
    var error: String?

    var formattedSize: String { size > 0 ? ByteCountFormatter.short(size) : "" }
    var sourcePath: String { source.path }

    enum Status: String { case pending, migrating, completed, failed, skipped }

    static let defaultMigrations: [MigrationTask] = {
        let h = FileManager.default.homeDirectoryForCurrentUser
        return [
            .init(source: h.appendingPathComponent("Desktop"), label: "Desktop"),
            .init(source: h.appendingPathComponent("Documents"), label: "Documents"),
            .init(source: h.appendingPathComponent("Downloads"), label: "Downloads"),
            .init(source: h.appendingPathComponent("Projects"), label: "Projects"),
        ]
    }()
}

struct CacheCategory: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let icon: String
    var size: Int64 = 0
    var selected = true

    var formattedSize: String { ByteCountFormatter.short(size) }

    static let all: [CacheCategory] = [
        .init(name: "npm Cache", path: "~/.npm/_cacache", icon: "cube.box"),
        .init(name: "pnpm Cache", path: "~/Library/Caches/pnpm", icon: "cube.box"),
        .init(name: "pip Cache", path: "~/Library/Caches/pip", icon: "cube.box"),
        .init(name: "npm Cache (old)", path: "~/Library/Caches/npm", icon: "cube.box"),
        .init(name: "yarn Cache", path: "~/Library/Caches/yarn", icon: "cube.box"),
        .init(name: "Xcode DerivedData", path: "~/Library/Developer/Xcode/DerivedData", icon: "hammer.fill"),
        .init(name: "Xcode Archives", path: "~/Library/Developer/Xcode/Archives", icon: "archivebox"),
        .init(name: "iOS DeviceSupport", path: "~/Library/Developer/Xcode/iOS DeviceSupport", icon: "iphone"),
        .init(name: "Safari Cache", path: "~/Library/Caches/com.apple.Safari", icon: "safari"),
        .init(name: "Spotify Cache", path: "~/Library/Caches/com.spotify.client", icon: "music.note"),
        .init(name: "Docker (prune)", path: "docker://system-prune", icon: "tray.full"),
    ]
}

// MARK: - Duplicate File
struct DuplicateGroup: Identifiable {
    let id = UUID()
    let size: Int64
    let count: Int
    let files: [URL]
    var selected: Bool = true
    var formattedSize: String { ByteCountFormatter.short(size) }
}

// MARK: - App for Uninstall
struct InstalledApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleURL: URL
    let appSize: Int64
    let supportSize: Int64
    let totalSize: Int64
    let supports: [URL]
    var selected: Bool = true
    var formattedTotal: String { ByteCountFormatter.short(totalSize) }
}
