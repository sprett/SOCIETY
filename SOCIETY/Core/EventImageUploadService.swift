//
//  EventImageUploadService.swift
//  SOCIETY
//
//  Uploads preprocessed event cover images to Supabase Storage.
//  Images are center-cropped, resized, and JPEG-encoded on-device before upload.
//  Requires a public Supabase Storage bucket named "event-images".
//  See supabase_storage_policies.sql for the required RLS policies.
//

import Foundation
import Supabase

protocol EventImageUploadService {
    /// Preprocesses raw image data and uploads a 512×512 main image (+ optional 100×100 thumb)
    /// to `events/<eventId>/<uuid>_1024.jpg` (and `<uuid>_256.jpg`).
    /// - Returns: Public URL of the 512 main image and optional thumb URL.
    func uploadProcessed(
        rawData: Data,
        eventId: UUID
    ) async throws -> (mainURL: URL, thumbURL: URL?)

    /// Uploads already-preprocessed data directly (no additional processing).
    /// - Parameters:
    ///   - mainData: 512×512 JPEG data ready for upload.
    ///   - thumbData: Optional 256×256 JPEG data.
    ///   - eventId: The event's UUID (used for the storage path).
    /// - Returns: Public URLs for main and optional thumb.
    func uploadPreprocessed(
        mainData: Data,
        thumbData: Data?,
        eventId: UUID
    ) async throws -> (mainURL: URL, thumbURL: URL?)

    /// Legacy upload: uploads raw `Data` as-is (no preprocessing, flat path).
    /// Prefer `uploadProcessed(rawData:eventId:)` for new code.
    func upload(_ data: Data) async throws -> URL

    /// Deletes the object at the given URL from storage if it belongs to this service's bucket.
    /// No-op if the URL is not from this bucket. Ignores errors so callers can treat it as best-effort cleanup.
    func deleteFromStorageIfOwned(url: String) async
}

final class SupabaseEventImageUploadService: EventImageUploadService {
    private let uploader: SupabaseStorageUploader
    private let imageProcessor: ImageProcessor
    private let client: SupabaseClient
    static let bucketName = "event-images"

    init(client: SupabaseClient, imageProcessor: ImageProcessor = ImageProcessor()) {
        self.client = client
        self.imageProcessor = imageProcessor
        self.uploader = SupabaseStorageUploader(client: client, bucketName: Self.bucketName)
    }

    func uploadProcessed(
        rawData: Data,
        eventId: UUID
    ) async throws -> (mainURL: URL, thumbURL: URL?) {
        // 1. Preprocess on a background thread
        let processed = try await imageProcessor.processEventImage(from: rawData)

        // 2. Build storage paths
        let fileId = UUID().uuidString
        let mainPath = "events/\(eventId.uuidString)/\(fileId)_1024.jpg"

        // 3. Upload main 1024×1024
        try await uploader.upload(data: processed.main512, path: mainPath)
        let mainURL = try uploader.publicURL(for: mainPath)

        // 4. Optionally upload 256×256 thumb
        var thumbURL: URL? = nil
        if let thumbData = processed.thumb100 {
            let thumbPath = "events/\(eventId.uuidString)/\(fileId)_256.jpg"
            try await uploader.upload(data: thumbData, path: thumbPath)
            thumbURL = try uploader.publicURL(for: thumbPath)
        }

        return (mainURL: mainURL, thumbURL: thumbURL)
    }

    func uploadPreprocessed(
        mainData: Data,
        thumbData: Data?,
        eventId: UUID
    ) async throws -> (mainURL: URL, thumbURL: URL?) {
        let fileId = UUID().uuidString
        let mainPath = "events/\(eventId.uuidString)/\(fileId)_1024.jpg"

        try await uploader.upload(data: mainData, path: mainPath)
        let mainURL = try uploader.publicURL(for: mainPath)

        var thumbURL: URL? = nil
        if let thumbData {
            let thumbPath = "events/\(eventId.uuidString)/\(fileId)_256.jpg"
            try await uploader.upload(data: thumbData, path: thumbPath)
            thumbURL = try uploader.publicURL(for: thumbPath)
        }

        return (mainURL: mainURL, thumbURL: thumbURL)
    }

    func upload(_ data: Data) async throws -> URL {
        let path = "\(UUID().uuidString).jpg"
        try await uploader.upload(data: data, path: path)
        return try uploader.publicURL(for: path)
    }

    func deleteFromStorageIfOwned(url: String) async {
        guard let path = pathInBucket(from: url) else { return }
        await uploader.delete(paths: [path])
    }

    // MARK: - Path extraction

    /// Extracts the storage object path from a public URL if it points to our bucket.
    private func pathInBucket(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let pathComponent = url.path.removingPercentEncoding ?? Optional(url.path)
        else { return nil }
        let path = pathComponent.hasPrefix("/") ? pathComponent : "/" + pathComponent

        let objectPublicPrefix = "/storage/v1/object/public/\(Self.bucketName)/"
        if path.hasPrefix(objectPublicPrefix) {
            let suffix = String(path.dropFirst(objectPublicPrefix.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return suffix.isEmpty ? nil : suffix
        }

        let publicPrefix = "/storage/v1/public/\(Self.bucketName)/"
        if path.hasPrefix(publicPrefix) {
            let suffix = String(path.dropFirst(publicPrefix.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return suffix.isEmpty ? nil : suffix
        }

        let marker = "/\(Self.bucketName)/"
        guard let range = path.range(of: marker) else { return nil }
        let suffix = String(path[range.upperBound...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return suffix.isEmpty ? nil : suffix
    }
}

/// Mock for previews; returns a placeholder URL without uploading.
struct MockEventImageUploadService: EventImageUploadService {
    func uploadProcessed(rawData: Data, eventId: UUID) async throws -> (mainURL: URL, thumbURL: URL?) {
        (mainURL: URL(string: "https://example.com/events/\(eventId)/placeholder_1024.jpg")!, thumbURL: nil)
    }

    func uploadPreprocessed(mainData: Data, thumbData: Data?, eventId: UUID) async throws -> (mainURL: URL, thumbURL: URL?) {
        (mainURL: URL(string: "https://example.com/events/\(eventId)/placeholder_1024.jpg")!, thumbURL: nil)
    }

    func upload(_ data: Data) async throws -> URL {
        URL(string: "https://example.com/placeholder.jpg")!
    }

    func deleteFromStorageIfOwned(url: String) async {}
}
