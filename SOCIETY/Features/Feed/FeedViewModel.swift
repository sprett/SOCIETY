//
//  FeedViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 01/02/2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var events: [Event] = []

    private let repository: any EventRepository

    init(repository: any EventRepository) {
        self.repository = repository
    }

    var feedEvents: [Event] {
        events.sorted { $0.startDate < $1.startDate }
    }

    func dateText(for event: Event) -> String {
        if let endDate = event.endDate {
            return EventDateFormatter.dateTimeRange(start: event.startDate, end: endDate)
        }
        return EventDateFormatter.dateOnly(event.startDate)
    }

    /// Feed shows events from friends and followed organizers (not implemented yet).
    /// Until then, keep feed empty.
    func refresh() async {
        events = []
    }
}
