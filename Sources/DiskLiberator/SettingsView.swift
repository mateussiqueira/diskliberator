import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: MainViewModel
    @AppStorage("extVolume") private var extVolume = "/Volumes/BACKUP"
    @State private var volOk = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings").font(.system(size: 18, weight: .bold)).foregroundStyle(ColorToken.primary).padding(.top, 8)

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("External Volume").font(.system(size: 13, weight: .semibold)).foregroundStyle(ColorToken.primary)
                    HStack(spacing: 8) {
                        TextField("/Volumes/BACKUP", text: $extVolume).textFieldStyle(.roundedBorder).frame(width: 300)
                        Circle().fill(volOk ? ColorToken.green : ColorToken.red).frame(width: 8)
                        Text(volOk ? "Connected" : "Not found").font(.system(size: 11)).foregroundStyle(ColorToken.secondary)
                    }
                }.padding()
            }.backgroundStyle(ColorToken.card)

            GroupBox {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Directories to Migrate").font(.system(size: 13, weight: .semibold)).foregroundStyle(ColorToken.primary)
                    ForEach(MigrationTask.defaultMigrations) { t in
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill").foregroundStyle(ColorToken.blue).font(.system(size: 12))
                            Text(t.label).font(.system(size: 12)).foregroundStyle(ColorToken.primary)
                            Spacer()
                            Text(t.sourcePath).font(.system(size: 11)).foregroundStyle(ColorToken.secondary).lineLimit(1)
                        }.padding(.vertical, 2)
                    }
                }.padding()
            }.backgroundStyle(ColorToken.card)

            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Text("About").font(.system(size: 13, weight: .semibold)).foregroundStyle(ColorToken.primary)
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Engine", value: "rsync + Swift")
                    LabeledContent("macOS", value: "14.0+")
                    LabeledContent("Min RAM", value: "512 MB / 2 GB")
                }.padding()
            }.backgroundStyle(ColorToken.card)

            Spacer()
        }
        .padding(32).frame(maxWidth: 520, alignment: .leading)
        .task { volOk = FileManager.default.fileExists(atPath: extVolume) }
        .onChange(of: extVolume) { _, n in volOk = FileManager.default.fileExists(atPath: n) }
    }
}
