//
//  AppDependencies.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 19/01/2026.
//

import Foundation
import Supabase

struct AppDependencies {
    let supabase: SupabaseClient
    let appActivityService: AppActivityService
    let authRepository: any AuthRepository
    let profileRepository: any ProfileRepository
    let categoryRepository: any CategoryRepository
    let notificationSettingsRepository: any NotificationSettingsRepository
    let eventRepository: any EventRepository
    let rsvpRepository: any RsvpRepository
    let eventImageUploadService: any EventImageUploadService
    let profileImageUploadService: any ProfileImageUploadService
    let avatarService: any AvatarService
    let imageProcessor: ImageProcessor
    let locationManager: LocationManager
}

extension AppDependencies {
    static func preview() -> AppDependencies {
        let supabase = SupabaseClient(
            supabaseURL: URL(string: "https://example.supabase.co")!,
            supabaseKey: "preview",
            options: SupabaseClientOptions(auth: .init(emitLocalSessionAsInitialSession: true))
        )
        let locationManager = LocationManager()
        return AppDependencies(
            supabase: supabase,
            appActivityService: AppActivityService(client: supabase, locationManager: locationManager),
            authRepository: PreviewAuthRepository(),
            profileRepository: MockProfileRepository(),
            categoryRepository: MockCategoryRepository(),
            notificationSettingsRepository: MockNotificationSettingsRepository(),
            eventRepository: MockEventRepository(),
            rsvpRepository: MockRsvpRepository(),
            eventImageUploadService: MockEventImageUploadService(),
            profileImageUploadService: MockProfileImageUploadService(),
            avatarService: MockAvatarService(),
            imageProcessor: ImageProcessor(),
            locationManager: locationManager
        )
    }
}
