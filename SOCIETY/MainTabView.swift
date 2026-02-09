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
                Label("Discover", systemImage: "magnifyingglass.circle")
                    .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
            }
            .tag(0)

            // Home Tab
            EventListView(
                eventRepository: dependencies.eventRepository,
                authRepository: dependencies.authRepository,
                eventImageUploadService: dependencies.eventImageUploadService,
                profileImageUploadService: dependencies.profileImageUploadService,
                rsvpRepository: dependencies.rsvpRepository,
                locationManager: dependencies.locationManager,
                requestCreate: $requestCreate
            )
            .tabItem {
                Label("Home", systemImage: "house")
                    .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
            }
            .tag(1)

            // Feed Tab
            FeedView(
                eventRepository: dependencies.eventRepository,
                rsvpRepository: dependencies.rsvpRepository,
                eventImageUploadService: dependencies.eventImageUploadService,
                profileImageUploadService: dependencies.profileImageUploadService,
                onDiscoverTapped: { selectedTab = 0 }
            )
            .tabItem {
                Label("Feed", systemImage: "list.bullet.rectangle")
                    .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
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
