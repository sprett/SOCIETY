//
//  EventCategory.swift
//  SOCIETY
//
//  DB-driven event category model (loaded from `event_categories` table).
//

import SwiftUI

struct EventCategory: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let iconIdentifier: String
    let accentColorHex: String?
    let displayOrder: Int

    /// Returns the accent color parsed from `accentColorHex`, falling back to `AppColors.color(for:)`.
    var accentColor: Color {
        if let hex = accentColorHex, let parsed = Color(hex: hex) {
            return parsed
        }
        return AppColors.color(for: name) ?? .gray
    }
}

// MARK: - Color + Hex Initializer

extension Color {
    /// Creates a Color from a hex string like "#FF5733" or "FF5733".
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

        guard hexSanitized.count == 6,
            let hexNumber = UInt64(hexSanitized, radix: 16)
        else { return nil }

        let r = Double((hexNumber & 0xFF0000) >> 16) / 255
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255
        let b = Double(hexNumber & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
