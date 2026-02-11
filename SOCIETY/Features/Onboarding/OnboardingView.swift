//
//  OnboardingView.swift
//  SOCIETY
//
//  Created for onboarding flow.
//

import AuthenticationServices
import SwiftUI

// MARK: - Illustration Kind

enum OnboardingIllustrationKind {
    case discover
    case stayConnected
    case hostManage
}

// MARK: - Page Model

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let illustrationKind: OnboardingIllustrationKind
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        title: "Discover",
        subtitle: "Events Near You",
        description:
            "Explore exciting events happening around you. From concerts to meetups, find what matters to you.",
        illustrationKind: .discover
    ),
    OnboardingPage(
        title: "Stay Connected",
        subtitle: "With Friends",
        description:
            "See where your friends are going and what they're attending. Never miss out on shared experiences.",
        illustrationKind: .stayConnected
    ),
    OnboardingPage(
        title: "Host & Manage",
        subtitle: "Your Events",
        description:
            "Create events, manage guest lists, and send reminders. Everything you need to be the perfect host.",
        illustrationKind: .hostManage
    ),
]

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = OnboardingViewModel()
    @AppStorage("hasCompletedOnboardingV2") private var hasCompletedOnboarding = false

    private let authRepository: any AuthRepository
    private let authSession: AuthSessionStore

    @State private var isLoading = false
    @State private var errorMessage: String?

    // Entrance animation state: illustration from bottom, text from left (in sync)
    @State private var illustrationOffsetY: CGFloat = 80
    @State private var illustrationOpacity: Double = 0
    @State private var textOffsetX: CGFloat = -50
    @State private var textOpacity: Double = 0

    init(
        authRepository: any AuthRepository,
        authSession: AuthSessionStore
    ) {
        self.authRepository = authRepository
        self.authSession = authSession
    }

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.flowStage {
            case .onboarding:
                onboardingContent
            case .signIn:
                OnboardingSignInView(
                    authSession: authSession,
                    isLoading: $isLoading,
                    errorMessage: $errorMessage,
                    onSignIn: handleSignInResult
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .overlay { onboardingLogoTransitionOverlay }
        .onChange(of: viewModel.flowStage) { _, newStage in
            if newStage == .signIn {
                hasCompletedOnboarding = true
            }
        }
    }

    // MARK: - Logo transition (top-left → center when tapping Get Started)

    private var onboardingLogoTransitionOverlay: some View {
        GeometryReader { geo in
            let isOnboarding = viewModel.flowStage == .onboarding
            let size: CGFloat = isOnboarding ? 28 : 240
            let x = isOnboarding ? (24 + size / 2) : geo.size.width / 2
            let y = isOnboarding ? (8 + size / 2) : geo.size.height / 2
            Image("OnboardingLogo")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(
                    isOnboarding
                        ? AppColors.primaryText.opacity(0.6)
                        : AppColors.primaryText
                )
                .frame(width: size, height: size)
                .position(x: x, y: y)
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: viewModel.flowStage)
        .allowsHitTesting(false)
    }

    // MARK: - Onboarding Carousel

    private var onboardingContent: some View {
        VStack(spacing: 0) {
            // Placeholder for logo (drawn in overlay so it can animate to center)
            HStack {
                Color.clear
                    .frame(width: 28, height: 28)
                    .padding(.leading, 24)
                    .padding(.top, 8)
                Spacer()
                Button("Skip") {
                    viewModel.skip()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.primaryText.opacity(0.4))
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }

            // Directional slide content
            GeometryReader { geo in
                ZStack {
                    ForEach(
                        Array(onboardingPages.enumerated()), id: \.offset
                    ) { index, page in
                        if index == viewModel.currentPage {
                            onboardingPageContent(
                                page: page, index: index, geo: geo
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .offset(
                                        x: viewModel.slideDirection > 0
                                            ? geo.size.width : -geo.size.width
                                    ).combined(with: .opacity),
                                    removal: .offset(
                                        x: viewModel.slideDirection > 0
                                            ? -geo.size.width : geo.size.width
                                    ).combined(with: .opacity)
                                )
                            )
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .animation(
                    .spring(response: 0.35, dampingFraction: 0.8),
                    value: viewModel.currentPage
                )
            }

            // Bottom section: dots + button
            VStack(spacing: 24) {
                pageIndicators
                nextButton
            }
            .padding(.bottom, 40)
        }
        .onChange(of: viewModel.currentPage) { _, _ in
            triggerEntranceAnimations()
        }
        .onAppear {
            triggerEntranceAnimations()
        }
    }

    // MARK: - Entrance Animations

    private func triggerEntranceAnimations() {
        illustrationOffsetY = 80
        illustrationOpacity = 0
        textOffsetX = -50
        textOpacity = 0
        let entranceAnimation = Animation.spring(response: 0.55, dampingFraction: 0.78)
        withAnimation(entranceAnimation) {
            illustrationOffsetY = 0
            illustrationOpacity = 1
            textOffsetX = 0
            textOpacity = 1
        }
    }

    // MARK: - Page Content

    private func onboardingPageContent(
        page: OnboardingPage, index: Int, geo: GeometryProxy
    ) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration — animates up from bottom
            illustrationView(for: page.illustrationKind)
                .frame(height: 240)
                .offset(y: illustrationOffsetY)
                .opacity(illustrationOpacity)
                .padding(.bottom, 48)

            // Text (title, subtitle, description) — flies in from left in sync with illustration
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(page.title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                    Text(page.subtitle)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppColors.onboardingAccent)
                        .multilineTextAlignment(.center)
                }
                Text(page.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .offset(x: textOffsetX)
            .opacity(textOpacity)

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(width: geo.size.width, height: geo.size.height)
    }

    @ViewBuilder
    private func illustrationView(for kind: OnboardingIllustrationKind)
        -> some View
    {
        switch kind {
        case .discover: DiscoverIllustrationView()
        case .stayConnected: StayConnectedIllustrationView()
        case .hostManage: HostManageIllustrationView()
        }
    }

    // MARK: - Page Indicators

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<OnboardingViewModel.numberOfPages, id: \.self) {
                index in
                Button {
                    viewModel.goToPage(index)
                } label: {
                    Capsule()
                        .fill(
                            index == viewModel.currentPage
                                ? AppColors.primaryText
                                : Color(.systemGray4)
                        )
                        .frame(
                            width: index == viewModel.currentPage ? 32 : 8,
                            height: 8
                        )
                }
                .buttonStyle(.plain)
                .animation(
                    .easeInOut(duration: 0.3), value: viewModel.currentPage)
            }
        }
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.next()
        } label: {
            HStack(spacing: 8) {
                Text(
                    viewModel.isLastPage ? "Get Started" : "Continue"
                )
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color(.systemBackground))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                AppColors.primaryText,
                in: RoundedRectangle(
                    cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(ScaleOnPressButtonStyle())
        .padding(.horizontal, 40)
    }

    // MARK: - Sign In Handler

    private func handleSignInResult(
        _ result: Result<ASAuthorization, Error>
    ) async {
        hasCompletedOnboarding = true
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential
                as? ASAuthorizationAppleIDCredential
            {
                do {
                    try await authSession.signInWithApple(
                        credential: appleIDCredential)
                    isLoading = false
                } catch {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            } else {
                errorMessage = "Invalid credential type"
                isLoading = false
            }

        case .failure(let error):
            if let authError = error as? ASAuthorizationError,
                authError.code == .canceled
            {
                // User cancelled – no error message
            } else {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Scale on Press Button Style

private struct ScaleOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(
                .easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(
        authRepository: PreviewAuthRepository(),
        authSession: AuthSessionStore(
            authRepository: PreviewAuthRepository())
    )
}
