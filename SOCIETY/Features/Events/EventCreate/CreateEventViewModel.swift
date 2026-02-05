//
//  CreateEventViewModel.swift
//  SOCIETY
//

import Combine
import CoreLocation
import Foundation
import PhotosUI
import SwiftUI

struct SelectedLocation: Equatable {
    let displayName: String
    let addressLine: String?
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: SelectedLocation, rhs: SelectedLocation) -> Bool {
        lhs.displayName == rhs.displayName
            && lhs.addressLine == rhs.addressLine
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

@MainActor
final class CreateEventViewModel: ObservableObject {
    @Published var eventName: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date().addingTimeInterval(2 * 3600)
    @Published var selectedLocation: SelectedLocation?
    @Published var descriptionText: String = ""
    @Published var visibility: EventVisibility = .public
    @Published var coverImageData: Data?
    @Published var coverPickerItem: PhotosPickerItem?

    // UI presentation state for sheets/editors. Keeping this here (instead of @State in the
    // view) avoids a SwiftUI crash in the @State backing initializer when the create sheet
    // is presented.
    @Published var isShowingStartDatePicker: Bool = false
    @Published var isShowingEndDatePicker: Bool = false
    @Published var isShowingLocationSearch: Bool = false
    @Published var isShowingDescriptionEditor: Bool = false
    @Published var isShowingVisibilitySheet: Bool = false

    private let authSession: AuthSessionStore
    private let onCreated: (Event) -> Void

    init(authSession: AuthSessionStore, onCreated: @escaping (Event) -> Void) {
        self.authSession = authSession
        self.onCreated = onCreated
    }

    var isFormValid: Bool {
        let nameValid = !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let datesValid = startDate < endDate
        let locationValid = selectedLocation != nil
        let descriptionValid = !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        return nameValid && datesValid && locationValid && descriptionValid
    }

    func selectLocation(
        displayName: String, addressLine: String?, coordinate: CLLocationCoordinate2D
    ) {
        selectedLocation = SelectedLocation(
            displayName: displayName,
            addressLine: addressLine,
            coordinate: coordinate
        )
    }

    func setDescription(_ text: String) {
        descriptionText = text
    }

    func setVisibility(_ value: EventVisibility) {
        visibility = value
    }

    /// End date is always 2 hours after start.
    private static let eventDuration: TimeInterval = 2 * 3600

    func setStartDate(_ date: Date) {
        startDate = date
        endDate = startDate.addingTimeInterval(Self.eventDuration)
    }

    func setEndDate(_ date: Date) {
        endDate = date
        startDate = endDate.addingTimeInterval(-Self.eventDuration)
    }

    func createEvent() {
        guard isFormValid, let location = selectedLocation else { return }

        let neighborhood = location.addressLine ?? location.displayName
        let addressLine = location.addressLine ?? ""

        let draft = EventDraft(
            ownerID: authSession.userID,
            title: eventName.trimmingCharacters(in: .whitespacesAndNewlines),
            category: "General",
            startDate: startDate,
            endDate: endDate,
            venueName: location.displayName,
            addressLine: addressLine,
            neighborhood: neighborhood.isEmpty ? nil : neighborhood,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            imageURL: nil,
            about: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            isFeatured: false,
            visibility: visibility
        )

        let event = Event.from(draft: draft)
        onCreated(event)
    }
}

// MARK: - Bindings for use in views that hold the view model by reference (no @ObservedObject)
extension CreateEventViewModel {
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<CreateEventViewModel, T>) -> Binding<T> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { [weak self] newValue in
                guard let self else { return }
                // Defer publish to avoid "Publishing changes from within view updates" when
                // the binding is written during a view update (e.g. RichTextEditor format actions).
                Task { @MainActor in
                    self[keyPath: keyPath] = newValue
                }
            }
        )
    }
}
