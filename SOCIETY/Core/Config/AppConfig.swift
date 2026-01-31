//
//  AppConfig.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import Foundation

enum AppConfigError: Error, LocalizedError {
    case missingInfoPlistKey(String)
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .missingInfoPlistKey(let key):
            return "Missing Info.plist key: \(key)"
        case .invalidURL(let raw):
            return "Invalid URL: \(raw)"
        }
    }
}

struct AppConfig {
    let supabaseURL: URL
    let supabaseAnonKey: String

    static func load(bundle: Bundle = .main) throws -> AppConfig {
        let urlRaw = try bundle.requiredString(forInfoPlistKey: "SUPABASE_URL")
        guard let url = URL(string: urlRaw) else { throw AppConfigError.invalidURL(urlRaw) }

        let anonKey = try bundle.requiredString(forInfoPlistKey: "SUPABASE_ANON_KEY")

        return AppConfig(supabaseURL: url, supabaseAnonKey: anonKey)
    }
}

private extension Bundle {
    func requiredString(forInfoPlistKey key: String) throws -> String {
        guard let raw = object(forInfoDictionaryKey: key) as? String, !raw.isEmpty else {
            throw AppConfigError.missingInfoPlistKey(key)
        }
        return raw
    }
}

