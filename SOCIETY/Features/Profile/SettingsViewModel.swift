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
    @Published private(set) var cacheSize: String = "Calculating..."

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
    
    func loadCacheSize() async {
        let bytes = await DiskCacheManager.shared.calculateCacheSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        await MainActor.run {
            cacheSize = formatter.string(fromByteCount: bytes)
        }
    }
    
    func clearImageCache() async {
        // Clear in-memory cache
        await ImageCache.shared.clearAll()
        
        // Clear only image disk cache (not all URL cache which includes API responses)
        await DiskCacheManager.shared.clearAllImageCache()
        
        // Update the displayed size
        await loadCacheSize()
    }
}
