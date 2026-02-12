//
//  FeedView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 01/02/2026.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @EnvironmentObject private var authSession: AuthSessionStore
    @State private var selectedEvent: Event?
    @State private var isProfilePresented: Bool = false

    private let eventRepository: any EventRepository
    private let profileRepository: any ProfileRepository
    private let notificationSettingsRepository: any NotificationSettingsRepository
    private let rsvpRepository: any RsvpRepository
    private let eventImageUploadService: any EventImageUploadService
    private let profileImageUploadService: any ProfileImageUploadService
    private let onDiscoverTapped: (() -> Void)?

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
        profileRepository: any ProfileRepository = MockProfileRepository(),
        notificationSettingsRepository: any NotificationSettingsRepository = MockNotificationSettingsRepository(),
        rsvpRepository: any RsvpRepository = MockRsvpRepository(),
        eventImageUploadService: any EventImageUploadService = MockEventImageUploadService(),
        profileImageUploadService: any ProfileImageUploadService = MockProfileImageUploadService(),
        onDiscoverTapped: (() -> Void)? = nil
    ) {
        self.eventRepository = eventRepository
        self.profileRepository = profileRepository
        self.notificationSettingsRepository = notificationSettingsRepository
        self.rsvpRepository = rsvpRepository
        self.eventImageUploadService = eventImageUploadService
        self.profileImageUploadService = profileImageUploadService
        self.onDiscoverTapped = onDiscoverTapped
        _viewModel = StateObject(wrappedValue: FeedViewModel(repository: eventRepository))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 68)

                        if viewModel.feedEvents.isEmpty {
                            emptyState
                                .padding(.top, 12)
                                .padding(.bottom, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.feedEvents) { event in
                                    Button {
                                        selectedEvent = event
                                    } label: {
                                        EventRow(
                                            event: event,
                                            dateText: viewModel.dateText(for: event)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(20)
                            .padding(.bottom, 40)
                        }
                    }
                }
                .background(AppColors.background.ignoresSafeArea())
                .refreshable {
                    await viewModel.refresh()
                }
                .onAppear {
                    Task { await viewModel.refresh() }
                }

                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(true)
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
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(
                event: event,
                eventRepository: eventRepository,
                eventImageUploadService: eventImageUploadService,
                rsvpRepository: rsvpRepository,
                authSession: authSession,
                onDeleted: { Task { await viewModel.refresh() } },
                onCoverChanged: {
                    Task {
                        await viewModel.refreshAndUpdateSelected(selectedEventId: event.id)
                        // Update selectedEvent with the refreshed data
                        if let updatedEvent = viewModel.event(by: event.id) {
                            selectedEvent = updatedEvent
                        }
                    }
                },
                onRsvpChanged: {}
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isProfilePresented) {
            SettingsView(
                authSession: authSession,
                profileRepository: profileRepository,
                notificationSettingsRepository: notificationSettingsRepository,
                profileImageUploadService: profileImageUploadService
            )
            .environmentObject(authSession)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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

            Text("Feed")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.secondaryText)

            VStack(spacing: 8) {
                Text("No friends or organizers yet")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .multilineTextAlignment(.center)

                Text("Follow friends and organizers to see their events here.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Button {
                onDiscoverTapped?()
            } label: {
                Label("Discover", systemImage: "magnifyingglass")
                    .font(.headline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FeedView(
        eventRepository: MockEventRepository(),
        profileImageUploadService: MockProfileImageUploadService()
    )
    .environmentObject(AuthSessionStore(authRepository: PreviewAuthRepository()))
}
