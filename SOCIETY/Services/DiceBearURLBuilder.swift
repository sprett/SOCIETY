//
//  DiceBearURLBuilder.swift
//  SOCIETY
//

import Foundation

/// Builds DiceBear URLs in one place so avatar styles can be swapped later with minimal code changes.
enum DiceBearURLBuilder {
    static let apiVersion = "9.x"
    static let notionistsStyle = "notionists"

    /// Builds a DiceBear Notionists PNG URL.
    /// - Note: PNG output from DiceBear is rate/size limited, so we request 256 and upscale to 512 for storage.
    static func notionistsPNG(seed: String, size: Int = 256) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.dicebear.com"
        components.path = "/\(apiVersion)/\(notionistsStyle)/png"
        components.queryItems = [
            URLQueryItem(name: "seed", value: seed),
            URLQueryItem(name: "size", value: String(size))
        ]

        guard let url = components.url else {
            preconditionFailure("Failed to build DiceBear URL")
        }

        return url
    }
}
