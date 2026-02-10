//
//  NotificationSettingsView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var viewModel: NotificationSettingsViewModel

    init(
        authSession: AuthSessionStore,
        notificationSettingsRepository: any NotificationSettingsRepository
    ) {
        _viewModel = StateObject(wrappedValue: NotificationSettingsViewModel(
            authSession: authSession,
            notificationSettingsRepository: notificationSettingsRepository
        ))
    }

    var body: some View {
        List {
            Section {
                Toggle(isOn: $viewModel.emailMarketingEnabled) {
                    Text("Email updates & announcements")
                        .foregroundStyle(AppColors.primaryText)
                }
                .tint(AppColors.accent)
                .onChange(of: viewModel.emailMarketingEnabled) { _, _ in
                    Task { await viewModel.save() }
                }
            } header: {
                Text("Email")
                    .foregroundStyle(AppColors.secondaryText)
            } footer: {
                Text("Receive product updates and event announcements by email.")
                    .foregroundStyle(AppColors.tertiaryText)
            }

            Section {
                Toggle(isOn: $viewModel.pushEventRemindersEnabled) {
                    Text("Event reminders")
                        .foregroundStyle(AppColors.primaryText)
                }
                .tint(AppColors.accent)
                .onChange(of: viewModel.pushEventRemindersEnabled) { _, _ in
                    Task { await viewModel.save() }
                }
                Toggle(isOn: $viewModel.pushHostUpdatesEnabled) {
                    Text("Host updates")
                        .foregroundStyle(AppColors.primaryText)
                }
                .tint(AppColors.accent)
                .onChange(of: viewModel.pushHostUpdatesEnabled) { _, _ in
                    Task { await viewModel.save() }
                }
            } header: {
                Text("Push Notifications")
                    .foregroundStyle(AppColors.secondaryText)
            } footer: {
                Text("Reminders for events you're attending and updates from hosts.")
                    .foregroundStyle(AppColors.tertiaryText)
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
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
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
        NotificationSettingsView(
            authSession: AuthSessionStore(authRepository: PreviewAuthRepository()),
            notificationSettingsRepository: MockNotificationSettingsRepository()
        )
    }
}
