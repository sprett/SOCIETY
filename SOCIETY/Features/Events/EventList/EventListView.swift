//
//  EventListView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Combine
import SwiftUI

struct EventListView: View {
    @StateObject private var viewModel: EventListViewModel
    @State private var selectedEvent: Event?
    @State private var selectedEventSheetDetent: PresentationDetent = .large

    init(eventRepository: any EventRepository = MockEventRepository()) {
        _viewModel = StateObject(wrappedValue: EventListViewModel(repository: eventRepository))
    }

    private var isEventDetailPresented: Bool {
        selectedEvent != nil
    }

    private var backgroundBlurRadius: CGFloat {
        guard isEventDetailPresented else { return 0 }
        return selectedEventSheetDetent == .large ? 10 : 4
    }

    private var backgroundDimOpacity: Double {
        guard isEventDetailPresented else { return 0 }
        return selectedEventSheetDetent == .large ? 0.12 : 0.06
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 68)

                        VStack(alignment: .leading, spacing: 24) {
                            nextEventSection
                            attendingSection
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                        .padding(.horizontal, 20)
                    }
                }
                .background(AppColors.background.ignoresSafeArea())

                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(true)
            }
        }
        .tint(AppColors.primaryText)
        .blur(radius: backgroundBlurRadius)
        .overlay {
            if isEventDetailPresented {
                Rectangle()
                    .fill(Color.black.opacity(backgroundDimOpacity))
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isEventDetailPresented)
        .animation(.easeInOut(duration: 0.18), value: selectedEventSheetDetent)
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
                .presentationDetents([.medium, .large], selection: $selectedEventSheetDetent)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: selectedEvent) { _, newValue in
            guard newValue != nil else { return }
            selectedEventSheetDetent = .large
        }
    }

    @ViewBuilder
    private var liquidGlassBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: .circle)
        } else {
            Color.clear
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            AsyncImage(
                url: URL(
                    string:
                        "https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?q=80&w=2034&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
                )
            ) { phase in
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

            Text("Society")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                viewModel.createEvent()
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 40, height: 40)
                    .background(liquidGlassBackground)
                    .clipShape(Circle())
            }
        }
    }

    private var nextEventSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next up")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            if let event = viewModel.nextEvent {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        Button {
                            selectedEvent = event
                        } label: {
                            FeaturedEventCard(
                                event: event,
                                dateText: viewModel.dateText(for: event)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            } else {
                Text("No upcoming events yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }

    private var attendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attending Events")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            LazyVStack(spacing: 12) {
                ForEach(viewModel.events) { event in
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
        }
    }
}

#Preview {
    EventListView()
}
