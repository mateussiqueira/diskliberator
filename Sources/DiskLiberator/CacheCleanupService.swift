import Foundation

final class CacheCleanupService {
    static let shared = CacheCleanupService()

    struct Result: Identifiable {
        let id = UUID()
        let name: String
        let freed: Int64
        let error: String?
        let success: Bool
        var freedFormatted: String { ByteCountFormatter.short(freed) }
    }

    func clean(_ cat: CacheCategory) -> Result {
        if cat.path == "docker://system-prune" { return pruneDocker(cat.name) }

        let url = URL(fileURLWithPath: NSString(string: cat.path).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return Result(name: cat.name, freed: 0, error: nil, success: true)
        }

        let before = DiskService.shared.cacheSize(cat.path)
        do {
            try FileManager.default.removeItem(at: url)
            return Result(name: cat.name, freed: before, error: nil, success: true)
        } catch {
            return Result(name: cat.name, freed: 0, error: error.localizedDescription, success: false)
        }
    }

    private func pruneDocker(_ name: String) -> Result {
        for path in ["/usr/local/bin/docker", "/opt/homebrew/bin/docker"] {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: path)
            p.arguments = ["system", "prune", "-af", "--volumes"]
            do {
                try p.run()
                p.waitUntilExit()
                return Result(name: name, freed: 0, error: nil, success: p.terminationStatus == 0)
            } catch { continue }
        }
        return Result(name: name, freed: 0, error: "Docker not found", success: false)
    }

    func scanAll() -> [CacheCategory] {
        var cats = CacheCategory.all
        for i in cats.indices { cats[i].size = DiskService.shared.cacheSize(cats[i].path) }
        return cats.sorted { $0.size > $1.size }
    }
}
