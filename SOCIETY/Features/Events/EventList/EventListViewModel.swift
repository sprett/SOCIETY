//
//  EventListViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI

@MainActor
final class EventListViewModel: ObservableObject {
    @Published private(set) var events: [Event] = []
    @Published private(set) var firstName: String = ""

    private let repository: any EventRepository
    private let rsvpRepository: any RsvpRepository
    private let profileRepository: any ProfileRepository
    private let locationManager: LocationManager
    @Published private(set) var userID: UUID?

    init(
        repository: any EventRepository,
        rsvpRepository: any RsvpRepository,
        profileRepository: any ProfileRepository,
        locationManager: LocationManager,
        userID: UUID?
    ) {
        self.repository = repository
        self.rsvpRepository = rsvpRepository
        self.profileRepository = profileRepository
        self.locationManager = locationManager
        self.userID = userID
    }

    func updateUserID(_ newUserID: UUID?) {
        userID = newUserID
        if newUserID == nil {
            firstName = ""
        }
    }

    func loadProfile(fallbackEmail: String?) {
        guard let userID = userID else { return }
        Task {
            do {
                if let profile = try await profileRepository.loadProfile(userID: userID, fallbackEmail: fallbackEmail) {
                    let first = profile.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                    firstName = first.isEmpty ? "" : first
                } else {
                    firstName = ""
                }
            } catch {
                firstName = ""
            }
        }
    }

    private func loadEvents() async {
        guard let userID = userID else {
            events = []
            return
        }

        do {
            let eventIds = try await rsvpRepository.fetchEventIdsAttending(userId: userID)
            if eventIds.isEmpty {
                events = []
            } else {
                events = try await repository.fetchEvents(ids: eventIds)
            }
        } catch {
            events = []
        }
    }

    func refresh() {
        Task { await loadEvents() }
    }
    
    func refreshAndUpdateSelected(selectedEventId: UUID) async {
        await loadEvents()
    }
    
    func event(by id: UUID) -> Event? {
        return events.first(where: { $0.id == id })
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

    func distanceFromUser(for event: Event) -> Double? {
        guard let userCoord = locationManager.userLocation,
            let eventCoord = event.coordinate
        else { return nil }
        let userLocation = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let eventLocation = CLLocation(
            latitude: eventCoord.latitude, longitude: eventCoord.longitude)
        return eventLocation.distance(from: userLocation) / 1000
    }
}
