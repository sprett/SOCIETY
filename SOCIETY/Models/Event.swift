//
//  Event.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import CoreLocation
import Foundation

struct Host: Identifiable, Hashable {
    let id: UUID
    let name: String
    let avatarPlaceholder: String
    /// When set, show this URL as the host's profile image instead of initials.
    let profileImageURL: String?

    init(id: UUID, name: String, avatarPlaceholder: String, profileImageURL: String? = nil) {
        self.id = id
        self.name = name
        self.avatarPlaceholder = avatarPlaceholder
        self.profileImageURL = profileImageURL
    }
}

struct Event: Identifiable, Hashable {
    let id: UUID
    /// Supabase auth user ID of the event creator; nil for mock or legacy data.
    let ownerID: UUID?
    let title: String
    let category: String
    let startDate: Date
    let venueName: String
    let neighborhood: String
    let distanceKm: Double
    let imageNameOrURL: String
    let isFeatured: Bool

    // Optional fields for Event Details sheet
    let endDate: Date?
    let addressLine: String?
    let coordinate: CLLocationCoordinate2D?
    let hosts: [Host]?
    let goingCount: Int?
    let about: String?

    init(
        id: UUID,
        ownerID: UUID? = nil,
        title: String,
        category: String,
        startDate: Date,
        venueName: String,
        neighborhood: String,
        distanceKm: Double,
        imageNameOrURL: String,
        isFeatured: Bool,
        endDate: Date? = nil,
        addressLine: String? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        hosts: [Host]? = nil,
        goingCount: Int? = nil,
        about: String? = nil
    ) {
        self.id = id
        self.ownerID = ownerID
        self.title = title
        self.category = category
        self.startDate = startDate
        self.venueName = venueName
        self.neighborhood = neighborhood
        self.distanceKm = distanceKm
        self.imageNameOrURL = imageNameOrURL
        self.isFeatured = isFeatured
        self.endDate = endDate
        self.addressLine = addressLine
        self.coordinate = coordinate
        self.hosts = hosts
        self.goingCount = goingCount
        self.about = about
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(ownerID)
        hasher.combine(title)
        hasher.combine(category)
        hasher.combine(startDate)
        hasher.combine(venueName)
        hasher.combine(neighborhood)
        hasher.combine(distanceKm)
        hasher.combine(imageNameOrURL)
        hasher.combine(isFeatured)
        hasher.combine(endDate)
        hasher.combine(addressLine)
        if let coordinate = coordinate {
            hasher.combine(coordinate.latitude)
            hasher.combine(coordinate.longitude)
        }
        hasher.combine(hosts)
        hasher.combine(goingCount)
        hasher.combine(about)
    }

    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id && lhs.ownerID == rhs.ownerID && lhs.title == rhs.title
            && lhs.category == rhs.category && lhs.startDate == rhs.startDate
            && lhs.venueName == rhs.venueName && lhs.neighborhood == rhs.neighborhood
            && lhs.distanceKm == rhs.distanceKm && lhs.imageNameOrURL == rhs.imageNameOrURL
            && lhs.isFeatured == rhs.isFeatured && lhs.endDate == rhs.endDate
            && lhs.addressLine == rhs.addressLine
            && lhs.coordinate?.latitude == rhs.coordinate?.latitude
            && lhs.coordinate?.longitude == rhs.coordinate?.longitude && lhs.hosts == rhs.hosts
            && lhs.goingCount == rhs.goingCount && lhs.about == rhs.about
    }
}
