//
//  OnboardingViewModel.swift
//  SOCIETY
//
//  Created for onboarding flow.
//

import Combine
import SwiftUI

enum OnboardingFlowStage {
    case onboarding
    case signIn
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    static let numberOfPages = 3

    @Published var currentPage: Int = 0
    @Published var flowStage: OnboardingFlowStage = .onboarding

    /// 1 = forward (next), -1 = backward (previous). Used for direction-aware slide animation.
    @Published var slideDirection: Int = 1

    func next() {
        if currentPage < Self.numberOfPages - 1 {
            slideDirection = 1
            currentPage += 1
        } else {
            transitionToSignIn()
        }
    }

    /// Skip to the sign-in stage directly.
    func skip() {
        transitionToSignIn()
    }

    /// Transition from onboarding carousel to the sign-in screen.
    func transitionToSignIn() {
        flowStage = .signIn
    }

    var isLastPage: Bool {
        currentPage == Self.numberOfPages - 1
    }

    /// Jump to a specific page (e.g. when tapping progress dot).
    func goToPage(_ index: Int) {
        guard index >= 0, index < Self.numberOfPages else { return }
        slideDirection = index > currentPage ? 1 : -1
        currentPage = index
    }
}
