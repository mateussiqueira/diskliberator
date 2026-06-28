import SwiftUI

struct CleanupView: View {
    @EnvironmentObject var vm: MainViewModel
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            HStack {
                Text("Clean Up").font(.system(size: 18, weight: .bold)).foregroundStyle(ColorToken.primary)
                Spacer()
                ActionButton(title: "Smart Scan", icon: "wand.and.stars", color: ColorToken.purple, disabled: vm.isSmartScanning) { vm.smartScan() }
            }
            .padding(20)

            Picker("", selection: $tab) {
                Text("Caches").tag(0)
                Text("System Junk").tag(1)
                Text("Duplicates").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20).padding(.bottom, 8)

            Divider().opacity(0.3)

            switch tab {
            case 0: cacheTab
            case 1: junkTab
            case 2: dupTab
            default: cacheTab
            }
        }
    }

    // MARK: - Cache Tab
    private var cacheTab: some View {
        VStack(spacing: 0) {
            HStack {
                let total = vm.caches.filter(\.selected).reduce(0) { $0 + $1.size }
                if total > 0 {
                    Text("\(ByteCountFormatter.short(total)) reclaimable").font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(ColorToken.orange)
                        .padding(.horizontal, 10).padding(.vertical, 4).background(ColorToken.orange.opacity(0.12)).clipShape(Capsule())
                }
                Spacer()
                ActionButton(title: "Scan", icon: "arrow.clockwise", color: ColorToken.blue, disabled: vm.isCacheScanning) { vm.scanCaches() }
                ActionButton(title: "Clean", icon: "trash", color: ColorToken.orange, disabled: vm.isCleaning || vm.caches.isEmpty || !vm.caches.contains(where: \.selected)) { vm.cleanCaches() }
            }
            .padding(12)

            if vm.isCacheScanning {
                VStack(spacing: 12) { Spacer(); ProgressView().scaleEffect(1.5); Text("Scanning caches...").foregroundStyle(ColorToken.secondary); Spacer() }
            } else if vm.isCleaning {
                VStack(spacing: 12) { Spacer(); ProgressView().scaleEffect(1.5); Text("Cleaning...").foregroundStyle(ColorToken.secondary); Spacer() }
            } else if vm.caches.isEmpty {
                VStack(spacing: 12) { Spacer(); Image(systemName: "trash.slash").font(.system(size: 40)).foregroundStyle(ColorToken.secondary); Text("No cache data").foregroundStyle(ColorToken.secondary); Spacer() }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(vm.caches.enumerated()), id: \.element.id) { i, cat in
                            HStack(spacing: 10) {
                                Image(systemName: cat.icon).font(.system(size: 13)).foregroundStyle(ColorToken.orange).frame(width: 18)
                                Toggle(cat.name, isOn: Binding(get: { vm.caches[i].selected }, set: { vm.caches[i].selected = $0 }))
                                    .toggleStyle(.checkbox).font(.system(size: 12)).foregroundStyle(ColorToken.primary)
                                Spacer()
                                Text(cat.formattedSize).font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(cat.size > 500_000_000 ? ColorToken.red : cat.size > 50_000_000 ? ColorToken.orange : ColorToken.secondary)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(ColorToken.card))
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            resultsBar
        }
    }

    // MARK: - Junk Tab
    private var junkTab: some View {
        VStack(spacing: 0) {
            HStack {
                let total = vm.smartWaste
                if total > 0 {
                    Text("\(ByteCountFormatter.short(total)) reclaimable").font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(ColorToken.orange)
                        .padding(.horizontal, 10).padding(.vertical, 4).background(ColorToken.orange.opacity(0.12)).clipShape(Capsule())
                }
                Spacer()
                ActionButton(title: "Scan", icon: "arrow.clockwise", color: ColorToken.blue, disabled: vm.isJunkScanning) { vm.scanJunk() }
                ActionButton(title: "Clean", icon: "trash", color: ColorToken.orange, disabled: vm.isCleaning || vm.junkCategories.isEmpty) { vm.cleanJunk() }
            }
            .padding(12)

            if vm.isJunkScanning {
                VStack(spacing: 12) { Spacer(); ProgressView().scaleEffect(1.5); Text("Scanning system junk...").foregroundStyle(ColorToken.secondary); Spacer() }
            } else if vm.isCleaning {
                VStack(spacing: 12) { Spacer(); ProgressView().scaleEffect(1.5); Text("Cleaning...").foregroundStyle(ColorToken.secondary); Spacer() }
            } else if vm.junkCategories.isEmpty {
                VStack(spacing: 12) { Spacer(); Image(systemName: "doc.badge.gearshape").font(.system(size: 40)).foregroundStyle(ColorToken.secondary); Text("No junk data").foregroundStyle(ColorToken.secondary); Spacer() }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(vm.junkCategories.enumerated()), id: \.element.id) { i, cat in
                            HStack(spacing: 10) {
                                Image(systemName: cat.icon).font(.system(size: 13)).foregroundStyle(ColorToken.teal).frame(width: 18)
                                Toggle(cat.name, isOn: Binding(get: { vm.junkCategories[i].selected }, set: { vm.junkCategories[i].selected = $0 }))
                                    .toggleStyle(.checkbox).font(.system(size: 12)).foregroundStyle(ColorToken.primary)
                                Spacer()
                                Text(cat.formattedSize).font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(cat.size > 500_000_000 ? ColorToken.red : cat.size > 50_000_000 ? ColorToken.orange : ColorToken.secondary)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(ColorToken.card))
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            resultsBar
        }
    }

    // MARK: - Duplicates Tab
    private var dupTab: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Path", text: $vm.dupPaths).textFieldStyle(.roundedBorder).frame(width: 250)
                ActionButton(title: "Scan Duplicates", icon: "doc.on.doc", color: ColorToken.purple, disabled: vm.isDupScanning) { vm.scanDuplicates() }
            }
            .padding(12)

            if vm.isDupScanning {
                VStack(spacing: 12) { Spacer(); ProgressView().scaleEffect(1.5); Text("Scanning for duplicates (fast phase)...").foregroundStyle(ColorToken.secondary); Spacer() }
            } else if vm.duplicateGroups.isEmpty {
                VStack(spacing: 12) { Spacer(); Image(systemName: "doc.on.doc").font(.system(size: 40)).foregroundStyle(ColorToken.secondary); Text("No duplicates found").foregroundStyle(ColorToken.secondary); Spacer() }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(vm.duplicateGroups) { group in
                            HStack(spacing: 10) {
                                Image(systemName: "doc.on.doc.fill").font(.system(size: 13)).foregroundStyle(ColorToken.purple).frame(width: 18)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(group.count) files, \(group.formattedSize) each").font(.system(size: 12)).foregroundStyle(ColorToken.primary)
                                    Text(group.files.first?.lastPathComponent ?? "").font(.system(size: 10)).foregroundStyle(ColorToken.secondary).lineLimit(1)
                                }
                                Spacer()
                                Text("\(ByteCountFormatter.short(group.size * Int64(group.count - 1))) reclaimable")
                                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(ColorToken.green)
                                MiniButton(icon: "trash", color: ColorToken.red) { vm.deleteDuplicates(in: group) }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(ColorToken.card))
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            resultsBar
        }
    }

    // MARK: - Results Bar
    private var resultsBar: some View {
        Group {
            if !vm.cacheResults.isEmpty || !vm.junkResults.isEmpty {
                Divider().opacity(0.3)
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(vm.cacheResults + vm.junkResults) { r in
                            HStack(spacing: 3) {
                                Image(systemName: r.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 9)).foregroundStyle(r.success ? ColorToken.green : ColorToken.red)
                                Text("\(r.name): \(r.freedFormatted)").font(.system(size: 10, design: .monospaced)).foregroundStyle(ColorToken.secondary)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 4).fill(ColorToken.card))
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 6)
                }
                .frame(height: 36)
            }
        }
    }
}
