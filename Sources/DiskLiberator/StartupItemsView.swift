import SwiftUI

struct StartupItemsView: View {
    @EnvironmentObject var vm: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Startup Items").font(.system(size: 18, weight: .bold)).foregroundStyle(ColorToken.primary)
                Spacer()
                Text("\(vm.startupItems.count) items").font(.system(size: 12)).foregroundStyle(ColorToken.secondary)
                ActionButton(title: "Scan", icon: "arrow.clockwise", color: ColorToken.blue, disabled: vm.isStartupScanning) { vm.scanStartupItems() }
            }
            .padding(20)
            Divider().opacity(0.3)

            if vm.isStartupScanning {
                VStack(spacing: 12) { Spacer(); ProgressView().scaleEffect(1.5); Text("Scanning startup items...").foregroundStyle(ColorToken.secondary); Spacer() }
            } else if vm.startupItems.isEmpty {
                VStack(spacing: 12) { Spacer(); Image(systemName: "power").font(.system(size: 48)).foregroundStyle(ColorToken.secondary); Text("No startup items").foregroundStyle(ColorToken.secondary); Spacer() }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(vm.startupItems) { item in
                            HStack(spacing: 10) {
                                Image(systemName: item.type == .loginItem ? "person.badge.plus" : "gearshape.2").foregroundStyle(ColorToken.blue).frame(width: 18)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.name).font(.system(size: 12)).foregroundStyle(ColorToken.primary)
                                    Text(item.type.rawValue).font(.system(size: 10)).foregroundStyle(ColorToken.secondary)
                                }
                                Spacer()
                                Text(item.path).font(.system(size: 10)).foregroundStyle(ColorToken.secondary).lineLimit(1)
                                MiniButton(icon: "xmark.circle", color: ColorToken.red) { vm.disableStartupItem(item) }
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
