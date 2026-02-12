//
//  ProfileImageUploadService.swift
//  SOCIETY
//
//  Uploads preprocessed profile avatar images to Supabase Storage.
//  Images are center-cropped, resized to 100×100, and JPEG-encoded on-device before upload.
//  Requires a public Supabase Storage bucket named "profile-images".
//  See supabase_storage_policies.sql for the required RLS policies.
//

import Foundation
import Supabase

protocol ProfileImageUploadService {
    /// Preprocesses raw image data and uploads a 100×100 avatar to
    /// `avatars/<userId>/<uuid>_512.jpg`.
    /// - Returns: Public URL of the uploaded avatar.
    func uploadProcessed(rawData: Data, userId: UUID) async throws -> URL

    /// Uploads already-preprocessed avatar data directly (no additional processing).
    /// - Parameters:
    ///   - avatarData: 100×100 JPEG data ready for upload.
    ///   - userId: The user's UUID (used for the storage path).
    /// - Returns: Public URL of the uploaded avatar.
    func uploadPreprocessed(avatarData: Data, userId: UUID) async throws -> URL

    /// Legacy upload: uploads raw `Data` as-is (no preprocessing, flat path).
    /// Prefer `uploadProcessed(rawData:userId:)` for new code.
    func upload(_ data: Data) async throws -> URL

    /// Deletes the object at the given URL from storage if it belongs to this service's bucket.
    /// No-op if the URL is not from this bucket. Ignores errors so callers can treat it as best-effort cleanup.
    func deleteFromStorageIfOwned(url: String) async
}

final class SupabaseProfileImageUploadService: ProfileImageUploadService {
    private let uploader: SupabaseStorageUploader
    private let imageProcessor: ImageProcessor
    private let client: SupabaseClient
    static let bucketName = "profile-images"

    init(client: SupabaseClient, imageProcessor: ImageProcessor = ImageProcessor()) {
        self.client = client
        self.imageProcessor = imageProcessor
        self.uploader = SupabaseStorageUploader(client: client, bucketName: Self.bucketName)
    }

    func uploadProcessed(rawData: Data, userId: UUID) async throws -> URL {
        // 1. Preprocess on a background thread
        let avatarData = try await imageProcessor.processProfileImage(from: rawData)

        // 2. Build storage path
        let fileId = UUID().uuidString
        let path = "avatars/\(userId.uuidString)/\(fileId)_512.jpg"

        // 3. Upload
        try await uploader.upload(data: avatarData, path: path)
        return try uploader.publicURL(for: path)
    }

    func uploadPreprocessed(avatarData: Data, userId: UUID) async throws -> URL {
        let fileId = UUID().uuidString
        let path = "avatars/\(userId.uuidString)/\(fileId)_512.jpg"
        try await uploader.upload(data: avatarData, path: path)
        return try uploader.publicURL(for: path)
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
struct MockProfileImageUploadService: ProfileImageUploadService {
    func uploadProcessed(rawData: Data, userId: UUID) async throws -> URL {
        URL(string: "https://example.com/avatars/\(userId)/placeholder_512.jpg")!
    }

    func uploadPreprocessed(avatarData: Data, userId: UUID) async throws -> URL {
        URL(string: "https://example.com/avatars/\(userId)/placeholder_512.jpg")!
    }

    func upload(_ data: Data) async throws -> URL {
        URL(string: "https://example.com/placeholder-profile.jpg")!
    }

    func deleteFromStorageIfOwned(url: String) async {}
}
