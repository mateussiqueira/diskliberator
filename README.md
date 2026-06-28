# DiskLiberator

**The ultimate free Mac cleaner — native Swift, Apple Silicon optimized.**

Inspired by CleanMyMac X and the best open-source Mac cleanup tools. DiskLiberator combines disk cleaning, memory optimization, file migration, app uninstaller, browser privacy, and disk visualization — all in one native SwiftUI app with a modern dark interface.

## Features (11 tools in 1)

| Module | Description |
|--------|-------------|
| **Dashboard** | Volume overview, RAM pressure, Smart Scan (one-click cleanup) |
| **Memory** | RAM pressure gauge, heavy process list, `purge` memory freeing |
| **Scanner** | Quick & Deep scan for large files with recursive size calculation |
| **Migrate** | Rsync-based folder migration to external SSD + automatic symlink |
| **Clean Up** | Cache cleanup (npm, pnpm, Xcode, Docker, pip, yarn), System Junk (logs, .DS_Store, crash reports, iOS Backups, Xcode Simulators, Brew), Duplicate File Finder (MD5 hash) |
| **Apps** | List all installed apps with size + support data, complete uninstall with leftovers |
| **Browser** | Clean history/cache/cookies for Safari, Chrome, Firefox, Brave, Edge |
| **Startup** | List login items and Launch Agents, disable with one click |
| **Backups** | Automatic `tar.gz` snapshots before any destructive operation, restore |
| **Disk Map** | Interactive treemap visualization (DaisyDisk-style) with hover details |
| **Settings** | Permissions checker (Full Disk Access), external volume config |

## Requirements

- macOS 14.0+ (Sonoma)
- Apple Silicon or Intel Mac
- External SSD recommended for migration features

## Installation

### Option 1: Download DMG
1. Download `DiskLiberator-1.0.0.dmg`
2. Open and drag to Applications

### Option 2: Build from source
```bash
git clone https://github.com/your-username/diskliberator.git
cd diskliberator
./build.sh
```

### Option 3: Open in Xcode
```bash
open DiskLiberator.xcodeproj
# ⌘R to run
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧S` | Smart Scan |
| `⌘⇧M` | Free Memory |
| `⌘⇧H` | Scan Home |
| `⌘⇧C` | Scan Caches |
| `⌘⇧U` | Migrate All |

## Architecture

```
Sources/DiskLiberator/
├── DiskLiberatorApp.swift    — @main entry point
├── ContentView.swift         — Sidebar navigation (11 tabs)
├── DesignSystem.swift        — Color tokens, reusable components
├── MainViewModel.swift       — Central state manager (@MainActor)
├── Models/
│   ├── DiskItem.swift        — Data models + VolumeInfo + CacheCategory
├── Services/
│   ├── DiskService.swift          — File scanning & size calculation
│   ├── MigrationService.swift     — rsync-based folder migration
│   ├── CacheCleanupService.swift  — Cache detection & cleaning
│   ├── SystemJunkService.swift    — Logs, .DS_Store, temp, Brew
│   ├── DuplicateFileService.swift — MD5 hash duplicate finder
│   ├── MemoryOptimizerService.swift — RAM pressure & process management
│   ├── AppUninstallService.swift  — App listing & complete removal
│   ├── BrowserPrivacyService.swift — Browser history/cache/cookie cleanup
│   ├── StartupItemsService.swift  — Login items & Launch Agents
│   ├── BackupService.swift        — tar.gz snapshots & restore
│   └── PermissionService.swift    — Full Disk Access & Accessibility check
└── Views/
    ├── DashboardView.swift
    ├── MemoryView.swift
    ├── ScanView.swift
    ├── MigrationView.swift
    ├── CleanupView.swift
    ├── AppUninstallView.swift
    ├── BrowserView.swift
    ├── StartupItemsView.swift
    ├── BackupView.swift
    ├── DiskUsageView.swift
    └── SettingsView.swift
```

## Tech Stack

- **Language:** Swift 5.9
- **UI:** SwiftUI (macOS 14+)
- **Engine:** Native `FileManager` + `rsync` + `purge` + `tar`
- **Build:** XcodeGen (`project.yml`) + SwiftPM
- **Design:** Dark mode, CleanMyMac-inspired sidebar, gradient cards

## Performance Targets

- **Minimum RAM:** 512 MB (Lite) / 2 GB (Full)
- **Scan speed:** ~2 min for full home directory scan
- **App size:** ~2 MB

## Roadmap

- [ ] Mac App Store release
- [ ] Localization (en/pt-BR)
- [ ] Photo Junk scanner (HEIC, duplicates)
- [ ] Mail attachments cleanup
- [ ] Secure delete (shredder)
- [ ] Cloud storage integration (iCloud, Google Drive)

## License

MIT License — free to use, modify, and distribute.

---

*Built with SwiftUI — Liberate your disk.*
