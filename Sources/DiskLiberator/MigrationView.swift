import SwiftUI

struct MigrationView: View {
    @EnvironmentObject var vm: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("File Migration").font(.system(size: 18, weight: .bold)).foregroundStyle(ColorToken.primary)
                Spacer()
                ActionButton(title: "Migrate All", icon: "play.fill", color: ColorToken.green,
                    disabled: vm.migrations.allSatisfy { $0.status == .completed || $0.status == .skipped }) { vm.migrateAll() }
            }
            .padding(20)
            Divider().opacity(0.3)

            if let i = vm.migratingIndex, vm.migrations.indices.contains(i) {
                ProgressCardView(title: vm.migrations[i].label, progress: vm.migrationProgress,
                    color: ColorToken.blue, status: "\(Int(vm.migrationProgress * 100))%")
                    .padding(.horizontal, 20).padding(.top, 12)
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(vm.migrations.enumerated()), id: \.element.id) { i, task in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(sColor(task.status).opacity(0.15)).frame(width: 28)
                                Image(systemName: sIcon(task.status))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(sColor(task.status))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.label).font(.system(size: 14, weight: .semibold)).foregroundStyle(ColorToken.primary)
                                if let err = task.error {
                                    Text(err).font(.system(size: 11)).foregroundStyle(ColorToken.red)
                                } else {
                                    Text(task.sourcePath).font(.system(size: 11)).foregroundStyle(ColorToken.secondary).lineLimit(1)
                                }
                            }
                            Spacer()
                            if !task.formattedSize.isEmpty {
                                Text(task.formattedSize).font(.system(size: 12, design: .monospaced)).foregroundStyle(ColorToken.secondary)
                            }
                            if task.status == .pending {
                                ActionButton(title: "Migrate", icon: "arrow.right", color: ColorToken.blue) { vm.migrate(at: i) }
                            } else if task.status == .migrating {
                                ProgressView().scaleEffect(0.6).frame(width: 30)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 10).fill(ColorToken.card))
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    private func sColor(_ s: MigrationTask.Status) -> Color {
        switch s {
        case .pending: return ColorToken.secondary
        case .migrating: return ColorToken.blue
        case .completed: return ColorToken.green
        case .failed: return ColorToken.red
        case .skipped: return ColorToken.secondary
        }
    }

    private func sIcon(_ s: MigrationTask.Status) -> String {
        switch s {
        case .pending: return "circle"
        case .migrating: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark"
        case .failed: return "exclamationmark"
        case .skipped: return "forward"
        }
    }
}
