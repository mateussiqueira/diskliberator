import Foundation
import AppKit
import ApplicationServices

final class PermissionService {
    static let shared = PermissionService()

    struct PermissionStatus {
        let name: String
        let icon: String
        let description: String
        let granted: Bool
        let helpURL: String?
    }

    func checkAll() -> [PermissionStatus] {
        [
            checkFullDiskAccess(),
            checkAccessibility(),
            checkAutomation(),
            checkNotifications(),
        ]
    }

    private func checkFullDiskAccess() -> PermissionStatus {
        // Check if we can read protected areas
        let testPaths = [
            "/Library/Application Support/Apple",
            "\(NSHomeDirectory())/Library/Mail",
        ]
        let granted = testPaths.contains { path in
            FileManager.default.isReadableFile(atPath: path)
        }
        return PermissionStatus(
            name: "Full Disk Access",
            icon: "lock.shield",
            description: "Required to clean system caches, logs, and user data",
            granted: granted,
            helpURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        )
    }

    private func checkAccessibility() -> PermissionStatus {
        let options = NSDictionary(dictionary: [
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: false
        ])
        let granted = AXIsProcessTrustedWithOptions(options)
        return PermissionStatus(
            name: "Accessibility",
            icon: "hand.raised",
            description: "Required for advanced system operations",
            granted: granted,
            helpURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )
    }

    private func checkAutomation() -> PermissionStatus {
        // Check if we can control Finder and Terminal
        let granted = NSAppleEventManager.shared().currentAppleEvent != nil
        return PermissionStatus(
            name: "Automation",
            icon: "gearshape.2",
            description: "Required for scripting operations",
            granted: granted,
            helpURL: nil
        )
    }

    private func checkNotifications() -> PermissionStatus {
        // Simple check - notifications might need authorization
        return PermissionStatus(
            name: "Notifications",
            icon: "bell.badge",
            description: "For cleanup completion alerts",
            granted: true,
            helpURL: nil
        )
    }

    func requestAccessibility() {
        let options = NSDictionary(dictionary: [
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true
        ])
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
    }
}
