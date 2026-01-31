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
    let eventRepository: any EventRepository
    let eventImageUploadService: any EventImageUploadService
}

extension AppDependencies {
    static func preview() -> AppDependencies {
        let supabase = SupabaseClient(
            supabaseURL: URL(string: "https://example.supabase.co")!,
            supabaseKey: "preview"
        )
        return AppDependencies(
            supabase: supabase,
            authRepository: PreviewAuthRepository(),
            eventRepository: MockEventRepository(),
            eventImageUploadService: MockEventImageUploadService()
        )
    }
}
