//
//  UserProfile.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Foundation

/// Domain model for the current user's profile (identity, contact, and social presence).
struct UserProfile: Equatable {
    var id: UUID
    var firstName: String
    var lastName: String
    var bio: String?
    var username: String
    var email: String
    var phoneNumber: String?
    var profileImageURL: String?

    // Social handles (stored as handles or URLs as appropriate)
    var instagramHandle: String?
    var twitterHandle: String?
    var youtubeHandle: String?
    var tiktokHandle: String?
    var linkedinHandle: String?
    var websiteURL: String?

    /// Display name built from first and last name.
    var fullName: String {
        [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    /// For backward compatibility when only a single name is stored (e.g. auth metadata).
    static func fullName(from singleName: String?) -> String {
        singleName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
