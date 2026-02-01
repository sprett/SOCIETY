//
//  DiscoverView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Combine
import CoreLocation
import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel: DiscoverViewModel
    @EnvironmentObject private var authSession: AuthSessionStore
    @State private var selectedEvent: Event?
    @State private var isProfilePresented: Bool = false
    @State private var isMapPresented: Bool = false
    private let eventRepository: any EventRepository
    private let rsvpRepository: any RsvpRepository
    private let eventImageUploadService: any EventImageUploadService
    private let profileImageUploadService: any ProfileImageUploadService
    @ObservedObject private var locationManager: LocationManager
    private let onHostEventTapped: (() -> Void)?

    private var isEventDetailPresented: Bool {
        selectedEvent != nil
    }

    private var backgroundBlurRadius: CGFloat {
        isEventDetailPresented ? 10 : 0
    }

    private var backgroundDimOpacity: Double {
        isEventDetailPresented ? 0.12 : 0
    }

    init(
        eventRepository: any EventRepository = MockEventRepository(),
        rsvpRepository: any RsvpRepository = MockRsvpRepository(),
        eventImageUploadService: any EventImageUploadService = MockEventImageUploadService(),
        profileImageUploadService: any ProfileImageUploadService = MockProfileImageUploadService(),
        locationManager: LocationManager,
        onHostEventTapped: (() -> Void)? = nil
    ) {
        self.eventRepository = eventRepository
        self.rsvpRepository = rsvpRepository
        self.eventImageUploadService = eventImageUploadService
        self.profileImageUploadService = profileImageUploadService
        _locationManager = ObservedObject(wrappedValue: locationManager)
        self.onHostEventTapped = onHostEventTapped
        _viewModel = StateObject(
            wrappedValue: DiscoverViewModel(
                repository: eventRepository, locationManager: locationManager))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Spacer to account for sticky header
                        Color.clear
                            .frame(height: 68)

                        LazyVStack(alignment: .leading, spacing: 24) {
                            categorySection
                            featuredSection
                            nearbySection
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                        .padding(.horizontal, 20)
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .onAppear {
                    locationManager.requestLocationPermission()
                    locationManager.getCurrentLocation()
                    Task { await viewModel.refresh() }
                }
                .background(AppColors.background.ignoresSafeArea())

                // Top gradient so content doesn't stack under the header (extends into top safe area)
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [AppColors.background, AppColors.background.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    .allowsHitTesting(false)
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)

                // Sticky header - always present with blur background
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(true)
            }
        }
        .tint(AppColors.primaryText)
        .blur(radius: backgroundBlurRadius)
        .overlay {
            if isEventDetailPresented {
                Rectangle()
                    .fill(Color.black.opacity(backgroundDimOpacity))
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isEventDetailPresented)
        .sheet(item: $selectedEvent) { event in
            EventDetailView(
                event: event,
                eventRepository: eventRepository,
                eventImageUploadService: eventImageUploadService,
                rsvpRepository: rsvpRepository,
                authSession: authSession,
                onDeleted: { Task { await viewModel.refresh() } },
                onCoverChanged: { Task { await viewModel.refresh() } },
                onRsvpChanged: {}
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isProfilePresented) {
            SettingsView(
                authSession: authSession,
                profileImageUploadService: profileImageUploadService
            )
            .environmentObject(authSession)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isMapPresented) {
            MapView(
                eventRepository: eventRepository,
                eventImageUploadService: eventImageUploadService,
                onDismiss: { isMapPresented = false }
            )
            .environmentObject(authSession)
        }
    }

    @ViewBuilder
    private var liquidGlassBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: .circle)
        } else {
            // Fallback for iOS < 26 - use ultraThinMaterial for liquid glass effect
            Color.clear
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                isProfilePresented = true
            } label: {
                UserAvatarView(imageURL: authSession.profileImageURL, size: 44)
            }
            .buttonStyle(.plain)

            Text("Discover")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                isMapPresented = true
            } label: {
                Image(systemName: "map")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 40, height: 40)
                    .background(liquidGlassBackground)
                    .clipShape(Circle())
            }

            Button {
                viewModel.handleSearchTap()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 40, height: 40)
                    .background(liquidGlassBackground)
                    .clipShape(Circle())
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Category")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.categoryOptions) { option in
                        CategoryChip(
                            title: option.title,
                            systemImageName: option.systemImageName,
                            isSelected: viewModel.selectedCategory == option.title
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.selectedCategory = option.title
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    private var featuredSection: some View {
        Group {
            if viewModel.selectedCategory == "All" && !viewModel.featuredEvents.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Featured events")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppColors.primaryText)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.featuredEvents) { event in
                                Button {
                                    selectedEvent = event
                                } label: {
                                    FeaturedEventCard(
                                        event: event,
                                        dateText: viewModel.dateText(for: event)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedCategory)
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Events near you")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            if viewModel.isSelectedCategoryEmpty {
                categoryEmptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.nearbyEventsGroupedByDate(), id: \.date) { group in
                        // Date divider
                        HStack {
                            Text(viewModel.dateHeaderText(for: group.date))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColors.secondaryText)
                            Spacer()
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        // Events for this date
                        ForEach(group.events) { event in
                            Button {
                                selectedEvent = event
                            } label: {
                                EventRow(
                                    event: event,
                                    dateText: viewModel.dateText(for: event),
                                    displayDistanceKm: viewModel.distanceFromUser(for: event)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedCategory)
    }

    private var categoryEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)

            Text("No \(viewModel.selectedCategory) events yet")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.center)

            Text("Be the first to host something for your community.")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)

            if let onHost = onHostEventTapped {
                Button {
                    onHost()
                } label: {
                    Label("Host an event", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accent)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}

@MainActor
final class DiscoverViewModel: ObservableObject {
    struct CategoryOption: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let systemImageName: String
    }

    @Published private(set) var events: [Event] = []
    @Published var selectedCategory: String = "All"

    private let repository: any EventRepository
    private let locationManager: LocationManager

    init(repository: any EventRepository, locationManager: LocationManager) {
        self.repository = repository
        self.locationManager = locationManager
    }

    /// Distance in km from the user's current location to the event. Nil if user location or event coordinate is unavailable.
    func distanceFromUser(for event: Event) -> Double? {
        guard let userCoord = locationManager.userLocation,
            let eventCoord = event.coordinate
        else { return nil }
        let userLocation = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let eventLocation = CLLocation(
            latitude: eventCoord.latitude, longitude: eventCoord.longitude)
        return eventLocation.distance(from: userLocation) / 1000
    }

    /// All categories (same as event create). "All" plus every category, even if empty.
    var categoryOptions: [CategoryOption] {
        let options = EventCategories.all.map { category in
            CategoryOption(title: category, systemImageName: EventCategories.icon(for: category))
        }
        return [CategoryOption(title: "All", systemImageName: "sparkles")] + options
    }

    var isSelectedCategoryEmpty: Bool {
        selectedCategory != "All" && filteredEvents.isEmpty
    }

    var featuredEvents: [Event] {
        filteredEvents.filter { $0.isFeatured }
    }

    var nearbyEvents: [Event] {
        let events = filteredEvents
        guard locationManager.userLocation != nil else {
            return events.sorted { $0.startDate < $1.startDate }
        }
        // Sort by date first, then by distance for events on the same date
        return events.sorted { e1, e2 in
            // Compare dates (ignoring time)
            let calendar = Calendar.current
            let date1 = calendar.startOfDay(for: e1.startDate)
            let date2 = calendar.startOfDay(for: e2.startDate)

            if date1 != date2 {
                return date1 < date2
            }

            // Same date: sort by distance
            let d1 = distanceFromUser(for: e1) ?? .infinity
            let d2 = distanceFromUser(for: e2) ?? .infinity
            return d1 < d2
        }
    }

    func nearbyEventsGroupedByDate() -> [(date: Date, events: [Event])] {
        let sorted = nearbyEvents
        let calendar = Calendar.current

        // Group events by date
        let grouped = Dictionary(grouping: sorted) { event in
            calendar.startOfDay(for: event.startDate)
        }

        // Convert to array of tuples and sort by date
        return grouped.map { (date: $0.key, events: $0.value) }
            .sorted { $0.date < $1.date }
    }

    func dateHeaderText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "d. MMMM"
        return formatter.string(from: date)
    }

    func dateText(for event: Event) -> String {
        Self.dateFormatter.string(from: event.startDate)
    }

    func handleSearchTap() {
        print("Discover search tapped")
    }

    private var filteredEvents: [Event] {
        guard selectedCategory != "All" else { return events }
        return events.filter { $0.category == selectedCategory }
    }

    private func loadEvents() async {
        do {
            events = try await repository.fetchEvents()
        } catch {
            // TODO: surface error in UI when we add a shared error component
            events = []
        }
    }

    func refresh() async {
        await loadEvents()
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d · HH:mm"
        formatter.locale = Locale.current
        return formatter
    }()

}

#Preview {
    DiscoverView(locationManager: LocationManager())
}
