//
//  SupabaseAuthRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import Foundation
import Supabase
import AuthenticationServices

final class SupabaseAuthRepository: AuthRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func currentUserID() async -> UUID? {
        // `session` throws if there's no session; treat as signed out.
        // With emitLocalSessionAsInitialSession: true, also treat expired sessions as signed out
        // until tokenRefreshed or signOut is received.
        do {
            let session = try await client.auth.session
            if session.isExpired { return nil }
            return session.user.id
        } catch {
            return nil
        }
    }

    func currentUserEmail() async -> String? {
        do {
            let session = try await client.auth.session
            if session.isExpired { return nil }
            return session.user.email
        } catch {
            return nil
        }
    }

    func currentUserName() async -> String? {
        do {
            let session = try await client.auth.session
            if session.isExpired { return nil }
            // Try to get name from user metadata (stored during Sign in with Apple)
            if let fullName = session.user.userMetadata["full_name"] as? String {
                return fullName
            }
            // Fallback to individual name components
            if let givenName = session.user.userMetadata["given_name"] as? String,
               let familyName = session.user.userMetadata["family_name"] as? String
            {
                return "\(givenName) \(familyName)"
            }
            if let givenName = session.user.userMetadata["given_name"] as? String {
                return givenName
            }
            return nil
        } catch {
            return nil
        }
    }

    func currentUserProfileImageURL() async -> String? {
        do {
            // Try to get from current session first
            let session = try await client.auth.session
            if session.isExpired { return nil }
            
            // Check userMetadata for profile_image_url
            if let profileImageURL = session.user.userMetadata["profile_image_url"] as? String {
                return profileImageURL
            }
            
            // If not in metadata, try fetching fresh user data
            // This ensures we get the latest metadata after updates
            let user = try await client.auth.user()
            return user.userMetadata["profile_image_url"] as? String
        } catch {
            return nil
        }
    }

    func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8)
        else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get identity token"])
        }

        // Sign in with Supabase using the Apple ID token
        // Note: Apple only provides email/name on first sign-in, so we'll update user metadata after sign-in
        _ = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idTokenString,
                accessToken: nil,
                nonce: nil
            )
        )
        
        // Apple only provides the user's full name during the first sign-in attempt
        // Save it to user metadata for future use (as recommended by Supabase docs)
        if let fullName = credential.fullName {
            var metadata: [String: AnyJSON] = [:]
            
            if let givenName = fullName.givenName {
                metadata["given_name"] = .string(givenName)
            }
            if let familyName = fullName.familyName {
                metadata["family_name"] = .string(familyName)
            }
            
            // Construct full name
            let fullNameString: String
            if let givenName = fullName.givenName, let familyName = fullName.familyName {
                fullNameString = "\(givenName) \(familyName)"
            } else if let givenName = fullName.givenName {
                fullNameString = givenName
            } else if let familyName = fullName.familyName {
                fullNameString = familyName
            } else {
                fullNameString = ""
            }
            
            if !fullNameString.isEmpty {
                metadata["full_name"] = .string(fullNameString)
            }
            
            // Update user metadata with name information
            if !metadata.isEmpty {
                try await client.auth.update(user: UserAttributes(data: metadata))
            }
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func updateUserName(_ name: String) async throws {
        var metadata: [String: AnyJSON] = [:]
        metadata["full_name"] = .string(name)
        try await client.auth.update(user: UserAttributes(data: metadata))
    }

    func updateUserProfileImage(_ imageURL: String) async throws {
        var metadata: [String: AnyJSON] = [:]
        metadata["profile_image_url"] = .string(imageURL)
        try await client.auth.update(user: UserAttributes(data: metadata))
    }
}

