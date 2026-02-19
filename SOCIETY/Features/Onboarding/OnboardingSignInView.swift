//
//  OnboardingSignInView.swift
//  SOCIETY
//
//  Sign-in stage of the onboarding flow, shown after the carousel.
//

import AuthenticationServices
import SwiftUI

struct OnboardingSignInView: View {
    @Environment(\.colorScheme) private var colorScheme

    let authSession: AuthSessionStore
    @Binding var isLoadingApple: Bool
    @Binding var isLoadingGoogle: Bool
    @Binding var errorMessage: String?
    let onSignIn: (Result<ASAuthorization, Error>) async -> Void
    let onSignInWithGoogle: () async -> Void

    // Staggered entrance animation states (logo animates from parent)
    @State private var nameOffset: CGFloat = 20
    @State private var nameOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 20
    @State private var taglineOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var termsOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo space (icon drawn by parent overlay and animates from top-left)
            Color.clear
                .frame(width: 240, height: 240)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            // App name + tagline pushed close to bottom, above the button
            VStack(spacing: 12) {
                Text("SOCIETY")
                    .font(.system(size: 40, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(AppColors.primaryText)
                    .offset(y: nameOffset)
                    .opacity(nameOpacity)

                Text("Connect with friends and discover\nevents happening around you")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .offset(y: taglineOffset)
                    .opacity(taglineOpacity)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)

            // Bottom section: same layout as carousel (dots + Continue) so button sits in same place
            VStack(spacing: 24) {
                ZStack {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task {
                                await onSignIn(result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 56)
                    .cornerRadius(14)
                    .padding(.horizontal, 40)
                    .allowsHitTesting(!isLoadingApple)

                    if isLoadingApple {
                        ProgressView()
                            .frame(height: 56)
                            .padding(.horizontal, 40)
                    }
                }
                .offset(y: buttonOffset)
                .opacity(buttonOpacity)

                HStack(spacing: 12) {
                    Rectangle()
                        .fill(AppColors.divider.opacity(0.8))
                        .frame(height: 1)
                    Text("or")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.tertiaryText)
                    Rectangle()
                        .fill(AppColors.divider.opacity(0.8))
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                .offset(y: buttonOffset)
                .opacity(buttonOpacity)

                Button {
                    Task { await onSignInWithGoogle() }
                } label: {
                    Group {
                        if isLoadingGoogle {
                            ProgressView()
                        } else {
                            HStack(spacing: 10) {
                                Image("GoogleLogo")
                                    .resizable()
                                    .renderingMode(.original)
                                    .frame(width: 24, height: 24)
                                Text("Continue with Google")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColors.primaryText)
                .background(AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
                }
                .padding(.horizontal, 40)
                .offset(y: buttonOffset)
                .opacity(buttonOpacity)
                .disabled(isLoadingGoogle)

                Text("By continuing, you agree to our\nTerms of Service and Privacy Policy")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColors.tertiaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(termsOpacity)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(AppColors.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            runEntranceAnimations()
        }
    }

    private func runEntranceAnimations() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
            nameOffset = 0
            nameOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.3)) {
            taglineOffset = 0
            taglineOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.4)) {
            buttonOffset = 0
            buttonOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
            termsOpacity = 1
        }
    }
}

#Preview {
    OnboardingSignInView(
        authSession: AuthSessionStore(authRepository: PreviewAuthRepository()),
        isLoadingApple: .constant(false),
        isLoadingGoogle: .constant(false),
        errorMessage: .constant(nil),
        onSignIn: { _ in },
        onSignInWithGoogle: {}
    )
}
