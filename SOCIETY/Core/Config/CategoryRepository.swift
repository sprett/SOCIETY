//
//  CategoryRepository.swift
//  SOCIETY
//
//  Protocol for loading DB-driven categories and saving user interests.
//

import Foundation

protocol CategoryRepository {
    /// Fetches all event categories, ordered by `display_order`.
    func fetchCategories() async throws -> [EventCategory]

    /// Fetches the category IDs the user has selected as interests.
    func fetchUserInterests(userId: UUID) async throws -> Set<UUID>

    /// Replaces all of a user's interests with the given category IDs.
    func saveUserInterests(userId: UUID, categoryIds: [UUID]) async throws
}

// MARK: - Mock for Previews & Tests

final class MockCategoryRepository: CategoryRepository {
    func fetchCategories() async throws -> [EventCategory] {
        [
            EventCategory(id: UUID(), name: "Music", iconIdentifier: "music.note", accentColorHex: "#E040FB", displayOrder: 1),
            EventCategory(id: UUID(), name: "Tech", iconIdentifier: "desktopcomputer", accentColorHex: "#FFD600", displayOrder: 2),
            EventCategory(id: UUID(), name: "Food & Drinks", iconIdentifier: "fork.knife", accentColorHex: "#FFB300", displayOrder: 3),
            EventCategory(id: UUID(), name: "Fitness", iconIdentifier: "figure.run", accentColorHex: "#FF7043", displayOrder: 4),
            EventCategory(id: UUID(), name: "Nature & Outdoors", iconIdentifier: "leaf.fill", accentColorHex: "#66BB6A", displayOrder: 5),
            EventCategory(id: UUID(), name: "Arts & Culture", iconIdentifier: "paintpalette.fill", accentColorHex: "#CE93D8", displayOrder: 6),
            EventCategory(id: UUID(), name: "Education", iconIdentifier: "book.fill", accentColorHex: "#42A5F5", displayOrder: 7),
            EventCategory(id: UUID(), name: "Personal Growth", iconIdentifier: "brain.head.profile", accentColorHex: "#AB47BC", displayOrder: 8),
            EventCategory(id: UUID(), name: "Climate & Sustainability", iconIdentifier: "leaf.circle.fill", accentColorHex: "#4CAF50", displayOrder: 9),
            EventCategory(id: UUID(), name: "Social & Community", iconIdentifier: "person.3.fill", accentColorHex: "#26C6DA", displayOrder: 10),
            EventCategory(id: UUID(), name: "Business & Networking", iconIdentifier: "briefcase.fill", accentColorHex: "#78909C", displayOrder: 11),
            EventCategory(id: UUID(), name: "Gaming", iconIdentifier: "gamecontroller.fill", accentColorHex: "#7C4DFF", displayOrder: 12),
            EventCategory(id: UUID(), name: "Film", iconIdentifier: "film", accentColorHex: "#FDD835", displayOrder: 13),
            EventCategory(id: UUID(), name: "Culture", iconIdentifier: "theatermasks.fill", accentColorHex: "#EC407A", displayOrder: 14),
            EventCategory(id: UUID(), name: "Family & Lifestyle", iconIdentifier: "house.fill", accentColorHex: "#FFA726", displayOrder: 15),
        ]
    }

    func fetchUserInterests(userId: UUID) async throws -> Set<UUID> {
        []
    }

    func saveUserInterests(userId: UUID, categoryIds: [UUID]) async throws {
        // no-op in previews
    }
}
