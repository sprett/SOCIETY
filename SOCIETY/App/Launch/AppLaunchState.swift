import Foundation

enum AppLaunchState: Equatable {
    case splash
    case unauthenticated
    case onboardingRequired
    case authenticatedReady
    case accountDeleted
    case accountDisabled(reason: String)
    case error(message: String)
}
