//
//  ProfileViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Combine
import PhotosUI
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var profileImageURL: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var selectedImageData: Data?
    @Published var showSignOutConfirmation: Bool = false

    private let authSession: AuthSessionStore
    private let profileImageUploadService: any ProfileImageUploadService
    private let imageProcessor: ImageProcessor
    private var cancellables = Set<AnyCancellable>()
    /// Preprocessed avatar data ready for upload (100×100 JPEG).
    private var processedAvatarData: Data?

    init(
        authSession: AuthSessionStore,
        profileImageUploadService: any ProfileImageUploadService,
        imageProcessor: ImageProcessor = ImageProcessor()
    ) {
        self.authSession = authSession
        self.profileImageUploadService = profileImageUploadService
        self.imageProcessor = imageProcessor

        // Initialize from auth session
        name = authSession.userName ?? ""
        email = authSession.userEmail ?? ""
        profileImageURL = authSession.profileImageURL

        // Observe auth session changes
        authSession.$userName
            .compactMap { $0 }
            .assign(to: \.name, on: self)
            .store(in: &cancellables)

        authSession.$userEmail
            .compactMap { $0 }
            .assign(to: \.email, on: self)
            .store(in: &cancellables)

        authSession.$profileImageURL
            .assign(to: \.profileImageURL, on: self)
            .store(in: &cancellables)

        // Handle photo selection
        $selectedPhoto
            .compactMap { $0 }
            .sink { [weak self] item in
                Task { @MainActor in
                    await self?.loadPhoto(item)
                }
            }
            .store(in: &cancellables)
    }

    func updateName() async {
        guard !name.isEmpty, name != authSession.userName else { return }
        isLoading = true
        errorMessage = nil

        do {
            try await authSession.updateUserName(name)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func uploadProfileImage() async {
        guard let userID = authSession.userID else { return }
        guard let avatarData = processedAvatarData else { return }
        // Fetch current profile image URL from server so we always have the right URL to delete (avoids nil/stale from cache)
        let oldProfileImageURL = await authSession.getCurrentProfileImageURL()
        isLoading = true
        errorMessage = nil

        do {
            let url = try await profileImageUploadService.uploadPreprocessed(
                avatarData: avatarData,
                userId: userID
            )
            try await authSession.updateProfileImage(url.absoluteString)
            // Delete previous profile image from storage to avoid orphaned files
            if let oldURL = oldProfileImageURL {
                await profileImageUploadService.deleteFromStorageIfOwned(url: oldURL)
            }
            // Clear selected data after a brief moment to allow UI to update
            // The profileImageURL will be updated via the Combine subscription to authSession
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds to allow refresh
            processedAvatarData = nil
            selectedImageData = nil
            selectedPhoto = nil
        } catch {
            errorMessage = error.localizedDescription
            // On error, keep processedAvatarData so user can try again
        }

        isLoading = false
    }

    func signOut() async throws {
        try await authSession.signOut()
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard let rawData = try? await item.loadTransferable(type: Data.self) else {
            return
        }

        // Preprocess: center-crop, resize to 100×100, JPEG-encode
        isLoading = true
        errorMessage = nil
        do {
            let avatarData = try await imageProcessor.processProfileImage(from: rawData)
            processedAvatarData = avatarData
            selectedImageData = avatarData  // Use preprocessed data for preview
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return
        }
        isLoading = false

        // Automatically upload when photo is selected
        await uploadProfileImage()
    }
}
