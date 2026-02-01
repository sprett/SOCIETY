//
//  EventRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 19/01/2026.
//

import Foundation

protocol EventRepository {
    func fetchEvents() async throws -> [Event]
    func createEvent(_ draft: EventDraft) async throws -> Event
    func updateEventCover(eventID: UUID, imageURL: String) async throws
    func deleteEvent(id: UUID) async throws
}

struct EventDraft: Hashable {
    let ownerID: UUID?
    let title: String
    let category: String
    let startDate: Date
    let endDate: Date?
    let venueName: String
    let addressLine: String
    let neighborhood: String?
    let latitude: Double?
    let longitude: Double?
    let imageURL: String?
    let about: String?
    let isFeatured: Bool
    let visibility: EventVisibility
}

enum EventVisibility: String, Hashable {
    case `public` = "public"
    case `private` = "private"
}
