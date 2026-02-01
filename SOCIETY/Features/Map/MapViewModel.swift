//
//  MapViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class MapViewModel: ObservableObject {
    @Published private(set) var events: [Event] = []
    @Published private(set) var userLocation: CLLocationCoordinate2D?
    @Published private(set) var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let eventRepository: any EventRepository
    private let locationManager: LocationManager
    private let authSession: AuthSessionStore?
    private var cancellables = Set<AnyCancellable>()

    init(eventRepository: any EventRepository, locationManager: LocationManager? = nil, authSession: AuthSessionStore? = nil) {
        self.eventRepository = eventRepository
        self.locationManager = locationManager ?? LocationManager()
        self.authSession = authSession

        // Observe location manager updates
        self.locationManager.$authorizationStatus
            .assign(to: \.locationAuthorizationStatus, on: self)
            .store(in: &cancellables)

        self.locationManager.$userLocation
            .assign(to: \.userLocation, on: self)
            .store(in: &cancellables)
    }

    func loadEvents() async {
        isLoading = true
        errorMessage = nil

        do {
            events = try await eventRepository.fetchEvents()
        } catch {
            errorMessage = error.localizedDescription
            events = []
        }

        isLoading = false
    }

    func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }

    func centerOnUserLocation() {
        guard userLocation != nil else {
            // Request location if we don't have it yet
            if locationAuthorizationStatus == .authorizedWhenInUse
                || locationAuthorizationStatus == .authorizedAlways
            {
                locationManager.getCurrentLocation()
                locationManager.startLocationUpdates()
            } else {
                requestLocationPermission()
            }
            return
        }

        // Location will be used to set map position in the view
    }

    func startLocationUpdates() {
        locationManager.startLocationUpdates()
    }

    func refresh() {
        Task { await loadEvents() }
    }

    var eventsWithCoordinates: [Event] {
        events.filter { $0.coordinate != nil }
    }

    func regionForUserLocation() -> MKCoordinateRegion? {
        guard let userLocation = userLocation else { return nil }

        // ~5km span (approximately 0.045 degrees at mid-latitudes)
        let span = MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045)
        return MKCoordinateRegion(center: userLocation, span: span)
    }
    
    // Future: Use this for personalization features like filtering events user is attending
    var currentUserID: UUID? {
        authSession?.userID
    }
}
