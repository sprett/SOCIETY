//
//  AvatarService.swift
//  SOCIETY
//

import Foundation
import Supabase
import UIKit

protocol AvatarService {
    func buildDiceBearURL(seed: String) -> URL
    func downloadDiceBearPNG(seed: String) async throws -> Data
    func prepareUploadData(from rawImageData: Data) throws -> (data: Data, contentType: String)
    func uploadAvatar(data: Data, contentType: String, userId: UUID) async throws -> URL
    func updateProfileAvatar(userId: UUID, avatarURL: URL, selection: AvatarSelection) async throws
}

@MainActor
final class SupabaseAvatarService: AvatarService {
    private let client: SupabaseClient
    private let imageProcessor: ImageProcessor

    private static let bucketName = "profile-images"
    private static let notionistsStyle = "notionists"

    init(client: SupabaseClient, imageProcessor: ImageProcessor = ImageProcessor()) {
        self.client = client
        self.imageProcessor = imageProcessor
    }

    func buildDiceBearURL(seed: String) -> URL {
        DiceBearURLBuilder.notionistsPNG(seed: seed)
    }

    func downloadDiceBearPNG(seed: String) async throws -> Data {
        let url = buildDiceBearURL(seed: seed)
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AvatarServiceError.dicebearDownloadFailed
        }

        guard UIImage(data: data) != nil else {
            throw AvatarServiceError.invalidImageData
        }

        return data
    }

    func prepareUploadData(from rawImageData: Data) throws -> (data: Data, contentType: String) {
        guard let original = UIImage(data: rawImageData) else {
            throw AvatarServiceError.invalidImageData
        }

        let squared = imageProcessor.centerCropSquare(original)
        let resized = imageProcessor.resize(image: squared, to: CGSize(width: 512, height: 512))

        if let png = resized.pngData(), png.count <= 2_000_000 {
            return (png, "image/png")
        }

        guard let jpeg = resized.jpegData(compressionQuality: 0.85) else {
            throw AvatarServiceError.encodingFailed
        }

        return (jpeg, "image/jpeg")
    }

    func uploadAvatar(data: Data, contentType: String, userId: UUID) async throws -> URL {
        let objectPath = "public/\(userId.uuidString)/avatar.png"
        let options = FileOptions(
            cacheControl: "3600",
            contentType: contentType,
            upsert: true
        )

        _ = try await client.storage
            .from(Self.bucketName)
            .upload(objectPath, data: data, options: options)

        return try client.storage
            .from(Self.bucketName)
            .getPublicURL(path: objectPath)
    }

    func updateProfileAvatar(userId: UUID, avatarURL: URL, selection: AvatarSelection) async throws {
        struct AvatarProfileUpdate: Encodable {
            let id: UUID
            let avatarUrl: String
            let avatarSource: String
            let avatarSeed: String?
            let avatarStyle: String?
            let updatedAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case avatarUrl = "avatar_url"
                case avatarSource = "avatar_source"
                case avatarSeed = "avatar_seed"
                case avatarStyle = "avatar_style"
                case updatedAt = "updated_at"
            }
        }

        let payload = AvatarProfileUpdate(
            id: userId,
            avatarUrl: avatarURL.absoluteString,
            avatarSource: selection.source.rawValue,
            avatarSeed: selection.seed,
            avatarStyle: selection.style,
            updatedAt: Date()
        )

        try await client
            .from("profiles")
            .upsert(payload)
            .execute()
    }
}

enum AvatarServiceError: LocalizedError {
    case dicebearDownloadFailed
    case invalidImageData
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .dicebearDownloadFailed:
            return "Failed to generate avatar. Please try again."
        case .invalidImageData:
            return "The selected image could not be processed."
        case .encodingFailed:
            return "Could not prepare avatar for upload."
        }
    }
}

struct MockAvatarService: AvatarService {
    func buildDiceBearURL(seed: String) -> URL {
        URL(string: "https://api.dicebear.com/9.x/notionists/png?seed=\(seed)")!
    }

    func downloadDiceBearPNG(seed: String) async throws -> Data {
        UIImage(systemName: "person.circle.fill")?.pngData() ?? Data()
    }

    func prepareUploadData(from rawImageData: Data) throws -> (data: Data, contentType: String) {
        (rawImageData, "image/png")
    }

    func uploadAvatar(data: Data, contentType: String, userId: UUID) async throws -> URL {
        URL(string: "https://example.com/avatars/public/\(userId.uuidString)/avatar.png")!
    }

    func updateProfileAvatar(userId: UUID, avatarURL: URL, selection: AvatarSelection) async throws {}
}
