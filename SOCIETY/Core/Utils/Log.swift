//
//  Log.swift
//  SOCIETY
//

import Foundation
import OSLog

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "dinoh.society"

    nonisolated static let auth = Logger(subsystem: subsystem, category: "auth")
    nonisolated static let cache = Logger(subsystem: subsystem, category: "cache")
    nonisolated static let image = Logger(subsystem: subsystem, category: "image")
    nonisolated static let event = Logger(subsystem: subsystem, category: "event")
    nonisolated static let network = Logger(subsystem: subsystem, category: "network")
    nonisolated static let ui = Logger(subsystem: subsystem, category: "ui")
}
