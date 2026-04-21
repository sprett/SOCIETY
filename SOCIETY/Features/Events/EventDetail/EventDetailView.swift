//
//  EventDetailView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 19/01/2026.
//

import Combine
import MapKit
import PhotosUI
import SwiftUI
import UIKit

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EventDetailViewModel

    init(
        event: Event,
        eventRepository: any EventRepository,
        eventImageUploadService: any EventImageUploadService,
        rsvpRepository: any RsvpRepository,
        authSession: AuthSessionStore,
        onDeleted: @escaping () -> Void = {},
        onCoverChanged: @escaping () -> Void = {},
        onRsvpChanged: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: EventDetailViewModel(
                event: event,
                eventRepository: eventRepository,
                eventImageUploadService: eventImageUploadService,
                rsvpRepository: rsvpRepository,
                authSession: authSession,
                onDeleted: onDeleted,
                onCoverChanged: onCoverChanged,
                onRsvpChanged: onRsvpChanged
            )
        )
    }

    var body: some View {
        ZStack {
            BlurredCoverBackground(
                imageNameOrURL: viewModel.event.imageNameOrURL,
                category: viewModel.event.category
            )
            .ignoresSafeArea(edges: .top)

            ScrollView(showsIndicators: false) {
                scrollContent
            }
        }
        .safeAreaInset(edge: .top, alignment: .center, spacing: 0) {
            topSafeAreaBar
        }
        .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
            Color.clear.frame(height: Self.bottomBlurHeight + 34)
        }
        .overlay(alignment: .bottom) {
            bottomSafeAreaBar
                .ignoresSafeArea(edges: .bottom)
        }
        .confirmationDialog(
            "More", isPresented: $viewModel.showMoreActions, titleVisibility: .visible
        ) {
            Button("Share") { viewModel.handleShareTap() }
            Button("Copy link") { viewModel.handleCopyLinkTap() }
            if viewModel.isOwner {
                Button("Change cover") { viewModel.showChangeCoverSheet = true }
            }
            Button("Delete event", role: .destructive) {
                Task { await viewModel.handleDeleteTap() }
            }
            Button("Report event", role: .destructive) { viewModel.handleReportTap() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "View location", isPresented: $viewModel.showMapActions, titleVisibility: .visible
        ) {
            Button("Open in Apple Maps") { viewModel.openInAppleMaps() }
            if viewModel.canOpenGoogleMaps {
                Button("Open in Google Maps") { viewModel.openInGoogleMaps() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose an app to view the event location.")
        }
        .sheet(isPresented: $viewModel.showChangeCoverSheet) {
            changeCoverSheet
        }
        .onChange(of: viewModel.changeCoverItem) { _, _ in
            Task { await viewModel.uploadNewCoverAndReplace() }
        }
        .alert("Couldn't delete event", isPresented: $viewModel.isDeleteErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.deleteErrorMessage ?? "Unknown error")
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            guard shouldDismiss else { return }
            dismiss()
        }
        .sheet(isPresented: $viewModel.showAttendeeList) {
            AttendeeListView(attendees: viewModel.attendees)
        }
        .onAppear {
            Task {
                await viewModel.fetchAttendees()
                await viewModel.checkIsAttending()
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }

    private var hero: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = width * 3 / 4  // 4:3

            EventHeroImage(
                imageNameOrURL: viewModel.event.imageNameOrURL, category: viewModel.event.category
            )
            .aspectRatio(4 / 3, contentMode: .fill)
            .frame(width: width, height: height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
        }
        .aspectRatio(4 / 3, contentMode: .fit)
    }

    private var topNavOverlay: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(navButtonBackground)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()

            Button {
                viewModel.showMoreActions = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(navButtonBackground)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options")
        }
        .padding(.horizontal, 16)
        .safeAreaPadding(.top, 16)
        .frame(maxWidth: .infinity)
    }

    private var topSafeAreaBar: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 88)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .top)
            topNavOverlay
        }
        .frame(maxWidth: .infinity)
    }

    private var navButtonBackground: some View {
        Color.clear
            .background(.ultraThinMaterial, in: Circle())
    }

    private var scrollContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            hero
                .padding(.horizontal, 20)

            HStack(alignment: .top, spacing: 12) {
                Text(viewModel.event.title)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                CategoryPill(label: viewModel.event.category, category: viewModel.event.category)
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                EventMetaRow(
                    icon: "mappin.circle.fill",
                    text: "\(viewModel.event.venueName), \(viewModel.event.neighborhood)")
                EventMetaRow(
                    icon: "calendar", text: "\(viewModel.dateText), \(viewModel.timezoneLabel)")
                EventMetaRow(icon: "tag.fill", text: viewModel.priceLabel)
            }
            .padding(.horizontal, 20)

            if viewModel.attendees.isEmpty == false || (viewModel.event.goingCount ?? 0) > 0 {
                AttendeesRow(
                    attendees: viewModel.attendees,
                    goingCount: viewModel.event.goingCount ?? 0,
                    onTap: { viewModel.showAttendeeList = true }
                )
                .padding(.horizontal, 20)
            }

            if let about = viewModel.event.about {
                Text(about)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
            }

            if let coordinate = viewModel.event.coordinate {
                MapPreviewCard(
                    title: viewModel.event.venueName,
                    coordinate: coordinate,
                    onTap: { viewModel.showMapActions = true }
                )
                .padding(.horizontal, 20)
            }

            if let hostName = viewModel.hostName {
                HStack(spacing: 6) {
                    Text("Hosted by:")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(hostName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .padding(.bottom, 100)
    }

    /// Bottom bar: blur behind, button on top. Height includes bottom safe area so blur extends to screen edge.
    private static let bottomBlurHeight: CGFloat = 88

    private var bottomSafeAreaBar: some View {
        GeometryReader { geometry in
            let bottomInset = geometry.safeAreaInsets.bottom
            ZStack(alignment: .bottom) {
                bottomBlurFade(height: Self.bottomBlurHeight + bottomInset)
                stickyRSVPButton
                    .padding(.bottom, bottomInset)
            }
            .frame(height: Self.bottomBlurHeight + bottomInset)
            .frame(maxWidth: .infinity)
        }
        .frame(height: Self.bottomBlurHeight + 34)
        .ignoresSafeArea(edges: .bottom)
    }

    /// Blur fading up from the bottom; sits behind the RSVP button and extends to screen edge.
    private func bottomBlurFade(height: CGFloat) -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .mask(
                LinearGradient(
                    colors: [Color.clear, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
    }

    private var stickyRSVPButton: some View {
        Button {
            Task {
                if viewModel.isAttending {
                    await viewModel.handleUnregisterTap()
                } else {
                    await viewModel.handleRegisterTap()
                }
            }
        } label: {
            Text(viewModel.isAttending ? "Cancel RSVP" : "RSVP")
                .font(.headline.weight(.semibold))
                .foregroundStyle(viewModel.isAttending ? .white : .black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.plain)
        .background(
            viewModel.isAttending ? Color.white.opacity(0.15) : Color.white,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .accessibilityLabel("RSVP")
        .accessibilityHint(
            "Double tap to \(viewModel.isAttending ? "cancel your RSVP" : "RSVP to this event")"
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private var changeCoverSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Choose a new cover image")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
                PhotosPicker(
                    selection: $viewModel.changeCoverItem,
                    matching: .images
                ) {
                    Label("Select photo", systemImage: "photo.on.rectangle.angled")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(24)
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.showChangeCoverSheet = false }
                        .foregroundStyle(AppColors.primaryText)
                }
            }
        }
    }
}

@MainActor
final class EventDetailViewModel: ObservableObject {
    @Published var event: Event

    @Published var isInterested: Bool = false
    @Published var showMoreActions: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var showChangeCoverSheet: Bool = false
    @Published var changeCoverItem: PhotosPickerItem?

    @Published var isDeleteErrorPresented: Bool = false
    @Published var deleteErrorMessage: String?

    @Published var attendees: [Attendee] = []
    @Published var isAttending: Bool = false
    @Published var showAttendeeList: Bool = false
    @Published var showMapActions: Bool = false

    private let eventRepository: any EventRepository
    private let eventImageUploadService: any EventImageUploadService
    private let rsvpRepository: any RsvpRepository
    private let authSession: AuthSessionStore
    private let imageProcessor: ImageProcessor
    private let onDeleted: () -> Void
    private let onCoverChanged: () -> Void
    private let onRsvpChanged: () -> Void

    var isOwner: Bool { event.ownerID == authSession.userID }

    init(
        event: Event,
        eventRepository: any EventRepository,
        eventImageUploadService: any EventImageUploadService,
        rsvpRepository: any RsvpRepository,
        authSession: AuthSessionStore,
        imageProcessor: ImageProcessor = ImageProcessor(),
        onDeleted: @escaping () -> Void,
        onCoverChanged: @escaping () -> Void,
        onRsvpChanged: @escaping () -> Void
    ) {
        self.event = event
        self.eventRepository = eventRepository
        self.eventImageUploadService = eventImageUploadService
        self.rsvpRepository = rsvpRepository
        self.authSession = authSession
        self.imageProcessor = imageProcessor
        self.onDeleted = onDeleted
        self.onCoverChanged = onCoverChanged
        self.onRsvpChanged = onRsvpChanged
    }

    struct OrganizerDisplay: Hashable {
        let name: String
        let initials: String
        /// When set, show profile image instead of initials avatar.
        let profileImageURL: String?
    }

    var primaryOrganizer: OrganizerDisplay? {
        // Show current user as organizer when they created the event.
        if event.ownerID == authSession.userID {
            let name = authSession.userName ?? "Me"
            return OrganizerDisplay(
                name: name,
                initials: String(name.prefix(2)).uppercased().isEmpty
                    ? "ME" : String(name.prefix(2)).uppercased(),
                profileImageURL: authSession.profileImageURL
            )
        }
        if let first = event.hosts?.first {
            return OrganizerDisplay(
                name: first.name,
                initials: String(first.avatarPlaceholder.prefix(2)),
                profileImageURL: first.profileImageURL
            )
        }
        // Owner exists but profile not loaded (e.g. fetch failed or legacy data)
        return OrganizerDisplay(name: "Organizer", initials: "?", profileImageURL: nil)
    }

    var dateText: String {
        if let endDate = event.endDate {
            return EventDateFormatter.dateTimeRange(start: event.startDate, end: endDate)
        }
        return EventDateFormatter.dateOnly(event.startDate)
    }

    /// e.g. "February 28, 5:00 PM, Berlin time" — timezone label for display. TODO: use event timezone when added to model.
    var timezoneLabel: String { "local time" }

    /// e.g. "From $140" or "Free event". TODO: Add price to Event model when supported.
    var priceLabel: String { "Free event" }

    var hostName: String? { event.hosts?.first?.name }

    var canOpenGoogleMaps: Bool {
        guard let url = URL(string: "comgooglemaps://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func openInAppleMaps() {
        guard let coordinate = event.coordinate else { return }
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = event.venueName
        item.openInMaps(launchOptions: nil)
    }

    func openInGoogleMaps() {
        guard let coordinate = event.coordinate else { return }
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let urlString = "comgooglemaps://?q=\(lat),\(lon)&center=\(lat),\(lon)&zoom=14"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    func fetchAttendees() async {
        do {
            attendees = try await rsvpRepository.fetchAttendees(eventId: event.id)
            // Update event with current going count
            if !attendees.isEmpty {
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
                    hosts: event.hosts,
                    goingCount: attendees.count,
                    about: event.about
                )
            }
        } catch {
            print("[EventDetail] Failed to fetch attendees: \(error)")
            attendees = []
        }
    }

    func checkIsAttending() async {
        guard let userID = authSession.userID else {
            isAttending = false
            return
        }
        do {
            isAttending = try await rsvpRepository.isAttending(eventId: event.id, userId: userID)
        } catch {
            print("[EventDetail] Failed to check attending status: \(error)")
            isAttending = false
        }
    }

    func handleRegisterTap() async {
        guard let userID = authSession.userID else {
            // Show sign-in prompt or alert
            print("[EventDetail] User not signed in")
            return
        }

        do {
            try await rsvpRepository.addRsvp(eventId: event.id, userId: userID)
            isAttending = true
            await fetchAttendees()
            onRsvpChanged()
        } catch {
            print("[EventDetail] Failed to add RSVP: \(error)")
        }
    }

    func handleUnregisterTap() async {
        guard let userID = authSession.userID else {
            return
        }

        do {
            try await rsvpRepository.removeRsvp(eventId: event.id, userId: userID)
            isAttending = false
            await fetchAttendees()
            onRsvpChanged()
        } catch {
            print("[EventDetail] Failed to remove RSVP: \(error)")
        }
    }

    func handleContactTap() {
        print("Contact tapped")
    }

    func handleInterestedToggle() {
        print("Interested toggled: \(isInterested)")
    }

    func handleShareTap() {
        print("Share tapped")
    }

    func handleCopyLinkTap() {
        print("Copy link tapped")
    }

    func handleReportTap() {
        print("Report tapped")
    }

    func handleOrganizerTap() {
        print("Organizer tapped")
    }

    func handleDeleteTap() async {
        do {
            try await eventRepository.deleteEvent(id: event.id)
            await eventImageUploadService.deleteFromStorageIfOwned(url: event.imageNameOrURL)
            onDeleted()
            shouldDismiss = true
        } catch {
            deleteErrorMessage = error.localizedDescription
            isDeleteErrorPresented = true
        }
    }

    func uploadNewCoverAndReplace() async {
        guard let item = changeCoverItem else { return }
        guard let rawData = try? await item.loadTransferable(type: Data.self), !rawData.isEmpty
        else {
            changeCoverItem = nil
            return
        }
        // Capture old URL first (same pattern as profile: use current value before any update).
        let oldImageURL = event.imageNameOrURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasOldImageInOurBucket =
            oldImageURL.contains("event-images")
            || (oldImageURL.hasPrefix("http") && oldImageURL.contains("event-images"))
        do {
            // Preprocess: center-crop, resize to 512×512 (+ 100×100 thumb), JPEG-encode
            let processed = try await imageProcessor.processEventImage(from: rawData)

            // Upload preprocessed data with structured path
            let uploaded = try await eventImageUploadService.uploadPreprocessed(
                mainData: processed.main512,
                thumbData: processed.thumb100,
                eventId: event.id
            )
            let newURLString = uploaded.mainURL.absoluteString

            // Delete previous cover from storage (best-effort)
            if hasOldImageInOurBucket, !oldImageURL.isEmpty {
                await eventImageUploadService.deleteFromStorageIfOwned(url: oldImageURL)
            }
            try await eventRepository.updateEventCover(eventID: event.id, imageURL: newURLString)
            event = Event(
                id: event.id,
                ownerID: event.ownerID,
                title: event.title,
                category: event.category,
                startDate: event.startDate,
                venueName: event.venueName,
                neighborhood: event.neighborhood,
                distanceKm: event.distanceKm,
                imageNameOrURL: newURLString,
                isFeatured: event.isFeatured,
                endDate: event.endDate,
                addressLine: event.addressLine,
                coordinate: event.coordinate,
                hosts: event.hosts,
                goingCount: event.goingCount,
                about: event.about
            )
            onCoverChanged()
            showChangeCoverSheet = false
            changeCoverItem = nil
        } catch {
            print("[EventDetail] Change cover failed: \(error)")
            changeCoverItem = nil
        }
    }
}

// MARK: - Subviews

struct EventDetailSection<Content: View>: View {
    var showBorder: Bool = true
    var horizontalPadding: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, horizontalPadding)
        .background(
            AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            if showBorder {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
            }
        }
    }
}

struct EventLocationSection: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            EventDetailSectionHeader(title: "Location")

            VStack(alignment: .leading, spacing: 4) {
                Text(event.venueName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                Text(addressText)
                    .font(.footnote)
                    .foregroundStyle(AppColors.tertiaryText)
            }

            if let coordinate = event.coordinate {
                EventLocationMap(title: event.venueName, coordinate: coordinate)
            }
        }
    }

    private var addressText: String {
        if let addressLine = event.addressLine, !addressLine.isEmpty {
            return addressLine
        }
        return "\(event.neighborhood), Oslo"
    }
}

struct EventLocationMap: View {
    let title: String
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        let position = MapCameraPosition.region(region)

        Map(position: .constant(position)) {
            Marker(title.isEmpty ? "Location" : title, coordinate: coordinate)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
        }
    }
}

struct EventHostsSection: View {
    let hosts: [Host]
    let category: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            EventDetailSectionHeader(title: "Hosts")

            ForEach(hosts) { host in
                HostRow(host: host, category: category)
            }
        }
    }
}

struct HostRow: View {
    let host: Host
    let category: String

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let url = host.profileImageURL {
                    UserAvatarView(imageURL: url, size: 36)
                } else {
                    EventAvatar(
                        initials: String(host.avatarPlaceholder.prefix(2)), category: category
                    )
                    .frame(width: 36, height: 36)
                }
            }

            Text(host.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
        }
    }
}

struct EventAttendingSection: View {
    let attendees: [Attendee]
    let goingCount: Int?
    let onTap: () -> Void

    private var displayCount: Int {
        if !attendees.isEmpty {
            return attendees.count
        }
        return goingCount ?? 0
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                EventDetailSectionHeader(title: "Attending")

                Text("\(displayCount) going")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)

                if !attendees.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(Array(attendees.prefix(5).enumerated()), id: \.element.id) {
                            index, attendee in
                            if let avatarURL = attendee.avatarURL {
                                UserAvatarView(imageURL: avatarURL, size: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Text(attendee.name?.prefix(2).uppercased() ?? "?")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppColors.tertiaryText)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                            }
                        }
                    }
                } else if displayCount > 0 {
                    HStack(spacing: -8) {
                        ForEach(0..<min(3, displayCount), id: \.self) { _ in
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.tertiaryText)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct AttendeeListView: View {
    let attendees: [Attendee]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if attendees.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColors.secondaryText)
                        Text("No attendees yet")
                            .font(.headline)
                            .foregroundStyle(AppColors.primaryText)
                        Text("Be the first to register!")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(attendees) { attendee in
                            HStack(spacing: 12) {
                                if let avatarURL = attendee.avatarURL {
                                    UserAvatarView(imageURL: avatarURL, size: 44)
                                } else {
                                    Circle()
                                        .fill(AppColors.surface)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Text(attendee.name?.prefix(2).uppercased() ?? "?")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(AppColors.secondaryText)
                                        )
                                }

                                Text(attendee.name ?? "Someone")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColors.primaryText)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Attendees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.primaryText)
                }
            }
        }
    }
}

struct EventAboutSection: View {
    let about: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EventDetailSectionHeader(title: "About")

            Text(about)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
        }
    }
}

struct EventDetailSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            Rectangle()
                .fill(AppColors.divider.opacity(0.8))
                .frame(height: 1)
        }
        .padding(.bottom, 6)
    }
}

struct CategoryPill: View {
    let label: String
    let category: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: EventCategories.icon(for: category))
                .font(.subheadline.weight(.medium))
            Text(label)
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color.white.opacity(0.18),
            in: Capsule(style: .continuous)
        )
    }
}

struct EventMetaRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 22, alignment: .center)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

struct AttendeesRow: View {
    let attendees: [Attendee]
    let goingCount: Int
    let onTap: () -> Void

    private var displayCount: Int {
        if !attendees.isEmpty { return attendees.count }
        return goingCount
    }

    private var label: String {
        if attendees.isEmpty {
            return "\(displayCount)+ going"
        }
        let names = attendees.prefix(2).compactMap { $0.name }
        if names.isEmpty {
            return "\(displayCount)+ going"
        }
        if names.count == 1 {
            return "\(displayCount)+ (inc. \(names[0]) and other friends)"
        }
        return "\(displayCount)+ (inc. \(names[0]), \(names[1]) and other friends)"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                HStack(spacing: -10) {
                    ForEach(Array(attendees.prefix(5).enumerated()), id: \.element.id) {
                        _, attendee in
                        if let avatarURL = attendee.avatarURL {
                            UserAvatarView(imageURL: avatarURL, size: 32)
                                .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.5))
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(attendee.name?.prefix(2).uppercased() ?? "?")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white)
                                )
                                .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.5))
                        }
                    }
                    if attendees.isEmpty && displayCount > 0 {
                        ForEach(0..<min(4, displayCount), id: \.self) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.8))
                                )
                                .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.5))
                        }
                    }
                }
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

struct MapPreviewCard: View {
    let title: String
    let coordinate: CLLocationCoordinate2D
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                let region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                let position = MapCameraPosition.region(region)

                Map(position: .constant(position)) {
                    Marker(title.isEmpty ? "Location" : title, coordinate: coordinate)
                }
                .allowsHitTesting(false)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("View location")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5), in: Capsule())
                    .padding(12)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View event location on map")
    }
}

struct BlurredCoverBackground: View {
    let imageNameOrURL: String
    let category: String

    private var resolvedURL: URL? {
        let trimmed = imageNameOrURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") else { return nil }
        if let url = URL(string: trimmed) { return url }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        guard let encoded, !encoded.isEmpty else { return nil }
        return URL(string: encoded)
    }

    private var gradientPlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.color(for: category) ?? AppColors.accent,
                        (AppColors.color(for: category) ?? AppColors.accent).opacity(0.55),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    var body: some View {
        ZStack {
            Group {
                if let url = resolvedURL {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        gradientPlaceholder
                    }
                } else {
                    gradientPlaceholder
                }
            }
            .frame(minWidth: 0, minHeight: 0)
            .blur(radius: 60)
            .ignoresSafeArea()

            Color.black.opacity(0.45)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.clear,
                    Color.black.opacity(0.5),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct EventHeroImage: View {
    let imageNameOrURL: String
    let category: String

    var body: some View {
        ZStack {
            if let url = resolvedURL {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .contentShape(Rectangle())
    }

    private var resolvedURL: URL? {
        let trimmed = imageNameOrURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") else { return nil }
        if let url = URL(string: trimmed) { return url }
        // If the user pasted a URL with spaces or unicode, try percent-encoding.
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        guard let encoded, !encoded.isEmpty else { return nil }
        return URL(string: encoded)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 0, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [startColor, endColor], startPoint: .topLeading,
                    endPoint: .bottomTrailing)
            )
            .overlay {
                LinearGradient(
                    colors: [Color.clear, AppColors.overlay.opacity(0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }

    private var startColor: Color {
        AppColors.color(for: category) ?? AppColors.accent
    }

    private var endColor: Color {
        (AppColors.color(for: category) ?? AppColors.accent).opacity(0.55)
    }
}

struct EventDetailFloatingButton: View {
    let systemImageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImageName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct EventVenueBadge: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            AppColors.overlay.opacity(0.35),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EventAvatar: View {
    let initials: String
    let category: String

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        (AppColors.color(for: category) ?? AppColors.accent).opacity(0.95),
                        (AppColors.color(for: category) ?? AppColors.accent).opacity(0.55),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text(initials.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
    }
}

#Preview("Event detail — AI") {
    let event = Event(
        id: UUID(),
        ownerID: nil,
        title: "Nordic AI Night",
        category: "AI",
        startDate: Date(timeIntervalSinceNow: 60 * 60 * 24),
        venueName: "Mesh Oslo",
        neighborhood: "Sentrum",
        distanceKm: 1.2,
        imageNameOrURL:
            "https://images.unsplash.com/photo-1521737604893-d14cc237f11d?q=80&w=2000&auto=format&fit=crop",
        isFeatured: true,
        endDate: Date(timeIntervalSinceNow: 60 * 60 * 24 + 60 * 60 * 2),
        addressLine: "Tordenskiolds gate 2, 0160 Oslo, Norway",
        coordinate: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7461),
        hosts: [Host(id: UUID(), name: "Candyce Costa", avatarPlaceholder: "CC")],
        goingCount: 75,
        about: "A relaxed meetup for AI builders in Oslo."
    )
    return EventDetailView(
        event: event,
        eventRepository: MockEventRepository(),
        eventImageUploadService: MockEventImageUploadService(),
        rsvpRepository: MockRsvpRepository(),
        authSession: AuthSessionStore(authRepository: PreviewAuthRepository())
    )
}

#Preview("Event detail — Music") {
    let event = Event(
        id: UUID(),
        ownerID: nil,
        title: "The Weeknd Starboy concert",
        category: "Music",
        startDate: Date(timeIntervalSinceNow: 60 * 60 * 24 * 7),
        venueName: "Olympischer Platz 3",
        neighborhood: "Berlin",
        distanceKm: 0,
        imageNameOrURL:
            "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?q=80&w=2000&auto=format&fit=crop",
        isFeatured: true,
        endDate: nil,
        addressLine: "Olympischer Platz 3, Berlin",
        coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        hosts: [Host(id: UUID(), name: "Live Nation", avatarPlaceholder: "LN")],
        goingCount: 750,
        about:
            "The tour celebrates The Weeknd's album After Hours, as well as his critically-acclaimed album Dawn FM."
    )
    return EventDetailView(
        event: event,
        eventRepository: MockEventRepository(),
        eventImageUploadService: MockEventImageUploadService(),
        rsvpRepository: MockRsvpRepository(),
        authSession: AuthSessionStore(authRepository: PreviewAuthRepository())
    )
}

#Preview("Event detail — Food") {
    let event = Event(
        id: UUID(),
        ownerID: nil,
        title: "Sourdough & Stories",
        category: "Food & Drink",
        startDate: Date(timeIntervalSinceNow: 60 * 60 * 24 * 2),
        venueName: "Mathallen",
        neighborhood: "Grünerløkka",
        distanceKm: 3.2,
        imageNameOrURL:
            "https://images.unsplash.com/photo-1592753054398-9fa298d40e85?q=80&w=1665&auto=format&fit=crop",
        isFeatured: false,
        endDate: Date(timeIntervalSinceNow: 60 * 60 * 24 * 2 + 60 * 60 * 2),
        addressLine: "Vulkan 5, 0178 Oslo, Norway",
        coordinate: CLLocationCoordinate2D(latitude: 59.9226, longitude: 10.7527),
        hosts: [Host(id: UUID(), name: "Elin Strand", avatarPlaceholder: "ES")],
        goingCount: 28,
        about:
            "A cozy evening of bread tasting and short stories. Come for the crust, stay for the conversation."
    )
    return EventDetailView(
        event: event,
        eventRepository: MockEventRepository(),
        eventImageUploadService: MockEventImageUploadService(),
        rsvpRepository: MockRsvpRepository(),
        authSession: AuthSessionStore(authRepository: PreviewAuthRepository())
    )
}
