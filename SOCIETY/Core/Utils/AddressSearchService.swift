//
//  AddressSearchService.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import CoreLocation
import Foundation
import Combine
import MapKit

struct AddressSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    fileprivate let completion: MKLocalSearchCompletion
}

@MainActor
final class AddressSearchService: NSObject, ObservableObject {
    @Published private(set) var suggestions: [AddressSuggestion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest]
        self.completer = completer
        super.init()
        self.completer.delegate = self
    }

    func updateQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            suggestions = []
            completer.queryFragment = ""
            return
        }
        completer.queryFragment = trimmed
    }

    func clearSuggestions() {
        suggestions = []
        completer.queryFragment = ""
    }

    func resolve(_ suggestion: AddressSuggestion) async throws -> MKMapItem {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.startAsync()
        if let first = response.mapItems.first { return first }
        if #available(iOS 26.0, *) {
            return MKMapItem(location: CLLocation(latitude: 0, longitude: 0), address: nil)
        } else {
            return MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
        }
    }
}

extension AddressSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.map { completion in
            AddressSuggestion(title: completion.title, subtitle: completion.subtitle, completion: completion)
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Keep the last suggestions; callers may show an error if desired.
    }
}

private extension MKLocalSearch {
    func startAsync() async throws -> MKLocalSearch.Response {
        try await withCheckedThrowingContinuation { continuation in
            start { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let response = response {
                    continuation.resume(returning: response)
                    return
                }
                continuation.resume(
                    throwing: NSError(domain: "AddressSearchService", code: 0, userInfo: nil)
                )
            }
        }
    }
}

