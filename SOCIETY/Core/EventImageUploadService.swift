//
//  EventImageUploadService.swift
//  SOCIETY
//
//  Uploads event cover images to storage and returns a public URL.
//  Requires a public Supabase Storage bucket named "event-images" with policies allowing
//  authenticated uploads (INSERT) and deletes (DELETE). See supabase_storage_policies.sql.
//

import Foundation
import Supabase

protocol EventImageUploadService {
    /// Uploads image data to storage and returns the public URL.
    /// - Parameter data: Image data (e.g. JPEG).
    /// - Returns: Public URL of the uploaded file.
    func upload(_ data: Data) async throws -> URL

    /// Deletes the object at the given URL from storage if it belongs to this service's bucket.
    /// No-op if the URL is not from this bucket. Ignores errors so callers can treat it as best-effort cleanup.
    func deleteFromStorageIfOwned(url: String) async
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

    /// Deletes the object at the given URL from storage if it belongs to this service's bucket.
    /// No-op if the URL is not from this bucket. Same behavior as ProfileImageUploadService.
    func deleteFromStorageIfOwned(url: String) async {
        guard let path = pathInBucket(from: url) else { return }
        _ = try? await client.storage
            .from(Self.bucketName)
            .remove(paths: [path])
    }

    /// Extracts the storage object path from a public URL if it points to our bucket.
    /// Supports: .../storage/v1/object/public/<bucket>/<path> and .../storage/v1/public/<bucket>/<path>
    /// Same logic as ProfileImageUploadService.pathInBucket (bucket name differs).
    private func pathInBucket(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let pathComponent = url.path.removingPercentEncoding ?? Optional(url.path)
        else { return nil }
        let path = pathComponent.hasPrefix("/") ? pathComponent : "/" + pathComponent
        // Try standard format first: /storage/v1/object/public/event-images/UUID.jpg
        let objectPublicPrefix = "/storage/v1/object/public/\(Self.bucketName)/"
        if path.hasPrefix(objectPublicPrefix) {
            let suffix = String(path.dropFirst(objectPublicPrefix.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return suffix.isEmpty ? nil : suffix
        }
        // Some SDKs or proxies use: /storage/v1/public/event-images/UUID.jpg
        let publicPrefix = "/storage/v1/public/\(Self.bucketName)/"
        if path.hasPrefix(publicPrefix) {
            let suffix = String(path.dropFirst(publicPrefix.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return suffix.isEmpty ? nil : suffix
        }
        // Fallback: any URL that contains our bucket name followed by the object path
        let marker = "/\(Self.bucketName)/"
        guard let range = path.range(of: marker) else { return nil }
        let suffix = String(path[range.upperBound...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return suffix.isEmpty ? nil : suffix
    }
}

/// Mock for previews; returns a placeholder URL without uploading.
struct MockEventImageUploadService: EventImageUploadService {
    func upload(_ data: Data) async throws -> URL {
        URL(string: "https://example.com/placeholder.jpg")!
    }

    func deleteFromStorageIfOwned(url: String) async {}
}
