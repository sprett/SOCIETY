//
//  LoginView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 20/01/2026.
//

import Combine
import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LoginViewModel

    init(
        authRepository: any AuthRepository,
        authSession: AuthSessionStore,
        onAuthenticated: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: LoginViewModel(
                authRepository: authRepository,
                authSession: authSession,
                onAuthenticated: onAuthenticated
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sign in")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(AppColors.primaryText)

                        Text("Create and manage your events.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.tertiaryText)
                    }

                    VStack(spacing: 12) {
                        TextField("Email", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding(14)
                            .background(AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
                            .padding(14)
                            .background(AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task { await viewModel.handleSignIn(dismiss: dismiss) }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isLoading { ProgressView().tint(.black) }
                                Text("Sign in")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.black)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .disabled(viewModel.isLoading || !viewModel.canSubmit)

                        Button {
                            Task { await viewModel.handleSignUp(dismiss: dismiss) }
                        } label: {
                            Text("Create account")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppColors.primaryText)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 1)
                        }
                        .disabled(viewModel.isLoading || !viewModel.canSubmit)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppColors.primaryText)
                }
            }
        }
    }
}

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authRepository: any AuthRepository
    private let authSession: AuthSessionStore
    private let onAuthenticated: () -> Void

    init(
        authRepository: any AuthRepository,
        authSession: AuthSessionStore,
        onAuthenticated: @escaping () -> Void
    ) {
        self.authRepository = authRepository
        self.authSession = authSession
        self.onAuthenticated = onAuthenticated
    }

    var canSubmit: Bool {
        email.contains("@") && password.count >= 6
    }

    func handleSignIn(dismiss: DismissAction) async {
        let email = self.email
        let password = self.password
        let authRepository = self.authRepository
        await submit(dismiss: dismiss) {
            try await authRepository.signIn(email: email, password: password)
        }
    }

    func handleSignUp(dismiss: DismissAction) async {
        let email = self.email
        let password = self.password
        let authRepository = self.authRepository
        await submit(dismiss: dismiss) {
            try await authRepository.signUp(email: email, password: password)
        }
    }

    private func submit(dismiss: DismissAction, action: @escaping () async throws -> Void) async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await action()
            await authSession.refresh()
            onAuthenticated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView(authRepository: PreviewAuthRepository(), authSession: AuthSessionStore(authRepository: PreviewAuthRepository()))
}

