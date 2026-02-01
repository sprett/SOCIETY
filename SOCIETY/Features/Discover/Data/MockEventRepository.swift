//
//  MockEventRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 16/01/2026.
//

import CoreLocation
import Foundation

final class MockEventRepository: EventRepository {
    func fetchEvents() async throws -> [Event] {
        let calendar = Calendar.current
        let now = Date()

        return [
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Nordic AI Night",
                category: "AI",
                startDate: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
                venueName: "Mesh Oslo",
                neighborhood: "Sentrum",
                distanceKm: 1.2,
                imageNameOrURL: "gradient-1",
                isFeatured: true,
                endDate: calendar.date(
                    byAdding: .hour, value: 2,
                    to: calendar.date(byAdding: .day, value: 1, to: now) ?? now),
                addressLine: "Tordenskiolds gate 2, 0160 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7461),
                hosts: [
                    Host(id: UUID(), name: "Candyce Costa", avatarPlaceholder: "CC"),
                    Host(id: UUID(), name: "Dylan Nguyen", avatarPlaceholder: "DN"),
                ],
                goingCount: 75,
                about:
                    "A relaxed meetup for AI builders in Oslo. Short talks, good conversations, and a low-pressure way to meet new people working on AI products."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Fjordside Fitness",
                category: "Fitness",
                startDate: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                venueName: "Aker Brygge",
                neighborhood: "Vika",
                distanceKm: 2.4,
                imageNameOrURL: "gradient-2",
                isFeatured: true,
                endDate: calendar.date(
                    byAdding: .hour, value: 1,
                    to: calendar.date(byAdding: .day, value: 2, to: now) ?? now),
                addressLine: "Aker Brygge, 0250 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9112, longitude: 10.7267),
                hosts: [
                    Host(id: UUID(), name: "Sofia Berg", avatarPlaceholder: "SB")
                ],
                goingCount: 42,
                about:
                    "Outdoor interval session by the water. Bring shoes, a light jacket, and your best energy. All levels welcome."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Oslo Climate Salon",
                category: "Climate",
                startDate: calendar.date(byAdding: .day, value: 3, to: now) ?? now,
                venueName: "DogA",
                neighborhood: "Torggata",
                distanceKm: 1.8,
                imageNameOrURL: "gradient-3",
                isFeatured: true,
                endDate: calendar.date(
                    byAdding: .hour, value: 2,
                    to: calendar.date(byAdding: .day, value: 3, to: now) ?? now),
                addressLine: "Hausmanns gate 16, 0182 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9145, longitude: 10.7572),
                hosts: [
                    Host(id: UUID(), name: "Amina El-Sayed", avatarPlaceholder: "AE"),
                    Host(id: UUID(), name: "Jonas Nilsen", avatarPlaceholder: "JN"),
                ],
                goingCount: 58,
                about:
                    "An intimate salon for climate tech founders, investors, and builders. Two short lightning talks, then open discussion."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Tech Founders Mixer",
                category: "Tech",
                startDate: calendar.date(byAdding: .day, value: 4, to: now) ?? now,
                venueName: "Startuplab",
                neighborhood: "Gaustad",
                distanceKm: 4.7,
                imageNameOrURL: "gradient-4",
                isFeatured: false,
                endDate: calendar.date(
                    byAdding: .hour, value: 2,
                    to: calendar.date(byAdding: .day, value: 4, to: now) ?? now),
                addressLine: "Gaustadalléen 21, 0349 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9488, longitude: 10.7176),
                hosts: [
                    Host(id: UUID(), name: "Ola Hansen", avatarPlaceholder: "OH")
                ],
                goingCount: 90,
                about:
                    "Meet other founders and operators for an informal evening. Quick intros, then free-flow networking."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Nordic Design Talk",
                category: "Arts & Culture",
                startDate: calendar.date(byAdding: .day, value: 5, to: now) ?? now,
                venueName: "Kulturhuset",
                neighborhood: "Youngstorget",
                distanceKm: 1.0,
                imageNameOrURL: "gradient-5",
                isFeatured: false,
                endDate: calendar.date(
                    byAdding: .hour, value: 2,
                    to: calendar.date(byAdding: .day, value: 5, to: now) ?? now),
                addressLine: "Youngs gate 6, 0181 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9149, longitude: 10.7503),
                hosts: [
                    Host(id: UUID(), name: "Maja Lund", avatarPlaceholder: "ML")
                ],
                goingCount: 36,
                about:
                    "A talk on modern Nordic design systems—what scales, what breaks, and how to keep craft as teams grow."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Sourdough & Stories",
                category: "Food & Drink",
                startDate: calendar.date(byAdding: .day, value: 6, to: now) ?? now,
                venueName: "Mathallen",
                neighborhood: "Grünerløkka",
                distanceKm: 3.2,
                imageNameOrURL:
                    "https://images.unsplash.com/photo-1592753054398-9fa298d40e85?q=80&w=1665&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
                isFeatured: false,
                endDate: calendar.date(
                    byAdding: .hour, value: 2,
                    to: calendar.date(byAdding: .day, value: 6, to: now) ?? now),
                addressLine: "Vulkan 5, 0178 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9226, longitude: 10.7527),
                hosts: [
                    Host(id: UUID(), name: "Elin Strand", avatarPlaceholder: "ES")
                ],
                goingCount: 28,
                about:
                    "A cozy evening of bread tasting and short stories. Come for the crust, stay for the conversation."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Wellness Wind Down",
                category: "Wellness",
                startDate: calendar.date(byAdding: .day, value: 7, to: now) ?? now,
                venueName: "The Well Studio",
                neighborhood: "Majorstuen",
                distanceKm: 3.9,
                imageNameOrURL: "gradient-7",
                isFeatured: true,
                endDate: calendar.date(
                    byAdding: .hour, value: 1,
                    to: calendar.date(byAdding: .day, value: 7, to: now) ?? now),
                addressLine: "Bogstadveien 41, 0366 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9294, longitude: 10.7144),
                hosts: [
                    Host(id: UUID(), name: "Noah Kim", avatarPlaceholder: "NK")
                ],
                goingCount: 18,
                about:
                    "A calm evening session with breathwork and light stretching. Perfect after a long day."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "AI Product Lab",
                category: "AI",
                startDate: calendar.date(byAdding: .day, value: 8, to: now) ?? now,
                venueName: "Oslo Science Park",
                neighborhood: "Blindern",
                distanceKm: 5.1,
                imageNameOrURL: "gradient-8",
                isFeatured: false,
                endDate: calendar.date(
                    byAdding: .hour, value: 2,
                    to: calendar.date(byAdding: .day, value: 8, to: now) ?? now),
                addressLine: "Gaustadalléen 23B, 0373 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9468, longitude: 10.7149),
                hosts: [
                    Host(id: UUID(), name: "Priya Shah", avatarPlaceholder: "PS")
                ],
                goingCount: 52,
                about:
                    "Hands-on lab for shipping AI features: prompt design, evaluation, and product UX. Bring a laptop and a problem."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "City Night Run",
                category: "Fitness",
                startDate: calendar.date(byAdding: .day, value: 9, to: now) ?? now,
                venueName: "Sognsvann",
                neighborhood: "Sognsvann",
                distanceKm: 6.8,
                imageNameOrURL: "gradient-9",
                isFeatured: false,
                endDate: calendar.date(
                    byAdding: .hour, value: 1,
                    to: calendar.date(byAdding: .day, value: 9, to: now) ?? now),
                addressLine: "Sognsvann, 0855 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9701, longitude: 10.6696),
                hosts: [
                    Host(id: UUID(), name: "Lukas Østby", avatarPlaceholder: "LØ")
                ],
                goingCount: 64,
                about: "A social night run around the lake. Headlamps optional, vibes mandatory."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Climate Tech Demo Day",
                category: "Climate",
                startDate: calendar.date(byAdding: .day, value: 10, to: now) ?? now,
                venueName: "Nydalen Factory",
                neighborhood: "Nydalen",
                distanceKm: 5.4,
                imageNameOrURL: "gradient-10",
                isFeatured: true,
                endDate: calendar.date(
                    byAdding: .hour, value: 2,
                    to: calendar.date(byAdding: .day, value: 10, to: now) ?? now),
                addressLine: "Nydalsveien 30, 0484 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9471, longitude: 10.7681),
                hosts: [
                    Host(id: UUID(), name: "Ingrid Moen", avatarPlaceholder: "IM"),
                    Host(id: UUID(), name: "Samir Patel", avatarPlaceholder: "SP"),
                ],
                goingCount: 120,
                about:
                    "Pitch-style demo day featuring early-stage climate tech startups. Come meet the teams and see what they're building."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Midnight Jazz Session",
                category: "Arts & Culture",
                startDate: calendar.date(byAdding: .day, value: 11, to: now) ?? now,
                venueName: "Blå",
                neighborhood: "Brennabekk",
                distanceKm: 2.6,
                imageNameOrURL: "gradient-11",
                isFeatured: false,
                endDate: calendar.date(
                    byAdding: .hour, value: 3,
                    to: calendar.date(byAdding: .day, value: 11, to: now) ?? now),
                addressLine: "Brenneriveien 9C, 0182 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9192, longitude: 10.7595),
                hosts: [
                    Host(id: UUID(), name: "Kari Johansen", avatarPlaceholder: "KJ")
                ],
                goingCount: 84,
                about:
                    "Late-night jazz with rotating musicians. Doors open early—arrive for a good spot."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Oslo Food Crawl",
                category: "Food & Drink",
                startDate: calendar.date(byAdding: .day, value: 12, to: now) ?? now,
                venueName: "Grünerløkka",
                neighborhood: "Grünerløkka",
                distanceKm: 3.0,
                imageNameOrURL: "gradient-12",
                isFeatured: false,
                endDate: calendar.date(
                    byAdding: .hour, value: 2,
                    to: calendar.date(byAdding: .day, value: 12, to: now) ?? now),
                addressLine: "Thorvald Meyers gate 33, 0555 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9234, longitude: 10.7592),
                hosts: [
                    Host(id: UUID(), name: "Marco Rossi", avatarPlaceholder: "MR")
                ],
                goingCount: 33,
                about:
                    "A guided stroll through Grünerløkka’s best bites. We’ll stop at 3–4 spots and keep it moving."
            ),
            Event(
                id: UUID(),
                ownerID: nil,
                title: "Mindful Morning",
                category: "Wellness",
                startDate: calendar.date(byAdding: .day, value: 13, to: now) ?? now,
                venueName: "Frogner Park",
                neighborhood: "Frogner",
                distanceKm: 4.3,
                imageNameOrURL: "gradient-13",
                isFeatured: false,
                endDate: calendar.date(
                    byAdding: .hour, value: 1,
                    to: calendar.date(byAdding: .day, value: 13, to: now) ?? now),
                addressLine: "Frognerparken, 0268 Oslo, Norway",
                coordinate: CLLocationCoordinate2D(latitude: 59.9270, longitude: 10.7002),
                hosts: [
                    Host(id: UUID(), name: "Sara Lind", avatarPlaceholder: "SL")
                ],
                goingCount: 21,
                about:
                    "Start the day with a gentle guided meditation in the park. Bring a mat or a jacket to sit on."
            ),
        ]
    }

    func createEvent(_ draft: EventDraft) async throws -> Event {
        Event(
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
            addressLine: draft.addressLine,
            coordinate: {
                guard let lat = draft.latitude, let lng = draft.longitude else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }(),
            hosts: nil,
            goingCount: nil,
            about: draft.about
        )
    }

    func updateEventCover(eventID: UUID, imageURL: String) async throws {
        // No-op for mock.
    }

    func deleteEvent(id: UUID) async throws {
        // No-op for mock.
    }
}
