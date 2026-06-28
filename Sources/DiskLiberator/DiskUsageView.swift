import SwiftUI

// Simple squarified treemap layout algorithm
struct TreemapLayout {
    let items: [DiskItem]
    let totalSize: Int64
    var rects: [CGRect] = []

    init(items: [DiskItem], in rect: CGRect) {
        self.items = items
        self.totalSize = items.reduce(0) { $0 + $1.size }
        self.rects = Self.layout(items: items.filter { $0.size > 0 }, total: Double(totalSize > 0 ? totalSize : 1), in: rect)
    }

    private static func layout(items: [DiskItem], total: Double, in rect: CGRect) -> [CGRect] {
        guard !items.isEmpty else { return [] }
        let sorted = items.sorted { $0.size > $1.size }
        var results: [CGRect] = []
        var remaining = rect
        var i = 0

        while i < sorted.count {
            let isWide = remaining.width >= remaining.height
            let totalRemaining = sorted[i..<sorted.count].reduce(0.0) { $0 + Double($1.size) }
            let rowSize = min(isWide ? remaining.width : remaining.height,
                             sqrt(totalRemaining / total) * (isWide ? remaining.height : remaining.width))

            var rowItems: [DiskItem] = []
            var rowTotal: Double = 0
            var j = i
            while j < sorted.count && rowTotal + Double(sorted[j].size) <= totalRemaining * (rowSize / (isWide ? remaining.height : remaining.width)) * 2 {
                rowItems.append(sorted[j])
                rowTotal += Double(sorted[j].size)
                j += 1
            }
            if rowItems.isEmpty { rowItems.append(sorted[i]); rowTotal = Double(sorted[i].size); j = i + 1 }

            var x = remaining.minX
            var y = remaining.minY
            for item in rowItems {
                let itemRatio = Double(item.size) / totalRemaining
                if isWide {
                    let h = remaining.height * itemRatio
                    results.append(CGRect(x: x, y: y, width: rowSize, height: h))
                    y += h
                } else {
                    let w = remaining.width * itemRatio
                    results.append(CGRect(x: x, y: y, width: w, height: rowSize))
                    x += w
                }
            }
            if isWide {
                remaining = CGRect(x: remaining.minX + rowSize, y: remaining.minY,
                                   width: remaining.width - rowSize, height: remaining.height)
            } else {
                remaining = CGRect(x: remaining.minX, y: remaining.minY + rowSize,
                                   width: remaining.width, height: remaining.height - rowSize)
            }
            i = j
        }
        return results
    }
}

struct DiskUsageView: View {
    @EnvironmentObject var vm: MainViewModel
    @State private var scanPath = "~"
    @State private var scanItems: [DiskItem] = []
    @State private var isScanning = false
    @State private var selectedItem: DiskItem?
    @State private var hoveredItem: DiskItem?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Disk Map").font(.system(size: 18, weight: .bold)).foregroundStyle(ColorToken.primary)
                Spacer()
                TextField("~/path", text: $scanPath).textFieldStyle(.roundedBorder).frame(width: 200)
                ActionButton(title: "Scan", icon: "magnifyingglass", color: ColorToken.blue, disabled: isScanning) { startScan() }
            }
            .padding(20)
            Divider().opacity(0.3)

            if isScanning {
                VStack(spacing: 12) { Spacer(); ProgressView().scaleEffect(1.5); Text("Scanning...").foregroundStyle(ColorToken.secondary); Spacer() }
            } else if scanItems.isEmpty {
                VStack(spacing: 12) { Spacer(); Image(systemName: "rectangle.3.group").font(.system(size: 48)).foregroundStyle(ColorToken.secondary)
                    Text("Enter a path and click Scan").foregroundStyle(ColorToken.secondary); Spacer() }
            } else {
                HStack(spacing: 0) {
                    // Treemap
                    treemapView
                        .frame(minWidth: 400)

                    Divider().opacity(0.3)

                    // Side panel
                    sidePanel
                        .frame(width: 250)
                }
            }
        }
    }

    private var treemapView: some View {
        let total = scanItems.reduce(0) { $0 + $1.size }
        return GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let layout = TreemapLayout(items: scanItems.prefix(50).map { $0 }, in: rect)
            ZStack(alignment: .topLeading) {
                ForEach(Array(scanItems.prefix(min(scanItems.count, layout.rects.count)).enumerated()), id: \.element.id) { i, item in
                    if i < layout.rects.count {
                        let r = layout.rects[i]
                        let isHover = hoveredItem?.id == item.id
                        let isSelected = selectedItem?.id == item.id
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorFor(item.size, total: total))
                            .frame(width: max(r.width - 1, 2), height: max(r.height - 1, 2))
                            .position(x: r.midX, y: r.midY)
                            .overlay(
                                r.width > 60 && r.height > 30 ?
                                Text(item.name).font(.system(size: 8)).foregroundStyle(.white).lineLimit(1).padding(2) : nil,
                                alignment: .center
                            )
                            .brightness(isHover ? 0.15 : isSelected ? 0.1 : 0)
                            .onHover { h in hoveredItem = h ? item : nil }
                            .onTapGesture { selectedItem = item }
                            .help("\(item.name): \(item.formattedSize)")
                    }
                }
            }
        }
        .background(Color.black.opacity(0.3))
    }

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details").font(.system(size: 14, weight: .semibold)).foregroundStyle(ColorToken.primary)
            if let item = selectedItem {
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Image(systemName: item.icon).foregroundStyle(ColorToken.blue); Text(item.name).font(.headline).foregroundStyle(ColorToken.primary) }
                    StatRowView(label: "Size", value: item.formattedSize, color: ColorToken.blue)
                    StatRowView(label: "Type", value: item.isDir ? "Directory" : "File")
                    StatRowView(label: "Path", value: item.url.path)
                }
            } else if let item = hoveredItem {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name).font(.headline).foregroundStyle(ColorToken.primary)
                    StatRowView(label: "Size", value: item.formattedSize, color: ColorToken.blue)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "hand.point.up").font(.title).foregroundStyle(ColorToken.secondary)
                    Text("Hover or tap a block to see details").font(.system(size: 12)).foregroundStyle(ColorToken.secondary)
                }
            }

            Spacer()

            // Legend
            VStack(alignment: .leading, spacing: 4) {
                Text("Legend").font(.caption).foregroundStyle(ColorToken.secondary)
                HStack { RoundedRectangle(cornerRadius: 2).fill(ColorToken.red).frame(width: 12, height: 12); Text("> 1GB").font(.caption2).foregroundStyle(ColorToken.secondary) }
                HStack { RoundedRectangle(cornerRadius: 2).fill(ColorToken.orange).frame(width: 12, height: 12); Text("100MB-1GB").font(.caption2).foregroundStyle(ColorToken.secondary) }
                HStack { RoundedRectangle(cornerRadius: 2).fill(ColorToken.blue).frame(width: 12, height: 12); Text("10-100MB").font(.caption2).foregroundStyle(ColorToken.secondary) }
                HStack { RoundedRectangle(cornerRadius: 2).fill(ColorToken.teal).frame(width: 12, height: 12); Text("< 10MB").font(.caption2).foregroundStyle(ColorToken.secondary) }
            }
            .padding(12).background(RoundedRectangle(cornerRadius: 8).fill(ColorToken.card))
        }
        .padding(16)
        .background(ColorToken.bg)
    }

    private func startScan() {
        isScanning = true; scanItems = []; selectedItem = nil
        let url = URL(fileURLWithPath: NSString(string: scanPath).expandingTildeInPath)
        Task.detached(priority: .userInitiated) {
            let items = DiskService.shared.scan(url)
            await MainActor.run { scanItems = items; isScanning = false }
        }
    }

    private func colorFor(_ size: Int64, total: Int64) -> Color {
        if size > 1_000_000_000 { return ColorToken.red }
        if size > 100_000_000 { return ColorToken.orange }
        if size > 10_000_000 { return ColorToken.blue }
        return ColorToken.teal
    }
}
