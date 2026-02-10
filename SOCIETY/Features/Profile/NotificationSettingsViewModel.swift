//
//  NotificationSettingsViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Combine
import SwiftUI

@MainActor
final class NotificationSettingsViewModel: ObservableObject {
    @Published var emailMarketingEnabled: Bool = true
    @Published var pushEventRemindersEnabled: Bool = true
    @Published var pushHostUpdatesEnabled: Bool = true
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    private let authSession: AuthSessionStore
    private let notificationSettingsRepository: any NotificationSettingsRepository

    init(
        authSession: AuthSessionStore,
        notificationSettingsRepository: any NotificationSettingsRepository
    ) {
        self.authSession = authSession
        self.notificationSettingsRepository = notificationSettingsRepository
    }

    func load() async {
        guard let userID = authSession.userID else { return }
        isLoading = true
        errorMessage = nil
        do {
            let settings = try await notificationSettingsRepository.loadSettings(for: userID)
            emailMarketingEnabled = settings.emailMarketingEnabled
            pushEventRemindersEnabled = settings.pushEventRemindersEnabled
            pushHostUpdatesEnabled = settings.pushHostUpdatesEnabled
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func save() async {
        guard let userID = authSession.userID else { return }
        isSaving = true
        errorMessage = nil
        let settings = NotificationSettings(
            emailMarketingEnabled: emailMarketingEnabled,
            pushEventRemindersEnabled: pushEventRemindersEnabled,
            pushHostUpdatesEnabled: pushHostUpdatesEnabled
        )
        do {
            try await notificationSettingsRepository.updateSettings(settings, for: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
