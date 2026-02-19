//
//  SupabaseAuthRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import AuthenticationServices
import Foundation
import Supabase

/// URL scheme used for OAuth redirect (must match Info.plist and Supabase redirect URL config).
private let oAuthRedirectScheme = "dinoh.society"
private let oAuthRedirectURL = URL(string: "\(oAuthRedirectScheme)://auth/callback")!

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
            if case .string(let fullName)? = session.user.userMetadata["full_name"] {
                return fullName
            }
            // Fallback to individual name components
            if case .string(let givenName)? = session.user.userMetadata["given_name"],
                case .string(let familyName)? = session.user.userMetadata["family_name"]
            {
                return "\(givenName) \(familyName)"
            }
            if case .string(let givenName)? = session.user.userMetadata["given_name"] {
                return givenName
            }
            return nil
        } catch {
            return nil
        }
    }

    func currentUserGivenName() async -> String? {
        do {
            let session = try await client.auth.session
            if session.isExpired { return nil }
            if case .string(let given)? = session.user.userMetadata["given_name"] {
                return given
            }
            return nil
        } catch {
            return nil
        }
    }

    func currentUserFamilyName() async -> String? {
        do {
            let session = try await client.auth.session
            if session.isExpired { return nil }
            if case .string(let family)? = session.user.userMetadata["family_name"] {
                return family
            }
            return nil
        } catch {
            return nil
        }
    }

    func currentUserProfileImageURL() async -> String? {
        do {
            let session = try await client.auth.session
            if session.isExpired { return nil }
            if let url = profileImageURL(from: session.user.userMetadata) { return url }
            let user = try await client.auth.user()
            return profileImageURL(from: user.userMetadata)
        } catch {
            return nil
        }
    }

    /// Reads profile image URL from metadata. Google uses "picture"; we also store "profile_image_url"; Apple does not provide one.
    private func profileImageURL(from metadata: [String: AnyJSON]) -> String? {
        let keys = ["profile_image_url", "picture", "avatar_url"]
        for key in keys {
            if case .string(let url)? = metadata[key], !url.isEmpty { return url }
        }
        return nil
    }

    /// Birthdate from provider metadata if present. Google does not return birthday by default; it may appear if custom scopes or People API are used.
    func currentUserBirthdate() async -> Date? {
        do {
            let session = try await client.auth.session
            if session.isExpired { return nil }
            if let date = parseBirthdate(from: session.user.userMetadata) { return date }
            let user = try await client.auth.user()
            return parseBirthdate(from: user.userMetadata)
        } catch {
            return nil
        }
    }

    func currentUserIdentityProvider() async -> String? {
        do {
            let session = try await client.auth.session
            if session.isExpired { return nil }
            if case .string(let provider)? = session.user.appMetadata["provider"] {
                return provider
            }
            return nil
        } catch {
            return nil
        }
    }

    private func parseBirthdate(from metadata: [String: AnyJSON]) -> Date? {
        let keys = ["birthdate", "birthday", "birth_date"]
        for key in keys {
            guard case .string(let value)? = metadata[key], !value.isEmpty else { continue }
            if let date = ISO8601DateFormatter().date(from: value) { return date }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: value) { return date }
            formatter.dateFormat = "MM/dd/yyyy"
            if let date = formatter.date(from: value) { return date }
        }
        return nil
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
            throw NSError(
                domain: "AuthError", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get identity token"])
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

    func signInWithGoogle() async throws {
        _ = try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: oAuthRedirectURL
        ) { (_: ASWebAuthenticationSession) in
            // Optional: customize ASWebAuthenticationSession (e.g. presentationContextProvider)
        }
    }

    func sessionFromRedirectURL(_ url: URL) async throws {
        guard url.scheme == oAuthRedirectScheme else { return }
        // Supabase returns tokens in the URL fragment: #access_token=...&refresh_token=...
        guard let fragment = url.fragment, !fragment.isEmpty else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing fragment in redirect URL"])
        }
        let params = parseFragment(fragment)
        guard let accessToken = params["access_token"], let refreshToken = params["refresh_token"] else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing access_token or refresh_token in redirect URL"])
        }
        try await client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
        let session = try await client.auth.session
        client.functions.setAuth(token: session.accessToken)
    }

    private func parseFragment(_ fragment: String) -> [String: String] {
        fragment.split(separator: "&").reduce(into: [String: String]()) { result, pair in
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                result[String(parts[0])] = String(parts[1]).removingPercentEncoding ?? String(parts[1])
            }
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Deletes the account via Edge Function (removes profile image, event images, events, RSVPs, then auth user), then signs out locally.
    func deleteAccount() async throws {
        let session = try await client.auth.session
        client.functions.setAuth(token: session.accessToken)
        try await client.functions.invoke("delete-account")
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

    func updateUserEmail(_ email: String) async throws {
        try await client.auth.update(user: UserAttributes(data: ["email": .string(email)]))
    }
}
