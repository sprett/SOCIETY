//
//  MapView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Combine
import MapKit
import SwiftUI
import UIKit

struct MapView: View {
    @StateObject private var viewModel: MapViewModel
    @EnvironmentObject private var authSession: AuthSessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEvent: Event?
    @State private var selectedMarkerID: UUID?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522),  // Oslo, Norway
            span: MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045)
        )
    )

    private let eventRepository: any EventRepository
    private let eventImageUploadService: any EventImageUploadService
    private let onDismiss: (() -> Void)?

    init(
        eventRepository: any EventRepository,
        eventImageUploadService: any EventImageUploadService = MockEventImageUploadService(),
        onDismiss: (() -> Void)? = nil
    ) {
        self.eventRepository = eventRepository
        self.eventImageUploadService = eventImageUploadService
        self.onDismiss = onDismiss
        _viewModel = StateObject(wrappedValue: MapViewModel(eventRepository: eventRepository))
    }

    var body: some View {
        NavigationStack {
            mapContent
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(
                event: event,
                eventRepository: eventRepository,
                eventImageUploadService: eventImageUploadService,
                rsvpRepository: MockRsvpRepository(),
                authSession: authSession,
                onDeleted: { viewModel.refresh() },
                onCoverChanged: { viewModel.refresh() },
                onRsvpChanged: {}
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: selectedEvent) { _, newEvent in
            if newEvent == nil {
                selectedMarkerID = nil
            }
        }
    }

    private var mapContent: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            eventMap
            mapOverlayButtons
            loadingIndicator
        }
    }

    private var mapOverlayButtons: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 44, height: 44)
                        .background(liquidGlassBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: handleLocateMeTap) {
                    Image(systemName: "location.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 44, height: 44)
                        .background(liquidGlassBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .allowsHitTesting(true)

            Spacer()
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(100)
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

    private var eventMap: some View {
        Map(position: $position, selection: $selectedMarkerID) {
            // Event annotations with images
            ForEach(viewModel.eventsWithCoordinates) { event in
                Annotation(event.title, coordinate: event.coordinate!) {
                    EventMapAnnotation(event: event)
                }
                .tag(event.id)
            }

            // User location marker
            if let userLocation = viewModel.userLocation {
                Marker("My Location", systemImage: "location.fill", coordinate: userLocation)
                    .tint(.blue)
            }
        }
        .mapStyle(.standard)
        .onMapCameraChange { context in
            position = .region(context.region)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
        .ignoresSafeArea(edges: [.top, .bottom])
        .onAppear {
            handleMapAppear()
            viewModel.refresh()
        }
        .onChange(of: viewModel.locationAuthorizationStatus) { _, newStatus in
            handleAuthorizationChange(newStatus)
        }
        .onChange(of: selectedMarkerID) { _, markerID in
            handleMarkerSelection(markerID)
        }
    }

    @ViewBuilder
    private var loadingIndicator: some View {
        if viewModel.isLoading {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
                .background(AppColors.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Map Event Handlers

    private func handleMapAppear() {
        if viewModel.locationAuthorizationStatus == .notDetermined {
            viewModel.requestLocationPermission()
        } else if viewModel.locationAuthorizationStatus == .authorizedWhenInUse
            || viewModel.locationAuthorizationStatus == .authorizedAlways
        {
            viewModel.startLocationUpdates()
        }
        // Don't automatically center on user location - let user browse around
    }

    private func handleAuthorizationChange(_ newStatus: CLAuthorizationStatus) {
        if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
            viewModel.startLocationUpdates()
            // Don't automatically center on user location - let user browse around
        }
    }

    private func handleMarkerSelection(_ markerID: UUID?) {
        guard let markerID = markerID,
            let event = viewModel.eventsWithCoordinates.first(where: { $0.id == markerID })
        else {
            return
        }
        selectedEvent = event
    }

    private func handleLocateMeTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.centerOnUserLocation()
        if let region = viewModel.regionForUserLocation() {
            withAnimation {
                position = .region(region)
            }
        }
    }
}

// MARK: - Event Map Annotation

struct EventMapAnnotation: View {
    let event: Event

    var body: some View {
        EventMapImageView(imageNameOrURL: event.imageNameOrURL, category: event.category)
    }
}

struct EventMapImageView: View {
    let imageNameOrURL: String
    let category: String

    private let size: CGFloat = 50

    var body: some View {
        ZStack {
            if isURL {
                AsyncImage(url: URL(string: imageNameOrURL)) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white, lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private var isURL: Bool {
        imageNameOrURL.hasPrefix("http://") || imageNameOrURL.hasPrefix("https://")
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(imageGradient)
            .frame(width: size, height: size)
    }

    private var imageGradient: LinearGradient {
        let categoryColor = AppColors.color(for: category) ?? AppColors.accent
        return LinearGradient(
            colors: [categoryColor, categoryColor.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    MapView(
        eventRepository: MockEventRepository(),
        eventImageUploadService: MockEventImageUploadService()
    )
    .environmentObject(AuthSessionStore(authRepository: PreviewAuthRepository()))
}
