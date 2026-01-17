//
//  EventListViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class EventListViewModel: ObservableObject {
    @Published var events: [Event] = []

    init() {
        loadMockEvents()
    }

    private func loadMockEvents() {
        let calendar = Calendar.current
        let now = Date()

        events = [
            Event(
                id: UUID(),
                title: "Tech Meetup",
                category: "Tech",
                startDate: calendar.date(byAdding: .day, value: 3, to: now) ?? now,
                venueName: "Startup House",
                neighborhood: "SOMA",
                distanceKm: 1.2,
                imageNameOrURL: "gradient-1",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Design Workshop",
                category: "Arts & Culture",
                startDate: calendar.date(byAdding: .day, value: 7, to: now) ?? now,
                venueName: "Design Lab",
                neighborhood: "Chelsea",
                distanceKm: 2.6,
                imageNameOrURL: "gradient-2",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Networking Night",
                category: "Tech",
                startDate: calendar.date(byAdding: .day, value: 10, to: now) ?? now,
                venueName: "Founders Hall",
                neighborhood: "Downtown",
                distanceKm: 3.4,
                imageNameOrURL: "gradient-3",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Product Launch Party",
                category: "Tech",
                startDate: calendar.date(byAdding: .day, value: 14, to: now) ?? now,
                venueName: "The Hub",
                neighborhood: "East Side",
                distanceKm: 4.1,
                imageNameOrURL: "gradient-4",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Hackathon 2026",
                category: "Tech",
                startDate: calendar.date(byAdding: .day, value: 21, to: now) ?? now,
                venueName: "Innovation Center",
                neighborhood: "Capitol Hill",
                distanceKm: 5.8,
                imageNameOrURL: "gradient-5",
                isFeatured: false
            ),
            Event(
                id: UUID(),
                title: "Community BBQ",
                category: "Food & Drink",
                startDate: calendar.date(byAdding: .day, value: 30, to: now) ?? now,
                venueName: "Community Park",
                neighborhood: "Eastside",
                distanceKm: 6.2,
                imageNameOrURL:
                    "https://images.unsplash.com/photo-1592753054398-9fa298d40e85?q=80&w=1665&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
                isFeatured: false
            ),
        ]
    }

    func createEvent() {
        print("Create event button tapped")
    }
}
