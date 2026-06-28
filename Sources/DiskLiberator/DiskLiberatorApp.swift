import SwiftUI

@main
struct DiskLiberatorApp: App {
    @StateObject private var vm = MainViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandMenu("Actions") {
                Button("Smart Scan") { Task { @MainActor in vm.smartScan() } }.keyboardShortcut("s", modifiers: [.command, .shift])
                Button("Free Memory") { Task { @MainActor in vm.purgeRAM() } }.keyboardShortcut("m", modifiers: [.command, .shift])
                Button("Scan Home") { Task { @MainActor in vm.scan(FileManager.default.home) } }.keyboardShortcut("h", modifiers: [.command, .shift])
                Button("Scan Caches") { Task { @MainActor in vm.scanCaches() } }.keyboardShortcut("c", modifiers: [.command, .shift])
                Divider()
                Button("Migrate All") { Task { @MainActor in vm.migrateAll() } }.keyboardShortcut("u", modifiers: [.command, .shift])
            }
        }
    }
}
