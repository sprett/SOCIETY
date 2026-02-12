//
//  ProfileSetupViewModel.swift
//  SOCIETY
//
//  Created for post–Sign in with Apple profile setup (stepped flow).
//

import Combine
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

/// UserDefaults key: value is the UUID string of the user who completed profile setup.
let profileSetupCompletedUserIDKey = "ProfileSetupCompletedUserID"

// MARK: - Profile Setup Step

enum ProfileSetupStep: Int, CaseIterable {
    case interests = 0
    case location
    case notifications
    case name
    case birthday
    case contact
    case photo

    static let totalSteps = Self.allCases.count
}

// MARK: - ViewModel

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    // MARK: Step state

    @Published var currentStep: ProfileSetupStep = .interests

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(ProfileSetupStep.totalSteps)
    }

    // MARK: User input fields

    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var birthday: Date?
    @Published var email: String = ""
    @Published var phoneLocal: String = ""
    @Published var selectedCountry: CountryPhoneCode = .norway
    @Published var profileImageURL: String?
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var selectedImageData: Data?

    // MARK: Interests

    @Published var categories: [EventCategory] = []
    @Published var selectedInterestIds: Set<UUID> = []
    @Published var isLoadingCategories: Bool = false

    // MARK: UI state

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var setupSucceeded: Bool = false

    // MARK: Dependencies

    private let authSession: AuthSessionStore
    private let profileRepository: any ProfileRepository
    private let categoryRepository: any CategoryRepository
    private let profileImageUploadService: any ProfileImageUploadService
    private let imageProcessor: ImageProcessor
    private var cancellables = Set<AnyCancellable>()
    private var loadedProfile: UserProfile?
    /// Preprocessed avatar data ready for upload (100×100 JPEG).
    private var processedAvatarData: Data?

    // MARK: Computed helpers

    /// Full name for display and username generation.
    var fullName: String {
        [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Assembled phone number (dial code + local number) for storage.
    var assembledPhone: String {
        let local = phoneLocal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !local.isEmpty else { return "" }
        return "\(selectedCountry.dialingCode) \(local)"
    }

    // MARK: Per-step validation

    var canContinueInterests: Bool {
        selectedInterestIds.count >= 3
    }

    var canContinueName: Bool {
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        return first.count >= 1 && last.count >= 1
    }

    var canContinueBirthday: Bool {
        birthday != nil
    }

    var canContinueContact: Bool {
        let emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phoneLocal.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailValid = (try? emailRegex.wholeMatch(in: trimmedEmail)) != nil
        let phoneValid = trimmedPhone.count >= 6
        return emailValid && phoneValid
    }

    // MARK: Init

    init(
        authSession: AuthSessionStore,
        profileRepository: any ProfileRepository,
        categoryRepository: any CategoryRepository,
        profileImageUploadService: any ProfileImageUploadService,
        imageProcessor: ImageProcessor = ImageProcessor()
    ) {
        self.authSession = authSession
        self.profileRepository = profileRepository
        self.categoryRepository = categoryRepository
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

    // MARK: Step navigation

    func goToNextStep() {
        let allSteps = ProfileSetupStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
            currentIndex < allSteps.count - 1
        else { return }
        currentStep = allSteps[currentIndex + 1]
    }

    func goToPreviousStep() {
        let allSteps = ProfileSetupStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
            currentIndex > 0
        else { return }
        currentStep = allSteps[currentIndex - 1]
    }

    // MARK: Interests

    func toggleInterest(_ categoryId: UUID) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if selectedInterestIds.contains(categoryId) {
            selectedInterestIds.remove(categoryId)
        } else {
            selectedInterestIds.insert(categoryId)
        }
    }

    var allInterestsSelected: Bool {
        !categories.isEmpty && selectedInterestIds.count == categories.count
    }

    func selectAllInterests() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedInterestIds = Set(categories.map(\.id))
    }

    func deselectAllInterests() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedInterestIds = []
    }

    func saveInterests() async {
        guard let userID = authSession.userID else { return }
        do {
            try await categoryRepository.saveUserInterests(
                userId: userID,
                categoryIds: Array(selectedInterestIds)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Permission requests

    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                // Register for remote notifications on the main thread
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            // Silently ignore – user can configure later
        }
    }

    // MARK: Load existing profile data

    func load() async {
        guard let userID = authSession.userID else { return }
        isLoading = true
        isLoadingCategories = true
        errorMessage = nil

        // Fetch categories and existing interests in parallel
        async let categoriesTask = categoryRepository.fetchCategories()
        async let interestsTask = categoryRepository.fetchUserInterests(userId: userID)
        do {
            categories = try await categoriesTask
            selectedInterestIds = try await interestsTask
        } catch {
            // Non-fatal – user can still proceed; categories might be empty but screen will show loader
            print("[ProfileSetup] Failed to load categories: \(error)")
        }
        isLoadingCategories = false

        do {
            let profile = try await profileRepository.loadProfile(
                userID: userID,
                fallbackEmail: authSession.userEmail
            )
            email = authSession.userEmail ?? ""
            if let p = profile {
                loadedProfile = p
                firstName = p.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                lastName = p.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
                birthday = p.birthday
                profileImageURL = p.profileImageURL
                // Try to parse phone number into country code + local
                if let existingPhone = p.phoneNumber {
                    parseExistingPhone(existingPhone)
                }
                if email.isEmpty { email = p.email }
            } else {
                // Prefer given_name/family_name from Apple ID
                if let given = authSession.userGivenName?.trimmingCharacters(in: .whitespacesAndNewlines),
                    !given.isEmpty
                {
                    firstName = given
                }
                if let family = authSession.userFamilyName?.trimmingCharacters(in: .whitespacesAndNewlines),
                    !family.isEmpty
                {
                    lastName = family
                }
                // Fall back to splitting full name
                if firstName.isEmpty && lastName.isEmpty, let userName = authSession.userName {
                    let full = userName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let parts = full.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                    firstName = parts.first.map(String.init) ?? ""
                    lastName = parts.count > 1 ? String(parts[1]) : ""
                }
                birthday = nil
                profileImageURL = authSession.profileImageURL
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: Complete setup (save to backend)

    func completeSetup() async {
        guard let userID = authSession.userID else { return }

        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = generateUsername(from: fullName)

        guard !first.isEmpty else { return }

        isSaving = true
        errorMessage = nil

        let phone = assembledPhone
        var profile = loadedProfile ?? UserProfile(
            id: userID,
            firstName: first,
            lastName: last,
            bio: nil,
            username: username,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phone.isEmpty ? nil : phone,
            profileImageURL: profileImageURL,
            birthday: birthday,
            instagramHandle: nil,
            twitterHandle: nil,
            youtubeHandle: nil,
            tiktokHandle: nil,
            linkedinHandle: nil,
            websiteURL: nil
        )
        profile.firstName = first
        profile.lastName = last
        // Only set username if not already set from loaded profile
        if profile.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profile.username = username
        }
        profile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.phoneNumber = phone.isEmpty ? nil : phone
        profile.birthday = birthday
        profile.profileImageURL = profileImageURL

        do {
            try await profileRepository.updateProfile(profile)
            authSession.setCurrentProfile(profile)
            try await authSession.updateUserName(profile.fullName)
            if let url = profile.profileImageURL {
                try? await authSession.updateProfileImage(url)
            }
            if profile.email != (authSession.userEmail ?? "") {
                try? await authSession.updateUserEmail(profile.email)
            }
            UserDefaults.standard.set(userID.uuidString, forKey: profileSetupCompletedUserIDKey)
            setupSucceeded = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    // MARK: Photo handling

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

    // MARK: Helpers

    /// Tries to parse an existing phone like "+47 12345678" into country + local.
    private func parseExistingPhone(_ phone: String) {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        // Try to match a known country code
        for country in CountryPhoneCode.all {
            if trimmed.hasPrefix(country.dialingCode) {
                selectedCountry = country
                let local = trimmed.dropFirst(country.dialingCode.count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                phoneLocal = local
                return
            }
        }
        // Fallback: put entire string in local
        phoneLocal = trimmed
    }

    /// Auto-generates a username from the full name (lowercase, no spaces).
    private func generateUsername(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleaned = trimmed.replacingOccurrences(of: " ", with: "")
            .filter { $0.isLetter || $0.isNumber }
        return cleaned.isEmpty ? "user\(Int.random(in: 1000...9999))" : cleaned
    }
}

// MARK: - Helper

/// Returns whether the current user has completed profile setup.
func hasCompletedProfileSetup(userID: UUID?) -> Bool {
    guard let userID = userID else { return false }
    return UserDefaults.standard.string(forKey: profileSetupCompletedUserIDKey) == userID.uuidString
}
