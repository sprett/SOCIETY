//
//  CreateEventViewModel.swift
//  SOCIETY
//

import Combine
import CoreLocation
import Foundation
import PhotosUI
import SwiftUI
import UIKit

struct SelectedLocation: Equatable {
    let displayName: String
    let addressLine: String?
    /// Neighborhood name for list/DB (e.g. Grünerløkka), from placemark subLocality/locality.
    let neighborhood: String?
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: SelectedLocation, rhs: SelectedLocation) -> Bool {
        lhs.displayName == rhs.displayName
            && lhs.addressLine == rhs.addressLine
            && lhs.neighborhood == rhs.neighborhood
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

    // Category selection (DB-driven)
    @Published var availableCategories: [EventCategory] = []
    @Published var selectedCategory: EventCategory?
    @Published var isShowingCategoryPicker: Bool = false

    // UI presentation state for sheets/editors. Keeping this here (instead of @State in the
    // view) avoids a SwiftUI crash in the @State backing initializer when the create sheet
    // is presented.
    @Published var isShowingStartDatePicker: Bool = false
    @Published var isShowingEndDatePicker: Bool = false
    @Published var isShowingLocationSearch: Bool = false
    @Published var isShowingDescriptionEditor: Bool = false
    @Published var isShowingVisibilitySheet: Bool = false

    @Published var isCreating: Bool = false
    @Published var createErrorMessage: String?
    @Published var isCreateErrorPresented: Bool = false

    private let authSession: AuthSessionStore
    private let eventRepository: any EventRepository
    private let categoryRepository: any CategoryRepository
    private let eventImageUploadService: any EventImageUploadService
    private let rsvpRepository: any RsvpRepository
    private let onCreated: (Event) -> Void

    init(
        authSession: AuthSessionStore,
        eventRepository: any EventRepository,
        categoryRepository: any CategoryRepository,
        eventImageUploadService: any EventImageUploadService,
        rsvpRepository: any RsvpRepository,
        onCreated: @escaping (Event) -> Void
    ) {
        self.authSession = authSession
        self.eventRepository = eventRepository
        self.categoryRepository = categoryRepository
        self.eventImageUploadService = eventImageUploadService
        self.rsvpRepository = rsvpRepository
        self.onCreated = onCreated

        Task { @MainActor in
            await loadCategories()
        }
    }

    func loadCategories() async {
        do {
            availableCategories = try await categoryRepository.fetchCategories()
        } catch {
            // Fallback: use static list so form is still usable
            availableCategories = EventCategories.all.enumerated().map { idx, name in
                EventCategory(
                    id: UUID(),
                    name: name,
                    iconIdentifier: EventCategories.icon(for: name),
                    accentColorHex: nil,
                    displayOrder: idx
                )
            }
        }
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
        displayName: String,
        addressLine: String?,
        neighborhood: String?,
        coordinate: CLLocationCoordinate2D
    ) {
        selectedLocation = SelectedLocation(
            displayName: displayName,
            addressLine: addressLine,
            neighborhood: neighborhood,
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

    func createEvent() async {
        guard isFormValid, let location = selectedLocation else { return }

        isCreating = true
        createErrorMessage = nil
        defer { isCreating = false }

        let addressLine = location.addressLine ?? ""

        var imageURL: String?
        if let data = coverImageData, !data.isEmpty {
            do {
                let url = try await eventImageUploadService.upload(data)
                imageURL = url.absoluteString
            } catch {
                createErrorMessage = error.localizedDescription
                isCreateErrorPresented = true
                return
            }
        }

        let draft = EventDraft(
            ownerID: authSession.userID,
            title: eventName.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory?.name ?? "General",
            startDate: startDate,
            endDate: endDate,
            venueName: location.displayName,
            addressLine: addressLine,
            neighborhood: location.neighborhood,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            imageURL: imageURL,
            about: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            isFeatured: false,
            visibility: visibility
        )

        do {
            var event = try await eventRepository.createEvent(draft)

            if event.hosts == nil, event.ownerID == authSession.userID, let uid = authSession.userID
            {
                let name = authSession.userName ?? "Me"
                let initials = String(name.prefix(2)).uppercased()
                let placeholder = initials.isEmpty ? "?" : initials
                event = Event(
                    id: event.id,
                    ownerID: event.ownerID,
                    title: event.title,
                    category: event.category,
                    startDate: event.startDate,
                    venueName: event.venueName,
                    neighborhood: event.neighborhood,
                    distanceKm: event.distanceKm,
                    imageNameOrURL: event.imageNameOrURL,
                    isFeatured: event.isFeatured,
                    endDate: event.endDate,
                    addressLine: event.addressLine,
                    coordinate: event.coordinate,
                    hosts: [
                        Host(
                            id: uid,
                            name: name,
                            avatarPlaceholder: placeholder,
                            profileImageURL: authSession.profileImageURL
                        )
                    ],
                    goingCount: event.goingCount,
                    about: event.about
                )
            }

            if let userID = authSession.userID {
                do {
                    try await rsvpRepository.addRsvp(eventId: event.id, userId: userID)
                } catch {
                    print("[CreateEvent] Auto-RSVP failed: \(error)")
                }
            }

            onCreated(event)
        } catch {
            createErrorMessage = error.localizedDescription
            isCreateErrorPresented = true
        }
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
