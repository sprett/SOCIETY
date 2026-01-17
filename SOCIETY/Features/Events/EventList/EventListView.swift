//
//  EventListView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import SwiftUI

struct EventListView: View {
    @StateObject private var viewModel = EventListViewModel()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Discover Events")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                // Event List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.events) { event in
                            EventCard(event: event, dateFormatter: dateFormatter)
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)  // Add bottom padding so content isn't hidden behind tab bar
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct EventCard: View {
    let event: Event
    let dateFormatter: DateFormatter

    var body: some View {
        HStack(spacing: 12) {
            // 1:1 Image
            EventImageView(imageNameOrURL: event.imageNameOrURL, category: event.category)
                .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(dateFormatter.string(from: event.startDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)
                    Text("\(event.venueName), \(event.neighborhood)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    EventListView()
}
