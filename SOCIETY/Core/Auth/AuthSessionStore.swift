//
//  AuthSessionStore.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import Foundation
import Combine

@MainActor
final class AuthSessionStore: ObservableObject {
    @Published private(set) var userID: UUID?

    private let authRepository: any AuthRepository

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
        Task { await refresh() }
    }

    var isAuthenticated: Bool { userID != nil }

    func refresh() async {
        userID = await authRepository.currentUserID()
    }

    func signIn(email: String, password: String) async throws {
        try await authRepository.signIn(email: email, password: password)
        await refresh()
    }

    func signUp(email: String, password: String) async throws {
        try await authRepository.signUp(email: email, password: password)
        await refresh()
    }

    func signOut() async throws {
        try await authRepository.signOut()
        await refresh()
    }
}

