//
//  ProfileView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import PhotosUI
import SwiftUI

struct ProfileView: View {
    enum DisplayMode {
        case sheet
        case pushed
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ProfileViewModel
    @State private var editedName: String = ""
    private let displayMode: DisplayMode

    init(
        authSession: AuthSessionStore,
        profileImageUploadService: any ProfileImageUploadService,
        displayMode: DisplayMode = .sheet
    ) {
        _viewModel = StateObject(
            wrappedValue: ProfileViewModel(
                authSession: authSession,
                profileImageUploadService: profileImageUploadService
            )
        )
        self.displayMode = displayMode
    }

    private var content: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Profile Image Section
                    VStack(spacing: 16) {
                        // Show selected image if available and URL hasn't updated yet, otherwise show URL-based image
                        if let imageData = viewModel.selectedImageData,
                           let uiImage = UIImage(data: imageData),
                           viewModel.profileImageURL == nil || viewModel.isLoading
                        {
                            // Show selected image while uploading or until URL is updated
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay {
                                    Circle()
                                        .strokeBorder(AppColors.divider.opacity(0.3), lineWidth: 2)
                                }
                        } else {
                            // Show URL-based image (will update automatically via Combine)
                            UserAvatarView(imageURL: viewModel.profileImageURL, size: 120)
                        }

                        PhotosPicker(
                            selection: $viewModel.selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text("Change Photo")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColors.accent)
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.top, 24)

                    // Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppColors.secondaryText)

                        TextField("Your name", text: $viewModel.name)
                            .textInputAutocapitalization(.words)
                            .padding(14)
                            .background(AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .onSubmit {
                                Task { await viewModel.updateName() }
                            }
                    }

                    // Email Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppColors.secondaryText)

                        Text(viewModel.email)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.tertiaryText)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.elevatedSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)

                    // Sign Out Button
                    Button {
                        viewModel.showSignOutConfirmation = true
                    } label: {
                        Text("Sign Out")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(.red.opacity(0.3), lineWidth: 1)
                            }
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if displayMode == .sheet {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundStyle(AppColors.primaryText)
                    }
                }
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

    var body: some View {
        Group {
            if displayMode == .pushed {
                content
            } else {
                NavigationStack {
                    content
                }
            }
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $viewModel.showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    do {
                        try await viewModel.signOut()
                        dismiss()
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

#Preview {
    ProfileView(
        authSession: AuthSessionStore(authRepository: PreviewAuthRepository()),
        profileImageUploadService: MockProfileImageUploadService()
    )
}
