//
//  DiscoverView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import SwiftUI

struct DiscoverView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Discover")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Discover events coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Discover")
        }
    }
}

#Preview {
    DiscoverView()
}
