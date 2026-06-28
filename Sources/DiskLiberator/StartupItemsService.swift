import Foundation

final class StartupItemsService {
    static let shared = StartupItemsService()

    struct StartupItem: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        let type: ItemType
        let enabled: Bool
        enum ItemType: String { case loginItem = "Login Item", launchAgent = "Launch Agent", launchDaemon = "Launch Daemon" }
    }

    func scan() -> [StartupItem] {
        var items: [StartupItem] = []

        // Login Items via AppleScript (must run on main thread)
        var loginItemNames: [String] = []
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            let script = "tell application \"System Events\"\nget the name of every login item\nend tell"
            var err: NSDictionary?
            if let output = NSAppleScript(source: script)?.executeAndReturnError(&err).stringValue {
                loginItemNames = output.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            }
            group.leave()
        }
        group.wait()

        for name in loginItemNames {
            items.append(StartupItem(name: name, path: "Login Item", type: .loginItem, enabled: true))
        }

        // Launch Agents
        let agentDirs = [
            FileManager.homeDir.appendingPathComponent("Library/LaunchAgents"),
            URL(fileURLWithPath: "/Library/LaunchAgents"),
        ]
        for dir in agentDirs {
            guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for f in files where f.pathExtension == "plist" {
                items.append(StartupItem(name: f.deletingPathExtension().lastPathComponent, path: f.path, type: .launchAgent, enabled: true))
            }
        }

        return items.sorted { $0.name < $1.name }
    }

    func disable(_ item: StartupItem) {
        if item.type == .loginItem {
            DispatchQueue.main.sync {
                let script = "tell application \"System Events\"\ndelete login item \"\(item.name)\"\nend tell"
                NSAppleScript(source: script)?.executeAndReturnError(nil)
            }
        } else if item.type == .launchAgent {
            try? FileManager.default.removeItem(atPath: item.path)
        }
    }
}
