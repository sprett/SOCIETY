//
//  DiscoverView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Combine
import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel(repository: MockEventRepository())

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    header
                    categorySection
                    featuredSection
                    nearbySection
                }
                .padding(.top, 12)
                .padding(.bottom, 40)
                .padding(.horizontal, 20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationDestination(for: Event.self) { event in
                EventDetailPlaceholderView(event: event)
            }
        }
        .tint(AppColors.primaryText)
    }

    private var header: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?q=80&w=2034&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(AppColors.secondaryText)
                        }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                case .failure:
                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(AppColors.secondaryText)
                        }
                @unknown default:
                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(AppColors.secondaryText)
                        }
                }
            }

            Text("Discover")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                viewModel.handleMapTap()
            } label: {
                Image(systemName: "map")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 40, height: 40)
                    .background(AppColors.surface)
                    .clipShape(Circle())
            }

            Button {
                viewModel.handleSearchTap()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 40, height: 40)
                    .background(AppColors.surface)
                    .clipShape(Circle())
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Category")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.categoryOptions) { option in
                        CategoryChip(
                            title: option.title,
                            systemImageName: option.systemImageName,
                            isSelected: viewModel.selectedCategory == option.title
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.selectedCategory = option.title
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    private var featuredSection: some View {
        Group {
            if viewModel.selectedCategory == "All" && !viewModel.featuredEvents.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular events nearby")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppColors.primaryText)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.featuredEvents) { event in
                                NavigationLink(value: event) {
                                    FeaturedEventCard(
                                        event: event,
                                        dateText: viewModel.dateText(for: event)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedCategory)
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Events near you")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            LazyVStack(spacing: 12) {
                ForEach(viewModel.nearbyEvents) { event in
                    NavigationLink(value: event) {
                        EventRow(
                            event: event,
                            dateText: viewModel.dateText(for: event)
                        )
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedCategory)
    }
}

@MainActor
final class DiscoverViewModel: ObservableObject {
    struct CategoryOption: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let systemImageName: String
    }

    @Published private(set) var events: [Event] = []
    @Published var selectedCategory: String = "All"

    private let repository: MockEventRepository

    init(repository: MockEventRepository) {
        self.repository = repository
        loadEvents()
    }

    var categoryOptions: [CategoryOption] {
        let eventCategories = Set(events.map { $0.category })
        let orderedCategories = categoryOrder.filter { eventCategories.contains($0) }
        let options = orderedCategories.map { category in
            CategoryOption(title: category, systemImageName: categoryIcons[category] ?? "sparkles")
        }
        return [CategoryOption(title: "All", systemImageName: "sparkles")] + options
    }

    var featuredEvents: [Event] {
        filteredEvents.filter { $0.isFeatured }
    }

    var nearbyEvents: [Event] {
        filteredEvents.sorted { $0.startDate < $1.startDate }
    }

    func dateText(for event: Event) -> String {
        Self.dateFormatter.string(from: event.startDate)
    }

    func handleSearchTap() {
        print("Discover search tapped")
    }

    func handleMapTap() {
        print("Discover map tapped")
    }

    private var filteredEvents: [Event] {
        guard selectedCategory != "All" else { return events }
        return events.filter { $0.category == selectedCategory }
    }

    private func loadEvents() {
        events = repository.fetchEvents()
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d · HH:mm"
        formatter.locale = Locale.current
        return formatter
    }()

    private let categoryOrder: [String] = [
        "Tech",
        "AI",
        "Climate",
        "Fitness",
        "Food & Drink",
        "Arts & Culture",
        "Wellness",
    ]

    private let categoryIcons: [String: String] = [
        "Tech": "bolt.fill",
        "AI": "brain.head.profile",
        "Climate": "leaf.fill",
        "Fitness": "figure.run",
        "Food & Drink": "fork.knife",
        "Arts & Culture": "paintpalette.fill",
        "Wellness": "leaf.circle.fill",
    ]
}

#Preview {
    DiscoverView()
}
