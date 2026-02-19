//
//  SupabaseProfileRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Foundation
import Supabase

final class SupabaseProfileRepository: ProfileRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func loadProfile(userID: UUID, fallbackEmail: String?) async throws -> UserProfile? {
        struct ProfileRow: Decodable {
            let id: UUID
            let fullName: String?
            let avatarUrl: String?
            let firstName: String?
            let lastName: String?
            let bio: String?
            let username: String?
            let phoneNumber: String?
            let instagramHandle: String?
            let twitterHandle: String?
            let youtubeHandle: String?
            let tiktokHandle: String?
            let linkedinHandle: String?
            let websiteUrl: String?
            /// Decoded as string (Postgres date is "YYYY-MM-DD"); use parseBirthday() when building UserProfile.
            let birthdayString: String?

            enum CodingKeys: String, CodingKey {
                case id
                case fullName = "full_name"
                case avatarUrl = "avatar_url"
                case firstName = "first_name"
                case lastName = "last_name"
                case bio
                case username
                case phoneNumber = "phone_number"
                case instagramHandle = "instagram_handle"
                case twitterHandle = "twitter_handle"
                case youtubeHandle = "youtube_handle"
                case tiktokHandle = "tiktok_handle"
                case linkedinHandle = "linkedin_handle"
                case websiteUrl = "website_url"
                case birthdayString = "birthday"
            }
        }

        let rows: [ProfileRow] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userID.uuidString)
            .execute()
            .value

        guard let row = rows.first else { return nil }

        let firstName = row.firstName?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? row.fullName.map { $0.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true) }.map { parts in
                if parts.count == 2 { return (String(parts[0]), String(parts[1])) }
                return (String(parts[0]), "")
            }.map { $0.0 } ?? ""
        let lastName = row.lastName?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? row.fullName.map { $0.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true) }.map { parts in
                if parts.count == 2 { return String(parts[1]) }
                return ""
            }.map { $0 } ?? ""

        return UserProfile(
            id: row.id,
            firstName: firstName.isEmpty ? " " : firstName,
            lastName: lastName,
            bio: row.bio?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? row.bio : nil,
            username: row.username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            email: fallbackEmail ?? "",
            phoneNumber: row.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? row.phoneNumber : nil,
            profileImageURL: row.avatarUrl?.isEmpty == false ? row.avatarUrl : nil,
            birthday: Self.parseBirthday(row.birthdayString),
            instagramHandle: row.instagramHandle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? row.instagramHandle : nil,
            twitterHandle: row.twitterHandle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? row.twitterHandle : nil,
            youtubeHandle: row.youtubeHandle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? row.youtubeHandle : nil,
            tiktokHandle: row.tiktokHandle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? row.tiktokHandle : nil,
            linkedinHandle: row.linkedinHandle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? row.linkedinHandle : nil,
            websiteURL: row.websiteUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? row.websiteUrl : nil
        )
    }

    private static func parseBirthday(_ string: String?) -> Date? {
        guard let string = string?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: string)
    }

    private static func formatBirthday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    func updateProfile(_ profile: UserProfile) async throws {
        struct ProfileUpdate: Encodable {
            let id: UUID
            let fullName: String
            let avatarUrl: String?
            let firstName: String
            let lastName: String
            let bio: String?
            let username: String
            let phoneNumber: String?
            let instagramHandle: String?
            let twitterHandle: String?
            let youtubeHandle: String?
            let tiktokHandle: String?
            let linkedinHandle: String?
            let websiteUrl: String?
            /// Encoded as "yyyy-MM-dd" for Postgres date column.
            let birthdayString: String?
            let updatedAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case fullName = "full_name"
                case avatarUrl = "avatar_url"
                case firstName = "first_name"
                case lastName = "last_name"
                case bio
                case username
                case phoneNumber = "phone_number"
                case instagramHandle = "instagram_handle"
                case twitterHandle = "twitter_handle"
                case youtubeHandle = "youtube_handle"
                case tiktokHandle = "tiktok_handle"
                case linkedinHandle = "linkedin_handle"
                case websiteUrl = "website_url"
                case birthdayString = "birthday"
                case updatedAt = "updated_at"
            }
        }

        let payload = ProfileUpdate(
            id: profile.id,
            fullName: profile.fullName,
            avatarUrl: profile.profileImageURL,
            firstName: profile.firstName,
            lastName: profile.lastName,
            bio: profile.bio,
            username: profile.username,
            phoneNumber: profile.phoneNumber,
            instagramHandle: profile.instagramHandle,
            twitterHandle: profile.twitterHandle,
            youtubeHandle: profile.youtubeHandle,
            tiktokHandle: profile.tiktokHandle,
            linkedinHandle: profile.linkedinHandle,
            websiteUrl: profile.websiteURL,
            birthdayString: profile.birthday.map { Self.formatBirthday($0) },
            updatedAt: Date()
        )

        try await client
            .from("profiles")
            .upsert(payload)
            .execute()
    }

    func markOnboardingCompleted(userID: UUID) async throws {
        struct OnboardingUpdate: Encodable {
            let onboardingCompleted: Bool

            enum CodingKeys: String, CodingKey {
                case onboardingCompleted = "onboarding_completed"
            }
        }

        try await client
            .from("profiles")
            .update(OnboardingUpdate(onboardingCompleted: true))
            .eq("id", value: userID.uuidString)
            .execute()
    }
    
    func checkUsernameAvailability(_ username: String, excludingUserID: UUID?) async throws -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Query to check if username exists
        var query = client
            .from("profiles")
            .select("id")
            .ilike("username", pattern: trimmed)
        
        // Exclude the current user if specified
        if let userID = excludingUserID {
            query = query.neq("id", value: userID.uuidString)
        }
        
        struct UsernameCheck: Decodable {
            let id: UUID
        }
        
        let results: [UsernameCheck] = try await query.execute().value
        
        // If no results, username is available
        return results.isEmpty
    }
}
