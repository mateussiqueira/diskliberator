import SwiftUI

struct AppUninstallView: View {
    @EnvironmentObject var vm: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("App Uninstaller").font(.system(size: 18, weight: .bold)).foregroundStyle(ColorToken.primary)
                Spacer()
                Text("\(vm.installedApps.count) apps").font(.system(size: 12)).foregroundStyle(ColorToken.secondary)
                ActionButton(title: "Scan Apps", icon: "arrow.clockwise", color: ColorToken.blue, disabled: vm.isAppScanning) { vm.scanApps() }
                ActionButton(title: "Uninstall Selected", icon: "trash", color: ColorToken.red, disabled: vm.isAppScanning || !vm.installedApps.contains(where: \.selected)) { vm.uninstallSelectedApps() }
            }
            .padding(20)
            Divider().opacity(0.3)

            if vm.isAppScanning {
                VStack(spacing: 12) { Spacer(); ProgressView().scaleEffect(1.5); Text("Scanning installed apps...").foregroundStyle(ColorToken.secondary); Spacer() }
            } else if vm.installedApps.isEmpty {
                VStack(spacing: 12) { Spacer(); Image(systemName: "square.grid.3x1.folder.fill.badge.plus").font(.system(size: 40)).foregroundStyle(ColorToken.secondary); Text("No apps scanned").foregroundStyle(ColorToken.secondary); Spacer() }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(vm.installedApps.enumerated()), id: \.element.id) { i, app in
                            HStack(spacing: 10) {
                                if let icon = appIcon(app.bundleURL) {
                                    Image(nsImage: icon).resizable().frame(width: 24, height: 24)
                                } else {
                                    Image(systemName: "app.badge").foregroundStyle(ColorToken.blue).frame(width: 24)
                                }
                                Toggle(app.name, isOn: Binding(get: { vm.installedApps[i].selected }, set: { vm.installedApps[i].selected = $0 }))
                                    .toggleStyle(.checkbox).font(.system(size: 12)).foregroundStyle(ColorToken.primary)
                                Text("v\(app.version)").font(.system(size: 10)).foregroundStyle(ColorToken.secondary)
                                Spacer()
                                Text(app.formattedTotal).font(.system(size: 11, design: .monospaced)).foregroundStyle(ColorToken.orange)
                                Text("(app: \(app.formattedApp), data: \(app.formattedSupport))").font(.system(size: 9)).foregroundStyle(ColorToken.secondary)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(ColorToken.card))
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            if !vm.appUninstallResults.isEmpty {
                Divider().opacity(0.3)
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(vm.appUninstallResults, id: \.name) { r in
                            HStack(spacing: 3) {
                                Image(systemName: r.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 9)).foregroundStyle(r.success ? ColorToken.green : ColorToken.red)
                                Text("\(r.name): \(r.success ? "Removed" : r.error ?? "")").font(.system(size: 10, design: .monospaced)).foregroundStyle(ColorToken.secondary)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4).background(RoundedRectangle(cornerRadius: 4).fill(ColorToken.card))
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 6)
                }
                .frame(height: 36)
            }
        }
    }

    private func appIcon(_ url: URL) -> NSImage? {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}
