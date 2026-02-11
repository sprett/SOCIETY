//
//  EditProfileView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import PhotosUI
import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditProfileViewModel

    init(
        authSession: AuthSessionStore,
        profileRepository: any ProfileRepository,
        profileImageUploadService: any ProfileImageUploadService
    ) {
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(
            authSession: authSession,
            profileRepository: profileRepository,
            profileImageUploadService: profileImageUploadService
        ))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                profileImageSection
                basicInfoSection
                bioSection
                socialHandlesSection
                footnote
                if let msg = viewModel.errorMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(AppColors.danger)
                }
            }
            .padding(20)
            .padding(.bottom, 32)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.save() }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.canSave ? AppColors.accent : AppColors.tertiaryText)
                }
                .disabled(!viewModel.canSave)
            }
        }
        .task {
            await viewModel.loadProfile()
        }
        .onChange(of: viewModel.saveSucceeded) { _, succeeded in
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

    private var profileImageSection: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                if let imageData = viewModel.selectedImageData,
                   let uiImage = UIImage(data: imageData),
                   (viewModel.profileImageURL == nil || viewModel.isLoading) {
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
                    UserAvatarView(imageURL: viewModel.profileImageURL, size: 120)
                }
                PhotosPicker(
                    selection: $viewModel.selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 40, height: 40)
                        .background(AppColors.elevatedSurface, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(AppColors.divider, lineWidth: 1)
                        }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("First Name")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)
                TextField("First name", text: $viewModel.firstName)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Last Name")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)
                TextField("Last name", text: $viewModel.lastName)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)
            TextField("Tell us about yourself", text: $viewModel.bio, axis: .vertical)
                .lineLimit(3...6)
                .padding(14)
                .background(AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var socialHandlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social Handles")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)
            VStack(spacing: 0) {
                socialRow(icon: "camera", label: "Instagram", placeholder: "username", text: $viewModel.instagramHandle)
                Divider().background(AppColors.divider).padding(.leading, 50)
                socialRow(icon: "xmark", label: "X (Twitter)", placeholder: "username", text: $viewModel.twitterHandle)
                Divider().background(AppColors.divider).padding(.leading, 50)
                socialRow(icon: "play.rectangle.fill", label: "YouTube", placeholder: "@username", text: $viewModel.youtubeHandle)
                Divider().background(AppColors.divider).padding(.leading, 50)
                socialRow(icon: "music.note", label: "TikTok", placeholder: "@username", text: $viewModel.tiktokHandle)
                Divider().background(AppColors.divider).padding(.leading, 50)
                socialRow(icon: "briefcase.fill", label: "LinkedIn", placeholder: "/in/username", text: $viewModel.linkedinHandle)
                Divider().background(AppColors.divider).padding(.leading, 50)
                socialRow(icon: "globe", label: "Website", placeholder: "https://", text: $viewModel.websiteURL)
            }
            .background(AppColors.elevatedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func socialRow(icon: String, label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppColors.secondaryText)
                .frame(width: 24, alignment: .center)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 100, alignment: .leading)
            TextField(placeholder, text: text)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.trailing)
        }
        .padding(14)
    }

    private var footnote: some View {
        Text("You can edit your username in Account Settings.")
            .font(.caption)
            .foregroundStyle(AppColors.tertiaryText)
    }

}

#Preview {
    NavigationStack {
        EditProfileView(
            authSession: AuthSessionStore(authRepository: PreviewAuthRepository()),
            profileRepository: MockProfileRepository(),
            profileImageUploadService: MockProfileImageUploadService()
        )
    }
}
