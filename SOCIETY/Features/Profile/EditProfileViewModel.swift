//
//  EditProfileViewModel.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import Combine
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class EditProfileViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var bio: String = ""
    @Published var instagramHandle: String = ""
    @Published var twitterHandle: String = ""
    @Published var youtubeHandle: String = ""
    @Published var tiktokHandle: String = ""
    @Published var linkedinHandle: String = ""
    @Published var websiteURL: String = ""
    @Published var profileImageURL: String?
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var selectedImageData: Data?
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var saveSucceeded: Bool = false

    private let authSession: AuthSessionStore
    private let profileRepository: any ProfileRepository
    private let profileImageUploadService: any ProfileImageUploadService
    private let imageProcessor: ImageProcessor
    private var cancellables = Set<AnyCancellable>()
    private var loadedProfile: UserProfile?
    /// Preprocessed avatar data ready for upload (100×100 JPEG).
    private var processedAvatarData: Data?

    var hasChanges: Bool {
        guard let p = loadedProfile else { return true }
        return firstName != p.firstName
            || lastName != p.lastName
            || bio != (p.bio ?? "")
            || instagramHandle != (p.instagramHandle ?? "")
            || twitterHandle != (p.twitterHandle ?? "")
            || youtubeHandle != (p.youtubeHandle ?? "")
            || tiktokHandle != (p.tiktokHandle ?? "")
            || linkedinHandle != (p.linkedinHandle ?? "")
            || websiteURL != (p.websiteURL ?? "")
    }

    var canSave: Bool {
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !first.isEmpty && !last.isEmpty && hasChanges && !isSaving
    }

    init(
        authSession: AuthSessionStore,
        profileRepository: any ProfileRepository,
        profileImageUploadService: any ProfileImageUploadService,
        imageProcessor: ImageProcessor = ImageProcessor()
    ) {
        self.authSession = authSession
        self.profileRepository = profileRepository
        self.profileImageUploadService = profileImageUploadService
        self.imageProcessor = imageProcessor

        $selectedPhoto
            .compactMap { $0 }
            .sink { [weak self] item in
                Task { @MainActor in
                    await self?.loadPhoto(item)
                }
            }
            .store(in: &cancellables)
    }

    func loadProfile() async {
        guard let userID = authSession.userID else { return }
        isLoading = true
        errorMessage = nil

        do {
            let profile = try await profileRepository.loadProfile(
                userID: userID,
                fallbackEmail: authSession.userEmail
            )
            if let p = profile {
                loadedProfile = p
                firstName = p.firstName
                lastName = p.lastName
                bio = p.bio ?? ""
                instagramHandle = p.instagramHandle ?? ""
                twitterHandle = p.twitterHandle ?? ""
                youtubeHandle = p.youtubeHandle ?? ""
                tiktokHandle = p.tiktokHandle ?? ""
                linkedinHandle = p.linkedinHandle ?? ""
                websiteURL = p.websiteURL ?? ""
                profileImageURL = p.profileImageURL
            } else {
                let full = UserProfile.fullName(from: authSession.userName)
                let parts = full.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                let first = String(parts.first ?? "")
                let last = parts.count > 1 ? String(parts[1]) : ""
                let p = UserProfile(
                    id: userID,
                    firstName: first,
                    lastName: last,
                    bio: nil,
                    username: "",
                    email: authSession.userEmail ?? "",
                    phoneNumber: nil,
                    profileImageURL: authSession.profileImageURL,
                    birthday: nil,
                    instagramHandle: nil,
                    twitterHandle: nil,
                    youtubeHandle: nil,
                    tiktokHandle: nil,
                    linkedinHandle: nil,
                    websiteURL: nil
                )
                loadedProfile = p
                firstName = p.firstName
                lastName = p.lastName
                profileImageURL = p.profileImageURL
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func save() async {
        guard let userID = authSession.userID else { return }
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !first.isEmpty, !last.isEmpty else { return }

        isSaving = true
        errorMessage = nil

        var profile = loadedProfile ?? UserProfile(
            id: userID,
            firstName: first,
            lastName: last,
            bio: nil,
            username: "",
            email: authSession.userEmail ?? "",
            phoneNumber: nil,
            profileImageURL: profileImageURL,
            birthday: nil,
            instagramHandle: nil,
            twitterHandle: nil,
            youtubeHandle: nil,
            tiktokHandle: nil,
            linkedinHandle: nil,
            websiteURL: nil
        )
        profile.firstName = first
        profile.lastName = last
        profile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.instagramHandle = instagramHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : instagramHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.twitterHandle = twitterHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : twitterHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.youtubeHandle = youtubeHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : youtubeHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.tiktokHandle = tiktokHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : tiktokHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.linkedinHandle = linkedinHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : linkedinHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.websiteURL = websiteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : websiteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.profileImageURL = profileImageURL

        do {
            try await profileRepository.updateProfile(profile)
            authSession.setCurrentProfile(profile)
            try await authSession.updateUserName(profile.fullName)
            if let url = profile.profileImageURL {
                try? await authSession.updateProfileImage(url)
            }
            loadedProfile = profile
            saveSucceeded = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        // Reject videos and GIFs; we only support static photo formats (e.g. JPEG, PNG, HEIC).
        let isVideoOrGif = item.supportedContentTypes.contains { type in
            type.conforms(to: .movie) || type.conforms(to: .video) || type.conforms(to: .gif)
        }
        if isVideoOrGif {
            selectedPhoto = nil
            errorMessage = "Please choose a photo only. Videos and GIFs are not supported."
            return
        }
        guard let rawData = try? await item.loadTransferable(type: Data.self) else { return }
        guard UIImage(data: rawData) != nil else {
            selectedPhoto = nil
            errorMessage = "Please choose a valid photo. This file format is not supported."
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

        await uploadProfileImage()
    }

    private func uploadProfileImage() async {
        guard let userID = authSession.userID else { return }
        guard let avatarData = processedAvatarData else { return }
        let oldProfileImageURL = await authSession.getCurrentProfileImageURL()
        isLoading = true
        errorMessage = nil

        do {
            let url = try await profileImageUploadService.uploadPreprocessed(
                avatarData: avatarData,
                userId: userID
            )
            profileImageURL = url.absoluteString
            try await authSession.updateProfileImage(url.absoluteString)
            if let oldURL = oldProfileImageURL {
                await profileImageUploadService.deleteFromStorageIfOwned(url: oldURL)
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            processedAvatarData = nil
            selectedImageData = nil
            selectedPhoto = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
