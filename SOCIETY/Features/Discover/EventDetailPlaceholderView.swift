//
//  EventDetailPlaceholderView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 16/01/2026.
//

import SwiftUI

struct EventDetailPlaceholderView: View {
    let event: Event

    var body: some View {
        VStack(spacing: 12) {
            Text(event.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Text("Event details coming soon.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
