import Foundation

final class BrowserPrivacyService {
    static let shared = BrowserPrivacyService()

    struct BrowserData: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let historySize: Int64
        let cacheSize: Int64
        let cookieSize: Int64
        let totalSize: Int64
        let paths: [URL]
        var formattedTotal: String { ByteCountFormatter.short(totalSize) }
    }

    func scanAll() -> [BrowserData] {
        [scanSafari(), scanChrome(), scanFirefox(), scanBrave(), scanEdge()].filter { $0.totalSize > 0 }
    }

    private func scanSafari() -> BrowserData {
        let home = FileManager.homeDir
        let paths = [
            home.appendingPathComponent("Library/Safari/History.db"),
            home.appendingPathComponent("Library/Safari/LocalStorage"),
            home.appendingPathComponent("Library/Caches/com.apple.Safari"),
            home.appendingPathComponent("Library/Caches/com.apple.WebKit.WebContent"),
        ]
        let sizes = paths.map { DiskService.shared.calcSize($0) }
        return BrowserData(name: "Safari", icon: "safari",
            historySize: sizes[0], cacheSize: sizes[2] + sizes[3], cookieSize: sizes[1],
            totalSize: sizes.reduce(0, +), paths: paths)
    }

    private func scanChrome() -> BrowserData {
        let home = FileManager.homeDir
        let base = home.appendingPathComponent("Library/Application Support/Google/Chrome/Default")
        let paths = [
            base.appendingPathComponent("History"),
            base.appendingPathComponent("Cache"),
            base.appendingPathComponent("Cookies"),
            base.appendingPathComponent("Service Worker/CacheStorage"),
        ]
        let sizes = paths.map { DiskService.shared.calcSize($0) }
        return BrowserData(name: "Chrome", icon: "globe",
            historySize: sizes[0], cacheSize: sizes[1] + sizes[3], cookieSize: sizes[2],
            totalSize: sizes.reduce(0, +), paths: paths)
    }

    private func scanFirefox() -> BrowserData {
        let home = FileManager.homeDir
        let base = home.appendingPathComponent("Library/Application Support/Firefox/Profiles")
        guard let profiles = try? FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil)
        else { return .init(name: "Firefox", icon: "flame", historySize: 0, cacheSize: 0, cookieSize: 0, totalSize: 0, paths: []) }

        var total: Int64 = 0; var hSize: Int64 = 0; var cSize: Int64 = 0; var paths: [URL] = []
        for p in profiles where p.lastPathComponent.contains(".default") || p.lastPathComponent.contains(".release") {
            let places = p.appendingPathComponent("places.sqlite")
            let cache = p.appendingPathComponent("cache2")
            let cookies = p.appendingPathComponent("cookies.sqlite")
            let s1 = DiskService.shared.calcSize(places); let s2 = DiskService.shared.calcSize(cache); let s3 = DiskService.shared.calcSize(cookies)
            hSize += s1; cSize += s2; total += s1 + s2 + s3; paths += [places, cache, cookies]
        }
        return BrowserData(name: "Firefox", icon: "flame", historySize: hSize, cacheSize: cSize, cookieSize: 0, totalSize: total, paths: paths)
    }

    private func scanBrave() -> BrowserData {
        let home = FileManager.homeDir
        let base = home.appendingPathComponent("Library/Application Support/BraveSoftware/Brave-Browser/Default")
        let paths = [base.appendingPathComponent("History"), base.appendingPathComponent("Cache"), base.appendingPathComponent("Cookies")]
        let sizes = paths.map { DiskService.shared.calcSize($0) }
        return BrowserData(name: "Brave", icon: "shield",
            historySize: sizes[0], cacheSize: sizes[1], cookieSize: sizes[2],
            totalSize: sizes.reduce(0, +), paths: paths)
    }

    private func scanEdge() -> BrowserData {
        let home = FileManager.homeDir
        let base = home.appendingPathComponent("Library/Application Support/Microsoft Edge/Default")
        let paths = [base.appendingPathComponent("History"), base.appendingPathComponent("Cache"), base.appendingPathComponent("Cookies")]
        let sizes = paths.map { DiskService.shared.calcSize($0) }
        return BrowserData(name: "Edge", icon: "safari",
            historySize: sizes[0], cacheSize: sizes[1], cookieSize: sizes[2],
            totalSize: sizes.reduce(0, +), paths: paths)
    }

    func clean(_ browser: BrowserData) -> Int64 {
        var total: Int64 = 0
        for path in browser.paths where FileManager.default.fileExists(atPath: path.path) {
            let before = DiskService.shared.calcSize(path)
            try? FileManager.default.removeItem(at: path)
            // Recreate empty dir for caches
            if path.lastPathComponent == "Cache" || path.lastPathComponent == "cache2" || path.lastPathComponent == "CacheStorage" || path.lastPathComponent == "LocalStorage" {
                try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            }
            total += before
        }
        return total
    }
}
