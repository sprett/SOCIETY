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

// Note: coverImageData now holds preprocessed (cropped/resized/compressed) JPEG data.
// Raw data from PhotosPicker is processed by ImageProcessor before being stored here.

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
    @Published var isProcessingCoverImage: Bool = false

    /// Preprocessed cover image data ready for upload (512×512 JPEG).
    private var processedCoverMain: Data?
    /// Preprocessed thumb data (100×100 JPEG), if available.
    private var processedCoverThumb: Data?

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
    private let imageProcessor: ImageProcessor
    private let onCreated: (Event) -> Void
    private var cancellables = Set<AnyCancellable>()

    init(
        authSession: AuthSessionStore,
        eventRepository: any EventRepository,
        categoryRepository: any CategoryRepository,
        eventImageUploadService: any EventImageUploadService,
        rsvpRepository: any RsvpRepository,
        imageProcessor: ImageProcessor = ImageProcessor(),
        onCreated: @escaping (Event) -> Void
    ) {
        self.authSession = authSession
        self.eventRepository = eventRepository
        self.categoryRepository = categoryRepository
        self.eventImageUploadService = eventImageUploadService
        self.rsvpRepository = rsvpRepository
        self.imageProcessor = imageProcessor
        self.onCreated = onCreated

        // Observe cover picker changes → load + preprocess
        $coverPickerItem
            .sink { [weak self] item in
                Task { @MainActor in
                    await self?.processCoverImage(from: item)
                }
            }
            .store(in: &cancellables)

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

    /// Loads raw data from the picker item, preprocesses (center-crop, resize, JPEG-encode),
    /// and stores the result for preview and later upload.
    func processCoverImage(from item: PhotosPickerItem?) async {
        guard let item else {
            coverImageData = nil
            processedCoverMain = nil
            processedCoverThumb = nil
            return
        }

        isProcessingCoverImage = true
        coverImageData = nil
        processedCoverMain = nil
        processedCoverThumb = nil

        do {
            guard let rawData = try await item.loadTransferable(type: Data.self), !rawData.isEmpty else {
                coverPickerItem = nil
                isProcessingCoverImage = false
                return
            }

            let result = try await imageProcessor.processEventImage(from: rawData)
            processedCoverMain = result.main512
            processedCoverThumb = result.thumb100
            // Use the preprocessed 512×512 image for preview
            coverImageData = result.main512
        } catch {
            createErrorMessage = error.localizedDescription
            isCreateErrorPresented = true
            coverPickerItem = nil
        }

        isProcessingCoverImage = false
    }

    func createEvent() async {
        guard isFormValid, let location = selectedLocation else { return }

        isCreating = true
        createErrorMessage = nil
        defer { isCreating = false }

        let addressLine = location.addressLine ?? ""

        // Create event first (without image), then upload cover with the event ID.
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
            imageURL: nil,
            about: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            isFeatured: false,
            visibility: visibility
        )

        do {
            var event = try await eventRepository.createEvent(draft)

            // Upload preprocessed cover image now that we have the event ID.
            if let mainData = processedCoverMain, !mainData.isEmpty {
                let uploaded = try await eventImageUploadService.uploadPreprocessed(
                    mainData: mainData,
                    thumbData: processedCoverThumb,
                    eventId: event.id
                )
                let imageURLString = uploaded.mainURL.absoluteString
                try await eventRepository.updateEventCover(
                    eventID: event.id,
                    imageURL: imageURLString
                )
                // Update event with the new image URL
                event = Event(
                    id: event.id,
                    ownerID: event.ownerID,
                    title: event.title,
                    category: event.category,
                    startDate: event.startDate,
                    venueName: event.venueName,
                    neighborhood: event.neighborhood,
                    distanceKm: event.distanceKm,
                    imageNameOrURL: imageURLString,
                    isFeatured: event.isFeatured,
                    endDate: event.endDate,
                    addressLine: event.addressLine,
                    coordinate: event.coordinate,
                    hosts: event.hosts,
                    goingCount: event.goingCount,
                    about: event.about
                )
            }

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
