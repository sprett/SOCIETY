//
//  RsvpRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 01/02/2026.
//

import Foundation

protocol RsvpRepository {
    func addRsvp(eventId: UUID, userId: UUID) async throws
    func removeRsvp(eventId: UUID, userId: UUID) async throws
    func fetchEventIdsAttending(userId: UUID) async throws -> [UUID]
    func fetchAttendees(eventId: UUID) async throws -> [Attendee]
    func isAttending(eventId: UUID, userId: UUID) async throws -> Bool
}
