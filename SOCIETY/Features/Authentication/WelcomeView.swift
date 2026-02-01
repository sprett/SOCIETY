//
//  WelcomeView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI
import Combine
import AuthenticationServices

struct WelcomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: WelcomeViewModel
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(
        authRepository: any AuthRepository,
        authSession: AuthSessionStore
    ) {
        _viewModel = StateObject(
            wrappedValue: WelcomeViewModel(
                authRepository: authRepository,
                authSession: authSession
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Welcome text
                VStack(spacing: 8) {
                    Text("Welcome to")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(AppColors.primaryText)

                    Text("SOCIETY")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                }

                // Sign in with Apple button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task {
                            await handleSignInResult(result)
                        }
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .padding(.top, 32)

                if isLoading {
                    ProgressView()
                        .padding(.top, 16)
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                        .padding(.horizontal, 40)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                do {
                    try await viewModel.signInWithApple(credential: appleIDCredential)
                    // Authentication successful - app will automatically transition to MainTabView
                    // via SOCIETYApp's authSession.isAuthenticated check
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
            // User cancelled or other error
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled
            {
                // User cancelled - don't show error
            } else {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

@MainActor
final class WelcomeViewModel: ObservableObject {
    private let authRepository: any AuthRepository
    private let authSession: AuthSessionStore

    init(
        authRepository: any AuthRepository,
        authSession: AuthSessionStore
    ) {
        self.authRepository = authRepository
        self.authSession = authSession
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        try await authSession.signInWithApple(credential: credential)
    }
}

#Preview {
    WelcomeView(
        authRepository: PreviewAuthRepository(),
        authSession: AuthSessionStore(authRepository: PreviewAuthRepository())
    )
}
