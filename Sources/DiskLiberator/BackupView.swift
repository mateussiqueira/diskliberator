import SwiftUI

struct BackupView: View {
    @EnvironmentObject var vm: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Backups & Restore").font(.system(size: 18, weight: .bold)).foregroundStyle(ColorToken.primary)
                Spacer()
                Text("\(vm.backupList.count) snapshots (\(ByteCountFormatter.short(vm.totalBackupSize)))").font(.system(size: 12)).foregroundStyle(ColorToken.secondary)
                ActionButton(title: "Refresh", icon: "arrow.clockwise", color: ColorToken.blue) { vm.refreshBackups() }
            }
            .padding(20)
            Divider().opacity(0.3)

            if vm.backupList.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 48)).foregroundStyle(ColorToken.secondary)
                    Text("No backups yet").font(.system(size: 15)).foregroundStyle(ColorToken.secondary)
                    Text("Backups are created automatically before cleanup operations")
                        .font(.system(size: 12)).foregroundStyle(ColorToken.secondary.opacity(0.7)).multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(vm.backupList, id: \.backupPath) { backup in
                            HStack(spacing: 10) {
                                Image(systemName: "archivebox").foregroundStyle(ColorToken.teal).frame(width: 18)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(backup.path).font(.system(size: 12)).foregroundStyle(ColorToken.primary)
                                    Text(backup.formattedSize).font(.system(size: 10, design: .monospaced)).foregroundStyle(ColorToken.secondary)
                                }
                                Spacer()
                                Text(backup.timestamp, style: .date).font(.system(size: 10)).foregroundStyle(ColorToken.secondary)
                                Text(backup.timestamp, style: .time).font(.system(size: 10)).foregroundStyle(ColorToken.secondary)
                                MiniButton(icon: "arrow.uturn.backward", color: ColorToken.orange) { vm.restoreBackup(backup) }
                                MiniButton(icon: "trash", color: ColorToken.red) { vm.deleteBackup(backup) }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(ColorToken.card))
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}
