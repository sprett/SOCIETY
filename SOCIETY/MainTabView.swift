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
                profileImageUploadService: dependencies.profileImageUploadService,
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
                eventImageUploadService: dependencies.eventImageUploadService,
                profileImageUploadService: dependencies.profileImageUploadService,
                requestCreate: $requestCreate
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(1)
            
            // Map Tab
            MapView(eventRepository: dependencies.eventRepository)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
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
