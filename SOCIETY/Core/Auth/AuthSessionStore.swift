//
//  AuthSessionStore.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import Foundation
import Combine
import AuthenticationServices

@MainActor
final class AuthSessionStore: ObservableObject {
    @Published private(set) var userID: UUID?
    @Published private(set) var userEmail: String?
    @Published private(set) var userName: String?
    @Published private(set) var profileImageURL: String?

    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
        Task { await refresh() }
    }

    var isAuthenticated: Bool { userID != nil }

    func refresh() async {
        userID = await authRepository.currentUserID()
        userEmail = await authRepository.currentUserEmail()
        userName = await authRepository.currentUserName()
        profileImageURL = await authRepository.currentUserProfileImageURL()
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

    func signOut() async throws {
        try await authRepository.signOut()
        await refresh()
    }

    func updateUserName(_ name: String) async throws {
        try await authRepository.updateUserName(name)
        await refresh()
    }

    func updateProfileImage(_ imageURL: String) async throws {
        try await authRepository.updateUserProfileImage(imageURL)
        // Refresh immediately - currentUserProfileImageURL now fetches fresh user data
        await refresh()
    }
}

