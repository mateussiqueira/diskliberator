#!/usr/bin/env swift

import Foundation

// MARK: - Test Runner
var passed = 0
var failed = 0
var errors: [String] = []

func test(_ name: String, block: () throws -> Void) {
    do {
        try block()
        passed += 1
        print("  ✓ \(name)")
    } catch {
        failed += 1
        errors.append("  ✗ \(name): \(error.localizedDescription)")
        print("  ✗ \(name): \(error.localizedDescription)")
    }
}

// MARK: - Paths
let home = FileManager.default.homeDirectoryForCurrentUser
let desktop = home.appendingPathComponent("Desktop")
let downloads = home.appendingPathComponent("Downloads")
let documents = home.appendingPathComponent("Documents")
let backupVolume = URL(fileURLWithPath: "/Volumes/BACKUP")

print("═══════════════════════════════════════════")
print("  DiskLiberator - Service Tests")
print("═══════════════════════════════════════════")
print()

// MARK: - 1. Volume Info
print("── Volume Info ──")
test("Read internal volume") {
    let vols = VolumeInfo.all()
    let internal_ = vols.first { $0.isInternal }
    guard let vol = internal_ else { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "No internal volume found"]) }
    print("    Name: \(vol.name)")
    print("    Total: \(vol.totalFormatted)")
    print("    Free: \(vol.freeFormatted)")
    print("    Used: \(vol.usedFormatted)")
    print("    Usage: \(Int(vol.usage * 100))%")
}

// MARK: - 2. DiskService
print("\n── DiskService ──")
test("Scan Desktop (quick)") {
    let items = DiskService.shared.scan(desktop)
    print("    Found \(items.count) items on Desktop")
}
test("Scan recursive") {
    let items = DiskService.shared.scanRecursive(desktop, maxItems: 10)
    print("    Found \(items.count) items > 1MB")
}
test("Calculate size") {
    let size = DiskService.shared.calcSize(downloads)
    print("    Downloads: \(ByteCountFormatter.short(size))")
    assert(size >= 0, "Size should be >= 0")
}
test("Cache size") {
    let size = DiskService.shared.cacheSize("~/Library/Caches")
    print("    Caches: \(ByteCountFormatter.short(size))")
}

// MARK: - 3. CacheCleanupService
print("\n── CacheCleanupService ──")
test("Scan all caches") {
    let cats = CacheCleanupService.shared.scanAll()
    print("    Found \(cats.count) cache categories")
    for cat in cats.prefix(5) where cat.size > 0 {
        print("      \(cat.name): \(cat.formattedSize)")
    }
}
test("Clean npm cache (if exists)") {
    let cat = CacheCategory(name: "npm", path: "~/.npm/_cacache", icon: "cube")
    let result = CacheCleanupService.shared.clean(cat)
    print("    Freed: \(result.freedFormatted)")
}

// MARK: - 4. SystemJunkService
print("\n── SystemJunkService ──")
test("Scan system junk") {
    let cats = SystemJunkService.shared.scan()
    print("    Found \(cats.count) junk categories")
    for cat in cats.prefix(5) {
        print("      \(cat.name): \(cat.formattedSize)")
    }
}

// MARK: - 5. DuplicateFileService
print("\n── DuplicateFileService ──")
test("Scan for duplicates on Desktop") {
    // Quick test: scan a small directory
    let groups = DuplicateFileService.shared.scan(urls: [documents], minSize: 50_000_000) // 50MB min
    print("    Found \(groups.count) duplicate groups in Documents")
    for g in groups.prefix(3) {
        print("      \(g.count) files, \(g.formattedSize) each")
    }
}

// MARK: - 6. MemoryOptimizerService
print("\n── MemoryOptimizerService ──")
test("Get memory info") {
    let info = MemoryOptimizerService.shared.getMemoryInfo()
    print("    Physical: \(info.totalFormatted)")
    print("    Used: \(info.usedFormatted) (\(info.pressure)%)")
    print("    Free: \(info.freeFormatted)")
    print("    Pressure: \(info.pressureLabel)")
}
test("Get heavy processes") {
    let procs = MemoryOptimizerService.shared.getHeavyProcesses()
    print("    Found \(procs.count) heavy processes")
    for p in procs.prefix(3) {
        print("      \(p.name): \(p.formattedMem)")
    }
}

// MARK: - 7. BackupService
print("\n── BackupService ──")
test("Create backup of Desktop") {
    if FileManager.default.fileExists(atPath: "/Volumes/BACKUP") {
        let result = BackupService.shared.backup(path: "~/Desktop")
        print("    Backup: \(result.success ? "✓" : "✗")")
        if result.success { print("    Size: \(result.formattedSize)") }
    } else {
        print("    ⚠ External volume not mounted, skipping")
    }
}
test("List backups") {
    let backups = BackupService.shared.listBackups()
    print("    Total backups: \(backups.count)")
    print("    Total size: \(ByteCountFormatter.short(BackupService.shared.totalBackupSize))")
}

// MARK: - 8. PermissionService
print("\n── PermissionService ──")
test("Check permissions") {
    let perms = PermissionService.shared.checkAll()
    for p in perms {
        print("    \(p.granted ? "✓" : "✗") \(p.name)")
    }
}

// MARK: - 9. BrowserPrivacyService
print("\n── BrowserPrivacyService ──")
test("Scan browsers") {
    let browsers = BrowserPrivacyService.shared.scanAll()
    print("    Found \(browsers.count) browsers with data")
    for b in browsers {
        print("      \(b.name): \(b.formattedTotal) (history: \(ByteCountFormatter.short(b.historySize)), cache: \(ByteCountFormatter.short(b.cacheSize)))")
    }
}

// MARK: - 10. AppUninstallService
print("\n── AppUninstallService ──")
test("Scan installed apps") {
    let apps = AppUninstallService.shared.scanApps()
    print("    Found \(apps.count) installed apps")
    for a in apps.prefix(5) {
        print("      \(a.name) v\(a.version): \(a.formattedTotal)")
    }
}

// MARK: - 11. StartupItemsService
print("\n── StartupItemsService ──")
test("Scan startup items") {
    let items = StartupItemsService.shared.scan()
    print("    Found \(items.count) startup items")
    for i in items.prefix(5) {
        print("      \(i.name) (\(i.type.rawValue))")
    }
}

// MARK: - Summary
print()
print("═══════════════════════════════════════════")
print("  RESULTS: \(passed) passed, \(failed) failed")
print("═══════════════════════════════════════════")
if failed > 0 {
    print()
    print("Errors:")
    for e in errors { print(e) }
}
print()
exit(failed > 0 ? 1 : 0)
