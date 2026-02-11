//
//  SupabaseCategoryRepository.swift
//  SOCIETY
//
//  Supabase-backed implementation of CategoryRepository.
//

import Foundation
import Supabase

final class SupabaseCategoryRepository: CategoryRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Fetch categories

    func fetchCategories() async throws -> [EventCategory] {
        let rows: [CategoryRow] = try await client
            .from("event_categories")
            .select()
            .order("display_order", ascending: true)
            .execute()
            .value

        return rows.map { $0.toDomain() }
    }

    // MARK: - Fetch user interests

    func fetchUserInterests(userId: UUID) async throws -> Set<UUID> {
        let rows: [InterestRow] = try await client
            .from("profile_interests")
            .select("category_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return Set(rows.map(\.categoryId))
    }

    // MARK: - Save user interests (replace all)

    func saveUserInterests(userId: UUID, categoryIds: [UUID]) async throws {
        // Delete existing interests for this user
        try await client
            .from("profile_interests")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Insert new interests
        guard !categoryIds.isEmpty else { return }

        let inserts = categoryIds.map { InterestInsertRow(userId: userId, categoryId: $0) }
        try await client
            .from("profile_interests")
            .insert(inserts)
            .execute()
    }
}

// MARK: - DB Row Types

private struct CategoryRow: Decodable {
    let id: UUID
    let name: String
    let iconIdentifier: String
    let accentColorHex: String?
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconIdentifier = "icon_identifier"
        case accentColorHex = "accent_color_hex"
        case displayOrder = "display_order"
    }

    func toDomain() -> EventCategory {
        EventCategory(
            id: id,
            name: name,
            iconIdentifier: iconIdentifier,
            accentColorHex: accentColorHex,
            displayOrder: displayOrder
        )
    }
}

private struct InterestRow: Decodable {
    let categoryId: UUID

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
    }
}

private struct InterestInsertRow: Encodable {
    let userId: UUID
    let categoryId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case categoryId = "category_id"
    }
}
