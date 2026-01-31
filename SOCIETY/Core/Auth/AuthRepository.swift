//
//  AuthRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import Foundation

protocol AuthRepository {
    func currentUserID() async -> UUID?

    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() async throws
}

final class PreviewAuthRepository: AuthRepository {
    func currentUserID() async -> UUID? { nil }
    func signIn(email: String, password: String) async throws {}
    func signUp(email: String, password: String) async throws {}
    func signOut() async throws {}
}

