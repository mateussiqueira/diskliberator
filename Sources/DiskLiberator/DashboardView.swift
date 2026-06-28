import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var vm: MainViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to DiskLiberator").font(.system(size: 24, weight: .bold)).foregroundStyle(ColorToken.primary)
                    Text("The ultimate Mac cleaner — free, native, powerful").font(.system(size: 13)).foregroundStyle(ColorToken.secondary)
                }
                .padding(.top, 8)

                // Internal Volume
                if let vol = vm.internalVol {
                    FeatureCard(icon: "internaldrive", title: "\(vol.name) \u{2014} \(vol.totalFormatted)", color: ColorToken.blue) {
                        VStack(spacing: 12) {
                            HStack(alignment: .center, spacing: 32) {
                                LargeMeter(value: vol.usage, color: ColorToken.blue, label: "Used", detail: vol.usedFormatted)
                                VStack(alignment: .leading, spacing: 10) {
                                    StatRowView(label: "Total capacity", value: vol.totalFormatted, color: ColorToken.primary)
                                    StatRowView(label: "Used space", value: vol.usedFormatted, color: ColorToken.blue)
                                    StatRowView(label: "Free space", value: vol.freeFormatted, color: ColorToken.green)
                                }
                            }
                        }
                    }
                }

                // External Drives
                if !vm.externalVols.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("External Drives").font(.system(size: 15, weight: .semibold)).foregroundStyle(ColorToken.primary)
                        ForEach(vm.externalVols) { vol in
                            FeatureCard(icon: "externaldrive", title: "\(vol.name) \u{2014} \(vol.totalFormatted)", color: ColorToken.teal) {
                                HStack(spacing: 24) {
                                    ProgressBarView(value: vol.usage, color: ColorToken.teal).frame(maxWidth: .infinity)
                                    Text("\(vol.freeFormatted) free").font(.system(size: 12, design: .monospaced)).foregroundStyle(ColorToken.teal)
                                }
                            }
                        }
                    }
                }

                // Quick Actions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Actions").font(.system(size: 15, weight: .semibold)).foregroundStyle(ColorToken.primary)
                    HStack(spacing: 12) {
                        ActionButton(title: "Smart Scan", icon: "wand.and.stars", color: ColorToken.purple, disabled: vm.isSmartScanning) { vm.smartScan() }
                        ActionButton(title: "Scan Home", icon: "magnifyingglass", color: ColorToken.blue) { vm.scan(FileManager.default.home) }
                        ActionButton(title: "Scan Caches", icon: "trash", color: ColorToken.orange) { vm.scanCaches() }
                        ActionButton(title: "Migrate All", icon: "externaldrive", color: ColorToken.green, disabled: vm.migrations.allSatisfy { $0.status == .completed || $0.status == .skipped }) { vm.migrateAll() }
                    }
                }

                // Activity
                if !vm.log.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Activity").font(.system(size: 13, weight: .semibold)).foregroundStyle(ColorToken.secondary)
                        ForEach(vm.log.suffix(5), id: \.self) { entry in
                            Text(entry).font(.system(size: 11, design: .monospaced)).foregroundStyle(ColorToken.secondary)
                        }
                    }
                    .padding(14).background(RoundedRectangle(cornerRadius: 10).fill(ColorToken.card))
                }
            }
            .padding(24)
        }
    }
}
