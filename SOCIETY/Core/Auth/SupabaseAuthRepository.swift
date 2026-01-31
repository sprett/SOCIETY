//
//  SupabaseAuthRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import Foundation
import Supabase

final class SupabaseAuthRepository: AuthRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func currentUserID() async -> UUID? {
        // `session` throws if there's no session; treat as signed out.
        do {
            let session = try await client.auth.session
            return session.user.id
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

    func signOut() async throws {
        try await client.auth.signOut()
    }
}

