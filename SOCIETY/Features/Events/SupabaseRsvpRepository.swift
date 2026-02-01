//
//  SupabaseRsvpRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 01/02/2026.
//

import Foundation
import Supabase

final class SupabaseRsvpRepository: RsvpRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func addRsvp(eventId: UUID, userId: UUID) async throws {
        struct RsvpInsert: Encodable {
            let eventId: UUID
            let userId: UUID

            enum CodingKeys: String, CodingKey {
                case eventId = "event_id"
                case userId = "user_id"
            }
        }

        _ =
            try await client
            .from("event_rsvps")
            .insert(RsvpInsert(eventId: eventId, userId: userId))
            .execute()
    }

    func removeRsvp(eventId: UUID, userId: UUID) async throws {
        _ =
            try await client
            .from("event_rsvps")
            .delete()
            .eq("event_id", value: eventId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func fetchEventIdsAttending(userId: UUID) async throws -> [UUID] {
        struct RsvpRow: Decodable {
            let eventId: UUID

            enum CodingKeys: String, CodingKey {
                case eventId = "event_id"
            }
        }

        let rows: [RsvpRow] =
            try await client
            .from("event_rsvps")
            .select("event_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return rows.map { $0.eventId }
    }

    func fetchAttendees(eventId: UUID) async throws -> [Attendee] {
        struct AttendeeRow: Decodable {
            let userId: UUID
            let profile: ProfileRow?

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case profile = "profiles"
            }

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
        }

        let rows: [AttendeeRow] =
            try await client
            .from("event_rsvps")
            .select("user_id, profiles(id, full_name, avatar_url)")
            .eq("event_id", value: eventId.uuidString)
            .execute()
            .value

        return rows.map { row in
            Attendee(
                id: row.userId,
                name: row.profile?.fullName,
                avatarURL: row.profile?.avatarUrl
            )
        }
    }

    func isAttending(eventId: UUID, userId: UUID) async throws -> Bool {
        struct RsvpRow: Decodable {
            let id: UUID
        }

        let rows: [RsvpRow] =
            try await client
            .from("event_rsvps")
            .select("id")
            .eq("event_id", value: eventId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return !rows.isEmpty
    }
}
