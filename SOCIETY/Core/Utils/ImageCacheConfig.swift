//
//  ImageCacheConfig.swift
//  SOCIETY
//
//  Configuration for image caching with size limits and eviction policies.
//

import Foundation

struct ImageCacheConfig {
    static let shared = ImageCacheConfig()
    
    // Configure URLCache with strict limits
    static func configuredURLCache() -> URLCache {
        // 20MB memory cache, 100MB disk cache
        let memoryCapacity = 20 * 1024 * 1024  // 20MB
        let diskCapacity = 100 * 1024 * 1024   // 100MB
        
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let diskCacheURL = cachesURL.appendingPathComponent("ImageCache")
        
        return URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            directory: diskCacheURL
        )
    }
    
    static func configuredURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = configuredURLCache()
        
        // Only cache successful image responses, not API calls
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 30
        
        return URLSession(configuration: configuration)
    }
}
