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

    func createEvent() {
        print("Create event button tapped")
    }
}
