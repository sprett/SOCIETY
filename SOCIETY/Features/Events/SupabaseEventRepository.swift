//
//  SupabaseEventRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import CoreLocation
import Foundation
import Supabase

final class SupabaseEventRepository: EventRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchEvents() async throws -> [Event] {
        let rows: [EventDBRow] =
            try await client
            .from("events")
            .select()
            .order("start_at", ascending: true)
            .execute()
            .value

        let ownerProfiles = await fetchOwnerProfiles(for: rows)
        return rows.map { row in
            row.toDomain(ownerProfile: row.ownerID.flatMap { ownerProfiles[$0] })
        }
    }

    func fetchEvents(ids: [UUID]) async throws -> [Event] {
        guard !ids.isEmpty else { return [] }

        let idStrings = ids.map { $0.uuidString }
        let rows: [EventDBRow] =
            try await client
            .from("events")
            .select()
            .in("id", values: idStrings)
            .order("start_at", ascending: true)
            .execute()
            .value

        let ownerProfiles = await fetchOwnerProfiles(for: rows)
        return rows.map { row in
            row.toDomain(ownerProfile: row.ownerID.flatMap { ownerProfiles[$0] })
        }
    }

    func createEvent(_ draft: EventDraft) async throws -> Event {
        let insert = EventInsertRow(from: draft)

        let row: EventDBRow =
            try await client
            .from("events")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return row.toDomain()
    }

    func updateEventCover(eventID: UUID, imageURL: String) async throws {
        struct UpdateCover: Encodable {
            let imageURL: String
            enum CodingKeys: String, CodingKey { case imageURL = "image_url" }
        }
        _ =
            try await client
            .from("events")
            .update(UpdateCover(imageURL: imageURL))
            .eq("id", value: eventID.uuidString)
            .execute()
    }

    func deleteEvent(id: UUID) async throws {
        _ =
            try await client
            .from("events")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Fetches profiles for event owners so we can show organizer name (and avoid "Society" fallback).
    private func fetchOwnerProfiles(for rows: [EventDBRow]) async -> [UUID: (
        name: String, avatarURL: String?
    )] {
        let ownerIDs = Set(rows.compactMap { $0.ownerID })
        guard !ownerIDs.isEmpty else { return [:] }

        struct ProfileRow: Decodable {
            let id: UUID
            let fullName: String?
            let avatarUrl: String?
            enum CodingKeys: String, CodingKey {
                case id
                case fullName = "full_name"
                case avatarUrl = "avatar_url"
            }
        }

        let idStrings = ownerIDs.map { $0.uuidString }
        guard
            let profiles: [ProfileRow] =
                try? await client
                .from("profiles")
                .select("id, full_name, avatar_url")
                .in("id", values: idStrings)
                .execute()
                .value
        else { return [:] }

        return Dictionary(
            uniqueKeysWithValues: profiles.map { row in
                let name =
                    (row.fullName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap {
                        $0.isEmpty ? nil : $0
                    } ?? "Organizer"
                return (row.id, (name: name, avatarURL: row.avatarUrl))
            })
    }
}

private struct EventInsertRow: Encodable {
    let ownerID: UUID?
    let title: String
    let category: String
    let about: String?
    let startAt: Date
    let endAt: Date?
    let venueName: String
    let addressLine: String
    let neighborhood: String?
    let latitude: Double?
    let longitude: Double?
    let imageURL: String?
    let isFeatured: Bool
    let visibility: String

    init(from draft: EventDraft) {
        ownerID = draft.ownerID
        title = draft.title
        category = draft.category
        about = draft.about
        startAt = draft.startDate
        endAt = draft.endDate
        venueName = draft.venueName
        addressLine = draft.addressLine
        neighborhood = draft.neighborhood
        latitude = draft.latitude
        longitude = draft.longitude
        imageURL = draft.imageURL
        isFeatured = draft.isFeatured
        visibility = draft.visibility.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case ownerID = "owner_id"
        case title
        case category
        case about
        case startAt = "start_at"
        case endAt = "end_at"
        case venueName = "venue_name"
        case addressLine = "address_line"
        case neighborhood
        case latitude
        case longitude
        case imageURL = "image_url"
        case isFeatured = "is_featured"
        case visibility
    }
}

private struct EventDBRow: Decodable {
    let id: UUID
    let ownerID: UUID?
    let title: String
    let category: String
    let about: String?
    let startAt: Date
    let endAt: Date?
    let venueName: String?
    let addressLine: String
    let neighborhood: String?
    let latitude: Double?
    let longitude: Double?
    let imageURL: String?
    let isFeatured: Bool
    let visibility: String

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case title
        case category
        case about
        case startAt = "start_at"
        case endAt = "end_at"
        case venueName = "venue_name"
        case addressLine = "address_line"
        case neighborhood
        case latitude
        case longitude
        case imageURL = "image_url"
        case isFeatured = "is_featured"
        case visibility
    }

    func toDomain(ownerProfile: (name: String, avatarURL: String?)? = nil) -> Event {
        let sanitizedImageURL = (imageURL ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var hosts: [Host]?
        if let profile = ownerProfile, let oid = ownerID {
            let initials = String(profile.name.prefix(2)).uppercased()
            hosts = [
                Host(
                    id: oid,
                    name: profile.name,
                    avatarPlaceholder: initials.isEmpty ? "?" : initials,
                    profileImageURL: profile.avatarURL
                )
            ]
        }

        return Event(
            id: id,
            ownerID: ownerID,
            title: title,
            category: category,
            startDate: startAt,
            venueName: venueName ?? "",
            neighborhood: neighborhood ?? "",
            distanceKm: 0,
            imageNameOrURL: sanitizedImageURL,
            isFeatured: isFeatured,
            endDate: endAt,
            addressLine: addressLine,
            coordinate: {
                guard let lat = latitude, let lng = longitude else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }(),
            hosts: hosts,
            goingCount: nil,
            about: about
        )
    }
}
