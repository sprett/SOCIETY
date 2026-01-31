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
final class EventListViewModel: ObservableObject {
    @Published private(set) var events: [Event] = []

    private let repository: any EventRepository

    init(repository: any EventRepository) {
        self.repository = repository
        Task { await loadEvents() }
    }

    private func loadEvents() async {
        do {
            events = try await repository.fetchEvents()
        } catch {
            events = []
        }
    }

    func refresh() {
        Task { await loadEvents() }
    }

    var nextEvent: Event? {
        let now = Date()
        if let upcoming = events.filter({ $0.startDate >= now }).sorted(by: {
            $0.startDate < $1.startDate
        }).first {
            return upcoming
        }
        return events.sorted(by: { $0.startDate < $1.startDate }).first
    }

    func dateText(for event: Event) -> String {
        if let endDate = event.endDate {
            return EventDateFormatter.dateTimeRange(start: event.startDate, end: endDate)
        }

        return EventDateFormatter.dateOnly(event.startDate)
    }
}
