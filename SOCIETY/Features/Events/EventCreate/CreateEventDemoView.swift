//
//  CreateEventDemoView.swift
//  SOCIETY
//
//  Demo parent that presents Create Event sheet and navigates to EventDetailView on created event.
//

import SwiftUI

struct CreateEventDemoView: View {
    @State private var isCreatePresented = false
    @State private var createdEvent: Event?
    private let authSession = AuthSessionStore(authRepository: PreviewAuthRepository())

    var body: some View {
        VStack(spacing: 24) {
            Text("Create Event Demo")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.primaryText)
            Button("Open Create Event") {
                isCreatePresented = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $isCreatePresented) {
            EventCreateSheetHost(
                authSession: authSession,
                eventRepository: MockEventRepository(),
                eventImageUploadService: MockEventImageUploadService(),
                rsvpRepository: MockRsvpRepository(),
                onCreated: { event in
                    createdEvent = event
                    isCreatePresented = false
                },
                onDismiss: { isCreatePresented = false }
            )
        }
        .sheet(item: $createdEvent) { event in
            EventDetailView(
                event: event,
                eventRepository: MockEventRepository(),
                eventImageUploadService: MockEventImageUploadService(),
                rsvpRepository: MockRsvpRepository(),
                authSession: authSession,
                onDeleted: { createdEvent = nil },
                onCoverChanged: {},
                onRsvpChanged: {}
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    CreateEventDemoView()
}
