//
//  AvatarFinalStepViewModel.swift
//  SOCIETY
//

import Combine
import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
final class AvatarFinalStepViewModel: ObservableObject {
    @Published var isGenerating: Bool = true
    @Published var isRandomizing: Bool = false
    @Published var selectedUIImage: UIImage?
    @Published var dicebearSeed: String
    @Published var dicebearImageData: Data?
    @Published var dicebearURL: URL?
    @Published var isUploading: Bool = false
    @Published var error: String?
    @Published var generationError: String?

    private let userId: UUID
    private let avatarService: any AvatarService
    private let existingImageURL: String?
    private var selectedPhotoData: Data?

    init(userId: UUID, avatarService: any AvatarService, existingImageURL: String? = nil) {
        self.userId = userId
        self.avatarService = avatarService
        self.existingImageURL = existingImageURL
        self.dicebearSeed = userId.uuidString
    }

    var canContinue: Bool {
        hasValidAvatar && !isUploading
    }

    var hasValidAvatar: Bool {
        selectedUIImage != nil || dicebearImageData != nil
    }

    var displayImage: UIImage? {
        if let selectedUIImage {
            return selectedUIImage
        }
        guard let dicebearImageData else { return nil }
        return UIImage(data: dicebearImageData)
    }

    func loadInitialAvatar() async {
        if let existing = existingImageURL, let url = URL(string: existing) {
            isGenerating = true
            generationError = nil
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    selectedUIImage = image
                    selectedPhotoData = data
                } else {
                    generationError = "Could not use profile image."
                }
            } catch {
                generationError = error.localizedDescription
            }
            isGenerating = false
            return
        }

        guard dicebearImageData == nil else {
            isGenerating = false
            return
        }
        isGenerating = true
        generationError = nil

        do {
            let data = try await avatarService.downloadDiceBearPNG(seed: dicebearSeed)
            dicebearImageData = data
            dicebearURL = avatarService.buildDiceBearURL(seed: dicebearSeed)
        } catch {
            generationError = error.localizedDescription
        }

        isGenerating = false
    }

    func randomizeAvatar() async {
        isRandomizing = true
        error = nil

        let newSeed = UUID().uuidString
        do {
            let data = try await avatarService.downloadDiceBearPNG(seed: newSeed)
            // Randomize should switch source back to DiceBear.
            selectedUIImage = nil
            selectedPhotoData = nil
            dicebearSeed = newSeed
            dicebearImageData = data
            dicebearURL = avatarService.buildDiceBearURL(seed: newSeed)
            generationError = nil
        } catch {
            if dicebearImageData == nil {
                generationError = error.localizedDescription
            } else {
                self.error = error.localizedDescription
            }
        }

        isRandomizing = false
    }

    func handleSelectedPhoto(_ item: PhotosPickerItem) async {
        let isVideoOrGif = item.supportedContentTypes.contains { type in
            type.conforms(to: .movie) || type.conforms(to: .video) || type.conforms(to: .gif)
        }
        if isVideoOrGif {
            error = "Please choose a photo only. Videos and GIFs are not supported."
            return
        }

        guard let rawData = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: rawData) else {
            error = "Please choose a valid photo. This file format is not supported."
            return
        }

        error = nil
        selectedPhotoData = rawData
        selectedUIImage = image
    }

    func uploadSelectionAndPersist() async throws -> String {
        isUploading = true
        defer { isUploading = false }

        let selection = try selectionForUpload()
        let url = try await avatarService.uploadAvatar(
            data: selection.imageData,
            contentType: selection.contentType,
            userId: userId
        )
        try await avatarService.updateProfileAvatar(userId: userId, avatarURL: url, selection: selection)

        return url.absoluteString
    }

    private func selectionForUpload() throws -> AvatarSelection {
        if let selectedPhotoData {
            let upload = try avatarService.prepareUploadData(from: selectedPhotoData)
            return AvatarSelection(
                source: .upload,
                seed: nil,
                style: nil,
                imageData: upload.data,
                contentType: upload.contentType
            )
        }

        guard let dicebearImageData else {
            throw AvatarServiceError.invalidImageData
        }

        let upload = try avatarService.prepareUploadData(from: dicebearImageData)
        return AvatarSelection(
            source: .dicebear,
            seed: dicebearSeed,
            style: DiceBearURLBuilder.notionistsStyle,
            imageData: upload.data,
            contentType: upload.contentType
        )
    }
}
