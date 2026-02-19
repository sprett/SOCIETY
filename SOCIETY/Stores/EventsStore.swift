import Combine
import Foundation

@MainActor
final class EventsStore: ObservableObject {
    @Published private(set) var events: [Event] = []
    @Published private(set) var isLoadingInitialData: Bool = false
    @Published private(set) var didFinishInitialLoad: Bool = false
    @Published private(set) var loadError: String?

    func clear() {
        events = []
        isLoadingInitialData = false
        didFinishInitialLoad = false
        loadError = nil
    }

    func replaceCachedEvents(_ events: [Event]) {
        self.events = events
        if isLoadingInitialData {
            isLoadingInitialData = false
        }
        didFinishInitialLoad = true
        loadError = nil
    }

    func prefetchAttendingEvents(
        userID: UUID,
        rsvpRepository: any RsvpRepository,
        eventRepository: any EventRepository
    ) async throws {
        isLoadingInitialData = true
        loadError = nil

        do {
            let eventIDs = try await rsvpRepository.fetchEventIdsAttending(userId: userID)
            let fetchedEvents: [Event]
            if eventIDs.isEmpty {
                fetchedEvents = []
            } else {
                fetchedEvents = try await eventRepository.fetchEvents(ids: eventIDs)
            }
            events = fetchedEvents
            didFinishInitialLoad = true
            isLoadingInitialData = false
        } catch {
            loadError = error.localizedDescription
            // Keep loading state true so Home can show a lightweight overlay
            // until the regular in-screen refresh replaces the cache.
            didFinishInitialLoad = false
            throw error
        }
    }
}
