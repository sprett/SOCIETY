//
//  ProfileRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Foundation

protocol ProfileRepository {
    /// Loads the current user's profile. Merges profiles table with auth email when needed.
    func loadProfile(userID: UUID, fallbackEmail: String?) async throws -> UserProfile?

    /// Upserts the given profile (id must match current user). Updates profiles table and optionally auth metadata for name/avatar.
    func updateProfile(_ profile: UserProfile) async throws
    
    /// Checks if a username is available. Returns true if available, false if taken.
    /// Optionally excludes a specific user ID (for when user is updating their own username).
    func checkUsernameAvailability(_ username: String, excludingUserID: UUID?) async throws -> Bool
}

/// Mock for previews and tests.
final class MockProfileRepository: ProfileRepository {
    var stubProfile: UserProfile?

    func loadProfile(userID: UUID, fallbackEmail: String?) async throws -> UserProfile? {
        stubProfile ?? UserProfile(
            id: userID,
            firstName: "Preview",
            lastName: "User",
            bio: nil,
            username: "previewuser",
            email: fallbackEmail ?? "preview@example.com",
            phoneNumber: nil,
            profileImageURL: nil,
            birthday: nil,
            instagramHandle: nil,
            twitterHandle: nil,
            youtubeHandle: nil,
            tiktokHandle: nil,
            linkedinHandle: nil,
            websiteURL: nil
        )
    }

    func updateProfile(_ profile: UserProfile) async throws {
        stubProfile = profile
    }
    
    func checkUsernameAvailability(_ username: String, excludingUserID: UUID?) async throws -> Bool {
        // Mock implementation: always return true (available)
        return true
    }
}
