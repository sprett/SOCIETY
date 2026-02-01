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
        let rows: [EventDBRow] = try await client
            .from("events")
            .select()
            .order("start_at", ascending: true)
            .execute()
            .value

        return rows.map { $0.toDomain() }
    }

    func createEvent(_ draft: EventDraft) async throws -> Event {
        let insert = EventInsertRow(from: draft)

        let row: EventDBRow = try await client
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
        _ = try await client
            .from("events")
            .update(UpdateCover(imageURL: imageURL))
            .eq("id", value: eventID.uuidString)
            .execute()
    }

    func deleteEvent(id: UUID) async throws {
        _ = try await client
            .from("events")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
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

    func toDomain() -> Event {
        let sanitizedImageURL = (imageURL ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

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
            hosts: nil,
            goingCount: nil,
            about: about
        )
    }
}

