//
//  OnboardingIllustrations.swift
//  SOCIETY
//
//  Onboarding illustration views using SVG assets from the asset catalog.
//

import SwiftUI

// MARK: - Discover (Search)

struct DiscoverIllustrationView: View {
    var body: some View {
        Image("OnboardingSearchIllustration")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Stay Connected (Friends)

struct StayConnectedIllustrationView: View {
    var body: some View {
        Image("OnboardingHavingFunIllustration")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Host & Manage (Add Post)

struct HostManageIllustrationView: View {
    var body: some View {
        Image("OnboardingAddPostIllustration")
            .resizable()
            .scaledToFit()
    }
}
