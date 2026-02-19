//
//  ContentView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import SwiftUI

/// Legacy entry point from the initial prototype.
/// The app now starts in `SOCIETYApp` -> `MainTabView`.
struct ContentView: View {
    var body: some View {
        MainTabView(eventsStore: EventsStore())
    }
}

#Preview {
    ContentView()
}
