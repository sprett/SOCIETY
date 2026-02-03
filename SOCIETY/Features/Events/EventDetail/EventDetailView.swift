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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                hero

                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.event.title)
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.leading)

                    if let organizer = viewModel.primaryOrganizer {
                        Button {
                            viewModel.handleOrganizerTap()
                        } label: {
                            HStack(spacing: 8) {
                                Group {
                                    if let url = organizer.profileImageURL {
                                        UserAvatarView(imageURL: url, size: 18)
                                    } else {
                                        EventAvatar(
                                            initials: organizer.initials,
                                            category: viewModel.event.category
                                        )
                                        .frame(width: 18, height: 18)
                                    }
                                }

                                Text(organizer.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColors.secondaryText)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppColors.tertiaryText)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Text(viewModel.dateText)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.tertiaryText)
                }

                if let about = viewModel.event.about {
                    EventDetailSection {
                        EventAboutSection(about: about)
                    }
                }

                if !viewModel.attendees.isEmpty || viewModel.event.goingCount != nil {
                    EventDetailSection {
                        EventAttendingSection(
                            attendees: viewModel.attendees,
                            goingCount: viewModel.attendees.isEmpty
                                ? viewModel.event.goingCount : nil,
                            onTap: {
                                viewModel.showAttendeeList = true
                            }
                        )
                    }
                }

                if viewModel.event.addressLine != nil || viewModel.event.coordinate != nil {
                    EventDetailSection {
                        EventLocationSection(event: viewModel.event)
                    }
                }

                if let hosts = viewModel.event.hosts, !hosts.isEmpty {
                    EventDetailSection {
                        EventHostsSection(hosts: hosts, category: viewModel.event.category)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(AppColors.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            actionBar
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
    }

    private var hero: some View {
        GeometryReader { geometry in
            let squareSize = geometry.size.width

            EventHeroImage(
                imageNameOrURL: viewModel.event.imageNameOrURL, category: viewModel.event.category
            )
            .frame(width: squareSize, height: squareSize)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                EventDetailFloatingButton(systemImageName: "square.and.arrow.up") {
                    viewModel.handleShareTap()
                }
                .padding(14)
            }
            .overlay(alignment: .bottomTrailing) {
                EventVenueBadge(title: viewModel.event.venueName)
                    .padding(14)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    if viewModel.isAttending {
                        await viewModel.handleUnregisterTap()
                    } else {
                        await viewModel.handleRegisterTap()
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.isAttending ? "xmark" : "plus")
                        .font(.subheadline.weight(.semibold))
                    Text(viewModel.isAttending ? "Unregister" : "Register")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(viewModel.isAttending ? AppColors.primaryText : .black)
            .background {
                if viewModel.isAttending {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                }
            }
            .overlay {
                if viewModel.isAttending {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
                }
            }

            Button {
                viewModel.handleContactTap()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope")
                        .font(.subheadline.weight(.semibold))
                    Text("Contact")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.primaryText)
            .background(
                .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
            }

            Button {
                viewModel.showMoreActions = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.weight(.semibold))
                    Text("More")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.primaryText)
            .background(
                .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
            }
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

    private let eventRepository: any EventRepository
    private let eventImageUploadService: any EventImageUploadService
    private let rsvpRepository: any RsvpRepository
    private let authSession: AuthSessionStore
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
        onDeleted: @escaping () -> Void,
        onCoverChanged: @escaping () -> Void,
        onRsvpChanged: @escaping () -> Void
    ) {
        self.event = event
        self.eventRepository = eventRepository
        self.eventImageUploadService = eventImageUploadService
        self.rsvpRepository = rsvpRepository
        self.authSession = authSession
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
        guard let imageData = try? await item.loadTransferable(type: Data.self), !imageData.isEmpty
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
            let newURL = try await eventImageUploadService.upload(imageData)
            let newURLString = newURL.absoluteString
            // Delete previous cover from storage before updating the event (same order as profile: delete old after upload, so we remove the file we're replacing).
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

struct EventHeroImage: View {
    let imageNameOrURL: String
    let category: String

    var body: some View {
        ZStack {
            if let url = resolvedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
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

#Preview {
    let previewEvent = Event(
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
        event: previewEvent,
        eventRepository: MockEventRepository(),
        eventImageUploadService: MockEventImageUploadService(),
        rsvpRepository: MockRsvpRepository(),
        authSession: AuthSessionStore(authRepository: PreviewAuthRepository())
    )
}
