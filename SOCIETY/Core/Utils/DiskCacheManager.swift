//
//  DiskCacheManager.swift
//  SOCIETY
//
//  Manages disk cache cleanup and size enforcement with age-based expiration.
//

import Foundation

actor DiskCacheManager {
    static let shared = DiskCacheManager()
    
    private let maxDiskSize: Int64 = 100 * 1024 * 1024  // 100MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60  // 7 days
    
    func cleanupIfNeeded() async {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let imageCacheURL = cacheURL.appendingPathComponent("ImageCache")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: imageCacheURL, withIntermediateDirectories: true)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: imageCacheURL,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                options: .skipsHiddenFiles
            )
            
            // Remove old files
            let now = Date()
            for fileURL in fileURLs {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                if let modificationDate = attributes[.modificationDate] as? Date {
                    if now.timeIntervalSince(modificationDate) > maxCacheAge {
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                }
            }
            
            // Check total size and remove oldest if over limit
            try await enforceMaxDiskSize(in: imageCacheURL)
            
        } catch {
            print("Cache cleanup failed: \(error)")
        }
    }
    
    func clearAllImageCache() async {
        // Clear only the ImageCache directory, not all URL cache
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let imageCacheURL = cacheURL.appendingPathComponent("ImageCache")
        
        do {
            // Remove the entire ImageCache directory
            try FileManager.default.removeItem(at: imageCacheURL)
            // Recreate it
            try FileManager.default.createDirectory(at: imageCacheURL, withIntermediateDirectories: true)
        } catch {
            print("Failed to clear image cache: \(error)")
        }
    }
    
    func calculateCacheSize() async -> Int64 {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let imageCacheURL = cacheURL.appendingPathComponent("ImageCache")
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: imageCacheURL,
                includingPropertiesForKeys: [.fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            var totalSize: Int64 = 0
            for fileURL in fileURLs {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                totalSize += attributes[.size] as? Int64 ?? 0
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
    
    private func enforceMaxDiskSize(in directory: URL) async throws {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        )
        
        var files: [(url: URL, size: Int64, date: Date)] = []
        var totalSize: Int64 = 0
        
        for fileURL in fileURLs {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let size = attributes[.size] as? Int64 ?? 0
            let date = attributes[.modificationDate] as? Date ?? Date.distantPast
            
            files.append((url: fileURL, size: size, date: date))
            totalSize += size
        }
        
        if totalSize > maxDiskSize {
            // Sort by date (oldest first) and delete until under limit
            files.sort { $0.date < $1.date }
            
            for file in files {
                if totalSize <= maxDiskSize { break }
                try? FileManager.default.removeItem(at: file.url)
                totalSize -= file.size
            }
        }
    }
}
