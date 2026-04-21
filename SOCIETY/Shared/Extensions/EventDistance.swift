//
//  EventDistance.swift
//  SOCIETY
//

import CoreLocation

enum EventDistance {
    /// Kilometers between the user's current location and `event`. Nil if either
    /// coordinate is unavailable.
    static func kilometers(from event: Event, user userCoord: CLLocationCoordinate2D?) -> Double? {
        guard let userCoord, let eventCoord = event.coordinate else { return nil }
        let userLocation = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let eventLocation = CLLocation(latitude: eventCoord.latitude, longitude: eventCoord.longitude)
        return eventLocation.distance(from: userLocation) / 1000
    }
}
