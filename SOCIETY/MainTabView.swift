//
//  MainTabView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var requestCreate = false
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .preview()) {
        self.dependencies = dependencies
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // Discover Tab
            DiscoverView(
                eventRepository: dependencies.eventRepository,
                profileRepository: dependencies.profileRepository,
                notificationSettingsRepository: dependencies.notificationSettingsRepository,
                rsvpRepository: dependencies.rsvpRepository,
                eventImageUploadService: dependencies.eventImageUploadService,
                profileImageUploadService: dependencies.profileImageUploadService,
                locationManager: dependencies.locationManager,
                onHostEventTapped: {
                    selectedTab = 1
                    requestCreate = true
                }
            )
            .tabItem {
                Label("Discover", systemImage: "magnifyingglass")
            }
            .tag(0)

            // Home Tab
            EventListView(
                eventRepository: dependencies.eventRepository,
                authRepository: dependencies.authRepository,
                profileRepository: dependencies.profileRepository,
                notificationSettingsRepository: dependencies.notificationSettingsRepository,
                eventImageUploadService: dependencies.eventImageUploadService,
                profileImageUploadService: dependencies.profileImageUploadService,
                rsvpRepository: dependencies.rsvpRepository,
                locationManager: dependencies.locationManager,
                requestCreate: $requestCreate
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(1)

            // Feed Tab
            FeedView(
                eventRepository: dependencies.eventRepository,
                profileRepository: dependencies.profileRepository,
                notificationSettingsRepository: dependencies.notificationSettingsRepository,
                rsvpRepository: dependencies.rsvpRepository,
                eventImageUploadService: dependencies.eventImageUploadService,
                profileImageUploadService: dependencies.profileImageUploadService,
                onDiscoverTapped: { selectedTab = 0 }
            )
            .tabItem {
                Label("Feed", systemImage: "list.bullet")
            }
            .tag(2)
        }
        .onChange(of: selectedTab) { _, _ in
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

#Preview {
    MainTabView(dependencies: .preview())
        .environmentObject(AuthSessionStore(authRepository: PreviewAuthRepository()))
}
