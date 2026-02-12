//
//  ImageCache.swift
//  SOCIETY
//
//  In-memory image cache with LRU eviction using NSCache.
//

import UIKit

actor ImageCache {
    static let shared = ImageCache()
    
    private let maxMemoryCost = 50 * 1024 * 1024  // 50MB in-memory limit
    private let cache: NSCache<NSString, UIImage>
    
    init() {
        cache = NSCache()
        cache.totalCostLimit = maxMemoryCost
        cache.countLimit = 200  // Max 200 images in memory
    }
    
    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url.absoluteString as NSString)
    }
    
    func cache(_ image: UIImage, for url: URL) {
        // Estimate cost based on image size
        let cost = image.size.width * image.size.height * 4  // 4 bytes per pixel
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: Int(cost))
    }
    
    func clearAll() {
        cache.removeAllObjects()
    }
}
