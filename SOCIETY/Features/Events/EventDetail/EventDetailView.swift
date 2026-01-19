//
//  EventDetailView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 19/01/2026.
//

import Combine
import MapKit
import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EventDetailViewModel
    @State private var heroSide: CGFloat = UIScreen.main.bounds.width - 40

    init(event: Event) {
        _viewModel = StateObject(wrappedValue: EventDetailViewModel(event: event))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                hero

                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.event.title)
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.leading)

                    if let organizer = viewModel.primaryOrganizer {
                        Button {
                            viewModel.handleOrganizerTap()
                        } label: {
                            HStack(spacing: 8) {
                                EventAvatar(
                                    initials: organizer.initials, category: viewModel.event.category
                                )
                                .frame(width: 18, height: 18)

                                Text(organizer.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColors.secondaryText)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppColors.tertiaryText)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Text(viewModel.dateText)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.tertiaryText)
                }

                if let about = viewModel.event.about {
                    EventDetailSection {
                        EventAboutSection(about: about)
                    }
                }

                if let goingCount = viewModel.event.goingCount {
                    EventDetailSection {
                        EventAttendingSection(goingCount: goingCount)
                    }
                }

                if viewModel.event.addressLine != nil || viewModel.event.coordinate != nil {
                    EventDetailSection {
                        EventLocationSection(event: viewModel.event)
                    }
                }

                if let hosts = viewModel.event.hosts, !hosts.isEmpty {
                    EventDetailSection {
                        EventHostsSection(hosts: hosts, category: viewModel.event.category)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(AppColors.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .confirmationDialog(
            "More", isPresented: $viewModel.showMoreActions, titleVisibility: .visible
        ) {
            Button("Share") { viewModel.handleShareTap() }
            Button("Copy link") { viewModel.handleCopyLinkTap() }
            Button("Report event", role: .destructive) { viewModel.handleReportTap() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var hero: some View {
        EventHeroImage(
            imageNameOrURL: viewModel.event.imageNameOrURL, category: viewModel.event.category
        )
        .frame(maxWidth: .infinity)
        .frame(height: heroSide)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: EventHeroSidePreferenceKey.self, value: proxy.size.width)
            }
        }
        .onPreferenceChange(EventHeroSidePreferenceKey.self) { newWidth in
            // Match height to the rendered width to force 1:1.
            if heroSide != newWidth, newWidth > 0 {
                heroSide = newWidth
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            EventDetailFloatingButton(systemImageName: "square.and.arrow.up") {
                viewModel.handleShareTap()
            }
            .padding(14)
        }
        .overlay(alignment: .bottomTrailing) {
            EventVenueBadge(title: viewModel.event.venueName)
                .padding(14)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.handleRegisterTap()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                    Text("Register")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                viewModel.handleContactTap()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope")
                        .font(.subheadline.weight(.semibold))
                    Text("Contact")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.primaryText)
            .background(
                .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
            }

            Button {
                viewModel.showMoreActions = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.weight(.semibold))
                    Text("More")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.primaryText)
            .background(
                .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}

@MainActor
final class EventDetailViewModel: ObservableObject {
    let event: Event

    @Published var isInterested: Bool = false
    @Published var showMoreActions: Bool = false

    init(event: Event) {
        self.event = event
    }

    struct OrganizerDisplay: Hashable {
        let name: String
        let initials: String
    }

    var primaryOrganizer: OrganizerDisplay? {
        guard let first = event.hosts?.first else { return nil }
        return OrganizerDisplay(
            name: first.name, initials: String(first.avatarPlaceholder.prefix(2)))
    }

    var dateText: String {
        if let endDate = event.endDate {
            return EventDateFormatter.dateTimeRange(start: event.startDate, end: endDate)
        }
        return EventDateFormatter.dateOnly(event.startDate)
    }

    func handleRegisterTap() {
        print("Register tapped")
    }

    func handleContactTap() {
        print("Contact tapped")
    }

    func handleInterestedToggle() {
        print("Interested toggled: \(isInterested)")
    }

    func handleShareTap() {
        print("Share tapped")
    }

    func handleCopyLinkTap() {
        print("Copy link tapped")
    }

    func handleReportTap() {
        print("Report tapped")
    }

    func handleOrganizerTap() {
        print("Organizer tapped")
    }
}

// MARK: - Subviews

struct EventDetailSection<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .background(
            AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
        }
    }
}

struct EventLocationSection: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            EventDetailSectionHeader(title: "Location")

            VStack(alignment: .leading, spacing: 4) {
                Text(event.venueName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                Text(addressText)
                    .font(.footnote)
                    .foregroundStyle(AppColors.tertiaryText)
            }

            if let coordinate = event.coordinate {
                EventLocationMap(coordinate: coordinate)
            }
        }
    }

    private var addressText: String {
        if let addressLine = event.addressLine, !addressLine.isEmpty {
            return addressLine
        }
        return "\(event.neighborhood), Oslo"
    }
}

struct EventLocationMap: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        let position = MapCameraPosition.region(region)

        Map(position: .constant(position)) {
            Marker("Event", coordinate: coordinate)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
        }
    }
}

struct EventHostsSection: View {
    let hosts: [Host]
    let category: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            EventDetailSectionHeader(title: "Hosts")

            ForEach(hosts) { host in
                HostRow(host: host, category: category)
            }
        }
    }
}

struct HostRow: View {
    let host: Host
    let category: String

    var body: some View {
        HStack(spacing: 12) {
            EventAvatar(initials: String(host.avatarPlaceholder.prefix(2)), category: category)
                .frame(width: 36, height: 36)

            Text(host.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
        }
    }
}

struct EventAttendingSection: View {
    let goingCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EventDetailSectionHeader(title: "Attending")

            Text("\(goingCount) going")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: -8) {
                ForEach(0..<min(3, goingCount), id: \.self) { _ in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
            }
        }
    }
}

struct EventAboutSection: View {
    let about: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EventDetailSectionHeader(title: "About")

            Text(about)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
        }
    }
}

struct EventDetailSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            Rectangle()
                .fill(AppColors.divider.opacity(0.8))
                .frame(height: 1)
        }
        .padding(.bottom, 6)
    }
}

struct EventHeroImage: View {
    let imageNameOrURL: String
    let category: String

    var body: some View {
        ZStack {
            if isURL {
                AsyncImage(url: URL(string: imageNameOrURL)) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .contentShape(Rectangle())
        .clipped()
    }

    private var isURL: Bool {
        imageNameOrURL.hasPrefix("http://") || imageNameOrURL.hasPrefix("https://")
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 0, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [startColor, endColor], startPoint: .topLeading,
                    endPoint: .bottomTrailing)
            )
            .overlay {
                LinearGradient(
                    colors: [Color.clear, AppColors.overlay.opacity(0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }

    private var startColor: Color {
        AppColors.color(for: category) ?? AppColors.accent
    }

    private var endColor: Color {
        (AppColors.color(for: category) ?? AppColors.accent).opacity(0.55)
    }
}

struct EventDetailFloatingButton: View {
    let systemImageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImageName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct EventVenueBadge: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            AppColors.overlay.opacity(0.35),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EventAvatar: View {
    let initials: String
    let category: String

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        (AppColors.color(for: category) ?? AppColors.accent).opacity(0.95),
                        (AppColors.color(for: category) ?? AppColors.accent).opacity(0.55),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text(initials.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
    }
}

private enum EventHeroSidePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    EventDetailView(
        event: Event(
            id: UUID(),
            title: "Nordic AI Night",
            category: "AI",
            startDate: Date(timeIntervalSinceNow: 60 * 60 * 24),
            venueName: "Mesh Oslo",
            neighborhood: "Sentrum",
            distanceKm: 1.2,
            imageNameOrURL:
                "https://images.unsplash.com/photo-1521737604893-d14cc237f11d?q=80&w=2000&auto=format&fit=crop",
            isFeatured: true,
            endDate: Date(timeIntervalSinceNow: 60 * 60 * 24 + 60 * 60 * 2),
            addressLine: "Tordenskiolds gate 2, 0160 Oslo, Norway",
            coordinate: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7461),
            hosts: [
                Host(id: UUID(), name: "Candyce Costa", avatarPlaceholder: "CC")
            ],
            goingCount: 75,
            about: "A relaxed meetup for AI builders in Oslo."
        )
    )
}
