//
//  CachedAsyncImage.swift
//  SOCIETY
//
//  Drop-in replacement for AsyncImage with cache support.
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @StateObject private var loader: ImageLoader
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                content(image)
            } else {
                placeholder()
            }
        }
        .onAppear {
            // Load if we don't have an image yet
            if loader.image == nil {
                loader.load()
            }
        }
        .onChange(of: url) { _, newURL in
            // Update URL and reload if URL changes
            loader.updateURL(newURL)
            if newURL != nil {
                loader.load()
            }
        }
    }
}
