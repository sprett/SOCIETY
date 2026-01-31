//
//  EventImageUploadService.swift
//  SOCIETY
//
//  Uploads event cover images to storage and returns a public URL.
//  Requires a public Supabase Storage bucket named "event-images" with policies allowing authenticated uploads.
//

import Foundation
import Supabase

protocol EventImageUploadService {
    /// Uploads image data to storage and returns the public URL.
    /// - Parameter data: Image data (e.g. JPEG).
    /// - Returns: Public URL of the uploaded file.
    func upload(_ data: Data) async throws -> URL
}

final class SupabaseEventImageUploadService: EventImageUploadService {
    private let client: SupabaseClient
    private static let bucketName = "event-images"
    private static let contentType = "image/jpeg"

    init(client: SupabaseClient) {
        self.client = client
    }

    func upload(_ data: Data) async throws -> URL {
        let path = "\(UUID().uuidString).jpg"
        let options = FileOptions(
            cacheControl: "3600",
            contentType: Self.contentType,
            upsert: false
        )
        _ = try await client.storage
            .from(Self.bucketName)
            .upload(path, data: data, options: options)
        return try client.storage
            .from(Self.bucketName)
            .getPublicURL(path: path)
    }
}

/// Mock for previews; returns a placeholder URL without uploading.
struct MockEventImageUploadService: EventImageUploadService {
    func upload(_ data: Data) async throws -> URL {
        URL(string: "https://example.com/placeholder.jpg")!
    }
}
