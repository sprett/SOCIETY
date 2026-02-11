//
//  NotificationSettingsRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Foundation

protocol NotificationSettingsRepository {
    func loadSettings(for userID: UUID) async throws -> NotificationSettings
    func updateSettings(_ settings: NotificationSettings, for userID: UUID) async throws
}

/// Mock for previews and tests.
final class MockNotificationSettingsRepository: NotificationSettingsRepository {
    var stubSettings: NotificationSettings = .default

    func loadSettings(for userID: UUID) async throws -> NotificationSettings {
        stubSettings
    }

    func updateSettings(_ settings: NotificationSettings, for userID: UUID) async throws {
        stubSettings = settings
    }
}
