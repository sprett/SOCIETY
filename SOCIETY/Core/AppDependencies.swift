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
    let authRepository: any AuthRepository
    let profileRepository: any ProfileRepository
    let notificationSettingsRepository: any NotificationSettingsRepository
    let eventRepository: any EventRepository
    let rsvpRepository: any RsvpRepository
    let eventImageUploadService: any EventImageUploadService
    let profileImageUploadService: any ProfileImageUploadService
    let locationManager: LocationManager
}

extension AppDependencies {
    static func preview() -> AppDependencies {
        let supabase = SupabaseClient(
            supabaseURL: URL(string: "https://example.supabase.co")!,
            supabaseKey: "preview",
            options: SupabaseClientOptions(auth: .init(emitLocalSessionAsInitialSession: true))
        )
        return AppDependencies(
            supabase: supabase,
            authRepository: PreviewAuthRepository(),
            profileRepository: MockProfileRepository(),
            notificationSettingsRepository: MockNotificationSettingsRepository(),
            eventRepository: MockEventRepository(),
            rsvpRepository: MockRsvpRepository(),
            eventImageUploadService: MockEventImageUploadService(),
            profileImageUploadService: MockProfileImageUploadService(),
            locationManager: LocationManager()
        )
    }
}
