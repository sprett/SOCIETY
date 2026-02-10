//
//  UserDefaultsNotificationSettingsRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Foundation

/// Stores notification preferences in UserDefaults keyed by user ID. Replace with a backend implementation when needed.
final class UserDefaultsNotificationSettingsRepository: NotificationSettingsRepository {
    private let defaults: UserDefaults
    private static func key(for userID: UUID) -> String {
        "notification_settings_\(userID.uuidString)"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSettings(for userID: UUID) async throws -> NotificationSettings {
        guard let data = defaults.data(forKey: Self.key(for: userID)),
              let decoded = try? JSONDecoder().decode(NotificationSettingsCodable.self, from: data)
        else {
            return .default
        }
        return decoded.toSettings()
    }

    func updateSettings(_ settings: NotificationSettings, for userID: UUID) async throws {
        let codable = NotificationSettingsCodable(from: settings)
        let data = try JSONEncoder().encode(codable)
        defaults.set(data, forKey: Self.key(for: userID))
    }
}

private struct NotificationSettingsCodable: Codable {
    let emailMarketingEnabled: Bool
    let pushEventRemindersEnabled: Bool
    let pushHostUpdatesEnabled: Bool

    init(from s: NotificationSettings) {
        emailMarketingEnabled = s.emailMarketingEnabled
        pushEventRemindersEnabled = s.pushEventRemindersEnabled
        pushHostUpdatesEnabled = s.pushHostUpdatesEnabled
    }

    func toSettings() -> NotificationSettings {
        NotificationSettings(
            emailMarketingEnabled: emailMarketingEnabled,
            pushEventRemindersEnabled: pushEventRemindersEnabled,
            pushHostUpdatesEnabled: pushHostUpdatesEnabled
        )
    }
}
