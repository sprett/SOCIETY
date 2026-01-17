//
//  MockEventRepository.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 16/01/2026.
//

import Foundation

final class MockEventRepository {
    func fetchEvents() -> [Event] {
        let calendar = Calendar.current
        let now = Date()

        return [
            Event(
                id: UUID(),
                title: "Nordic AI Night",
                category: "AI",
                startDate: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
                venueName: "Mesh Oslo",
                neighborhood: "Sentrum",
                distanceKm: 1.2,
                imageNameOrURL: "gradient-1",
                isFeatured: true
            ),
            Event(
                id: UUID(),
                title: "Fjordside Fitness",
                category: "Fitness",
                startDate: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                venueName: "Aker Brygge",
                neighborhood: "Vika",
                distanceKm: 2.4,
                imageNameOrURL: "gradient-2",
                isFeatured: true
            ),
            Event(
                id: UUID(),
                title: "Oslo Climate Salon",
                category: "Climate",
                startDate: calendar.date(byAdding: .day, value: 3, to: now) ?? now,
                venueName: "DogA",
                neighborhood: "Torggata",
                distanceKm: 1.8,
                imageNameOrURL: "gradient-3",
                isFeatured: true
            ),
            Event(
                id: UUID(),
                title: "Tech Founders Mixer",
                category: "Tech",
                startDate: calendar.date(byAdding: .day, value: 4, to: now) ?? now,
                venueName: "Startuplab",
                neighborhood: "Gaustad",
                distanceKm: 4.7,
                imageNameOrURL: "gradient-4",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Nordic Design Talk",
                category: "Arts & Culture",
                startDate: calendar.date(byAdding: .day, value: 5, to: now) ?? now,
                venueName: "Kulturhuset",
                neighborhood: "Youngstorget",
                distanceKm: 1.0,
                imageNameOrURL: "gradient-5",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Sourdough & Stories",
                category: "Food & Drink",
                startDate: calendar.date(byAdding: .day, value: 6, to: now) ?? now,
                venueName: "Mathallen",
                neighborhood: "Grünerløkka",
                distanceKm: 3.2,
                imageNameOrURL:
                    "https://images.unsplash.com/photo-1592753054398-9fa298d40e85?q=80&w=1665&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Wellness Wind Down",
                category: "Wellness",
                startDate: calendar.date(byAdding: .day, value: 7, to: now) ?? now,
                venueName: "The Well Studio",
                neighborhood: "Majorstuen",
                distanceKm: 3.9,
                imageNameOrURL: "gradient-7",
                isFeatured: true
            ),
            Event(
                id: UUID(),
                title: "AI Product Lab",
                category: "AI",
                startDate: calendar.date(byAdding: .day, value: 8, to: now) ?? now,
                venueName: "Oslo Science Park",
                neighborhood: "Blindern",
                distanceKm: 5.1,
                imageNameOrURL: "gradient-8",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "City Night Run",
                category: "Fitness",
                startDate: calendar.date(byAdding: .day, value: 9, to: now) ?? now,
                venueName: "Sognsvann",
                neighborhood: "Sognsvann",
                distanceKm: 6.8,
                imageNameOrURL: "gradient-9",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Climate Tech Demo Day",
                category: "Climate",
                startDate: calendar.date(byAdding: .day, value: 10, to: now) ?? now,
                venueName: "Nydalen Factory",
                neighborhood: "Nydalen",
                distanceKm: 5.4,
                imageNameOrURL: "gradient-10",
                isFeatured: true
            ),
            Event(
                id: UUID(),
                title: "Midnight Jazz Session",
                category: "Arts & Culture",
                startDate: calendar.date(byAdding: .day, value: 11, to: now) ?? now,
                venueName: "Blå",
                neighborhood: "Brennabekk",
                distanceKm: 2.6,
                imageNameOrURL: "gradient-11",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Oslo Food Crawl",
                category: "Food & Drink",
                startDate: calendar.date(byAdding: .day, value: 12, to: now) ?? now,
                venueName: "Grünerløkka",
                neighborhood: "Grünerløkka",
                distanceKm: 3.0,
                imageNameOrURL: "gradient-12",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Mindful Morning",
                category: "Wellness",
                startDate: calendar.date(byAdding: .day, value: 13, to: now) ?? now,
                venueName: "Frogner Park",
                neighborhood: "Frogner",
                distanceKm: 4.3,
                imageNameOrURL: "gradient-13",
                isFeatured: false
            ),
        ]
    }
}
