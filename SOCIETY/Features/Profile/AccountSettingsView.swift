//
//  AccountSettingsView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AccountSettingsViewModel
    @State private var showEditEmail = false
    @State private var showEditPhone = false
    @State private var showEditUsername = false

    init(
        authSession: AuthSessionStore,
        profileRepository: any ProfileRepository
    ) {
        _viewModel = StateObject(
            wrappedValue: AccountSettingsViewModel(
                authSession: authSession,
                profileRepository: profileRepository
            ))
    }

    var body: some View {
        List {
            Section {
                Button {
                    showEditEmail = true
                } label: {
                    HStack {
                        Text("Email")
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Text(viewModel.email.isEmpty ? "—" : viewModel.email)
                            .foregroundStyle(AppColors.tertiaryText)
                            .lineLimit(1)
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
                Button {
                    showEditPhone = true
                } label: {
                    HStack {
                        Text("Phone Number")
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Text(viewModel.phoneNumber.isEmpty ? "—" : viewModel.phoneNumber)
                            .foregroundStyle(AppColors.tertiaryText)
                            .lineLimit(1)
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
                Button {
                    showEditUsername = true
                } label: {
                    HStack {
                        Text("Username")
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Text(viewModel.username.isEmpty ? "—" : "@\(viewModel.username)")
                            .foregroundStyle(AppColors.tertiaryText)
                            .lineLimit(1)
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
            } header: {
                Text("Information")
                    .foregroundStyle(AppColors.secondaryText)
            }

            Section {
                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    Text("Delete Account")
                }
                .disabled(viewModel.isDeleting)
            } header: {
                Text("Danger Zone")
                    .foregroundStyle(AppColors.secondaryText)
            }

            if let msg = viewModel.errorMessage {
                Section {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(AppColors.danger)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(AppColors.background)
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showEditEmail) {
            EditEmailView(
                currentEmail: viewModel.email,
                onSave: { newEmail in
                    Task { await viewModel.updateEmail(newEmail) }
                    showEditEmail = false
                },
                onDismiss: { showEditEmail = false }
            )
        }
        .sheet(isPresented: $showEditPhone) {
            EditPhoneNumberView(
                currentPhone: viewModel.phoneNumber,
                onSave: { newPhone in
                    Task { await viewModel.updatePhoneNumber(newPhone) }
                    showEditPhone = false
                },
                onDismiss: { showEditPhone = false }
            )
        }
        .sheet(isPresented: $showEditUsername) {
            EditUsernameView(
                currentUsername: viewModel.username,
                onSave: { newUsername in
                    Task { await viewModel.updateUsername(newUsername) }
                    showEditUsername = false
                },
                onDismiss: { showEditUsername = false }
            )
        }
        .alert("Delete Account", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Account", role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                    if viewModel.deleteSucceeded {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .onChange(of: viewModel.deleteSucceeded) { _, succeeded in
            if succeeded { dismiss() }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                    .background(AppColors.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView(
            authSession: AuthSessionStore(authRepository: PreviewAuthRepository()),
            profileRepository: MockProfileRepository()
        )
    }
}
