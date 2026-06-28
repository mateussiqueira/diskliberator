import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var vm: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Memory & Performance").font(.system(size: 18, weight: .bold)).foregroundStyle(ColorToken.primary)
                Spacer()
                ActionButton(title: "Refresh", icon: "arrow.clockwise", color: ColorToken.blue) { vm.refreshMemory() }
                ActionButton(title: "Free Memory", icon: "bolt.fill", color: ColorToken.purple, disabled: vm.isPurging) { vm.purgeRAM() }
            }
            .padding(20)
            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 16) {
                    // Memory Gauge
                    FeatureCard(icon: "memorychip", title: "Memory Pressure", color: ColorToken.purple) {
                        VStack(spacing: 16) {
                            HStack(spacing: 40) {
                                LargeMeter(value: Double(vm.memPressure) / 100, color: memColor(vm.memPressure), label: vm.memLabel, detail: "\(vm.memPressure)%")
                                VStack(alignment: .leading, spacing: 8) {
                                    StatRowView(label: "Physical Memory", value: vm.memInfo?.totalFormatted ?? "-")
                                    StatRowView(label: "Used Memory", value: vm.memInfo?.usedFormatted ?? "-", color: ColorToken.purple)
                                    StatRowView(label: "Free Memory", value: vm.memInfo?.freeFormatted ?? "-", color: ColorToken.green)
                                    StatRowView(label: "Wired", value: vm.memInfo.flatMap { ByteCountFormatter.short(Int64($0.wired)) } ?? "-", color: ColorToken.orange)
                                    StatRowView(label: "Compressed", value: vm.memInfo.flatMap { ByteCountFormatter.short(Int64($0.compressed)) } ?? "-", color: ColorToken.red)
                                }
                            }
                        }
                    }

                    // Heavy Processes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Heavy Processes").font(.system(size: 15, weight: .semibold)).foregroundStyle(ColorToken.primary)
                        if vm.heavyProcesses.isEmpty {
                            HStack { Spacer(); Text("No heavy processes found").foregroundStyle(ColorToken.secondary); Spacer() }.padding()
                        } else {
                            ForEach(vm.heavyProcesses) { proc in
                                HStack(spacing: 10) {
                                    Image(systemName: proc.isSuspicious ? "exclamationmark.triangle.fill" : "gearshape.2")
                                        .foregroundStyle(proc.isSuspicious ? ColorToken.red : ColorToken.secondary).frame(width: 16)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(proc.name).font(.system(size: 12)).foregroundStyle(ColorToken.primary)
                                        Text("PID \(proc.pid)").font(.system(size: 10)).foregroundStyle(ColorToken.secondary)
                                    }
                                    Spacer()
                                    Text(proc.formattedMem).font(.system(size: 11, design: .monospaced)).foregroundStyle(proc.isSuspicious ? ColorToken.red : ColorToken.orange)
                                    Text(String(format: "%.1f%%", proc.cpuPercent)).font(.system(size: 10, design: .monospaced)).foregroundStyle(ColorToken.secondary)
                                    MiniButton(icon: "xmark", color: ColorToken.red) { vm.killProcess(pid: proc.pid) }
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 6).fill(ColorToken.card))
                                .padding(.horizontal, 2)
                            }
                        }
                    }

                    if let lastPurge = vm.lastPurgeResult {
                        HStack {
                            Image(systemName: lastPurge.contains("OK") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(lastPurge.contains("OK") ? ColorToken.green : ColorToken.red)
                            Text(lastPurge).font(.system(size: 11)).foregroundStyle(ColorToken.secondary)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 6).fill(ColorToken.card))
                    }
                }
                .padding(20)
            }
        }
        .task { vm.refreshMemory() }
    }

    private func memColor(_ p: Int) -> Color {
        p < 50 ? ColorToken.green : p < 75 ? ColorToken.orange : ColorToken.red
    }
}
