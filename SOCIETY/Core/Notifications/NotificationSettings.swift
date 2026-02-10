//
//  NotificationSettings.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Foundation

struct NotificationSettings: Equatable {
    var emailMarketingEnabled: Bool
    var pushEventRemindersEnabled: Bool
    var pushHostUpdatesEnabled: Bool

    static let `default` = NotificationSettings(
        emailMarketingEnabled: true,
        pushEventRemindersEnabled: true,
        pushHostUpdatesEnabled: true
    )
}
