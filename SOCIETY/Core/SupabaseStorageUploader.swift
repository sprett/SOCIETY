//
//  SupabaseStorageUploader.swift
//  SOCIETY
//
//  Generic helper that uploads data to a Supabase Storage bucket and returns public URLs.
//  Callers are responsible for constructing the storage path (e.g. "events/<id>/uuid_512.jpg").
//

import Foundation
import Supabase

final class SupabaseStorageUploader {
    private let client: SupabaseClient
    private let bucketName: String

    init(client: SupabaseClient, bucketName: String) {
        self.client = client
        self.bucketName = bucketName
    }

    /// Uploads data to the given path in the bucket.
    /// - Parameters:
    ///   - data: Raw file data (e.g. JPEG bytes).
    ///   - path: Storage object path (e.g. "events/<eventId>/<uuid>_512.jpg").
    ///   - contentType: MIME type. Defaults to `image/jpeg`.
    func upload(data: Data, path: String, contentType: String = "image/jpeg") async throws {
        let options = FileOptions(
            cacheControl: "3600",
            contentType: contentType,
            upsert: false
        )
        _ = try await client.storage
            .from(bucketName)
            .upload(path, data: data, options: options)
    }

    /// Returns the public URL for an object at the given path.
    func publicURL(for path: String) throws -> URL {
        try client.storage
            .from(bucketName)
            .getPublicURL(path: path)
    }

    /// Deletes object(s) at the given paths. Errors are swallowed (best-effort).
    func delete(paths: [String]) async {
        _ = try? await client.storage
            .from(bucketName)
            .remove(paths: paths)
    }
}
