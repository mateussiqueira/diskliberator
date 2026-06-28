import SwiftUI

@MainActor
final class MainViewModel: ObservableObject {
    // Volumes
    @Published var internalVol: VolumeInfo?
    @Published var externalVols: [VolumeInfo] = []

    // Scan
    @Published var scanItems: [DiskItem] = []; @Published var isScanning = false; @Published var scanError: String?

    // Migration
    @Published var migrations: [MigrationTask] = MigrationTask.defaultMigrations
    @Published var migratingIndex: Int?; @Published var migrationProgress: Double = 0; @Published var migrationStatus = ""

    // Cache
    @Published var caches: [CacheCategory] = []; @Published var isCleaning = false; @Published var isCacheScanning = false
    @Published var cacheResults: [CacheCleanupService.Result] = []

    // Junk
    @Published var junkCategories: [SystemJunkCategory] = []; @Published var isJunkScanning = false; @Published var junkResults: [CacheCleanupService.Result] = []

    // Duplicates
    @Published var duplicateGroups: [DuplicateGroup] = []; @Published var isDupScanning = false; @Published var dupPaths = "~"

    // Smart Scan
    @Published var smartWaste: Int64 = 0; @Published var isSmartScanning = false

    // Memory
    @Published var memInfo: MemoryOptimizerService.MemoryInfo?
    @Published var memPressure: Int = 0; @Published var memLabel = "Normal"
    @Published var heavyProcesses: [MemoryOptimizerService.HeavyProcess] = []
    @Published var isPurging = false; @Published var lastPurgeResult: String?

    // Apps
    @Published var installedApps: [AppUninstallService.InstalledApp] = []
    @Published var isAppScanning = false
    @Published var appUninstallResults: [(name: String, success: Bool, error: String?)] = []

    // Backups
    @Published var backupList: [BackupService.BackupResult] = []
    @Published var totalBackupSize: Int64 = 0

    // Permissions
    @Published var permissions: [PermissionService.PermissionStatus] = []

    // Browser
    @Published var browserData: [BrowserPrivacyService.BrowserData] = []
    @Published var isBrowserScanning = false
    @Published var browserResults: [CacheCleanupService.Result] = []

    // Startup
    @Published var startupItems: [StartupItemsService.StartupItem] = []
    @Published var isStartupScanning = false

    // Log
    @Published var log: [String] = []

    func load() {
        let vols = VolumeInfo.all()
        internalVol = vols.first { $0.isInternal }
        externalVols = vols.filter { !$0.isInternal }
        refreshMemory()
        permissions = PermissionService.shared.checkAll()
        refreshBackups()
    }

    // MARK: - Scan
    func scan(_ url: URL) {
        isScanning = true; scanError = nil; scanItems = []
        let url2 = url
        Task.detached(priority: .userInitiated) {
            let items = DiskService.shared.scanRecursive(url2)
            await MainActor.run { [weak self] in
                self?.scanItems = items; self?.isScanning = false
            }
        }
    }
    func scanQuick(_ url: URL) {
        isScanning = true; scanError = nil; scanItems = []
        let url2 = url
        Task.detached(priority: .userInitiated) {
            let items = DiskService.shared.scan(url2)
            await MainActor.run { [weak self] in
                self?.scanItems = items; self?.isScanning = false
            }
        }
    }

    // MARK: - Migration
    func migrate(at i: Int) {
        guard migrations.indices.contains(i) else { return }
        let task = migrations[i]
        if (try? task.source.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true { migrations[i].status = .skipped; return }
        migrations[i].status = .migrating; migratingIndex = i; migrationProgress = 0
        let dest = URL(fileURLWithPath: "/Volumes/BACKUP").appendingPathComponent(task.label)
        Task {
            do {
                try await MigrationService.shared.migrate(source: task.source, dest: dest) { [weak self] p in
                    Task { @MainActor in self?.migrationProgress = p }
                }
                migrations[i].status = .completed; log.append("✓ \(task.label) migrated")
            } catch {
                migrations[i].status = .failed; migrations[i].error = error.localizedDescription; log.append("✗ \(task.label): \(error.localizedDescription)")
            }
            migratingIndex = nil
        }
    }
    func migrateAll() { for i in migrations.indices where migrations[i].status == .pending { migrate(at: i) } }

    // MARK: - Cache
    func scanCaches() {
        isCacheScanning = true
        Task.detached(priority: .userInitiated) {
            let cats = CacheCleanupService.shared.scanAll()
            await MainActor.run { [weak self] in
                self?.caches = cats; self?.isCacheScanning = false
            }
        }
    }
    func cleanCaches() {
        isCleaning = true; cacheResults = []
        let selected = caches.filter(\.selected)
        Task.detached(priority: .utility) { [weak self] in
            var rs: [CacheCleanupService.Result] = []
            for cat in selected {
                let r = CacheCleanupService.shared.clean(cat)
                rs.append(r)
                await MainActor.run { self?.log.append("Cache: \(r.success ? "✓" : "✗") \(cat.name): \(r.freedFormatted)") }
            }
            let cats = CacheCleanupService.shared.scanAll()
            await MainActor.run {
                self?.cacheResults = rs; self?.caches = cats; self?.isCleaning = false
            }
        }
    }

    // MARK: - Junk
    func scanJunk() {
        isJunkScanning = true
        Task.detached(priority: .userInitiated) { [weak self] in
            let cats = SystemJunkService.shared.scan()
            let total = cats.reduce(0) { $0 + $1.scan() }
            await MainActor.run { self?.junkCategories = cats; self?.smartWaste = total; self?.isJunkScanning = false }
        }
    }
    func cleanJunk() {
        isCleaning = true; junkResults = []
        let selected = junkCategories.filter(\.selected)
        Task.detached(priority: .utility) { [weak self] in
            var rs: [CacheCleanupService.Result] = []
            for cat in selected {
                let (freed, err) = cat.clean(); BackupService.shared.backup(path: cat.name)
                rs.append(.init(name: cat.name, freed: freed, error: err, success: err == nil))
                await MainActor.run { self?.log.append("Junk: \(err == nil ? "✓" : "✗") \(cat.name): \(ByteCountFormatter.short(freed))") }
            }
            await MainActor.run { self?.junkResults = rs; self?.isCleaning = false }
        }
    }

    // MARK: - Duplicates
    func scanDuplicates() {
        isDupScanning = true; duplicateGroups = []
        let url = URL(fileURLWithPath: NSString(string: dupPaths).expandingTildeInPath)
        Task.detached(priority: .userInitiated) { [weak self] in
            let groups = DuplicateFileService.shared.scan(urls: [url])
            await MainActor.run { self?.duplicateGroups = groups; self?.isDupScanning = false }
        }
    }
    func deleteDuplicates(in group: DuplicateGroup) {
        let toDelete = Array(group.files.dropFirst())
        Task.detached(priority: .utility) { [weak self] in
            for url in toDelete { _ = try? FileManager.default.removeItem(at: url) }
            await MainActor.run { self?.log.append("Duplicates: Deleted \(toDelete.count) files") }
        }
    }

    // MARK: - Smart Scan
    func smartScan() {
        isSmartScanning = true; log.append("Smart Scan started...")
        Task.detached(priority: .userInitiated) { [weak self] in
            let caches = CacheCleanupService.shared.scanAll()
            let junk = SystemJunkService.shared.scan()
            var rs: [CacheCleanupService.Result] = []
            for cat in caches where cat.selected { let r = CacheCleanupService.shared.clean(cat); rs.append(r); BackupService.shared.backup(path: cat.name) }
            for cat in junk where cat.selected { let (f, e) = cat.clean(); rs.append(.init(name: cat.name, freed: f, error: e, success: e == nil)); BackupService.shared.backup(path: cat.name) }
            let total = rs.reduce(0) { $0 + $1.freed }
            await MainActor.run {
                self?.caches = caches; self?.junkCategories = junk; self?.cacheResults = rs
                self?.isSmartScanning = false; self?.log.append("Smart Scan: Freed \(ByteCountFormatter.short(total))")
                self?.refreshBackups()
            }
        }
    }

    // MARK: - Memory
    func refreshMemory() {
        Task.detached(priority: .userInitiated) { [weak self] in
            let info = MemoryOptimizerService.shared.getMemoryInfo()
            let procs = MemoryOptimizerService.shared.getHeavyProcesses()
            await MainActor.run {
                self?.memInfo = info; self?.memPressure = info.pressure; self?.memLabel = info.pressureLabel
                self?.heavyProcesses = procs
            }
        }
    }
    func purgeRAM() {
        isPurging = true; lastPurgeResult = nil
        Task.detached(priority: .userInitiated) { [weak self] in
            let result = MemoryOptimizerService.shared.purgeRAM()
            await MainActor.run { self?.lastPurgeResult = result; self?.isPurging = false; self?.refreshMemory(); self?.log.append("RAM: \(result)") }
        }
    }
    func killProcess(pid: Int32) {
        _ = MemoryOptimizerService.shared.killProcess(pid: pid)
        refreshMemory(); log.append("Killed process \(pid)")
    }

    // MARK: - Apps
    func scanApps() {
        isAppScanning = true; installedApps = []
        Task.detached(priority: .userInitiated) { [weak self] in
            let apps = AppUninstallService.shared.scanApps()
            await MainActor.run { self?.installedApps = apps; self?.isAppScanning = false }
        }
    }
    func uninstallSelectedApps() {
        let selected = installedApps.filter(\.selected); appUninstallResults = []
        Task.detached(priority: .utility) { [weak self] in
            var results: [(String, Bool, String?)] = []
            for app in selected {
                let (success, err) = AppUninstallService.shared.uninstall(app: app)
                results.append((app.name, success, err))
                await MainActor.run { self?.log.append("App: \(success ? "✓" : "✗") \(app.name)") }
            }
            await MainActor.run { self?.appUninstallResults = results; self?.scanApps() }
        }
    }

    // MARK: - Browser
    func scanBrowsers() {
        isBrowserScanning = true; browserData = []
        Task.detached(priority: .userInitiated) { [weak self] in
            let data = BrowserPrivacyService.shared.scanAll()
            await MainActor.run { self?.browserData = data; self?.isBrowserScanning = false }
        }
    }
    func cleanBrowser(_ browser: BrowserPrivacyService.BrowserData) {
        let name = browser.name
        Task.detached(priority: .utility) { [weak self] in
            let freed = BrowserPrivacyService.shared.clean(browser)
            await MainActor.run { self?.log.append("Browser: Cleaned \(name) (\(ByteCountFormatter.short(freed)))"); self?.scanBrowsers() }
        }
    }

    // MARK: - Startup
    func scanStartupItems() {
        isStartupScanning = true; startupItems = []
        Task.detached(priority: .userInitiated) { [weak self] in
            let items = StartupItemsService.shared.scan()
            await MainActor.run { self?.startupItems = items; self?.isStartupScanning = false }
        }
    }
    func disableStartupItem(_ item: StartupItemsService.StartupItem) {
        StartupItemsService.shared.disable(item)
        log.append("Disabled startup: \(item.name)")
        scanStartupItems()
    }

    // MARK: - Backups
    func refreshBackups() {
        let list = BackupService.shared.listBackups()
        backupList = list; totalBackupSize = BackupService.shared.totalBackupSize
    }
    func restoreBackup(_ backup: BackupService.BackupResult) {
        Task.detached(priority: .utility) { [weak self] in
            let ok = BackupService.shared.restore(backupPath: backup.backupPath)
            await MainActor.run { self?.log.append("Restore: \(ok ? "✓" : "✗") \(backup.path)") }
        }
    }
    func deleteBackup(_ backup: BackupService.BackupResult) {
        try? FileManager.default.removeItem(atPath: backup.backupPath)
        refreshBackups(); log.append("Deleted backup: \(backup.path)")
    }

    // MARK: - Permissions
    func openPrivacySettings() { PermissionService.shared.openPrivacySettings() }
}
