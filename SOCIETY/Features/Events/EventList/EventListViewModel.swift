//
//  EventListViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Foundation
import SwiftUI
import Combine

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
                date: calendar.date(byAdding: .day, value: 3, to: now) ?? now,
                location: "San Francisco, CA",
                rsvpStatus: .going
            ),
            Event(
                id: UUID(),
                title: "Design Workshop",
                date: calendar.date(byAdding: .day, value: 7, to: now) ?? now,
                location: "New York, NY",
                rsvpStatus: .maybe
            ),
            Event(
                id: UUID(),
                title: "Networking Night",
                date: calendar.date(byAdding: .day, value: 10, to: now) ?? now,
                location: "Los Angeles, CA",
                rsvpStatus: .going
            ),
            Event(
                id: UUID(),
                title: "Product Launch Party",
                date: calendar.date(byAdding: .day, value: 14, to: now) ?? now,
                location: "Austin, TX",
                rsvpStatus: .notGoing
            ),
            Event(
                id: UUID(),
                title: "Hackathon 2026",
                date: calendar.date(byAdding: .day, value: 21, to: now) ?? now,
                location: "Seattle, WA",
                rsvpStatus: .going
            ),
            Event(
                id: UUID(),
                title: "Community BBQ",
                date: calendar.date(byAdding: .day, value: 30, to: now) ?? now,
                location: "Portland, OR",
                rsvpStatus: .maybe
            )
        ]
    }
    
    func createEvent() {
        print("Create event button tapped")
    }
}
