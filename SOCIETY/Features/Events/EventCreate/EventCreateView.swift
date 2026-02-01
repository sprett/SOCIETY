//
//  EventCreateView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import Combine
import Contacts
import MapKit
import PhotosUI
import SwiftUI

struct EventCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EventCreateViewModel

    init(
        eventRepository: any EventRepository,
        authSession: AuthSessionStore,
        eventImageUploadService: any EventImageUploadService,
        onCreated: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: EventCreateViewModel(
                eventRepository: eventRepository,
                authSession: authSession,
                eventImageUploadService: eventImageUploadService,
                onCreated: onCreated
            )
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                heroPreview

                VStack(alignment: .leading, spacing: 10) {
                    Text("Create event")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Fill in the details. You can edit later.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.tertiaryText)
                }

                VStack(alignment: .leading, spacing: 12) {
                    EventDetailSectionHeader(title: "Basics")

                    TextField("Title", text: $viewModel.title)
                        .textInputAutocapitalization(.words)
                        .padding(12)
                        .background(
                            AppColors.surface,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Picker(selection: $viewModel.category) {
                        ForEach(viewModel.availableCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    } label: {
                        Text(viewModel.category)
                            .foregroundStyle(AppColors.primaryText)
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        AppColors.surface,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 12) {
                    EventDetailSectionHeader(title: "Time")

                    VStack(alignment: .leading, spacing: 12) {
                        DatePicker("Start", selection: $viewModel.startDate)
                            .datePickerStyle(.compact)

                        DatePicker("End", selection: $viewModel.endDate)
                            .datePickerStyle(.compact)
                    }
                    .foregroundStyle(AppColors.primaryText)
                }

                VStack(alignment: .leading, spacing: 12) {
                    EventDetailSectionHeader(title: "Location")

                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Search address", text: $viewModel.addressQuery)
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(
                                AppColors.surface,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        if !viewModel.suggestions.isEmpty, viewModel.addressLine == nil {
                            VStack(spacing: 0) {
                                ForEach(viewModel.suggestions) { suggestion in
                                    Button {
                                        Task { await viewModel.selectSuggestion(suggestion) }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(suggestion.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(AppColors.primaryText)
                                            if !suggestion.subtitle.isEmpty {
                                                Text(suggestion.subtitle)
                                                    .font(.footnote)
                                                    .foregroundStyle(AppColors.tertiaryText)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 10)
                                    }
                                    .buttonStyle(.plain)

                                    Divider().background(AppColors.divider.opacity(0.7))
                                }
                            }
                            .background(
                                AppColors.elevatedSurface,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
                            }
                        }

                        TextField("Venue name", text: $viewModel.venueName)
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(
                                AppColors.surface,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        if let addressLine = viewModel.addressLine, !addressLine.isEmpty {
                            Text(addressLine)
                                .font(.footnote)
                                .foregroundStyle(AppColors.tertiaryText)
                        }

                        if let coordinate = viewModel.coordinate {
                            EventLocationMap(title: viewModel.venueName, coordinate: coordinate)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    EventDetailSectionHeader(title: "Details")

                    TextField("About", text: $viewModel.about, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .padding(12)
                        .background(
                            AppColors.surface,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .onChange(of: viewModel.selectedImageItems) { _, _ in
            Task { await viewModel.loadImageFromSelectedItem() }
        }
    }
}

extension EventCreateView {
    private var heroPreview: some View {
        let imageData = viewModel.selectedImageData
        return PhotosPicker(
            selection: $viewModel.selectedImageItems,
            maxSelectionCount: 1,
            matching: .images
        ) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .center) {
                    Group {
                        if let data = imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundStyle(AppColors.tertiaryText)
                                Text("Upload image, max 5MB")
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.secondaryText)
                                Text("Tap to upload")
                                    .font(.footnote)
                                    .foregroundStyle(AppColors.tertiaryText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    if imageData == nil {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                AppColors.divider.opacity(1),
                                style: StrokeStyle(lineWidth: 2, dash: [8]))
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.createEventAndDismiss(dismiss: dismiss) }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text("Create")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .disabled(!viewModel.canCreate || viewModel.isSaving)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}

@MainActor
final class EventCreateViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var category: String = ""
    @Published var startDate: Date = Date() {
        didSet { adjustEndDateIfNeeded() }
    }
    @Published var endDate: Date = Date().addingTimeInterval(2 * 60 * 60) {
        didSet {
            guard !isAutoAdjustingEndDate else { return }
            hasUserEditedEndDate = true
        }
    }
    @Published var venueName: String = ""
    @Published var addressQuery: String = "" {
        didSet { addressSearch.updateQuery(addressQuery) }
    }
    @Published var selectedImageItems: [PhotosPickerItem] = []
    @Published private(set) var selectedImageData: Data?
    @Published var about: String = ""

    @Published private(set) var suggestions: [AddressSuggestion] = []
    @Published private(set) var addressLine: String?
    @Published private(set) var neighborhood: String?
    @Published private(set) var coordinate: CLLocationCoordinate2D?

    @Published private(set) var isSaving: Bool = false

    private let eventRepository: any EventRepository
    private let authSession: AuthSessionStore
    private let eventImageUploadService: any EventImageUploadService
    private let onCreated: () -> Void

    private static let maxImageBytes = 5 * 1024 * 1024

    private let addressSearch = AddressSearchService()
    private var hasUserEditedEndDate: Bool = false
    private var isAutoAdjustingEndDate: Bool = false

    init(
        eventRepository: any EventRepository,
        authSession: AuthSessionStore,
        eventImageUploadService: any EventImageUploadService,
        onCreated: @escaping () -> Void
    ) {
        self.eventRepository = eventRepository
        self.authSession = authSession
        self.eventImageUploadService = eventImageUploadService
        self.onCreated = onCreated

        // Keep suggestions in sync.
        addressSearch.$suggestions.assign(to: &$suggestions)

        // Reasonable defaults for MVP. Round to 15-min and set end = start + 2h.
        category = "Tech"
        startDate = Self.roundToFifteenMinutes(startDate)
        isAutoAdjustingEndDate = true
        endDate = Self.roundToFifteenMinutes(startDate.addingTimeInterval(2 * 60 * 60))
        isAutoAdjustingEndDate = false
    }

    /// Returns CNPostalAddress from an MKMapItem. Uses placemark (deprecated in iOS 26 in favor of address/addressRepresentations).
    private static func postalAddress(from item: MKMapItem) -> CNPostalAddress? {
        item.placemark.postalAddress
    }

    /// Returns (postalAddress, locality, subAdministrativeArea) from an MKMapItem.
    private static func addressComponents(from item: MKMapItem) -> (
        CNPostalAddress?, String?, String?
    ) {
        (
            item.placemark.postalAddress,
            item.placemark.locality,
            item.placemark.subAdministrativeArea
        )
    }

    /// Rounds a date to the nearest 15-minute boundary (e.g. 10:07 → 10:00, 10:08 → 10:15).
    static func roundToFifteenMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let m = components.minute else { return date }
        let roundedMinute = (m / 15) * 15
        return calendar.date(
            from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: components.hour,
                minute: roundedMinute
            )
        ) ?? date
    }

    func loadImageFromSelectedItem() async {
        guard let item = selectedImageItems.first else {
            selectedImageData = nil
            return
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            selectedImageData = nil
            return
        }
        if data.count > Self.maxImageBytes {
            selectedImageItems = []
            selectedImageData = nil
            print("[EventCreate] Image too large (\(data.count) bytes, max \(Self.maxImageBytes))")
            return
        }
        selectedImageData = data
    }

    var availableCategories: [String] {
        EventCategories.all
    }

    var canCreate: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        guard let addressLine, !addressLine.isEmpty else { return false }
        guard !venueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        guard selectedImageData != nil else { return false }
        guard !about.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if endDate <= startDate { return false }
        return true
    }

    func selectSuggestion(_ suggestion: AddressSuggestion) async {
        addressSearch.clearSuggestions()
        do {
            let item = try await addressSearch.resolve(suggestion)

            let formattedAddress: String? = {
                // Prefer CNPostalAddress when available and compose a single-line string.
                let postal = Self.postalAddress(from: item)
                if let postal = postal {
                    var components: [String] = []
                    // Street (e.g., "1 Infinite Loop")
                    if !postal.street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        components.append(postal.street)
                    }
                    // City/locality
                    if !postal.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        components.append(postal.city)
                    }
                    // State/region
                    if !postal.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        components.append(postal.state)
                    }
                    // Postal code
                    if !postal.postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        components.append(postal.postalCode)
                    }
                    // Country
                    if !postal.country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        components.append(postal.country)
                    }
                    let line = components.joined(separator: ", ")
                    if !line.isEmpty { return line }
                }

                // Fall back to MapKit-provided title/subtitle.
                let fallback = "\(suggestion.title) \(suggestion.subtitle)".trimmingCharacters(
                    in: .whitespaces)
                return fallback.isEmpty ? nil : fallback
            }()

            let bestAddress =
                formattedAddress
                ?? "\(suggestion.title) \(suggestion.subtitle)".trimmingCharacters(in: .whitespaces)

            addressLine = bestAddress

            // item.location is non-optional in modern APIs; assign directly.
            coordinate = item.location.coordinate

            let derivedNeighborhood: String? = {
                if let postal = Self.postalAddress(from: item) {
                    let city = postal.city.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !city.isEmpty { return city }
                }
                let (_, locality, subAdmin) = Self.addressComponents(from: item)
                if let locality = locality,
                    !locality.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                {
                    return locality
                }
                if let subAdmin = subAdmin,
                    !subAdmin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                {
                    return subAdmin
                }
                return nil
            }()
            neighborhood = derivedNeighborhood

            addressQuery = bestAddress
            addressSearch.clearSuggestions()

            if venueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                venueName = item.name ?? suggestion.title
            }
        } catch {
            print("[EventCreate] Address selection failed: \(error)")
        }
    }

    func createEventAndDismiss(dismiss: DismissAction) async {
        guard !isSaving else { return }
        guard let addressLine else { return }
        guard let imageData = selectedImageData else { return }
        adjustEndDateIfNeeded()

        isSaving = true
        defer { isSaving = false }

        do {
            let imageURL = try await eventImageUploadService.upload(imageData)
            let ownerID = authSession.userID
            let draft = EventDraft(
                ownerID: ownerID,
                title: title,
                category: category,
                startDate: startDate,
                endDate: endDate,
                venueName: venueName,
                addressLine: addressLine,
                neighborhood: neighborhood,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude,
                imageURL: imageURL.absoluteString,
                about: about,
                isFeatured: false,
                visibility: .public
            )

            _ = try await eventRepository.createEvent(draft)
            onCreated()
            dismiss()
        } catch {
            print("[EventCreate] Create event failed: \(error)")
        }
    }

    private func adjustEndDateIfNeeded(force: Bool = false) {
        // When start changes, set end to start + 2h (15-min rounded). Don't overwrite user-chosen end unless invalid.
        let defaultEnd = Self.roundToFifteenMinutes(startDate.addingTimeInterval(2 * 60 * 60))

        if force || (!hasUserEditedEndDate) || (endDate <= startDate) {
            isAutoAdjustingEndDate = true
            endDate = defaultEnd
            isAutoAdjustingEndDate = false
        }
    }
}

#Preview {
    EventCreateView(
        eventRepository: MockEventRepository(),
        authSession: AuthSessionStore(authRepository: PreviewAuthRepository()),
        eventImageUploadService: MockEventImageUploadService()
    )
}
