//
//  LocationSearchViewModel.swift
//  SOCIETY
//

import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class LocationSearchViewModel: ObservableObject {
    @Published var query: String = "" {
        didSet { addressSearchService.updateQuery(query) }
    }

    @Published private(set) var suggestions: [AddressSuggestion] = []
    @Published private(set) var isResolving: Bool = false
    @Published var errorMessage: String?

    private let addressSearchService: AddressSearchService
    private var cancellables: Set<AnyCancellable> = []

    init(addressSearchService: AddressSearchService? = nil) {
        self.addressSearchService = addressSearchService ?? AddressSearchService()
        self.addressSearchService.$suggestions
            .receive(on: DispatchQueue.main)
            .assign(to: \.suggestions, on: self)
            .store(in: &cancellables)
    }

    /// Returns displayName, full address line, neighborhood (e.g. Grünerløkka), and coordinate.
    /// Neighborhood comes from subLocality (district) or locality (city) so it matches existing events.
    func resolve(_ suggestion: AddressSuggestion) async -> (
        displayName: String, addressLine: String?, neighborhood: String?,
        coordinate: CLLocationCoordinate2D
    )? {
        isResolving = true
        errorMessage = nil
        defer { isResolving = false }

        do {
            let mapItem = try await addressSearchService.resolve(suggestion)
            let placemark = mapItem.placemark
            let coordinate = placemark.coordinate
            let displayName = mapItem.name ?? placemark.title ?? suggestion.title
            let addressLine: String? = {
                let parts = [
                    placemark.thoroughfare, placemark.subThoroughfare, placemark.locality,
                    placemark.administrativeArea,
                ]
                .compactMap { $0 }
                return parts.isEmpty
                    ? (placemark.title ?? placemark.subtitle) : parts.joined(separator: ", ")
            }()
            // Neighborhood for DB/list display: subLocality (e.g. Grünerløkka) or locality (e.g. Oslo).
            let neighborhood: String? = (placemark.subLocality ?? placemark.locality)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .flatMap { $0.isEmpty ? nil : $0 }
            return (
                displayName: displayName, addressLine: addressLine, neighborhood: neighborhood,
                coordinate: coordinate
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
