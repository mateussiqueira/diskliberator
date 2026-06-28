import Foundation
import IOKit
import MachO

final class MemoryOptimizerService {
    static let shared = MemoryOptimizerService()

    struct MemoryInfo {
        let physical: UInt64
        let used: UInt64
        let wired: UInt64
        let compressed: UInt64
        let appMemory: UInt64
        let free: UInt64
        let pressure: Int // 0-100

        var usagePercent: Double { physical > 0 ? Double(used) / Double(physical) : 0 }
        var freeFormatted: String { ByteCountFormatter.short(Int64(free)) }
        var usedFormatted: String { ByteCountFormatter.short(Int64(used)) }
        var totalFormatted: String { ByteCountFormatter.short(Int64(physical)) }
        var pressureLabel: String {
            if pressure < 30 { return "Normal" }
            if pressure < 60 { return "Elevated" }
            if pressure < 80 { return "High" }
            return "Critical"
        }
        var pressureColor: String {
            if pressure < 30 { return "green" }
            if pressure < 60 { return "orange" }
            return "red"
        }
    }

    struct HeavyProcess: Identifiable {
        let id = UUID()
        let name: String
        let pid: Int32
        let memBytes: UInt64
        let cpuPercent: Double
        let isSuspicious: Bool
        var formattedMem: String { ByteCountFormatter.short(Int64(memBytes)) }
    }

    func getMemoryInfo() -> MemoryInfo {
        let vmStats = getVMStats()
        let total = ProcessInfo.processInfo.physicalMemory
        let pageSize = UInt64(vm_page_size)
        let used = (vmStats.active + vmStats.wired + vmStats.compressed) * pageSize
        let free = vmStats.free * pageSize

        return MemoryInfo(
            physical: total,
            used: used,
            wired: vmStats.wired * pageSize,
            compressed: vmStats.compressed * pageSize,
            appMemory: vmStats.active * pageSize,
            free: free,
            pressure: Int(Double(used) / Double(total) * 100)
        )
    }

    func getHeavyProcesses() -> [HeavyProcess] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/top")
        task.arguments = ["-l", "1", "-n", "20", "-stats", "pid,command,cpu,mem", "-mem"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        guard let data = try? pipe.fileHandleForReading.readToEnd(),
              let output = String(data: data, encoding: .utf8) else { return [] }

        var processes: [HeavyProcess] = []
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 4,
                  let pid = Int32(parts[0]),
                  let memStr = parts.last.flatMap({ String($0).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "") }),
                  let cpuStr = parts.dropLast(1).last
            else { continue }
            let memBytes = parseMem(memStr)
            let cpu = Double(cpuStr) ?? 0
            let name = parts.dropFirst(1).dropLast(2).joined(separator: " ")
            if memBytes > 100_000_000 || cpu > 20 {
                processes.append(HeavyProcess(name: name, pid: pid, memBytes: memBytes, cpuPercent: cpu, isSuspicious: memBytes > 1_000_000_000 || cpu > 80))
            }
        }
        return processes.sorted { $0.memBytes > $1.memBytes }
    }

    func purgeRAM() -> String {
        let p1 = Process()
        p1.executableURL = URL(fileURLWithPath: "/usr/bin/purge")
        do {
            try p1.run()
            p1.waitUntilExit()
        } catch { return "purge failed: \(error.localizedDescription)" }

        // Also try to free disk cache
        let p2 = Process()
        p2.executableURL = URL(fileURLWithPath: "/usr/sbin/memory_pressure")
        p2.arguments = ["/dev/null"]
        return p1.terminationStatus == 0 ? "OK" : "purge exited with code \(p1.terminationStatus)"
    }

    func killProcess(pid: Int32) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/kill")
        p.arguments = [String(pid)]
        do {
            try p.run()
            p.waitUntilExit()
            return p.terminationStatus == 0
        } catch { return false }
    }

    // MARK: - Private
    private struct VMStats {
        var free: UInt64 = 0
        var active: UInt64 = 0
        var inactive: UInt64 = 0
        var wired: UInt64 = 0
        var compressed: UInt64 = 0
    }

    private func getVMStats() -> VMStats {
        var stats = VMStats()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStat = vm_statistics64_data_t()
        let result = withUnsafeMutablePointer(to: &vmStat) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &size)
            }
        }
        guard result == KERN_SUCCESS else { return stats }

        stats.free = UInt64(vmStat.free_count)
        stats.active = UInt64(vmStat.active_count)
        stats.inactive = UInt64(vmStat.inactive_count)
        stats.wired = UInt64(vmStat.wire_count)
        stats.compressed = UInt64(vmStat.compressor_page_count)
        return stats
    }

    private func parseMem(_ s: String) -> UInt64 {
        if s.hasSuffix("G") { return UInt64((Double(s.dropLast()) ?? 0) * 1_000_000_000) }
        if s.hasSuffix("M") { return UInt64((Double(s.dropLast()) ?? 0) * 1_000_000) }
        if s.hasSuffix("K") { return UInt64((Double(s.dropLast()) ?? 0) * 1_000) }
        return UInt64(s) ?? 0
    }
}
