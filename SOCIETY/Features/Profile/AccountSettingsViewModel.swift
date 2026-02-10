//
//  AccountSettingsViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Combine
import SwiftUI

@MainActor
final class AccountSettingsViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var username: String = ""
    @Published var isLoading: Bool = false
    @Published var isDeleting: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation: Bool = false
    @Published var deleteSucceeded: Bool = false

    private let authSession: AuthSessionStore
    private let profileRepository: any ProfileRepository
    private var loadedProfile: UserProfile?

    init(
        authSession: AuthSessionStore,
        profileRepository: any ProfileRepository
    ) {
        self.authSession = authSession
        self.profileRepository = profileRepository
    }

    func load() async {
        guard let userID = authSession.userID else { return }
        isLoading = true
        errorMessage = nil

        do {
            let profile = try await profileRepository.loadProfile(
                userID: userID,
                fallbackEmail: authSession.userEmail
            )
            if let p = profile {
                loadedProfile = p
                email = p.email
                phoneNumber = p.phoneNumber ?? ""
                username = p.username
            } else {
                email = authSession.userEmail ?? ""
                phoneNumber = ""
                username = ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func updateEmail(_ newEmail: String) async {
        let trimmed = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != email else { return }
        errorMessage = nil
        do {
            try await authSession.updateUserEmail(trimmed)
            email = trimmed
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updatePhoneNumber(_ newPhone: String) async {
        let trimmed = newPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var profile = loadedProfile ?? buildMinimalProfile() else { return }
        profile.phoneNumber = trimmed.isEmpty ? nil : trimmed
        errorMessage = nil
        do {
            try await profileRepository.updateProfile(profile)
            loadedProfile = profile
            phoneNumber = trimmed
            authSession.setCurrentProfile(profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateUsername(_ newUsername: String) async {
        let trimmed = newUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var profile = loadedProfile ?? buildMinimalProfile() else { return }
        profile.username = trimmed
        errorMessage = nil
        do {
            try await profileRepository.updateProfile(profile)
            loadedProfile = profile
            username = trimmed
            authSession.setCurrentProfile(profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount() async {
        isDeleting = true
        errorMessage = nil
        do {
            try await authSession.deleteAccount()
            deleteSucceeded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isDeleting = false
    }

    private func buildMinimalProfile() -> UserProfile? {
        guard let userID = authSession.userID else { return nil }
        let full = UserProfile.fullName(from: authSession.userName)
        let parts = full.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let first = loadedProfile?.firstName ?? String(parts.first ?? "")
        let last = loadedProfile?.lastName ?? (parts.count > 1 ? String(parts[1]) : "")
        return UserProfile(
            id: userID,
            firstName: first,
            lastName: last,
            bio: loadedProfile?.bio,
            username: username,
            email: email,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            profileImageURL: loadedProfile?.profileImageURL,
            instagramHandle: loadedProfile?.instagramHandle,
            twitterHandle: loadedProfile?.twitterHandle,
            youtubeHandle: loadedProfile?.youtubeHandle,
            tiktokHandle: loadedProfile?.tiktokHandle,
            linkedinHandle: loadedProfile?.linkedinHandle,
            websiteURL: loadedProfile?.websiteURL
        )
    }
}
