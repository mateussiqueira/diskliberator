import SwiftUI

struct ScanView: View {
    @EnvironmentObject var vm: MainViewModel
    @State private var path = "~"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Disk Scanner").font(.system(size: 18, weight: .bold)).foregroundStyle(ColorToken.primary)
                Spacer()
                HStack(spacing: 6) {
                    TextField("~/path", text: $path).textFieldStyle(.roundedBorder).frame(width: 200)
                    ActionButton(title: "Quick", icon: "list.bullet", color: ColorToken.blue) {
                        vm.scanQuick(URL(fileURLWithPath: NSString(string: path).expandingTildeInPath))
                    }
                    ActionButton(title: "Deep Scan", icon: "arrowtriangle.down.circle", color: ColorToken.purple) {
                        vm.scan(URL(fileURLWithPath: NSString(string: path).expandingTildeInPath))
                    }
                }
            }
            .padding(20)
            Divider().opacity(0.3)

            if vm.isScanning {
                VStack(spacing: 20) { Spacer(); ProgressView().scaleEffect(1.5)
                    Text("Scanning...").foregroundStyle(ColorToken.secondary)
                    ProgressView().progressViewStyle(.linear).frame(width: 240); Spacer() }
            } else if vm.scanItems.isEmpty {
                VStack(spacing: 12) { Spacer()
                    Image(systemName: "magnifyingglass.circle").font(.system(size: 48)).foregroundStyle(ColorToken.secondary)
                    Text("No scan results").foregroundStyle(ColorToken.secondary)
                    Text("Enter a path and click Quick or Deep Scan").font(.system(size: 12)).foregroundStyle(ColorToken.secondary.opacity(0.7))
                    Spacer() }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        let total = vm.scanItems.reduce(0) { $0 + $1.size }
                        HStack {
                            Text("Found \(vm.scanItems.count) items").font(.system(size: 12)).foregroundStyle(ColorToken.secondary)
                            Spacer()
                            Text("Total: \(ByteCountFormatter.short(total))")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(ColorToken.primary)
                        }
                        .padding(.horizontal, 20).padding(.vertical, 10)

                        LazyVStack(spacing: 1) {
                            ForEach(vm.scanItems) { item in
                                HStack(spacing: 12) {
                                    Image(systemName: item.icon).font(.system(size: 14))
                                        .foregroundStyle(item.size > 1_000_000_000 ? ColorToken.red : item.size > 100_000_000 ? ColorToken.orange : ColorToken.secondary)
                                        .frame(width: 18)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.name).font(.system(size: 13)).foregroundStyle(ColorToken.primary)
                                        Text(item.detail).font(.system(size: 10)).foregroundStyle(ColorToken.secondary).lineLimit(1)
                                    }
                                    Spacer()
                                    Text(item.formattedSize)
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundStyle(item.size > 1_000_000_000 ? ColorToken.red : item.size > 100_000_000 ? ColorToken.orange : ColorToken.secondary)
                                }
                                .padding(.horizontal, 20).padding(.vertical, 8)
                                .background(ColorToken.card.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(.horizontal, 20).padding(.vertical, 1)
                            }
                        }
                    }
                }
            }
        }
    }
}
