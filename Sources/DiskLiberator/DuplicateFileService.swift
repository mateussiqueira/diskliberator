import Foundation
import CommonCrypto

final class DuplicateFileService {
    static let shared = DuplicateFileService()

    func scan(urls: [URL], minSize: Int64 = 1_000_000) -> [DuplicateGroup] {
        // Phase 1: Group files by size
        var bySize: [Int64: [URL]] = [:]
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey]

        for url in urls {
            guard let e = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles, .skipsPackageDescendants])
            else { continue }
            for case let f as URL in e {
                guard let r = try? f.resourceValues(forKeys: keys),
                      r.isRegularFile == true, r.isSymbolicLink != true,
                      let size = r.fileSize, size >= Int(minSize)
                else { continue }
                bySize[Int64(size), default: []].append(f)
            }
        }

        // Phase 2: Only keep size groups with 2+ files, compute partial MD5 for each
        var groups: [DuplicateGroup] = []

        // Process each size group
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)
        var resultsLock = NSLock()
        var results: [DuplicateGroup] = []

        for (size, files) in bySize where files.count >= 2 {
            group.enter()
            queue.async {
                let chunked = self.chunkFiles(files, bytes: 4096)  // First 4KB only for speed
                var byHash: [String: [URL]] = [:]
                for (f, hash) in chunked {
                    byHash[hash, default: []].append(f)
                }
                for (_, matches) in byHash where matches.count >= 2 {
                    resultsLock.lock()
                    results.append(DuplicateGroup(size: size, count: matches.count, files: matches))
                    resultsLock.unlock()
                }
                group.leave()
            }
        }
        group.wait()

        return results.sorted { $0.size > $1.size }
    }

    private func chunkFiles(_ files: [URL], bytes: Int) -> [(URL, String)] {
        return files.compactMap { url in
            guard let data = try? Data(contentsOf: url, options: .alwaysMapped) else { return nil }
            let chunk = data.subdata(in: 0..<min(bytes, data.count))
            return (url, chunk.md5Hex)
        }
    }

    func fullCompare(group: DuplicateGroup) -> [URL] {
        let fullHashes = group.files.compactMap { url -> (URL, String)? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return (url, data.md5Hex)
        }
        var byHash: [String: [URL]] = [:]
        for (url, hash) in fullHashes {
            byHash[hash, default: []].append(url)
        }
        return byHash.values.filter { $0.count >= 2 }.flatMap { $0 }
    }
}

extension Data {
    var md5Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        withUnsafeBytes { buf in
            _ = CC_MD5(buf.baseAddress, CC_LONG(count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
