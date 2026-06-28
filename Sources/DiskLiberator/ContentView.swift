import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: MainViewModel
    @State private var tab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard, memory, scan, migrate, cleanup, apps, browser, startup, backups, diskmap, settings

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .memory: return "memorychip"
            case .scan: return "magnifyingglass"
            case .migrate: return "externaldrive"
            case .cleanup: return "trash"
            case .apps: return "square.grid.3x1.folder.fill.badge.plus"
            case .browser: return "globe"
            case .startup: return "power"
            case .backups: return "clock.arrow.circlepath"
            case .diskmap: return "rectangle.3.group"
            case .settings: return "gearshape"
            }
        }
        var label: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .memory: return "Memory"
            case .scan: return "Scanner"
            case .migrate: return "Migrate"
            case .cleanup: return "Clean Up"
            case .apps: return "Apps"
            case .browser: return "Browser"
            case .startup: return "Startup"
            case .backups: return "Backups"
            case .diskmap: return "Disk Map"
            case .settings: return "Settings"
            }
        }
    }

    var body: some View {
        HSplitView {
            sidebar.frame(width: 200)
            main.frame(minWidth: 650)
        }
        .preferredColorScheme(.dark)
        .task { vm.load() }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient.accent(Color.blue))
                        .frame(width: 28, height: 28)
                    Image(systemName: "externaldrive.badge.checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("DiskLiberator").font(.system(size: 15, weight: .bold)).foregroundStyle(ColorToken.primary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 16)

            VStack(spacing: 2) {
                ForEach(Tab.allCases, id: \.self) { t in
                    SidebarButton(icon: t.icon, label: t.label, isSelected: tab == t) { tab = t }
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            // Bottom status
            VStack(spacing: 4) {
                Divider().opacity(0.3)
                if let vol = vm.internalVol {
                    HStack(spacing: 6) {
                        ProgressBarView(value: vol.usage, color: ColorToken.blue).frame(width: 60)
                        Text("\(Int(vol.usage * 100))%").font(.system(size: 10, design: .monospaced)).foregroundStyle(ColorToken.secondary)
                        Spacer()
                        Text(vol.freeFormatted).font(.system(size: 10, design: .monospaced)).foregroundStyle(ColorToken.green)
                    }
                    .padding(.horizontal, 12).padding(.bottom, 8)
                }
                // Memory quick status
                HStack(spacing: 4) {
                    Circle().fill(vm.memPressure < 50 ? ColorToken.green : vm.memPressure < 75 ? ColorToken.orange : ColorToken.red).frame(width: 6)
                    Text("RAM: \(vm.memPressure)%").font(.system(size: 10)).foregroundStyle(ColorToken.secondary)
                    Spacer()
                    if !vm.heavyProcesses.isEmpty {
                        Text("\(vm.heavyProcesses.count) heavy").font(.system(size: 10)).foregroundStyle(ColorToken.orange)
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 12)
            }
        }
        .background(ColorToken.sidebar)
    }

    private var main: some View {
        Group {
            switch tab {
            case .dashboard: DashboardView()
            case .memory: MemoryView()
            case .scan: ScanView()
            case .migrate: MigrationView()
            case .cleanup: CleanupView()
            case .apps: AppUninstallView()
            case .browser: BrowserView()
            case .startup: StartupItemsView()
            case .backups: BackupView()
            case .diskmap: DiskUsageView()
            case .settings: SettingsView()
            }
        }
        .background(ColorToken.bg)
    }
}
