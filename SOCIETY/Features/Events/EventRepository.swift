//
//  EventRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 19/01/2026.
//

import Foundation

protocol EventRepository {
    func fetchEvents() async throws -> [Event]
    func fetchEvents(ids: [UUID]) async throws -> [Event]
    func createEvent(_ draft: EventDraft) async throws -> Event
    func updateEventCover(eventID: UUID, imageURL: String) async throws
    func deleteEvent(id: UUID) async throws
}
