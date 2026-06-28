import SwiftUI

struct BrowserView: View {
    @EnvironmentObject var vm: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Browser Privacy").font(.system(size: 18, weight: .bold)).foregroundStyle(ColorToken.primary)
                Spacer()
                ActionButton(title: "Scan Browsers", icon: "arrow.clockwise", color: ColorToken.blue, disabled: vm.isBrowserScanning) { vm.scanBrowsers() }
            }
            .padding(20)
            Divider().opacity(0.3)

            if vm.isBrowserScanning {
                VStack(spacing: 12) { Spacer(); ProgressView().scaleEffect(1.5); Text("Scanning browsers...").foregroundStyle(ColorToken.secondary); Spacer() }
            } else if vm.browserData.isEmpty {
                VStack(spacing: 12) { Spacer(); Image(systemName: "globe").font(.system(size: 48)).foregroundStyle(ColorToken.secondary); Text("No browser data").foregroundStyle(ColorToken.secondary); Spacer() }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(vm.browserData) { browser in
                            FeatureCard(icon: browser.icon, title: browser.name, color: ColorToken.blue) {
                                VStack(spacing: 10) {
                                    HStack {
                                        StatRowView(label: "History", value: ByteCountFormatter.short(browser.historySize))
                                        StatRowView(label: "Cache", value: ByteCountFormatter.short(browser.cacheSize), color: ColorToken.orange)
                                        StatRowView(label: "Cookies", value: ByteCountFormatter.short(browser.cookieSize), color: ColorToken.secondary)
                                    }
                                    HStack {
                                        Text("Total: \(browser.formattedTotal)").font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(ColorToken.orange)
                                        Spacer()
                                        ActionButton(title: "Clean", icon: "trash", color: ColorToken.orange) { vm.cleanBrowser(browser) }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}
