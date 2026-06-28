import Foundation

final class DiskService {
    static let shared = DiskService()

    func scan(_ url: URL, maxItems: Int = 200) -> [DiskItem] {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey]
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: Array(keys), options: .skipsHiddenFiles
        ) else { return [] }

        var items: [DiskItem] = []
        for file in contents {
            guard let r = try? file.resourceValues(forKeys: keys) else { continue }
            let isDir = r.isDirectory ?? false
            let isLink = r.isSymbolicLink ?? false
            let size: Int64 = isDir && !isLink ? calcSize(file) : Int64(r.fileSize ?? 0)
            if size > 1_000_000 {
                items.append(DiskItem(url: file, name: file.lastPathComponent, size: size, isDir: isDir, isSymlink: isLink))
            }
        }
        return items.sorted { $0.size > $1.size }.prefix(maxItems).map { $0 }
    }

    func scanRecursive(_ url: URL, maxItems: Int = 200) -> [DiskItem] {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey, .totalFileSizeKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var dirSizes: [URL: Int64] = [:]
        var dirSet: Set<URL> = []

        for case let f as URL in enumerator {
            guard let r = try? f.resourceValues(forKeys: keys) else { continue }
            if r.isSymbolicLink == true { continue }
            if r.isDirectory == true { dirSet.insert(f) }
            let fs = Int64(r.totalFileSize ?? r.fileSize ?? 0)
            if fs == 0 { continue }
            var p = r.isDirectory == true ? f : f.deletingLastPathComponent()
            while p != url {
                dirSizes[p] = (dirSizes[p] ?? 0) + fs
                p = p.deletingLastPathComponent()
                if !dirSet.contains(p) && p != url { break }
            }
            if dirSizes.count > maxItems * 5 { break }
        }

        return dirSizes
            .filter { $0.key != url }
            .sorted { $0.value > $1.value }
            .prefix(maxItems)
            .map { DiskItem(url: $0.key, name: $0.key.lastPathComponent, size: $0.value, isDir: dirSet.contains($0.key), isSymlink: false) }
    }

    func calcSize(_ url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .totalFileSizeKey, .isSymbolicLinkKey]
        guard let e = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles, .skipsPackageDescendants])
        else { return 0 }
        var total: Int64 = 0
        for case let f as URL in e {
            guard let r = try? f.resourceValues(forKeys: keys), r.isSymbolicLink != true else { continue }
            total += Int64(r.totalFileSize ?? r.fileSize ?? 0)
        }
        return total
    }

    func cacheSize(_ path: String) -> Int64 {
        let url = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: url.path) else { return 0 }
        return calcSize(url)
    }
}
