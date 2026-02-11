//
//  AuthRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import AuthenticationServices
import Foundation

protocol AuthRepository {
    func currentUserID() async -> UUID?
    func currentUserEmail() async -> String?
    func currentUserName() async -> String?
    func currentUserProfileImageURL() async -> String?

    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws
    func signOut() async throws
    func deleteAccount() async throws

    func updateUserName(_ name: String) async throws
    func updateUserProfileImage(_ imageURL: String) async throws
    func updateUserEmail(_ email: String) async throws
}

final class PreviewAuthRepository: AuthRepository {
    func currentUserID() async -> UUID? { nil }
    func currentUserEmail() async -> String? { nil }
    func currentUserName() async -> String? { nil }
    func currentUserProfileImageURL() async -> String? { nil }
    func signIn(email: String, password: String) async throws {}
    func signUp(email: String, password: String) async throws {}
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {}
    func signOut() async throws {}
    func deleteAccount() async throws {}
    func updateUserName(_ name: String) async throws {}
    func updateUserProfileImage(_ imageURL: String) async throws {}
    func updateUserEmail(_ email: String) async throws {}
}
