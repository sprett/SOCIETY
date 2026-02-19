//
//  AuthSessionStore.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import AuthenticationServices
import Combine
import Foundation

@MainActor
final class AuthSessionStore: ObservableObject {
    @Published private(set) var userID: UUID?
    @Published private(set) var userEmail: String?
    @Published private(set) var userName: String?
    @Published private(set) var userGivenName: String?
    @Published private(set) var userFamilyName: String?
    @Published private(set) var profileImageURL: String?
    @Published private(set) var userBirthdate: Date?
    /// Identity provider used to sign in: "apple", "google", or nil for email/password.
    @Published private(set) var identityProvider: String?

    /// Cached full profile; when set, display name/email/avatar are derived from it.
    @Published private(set) var currentProfile: UserProfile?

    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
        Task { await refresh() }
    }

    var isAuthenticated: Bool { userID != nil }

    func refresh() async {
        let newUserID = await authRepository.currentUserID()
        userID = newUserID
        if newUserID == nil {
            currentProfile = nil
        }
        userEmail = await authRepository.currentUserEmail()
        userName = await authRepository.currentUserName()
        userGivenName = await authRepository.currentUserGivenName()
        userFamilyName = await authRepository.currentUserFamilyName()
        profileImageURL = await authRepository.currentUserProfileImageURL()
        userBirthdate = await authRepository.currentUserBirthdate()
        identityProvider = await authRepository.currentUserIdentityProvider()
    }

    /// Returns the current profile image URL from the server. Use this when you need the authoritative value (e.g. before replacing the image) rather than the cached published property.
    func getCurrentProfileImageURL() async -> String? {
        await authRepository.currentUserProfileImageURL()
    }

    func signIn(email: String, password: String) async throws {
        try await authRepository.signIn(email: email, password: password)
        await refresh()
    }

    func signUp(email: String, password: String) async throws {
        try await authRepository.signUp(email: email, password: password)
        await refresh()
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        try await authRepository.signInWithApple(credential: credential)
        await refresh()
    }

    func signInWithGoogle() async throws {
        try await authRepository.signInWithGoogle()
        await refresh()
    }

    func sessionFromRedirectURL(_ url: URL) async throws {
        try await authRepository.sessionFromRedirectURL(url)
        await refresh()
    }

    func signOut() async throws {
        try await authRepository.signOut()
        await refresh()
    }

    func deleteAccount() async throws {
        try await authRepository.deleteAccount()
        await refresh()
    }

    func updateUserName(_ name: String) async throws {
        try await authRepository.updateUserName(name)
        await refresh()
    }

    func updateProfileImage(_ imageURL: String) async throws {
        try await authRepository.updateUserProfileImage(imageURL)
        await refresh()
    }

    func updateUserEmail(_ email: String) async throws {
        try await authRepository.updateUserEmail(email)
        await refresh()
    }

    /// Updates cached profile and derived display values (userName, userEmail, profileImageURL).
    func setCurrentProfile(_ profile: UserProfile?) {
        currentProfile = profile
        if let p = profile {
            userName = p.fullName
            userEmail = p.email
            profileImageURL = p.profileImageURL
        }
    }
}
