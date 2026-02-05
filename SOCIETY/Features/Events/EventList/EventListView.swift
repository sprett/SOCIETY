//
//  EventListView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Combine
import SwiftUI

struct EventListView: View {
    @StateObject private var viewModel: EventListViewModel
    @EnvironmentObject private var authSession: AuthSessionStore
    @Binding var requestCreate: Bool

    private let eventRepository: any EventRepository
    private let authRepository: any AuthRepository
    private let eventImageUploadService: any EventImageUploadService
    private let profileImageUploadService: any ProfileImageUploadService
    private let rsvpRepository: any RsvpRepository
    @ObservedObject private var locationManager: LocationManager

    @State private var selectedEvent: Event?
    @State private var isCreatePresented: Bool = false
    @State private var isProfilePresented: Bool = false

    init(
        eventRepository: any EventRepository = MockEventRepository(),
        authRepository: any AuthRepository = PreviewAuthRepository(),
        eventImageUploadService: any EventImageUploadService = MockEventImageUploadService(),
        profileImageUploadService: any ProfileImageUploadService = MockProfileImageUploadService(),
        rsvpRepository: any RsvpRepository = MockRsvpRepository(),
        locationManager: LocationManager,
        requestCreate: Binding<Bool> = .constant(false)
    ) {
        self.eventRepository = eventRepository
        self.authRepository = authRepository
        self.eventImageUploadService = eventImageUploadService
        self.profileImageUploadService = profileImageUploadService
        self.rsvpRepository = rsvpRepository
        _locationManager = ObservedObject(wrappedValue: locationManager)
        _requestCreate = requestCreate
        // Note: userID will be set via onChange of authSession.userID
        // We can't access authSession here in init, so start with nil
        _viewModel = StateObject(
            wrappedValue: EventListViewModel(
                repository: eventRepository,
                rsvpRepository: rsvpRepository,
                locationManager: locationManager,
                userID: nil
            )
        )
    }

    private var isEventDetailPresented: Bool {
        selectedEvent != nil
    }

    private var backgroundBlurRadius: CGFloat {
        isEventDetailPresented ? 10 : 0
    }

    private var backgroundDimOpacity: Double {
        isEventDetailPresented ? 0.12 : 0
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 68)

                        VStack(alignment: .leading, spacing: 24) {
                            nextEventSection
                            attendingSection
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                        .padding(.horizontal, 20)
                    }
                }
                .background(AppColors.background.ignoresSafeArea())
                .onAppear {
                    // Set initial userID and refresh
                    locationManager.requestLocationPermission()
                    locationManager.getCurrentLocation()
                    viewModel.updateUserID(authSession.userID)
                    viewModel.refresh()
                }
                .onChange(of: authSession.userID) { _, _ in
                    // Update ViewModel with current userID when auth state changes
                    viewModel.updateUserID(authSession.userID)
                    viewModel.refresh()
                }

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
        .fullScreenCover(isPresented: $isCreatePresented) {
            EventCreateSheetHost(
                authSession: authSession,
                onCreated: { createdEvent in
                    selectedEvent = createdEvent
                    viewModel.refresh()
                    isCreatePresented = false
                },
                onDismiss: { isCreatePresented = false }
            )
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(
                event: event,
                eventRepository: eventRepository,
                eventImageUploadService: eventImageUploadService,
                rsvpRepository: rsvpRepository,
                authSession: authSession,
                onDeleted: { viewModel.refresh() },
                onCoverChanged: { viewModel.refresh() },
                onRsvpChanged: { viewModel.refresh() }
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
        .onChange(of: requestCreate) { _, requested in
            if requested {
                isCreatePresented = true
                requestCreate = false
            }
        }
    }

    @ViewBuilder
    private var liquidGlassBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: .circle)
        } else {
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

            Text("Society")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                isCreatePresented = true
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 40, height: 40)
                    .background(liquidGlassBackground)
                    .clipShape(Circle())
            }
        }
    }

    private var nextEventSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next up")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            if let event = viewModel.nextEvent {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
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
                    .padding(.vertical, 4)
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            } else {
                if authSession.userID == nil {
                    Text("Sign in to see events you're attending.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                } else {
                    Text("No upcoming events yet.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }

    private var attendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attending Events")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            if authSession.userID == nil {
                Text("Sign in to see events you're attending.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            } else if viewModel.events.isEmpty {
                Text("You haven't registered for any events yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.events) { event in
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
}

#Preview {
    EventListView(locationManager: LocationManager())
        .environmentObject(AuthSessionStore(authRepository: PreviewAuthRepository()))
}
