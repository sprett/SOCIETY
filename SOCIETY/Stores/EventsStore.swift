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

    /// Marks the cache as needing a refresh on the next visible screen without
    /// blanking the UI. Views that read from the store should also call refresh
    /// after this on next appear.
    func invalidate() {
        didFinishInitialLoad = false
    }

    /// Inserts or updates a single event in the cached list. Use after create,
    /// edit, or RSVP changes so list-based screens reflect the change immediately.
    func upsert(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.insert(event, at: 0)
        }
    }

    /// Drops a single event from the cached list (e.g. after delete).
    func remove(id: UUID) {
        events.removeAll { $0.id == id }
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
