//
//  EventCategories.swift
//  SOCIETY
//
//  Single source of truth for event categories (create + discover).
//

import Foundation

enum EventCategories {
    /// Static fallback list of categories. The canonical source is the `event_categories` DB table.
    /// This list is used when the DB is unreachable or as a local reference.
    static let all: [String] = [
        "Music",
        "Tech",
        "Food & Drinks",
        "Fitness",
        "Nature & Outdoors",
        "Arts & Culture",
        "Education",
        "Personal Growth",
        "Climate & Sustainability",
        "Social & Community",
        "Business & Networking",
        "Gaming",
        "Film",
        "Culture",
        "Family & Lifestyle",
    ]

    private static let icons: [String: String] = [
        "Music": "music.note",
        "Tech": "desktopcomputer",
        "Food & Drinks": "fork.knife",
        "Fitness": "figure.run",
        "Nature & Outdoors": "leaf.fill",
        "Arts & Culture": "paintpalette.fill",
        "Education": "book.fill",
        "Personal Growth": "brain.head.profile",
        "Climate & Sustainability": "leaf.circle.fill",
        "Social & Community": "person.3.fill",
        "Business & Networking": "briefcase.fill",
        "Gaming": "gamecontroller.fill",
        "Film": "film",
        "Culture": "theatermasks.fill",
        "Family & Lifestyle": "house.fill",
        // Legacy names kept for backward compat with older events
        "AI": "brain.head.profile",
        "Business": "briefcase.fill",
        "Networking": "person.2.fill",
        "Wellness": "leaf.circle.fill",
        "Art": "paintpalette.fill",
        "Food": "fork.knife",
        "Social": "person.3.fill",
    ]

    static func icon(for category: String) -> String {
        icons[category] ?? "sparkles"
    }
}
