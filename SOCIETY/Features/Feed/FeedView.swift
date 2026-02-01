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

    private let eventRepository: any EventRepository
    private let eventImageUploadService: any EventImageUploadService

    init(
        eventRepository: any EventRepository = MockEventRepository(),
        eventImageUploadService: any EventImageUploadService = MockEventImageUploadService()
    ) {
        self.eventRepository = eventRepository
        self.eventImageUploadService = eventImageUploadService
        _viewModel = StateObject(wrappedValue: FeedViewModel(repository: eventRepository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.feedEvents.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
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
                    }
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
            }
            .onAppear {
                Task { await viewModel.refresh() }
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(
                event: event,
                eventRepository: eventRepository,
                eventImageUploadService: eventImageUploadService,
                authSession: authSession,
                onDeleted: { Task { await viewModel.refresh() } },
                onCoverChanged: { Task { await viewModel.refresh() } }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)

            Text("No events in feed")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            Text("Events you’re following or interested in will show up here.")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FeedView(eventRepository: MockEventRepository())
        .environmentObject(AuthSessionStore(authRepository: PreviewAuthRepository()))
}
