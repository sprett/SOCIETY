//
//  PermissionsView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI

struct PermissionsView: View {
    @StateObject private var viewModel = PermissionsViewModel()

    var body: some View {
        List {
            Section {
                permissionRow(
                    title: "Camera",
                    status: viewModel.cameraStatus,
                    footnote: "Used for profile photos and QR code scanning."
                )
                permissionRow(
                    title: "Location",
                    status: viewModel.locationStatus,
                    footnote: "Used to find events near you and show event locations."
                )
                permissionRow(
                    title: "Contacts",
                    status: viewModel.contactsStatus,
                    footnote: "Used to invite contacts to events."
                )
            } header: {
                Text("App Permissions")
                    .foregroundStyle(AppColors.secondaryText)
            }

            Section {
                Button {
                    viewModel.openSystemSettings()
                } label: {
                    HStack {
                        Text("Open System Settings")
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(AppColors.background)
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.refresh()
        }
    }

    private func permissionRow(title: String, status: String, footnote: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.tertiaryText)
            }
            Text(footnote)
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PermissionsView()
    }
}
