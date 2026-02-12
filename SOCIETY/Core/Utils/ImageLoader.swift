//
//  ImageLoader.swift
//  SOCIETY
//
//  Observable image loader with two-tier caching (memory + disk).
//

import SwiftUI
import UIKit
import Combine

@MainActor
final class ImageLoader: ObservableObject {
    @Published var image: Image?
    
    private var url: URL?
    private let session: URLSession
    private var task: Task<Void, Never>?
    
    nonisolated init(url: URL?) {
        self.url = url
        self.session = ImageCacheConfig.configuredURLSession()
    }
    
    func updateURL(_ newURL: URL?) {
        self.url = newURL
    }
    
    func load() {
        guard let url = url else { return }
        
        // Cancel any existing task
        task?.cancel()
        
        // Check memory cache first
        task = Task { @MainActor in
            let cache = ImageCache.shared
            if let cachedImage = await cache.image(for: url) {
                self.image = Image(uiImage: cachedImage)
                return
            }
            
            // Download and cache
            do {
                let (data, response) = try await session.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let uiImage = UIImage(data: data) else {
                    return
                }
                
                // Cache the image
                await cache.cache(uiImage, for: url)
                
                self.image = Image(uiImage: uiImage)
            } catch {
                // Silent failure - placeholder will be shown
                print("Failed to load image from \(url): \(error)")
            }
        }
    }
    
    deinit {
        task?.cancel()
    }
}
