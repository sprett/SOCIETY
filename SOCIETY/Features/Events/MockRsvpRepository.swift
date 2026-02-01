//
//  MockRsvpRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 01/02/2026.
//

import Foundation

final class MockRsvpRepository: RsvpRepository {
    // In-memory storage: Set of (eventId, userId) tuples
    private var rsvps: Set<RSVPKey> = []

    private struct RSVPKey: Hashable {
        let eventId: UUID
        let userId: UUID
    }

    func addRsvp(eventId: UUID, userId: UUID) async throws {
        rsvps.insert(RSVPKey(eventId: eventId, userId: userId))
    }

    func removeRsvp(eventId: UUID, userId: UUID) async throws {
        rsvps.remove(RSVPKey(eventId: eventId, userId: userId))
    }

    func fetchEventIdsAttending(userId: UUID) async throws -> [UUID] {
        return
            rsvps
            .filter { $0.userId == userId }
            .map { $0.eventId }
    }

    func fetchAttendees(eventId: UUID) async throws -> [Attendee] {
        // Return empty list for mock - can be extended with seeded data if needed
        return []
    }

    func isAttending(eventId: UUID, userId: UUID) async throws -> Bool {
        return rsvps.contains(RSVPKey(eventId: eventId, userId: userId))
    }
}
