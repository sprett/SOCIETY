//
//  EventCategories.swift
//  SOCIETY
//
//  Single source of truth for event categories (create + discover).
//

import Foundation

enum EventCategories {
    /// All categories available when creating an event. Shown in Browse by Category and create picker.
    static let all: [String] = [
        "AI",
        "Tech",
        "Business",
        "Networking",
        "Fitness",
        "Wellness",
        "Music",
        "Art",
        "Food",
        "Social",
    ]

    private static let icons: [String: String] = [
        "AI": "brain.head.profile",
        "Tech": "bolt.fill",
        "Business": "briefcase.fill",
        "Networking": "person.2.fill",
        "Fitness": "figure.run",
        "Wellness": "leaf.circle.fill",
        "Music": "music.note",
        "Art": "paintpalette.fill",
        "Food": "fork.knife",
        "Social": "person.3.fill",
    ]

    static func icon(for category: String) -> String {
        icons[category] ?? "sparkles"
    }
}
