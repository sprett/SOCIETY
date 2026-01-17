//
//  MainTabView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() {
        // Configure tab bar appearance to remove white background section
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        // Use a subtle background with blur for better visibility
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // Discover Tab
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(0)
            
            // Home Tab
            EventListView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(1)
            
            // Map Tab
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
}
