//
//  SettingsView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authSession: AuthSessionStore
    @StateObject private var viewModel: SettingsViewModel
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode: String = AppearanceMode.system.rawValue
    private let profileRepository: any ProfileRepository
    private let notificationSettingsRepository: any NotificationSettingsRepository
    private let profileImageUploadService: any ProfileImageUploadService

    init(
        authSession: AuthSessionStore,
        profileRepository: any ProfileRepository,
        notificationSettingsRepository: any NotificationSettingsRepository,
        profileImageUploadService: any ProfileImageUploadService
    ) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(authSession: authSession))
        self.profileRepository = profileRepository
        self.notificationSettingsRepository = notificationSettingsRepository
        self.profileImageUploadService = profileImageUploadService
    }

    private var resolvedColorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    var body: some View {
        NavigationStack {
            settingsContent
        }
        .preferredColorScheme(resolvedColorScheme)
        .animation(.easeInOut(duration: 0.35), value: appearanceMode)
        .onAppear {
            Task {
                await viewModel.loadCacheSize()
            }
        }
        .confirmationDialog("Sign Out", isPresented: $viewModel.showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task {
                    do {
                        try await viewModel.signOut()
                        dismiss()
                    } catch {
                        // Error could be surfaced via viewModel if needed
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private var settingsContent: some View {
        List {
                // User profile section
                Section {
                    NavigationLink {
                        EditProfileView(
                            authSession: authSession,
                            profileRepository: profileRepository,
                            profileImageUploadService: profileImageUploadService
                        )
                    } label: {
                        HStack(spacing: 12) {
                            UserAvatarView(imageURL: authSession.profileImageURL, size: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authSession.userName?.isEmpty ?? true ? "Profile" : (authSession.userName ?? ""))
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AppColors.primaryText)
                                Text("Edit Profile")
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Account
                Section {
                    NavigationLink {
                        AccountSettingsView(
                            authSession: authSession,
                            profileRepository: profileRepository
                        )
                    } label: {
                        Label("Account Settings", systemImage: "gearshape")
                            .foregroundStyle(AppColors.primaryText)
                    }
                }

                // Preferences
                Section {
                    NavigationLink {
                        NotificationSettingsView(
                            authSession: authSession,
                            notificationSettingsRepository: notificationSettingsRepository
                        )
                    } label: {
                        Label("Notifications", systemImage: "bell")
                            .foregroundStyle(AppColors.primaryText)
                    }
                    NavigationLink {
                        PermissionsView()
                    } label: {
                        Label("Permissions", systemImage: "hand.raised")
                            .foregroundStyle(AppColors.primaryText)
                    }
                    NavigationLink {
                        AppearanceView()
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                            .foregroundStyle(AppColors.primaryText)
                    }
                } header: {
                    Text("Preferences")
                        .foregroundStyle(AppColors.secondaryText)
                }

                // Storage
                Section {
                    HStack {
                        Label("Image Cache", systemImage: "photo.stack")
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Text(viewModel.cacheSize)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    
                    Button {
                        Task {
                            await viewModel.clearImageCache()
                        }
                    } label: {
                        Label("Clear Image Cache", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Storage")
                        .foregroundStyle(AppColors.secondaryText)
                }

                // Sign Out
                Section {
                    Button {
                        viewModel.showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(AppColors.primaryText)
                    }
                }

                // Footer
                Section {
                    VStack(spacing: 8) {
                        Text("SOCIETY")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.secondaryText)
                        Text(appVersion)
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                        Button("Terms & Privacy") {
                            // Placeholder
                        }
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 24, leading: 0, bottom: 24, trailing: 0))
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppColors.primaryText)
                            .frame(width: 30, height: 30)
                    }
                }
            }
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(short) (\(build))"
    }
}

#Preview {
    let authSession = AuthSessionStore(authRepository: PreviewAuthRepository())
    return SettingsView(
        authSession: authSession,
        profileRepository: MockProfileRepository(),
        notificationSettingsRepository: MockNotificationSettingsRepository(),
        profileImageUploadService: MockProfileImageUploadService()
    )
    .environmentObject(authSession)
}
