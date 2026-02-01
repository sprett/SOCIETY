//
//  SettingsViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var showSignOutConfirmation: Bool = false

    var userName: String { authSession.userName ?? "" }
    var userEmail: String { authSession.userEmail ?? "" }
    var profileImageURL: String? { authSession.profileImageURL }

    private let authSession: AuthSessionStore

    init(authSession: AuthSessionStore) {
        self.authSession = authSession
    }

    func signOut() async throws {
        try await authSession.signOut()
    }
}
