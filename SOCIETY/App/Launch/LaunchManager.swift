import Combine
import Foundation
import Supabase

@MainActor
final class LaunchManager: ObservableObject {
    @Published private(set) var state: AppLaunchState = .splash

    private let dependencies: AppDependencies
    private let authSession: AuthSessionStore
    private let eventsStore: EventsStore

    private let minSplashDuration: TimeInterval = 0.6
    private let maxWaitForPrefetch: TimeInterval = 2.5

    private var launchTask: Task<Void, Never>?
    private var sessionCancellable: AnyCancellable?

    init(
        dependencies: AppDependencies,
        authSession: AuthSessionStore,
        eventsStore: EventsStore
    ) {
        self.dependencies = dependencies
        self.authSession = authSession
        self.eventsStore = eventsStore

        sessionCancellable = authSession.$userID
            .dropFirst()
            .sink { [weak self] userID in
                guard let self else { return }
                Task { @MainActor in
                    if userID == nil {
                        self.eventsStore.clear()
                        self.state = .unauthenticated
                    } else if case .unauthenticated = self.state {
                        self.start()
                    }
                }
            }
    }

    func start() {
        launchTask?.cancel()
        launchTask = Task { [weak self] in
            guard let self else { return }
            await self.runLaunchPipeline()
        }
    }

    func retry() {
        start()
    }

    func validateAccountStatus() async {
        guard case .authenticatedReady = state else { return }
        guard let userID = authSession.userID else { return }

        do {
            let profile = try await fetchLaunchProfile(userID: userID)
            guard let profile else {
                state = .accountDeleted
                return
            }

            if (profile.isActive ?? true) == false || profile.deletedAt != nil {
                state = .accountDisabled(reason: "Your account is disabled.")
                return
            }
        } catch {
            if isUnauthorizedError(error) {
                state = .unauthenticated
            }
        }
    }

    func handleOnboardingCompleted() {
        Task { [weak self] in
            guard let self else { return }
            guard let userID = self.authSession.userID else {
                self.state = .unauthenticated
                return
            }

            await self.prefetchWithTimeout(userID: userID)
            self.state = .authenticatedReady
        }
    }

    private func runLaunchPipeline() async {
        state = .splash
        let launchStartedAt = Date()

        await authSession.refresh()

        let userID: UUID
        do {
            let session = try await dependencies.supabase.auth.session
            if session.isExpired {
                await finalize(.unauthenticated, launchStartedAt: launchStartedAt)
                return
            }
            userID = session.user.id
        } catch {
            await finalize(.unauthenticated, launchStartedAt: launchStartedAt)
            return
        }

        do {
            let profile = try await fetchLaunchProfile(userID: userID)

            guard let profile else {
                await finalize(
                    .accountDeleted,
                    launchStartedAt: launchStartedAt
                )
                return
            }

            if (profile.isActive ?? true) == false || profile.deletedAt != nil {
                await finalize(
                    .accountDisabled(reason: "Your account is disabled."),
                    launchStartedAt: launchStartedAt
                )
                return
            }

            if !(profile.onboardingCompleted ?? false) {
                await finalize(.onboardingRequired, launchStartedAt: launchStartedAt)
                return
            }

            await prefetchWithTimeout(userID: userID)
            await finalize(.authenticatedReady, launchStartedAt: launchStartedAt)
        } catch {
            if isUnauthorizedError(error) {
                await finalize(.unauthenticated, launchStartedAt: launchStartedAt)
            } else {
                await finalize(
                    .error(message: error.localizedDescription),
                    launchStartedAt: launchStartedAt
                )
            }
        }
    }

    private func finalize(_ finalState: AppLaunchState, launchStartedAt: Date) async {
        let elapsed = Date().timeIntervalSince(launchStartedAt)
        let remaining = minSplashDuration - elapsed
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }
        guard !Task.isCancelled else { return }
        state = finalState
    }

    private func fetchLaunchProfile(userID: UUID) async throws -> LaunchProfileRow? {
        let rows: [LaunchProfileRow] = try await dependencies.supabase
            .from("profiles")
            .select()
            .eq("id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    private func prefetchWithTimeout(userID: UUID) async {
        let fetchTask = Task { [weak self] in
            guard let self else { return }
            try await self.eventsStore.prefetchAttendingEvents(
                userID: userID,
                rsvpRepository: self.dependencies.rsvpRepository,
                eventRepository: self.dependencies.eventRepository
            )
        }

        let completedWithinTimeout = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                do {
                    try await fetchTask.value
                    return true
                } catch {
                    return true
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(self.maxWaitForPrefetch * 1_000_000_000))
                return false
            }

            let first = await group.next() ?? true
            group.cancelAll()
            return first
        }

        // Let the background fetch continue if timeout fired.
        if !completedWithinTimeout {
            return
        }
    }

    private func isUnauthorizedError(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("unauthorized")
            || message.contains("jwt")
            || message.contains("401")
            || message.contains("auth")
    }
}

private struct LaunchProfileRow: Decodable {
    let id: UUID
    let onboardingCompleted: Bool?
    let isActive: Bool?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case onboardingCompleted = "onboarding_completed"
        case isActive = "is_active"
        case deletedAt = "deleted_at"
    }
}
