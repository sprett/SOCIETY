//
//  EventModels.swift
//  SOCIETY
//

import CoreLocation
import Foundation

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

extension Event {
    /// Builds an Event from a draft for local-only create (no backend).
    static func from(draft: EventDraft) -> Event {
        let coordinate: CLLocationCoordinate2D? = {
            guard let lat = draft.latitude, let lng = draft.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }()
        return Event(
            id: UUID(),
            ownerID: draft.ownerID,
            title: draft.title,
            category: draft.category,
            startDate: draft.startDate,
            venueName: draft.venueName,
            neighborhood: draft.neighborhood ?? "",
            distanceKm: 0,
            imageNameOrURL: draft.imageURL ?? "",
            isFeatured: draft.isFeatured,
            endDate: draft.endDate,
            addressLine: draft.addressLine.isEmpty ? nil : draft.addressLine,
            coordinate: coordinate,
            hosts: nil,
            goingCount: nil,
            about: draft.about
        )
    }
}
