//
//  SOCIETYApp.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import SwiftUI
import SwiftData
import Supabase

@main
struct SOCIETYApp: App {
    private let dependencies: AppDependencies
    @StateObject private var authSession: AuthSessionStore

    init() {
        do {
            let config = try AppConfig.load()
            let supabase = SupabaseClient(
                supabaseURL: config.supabaseURL,
                supabaseKey: config.supabaseAnonKey
            )

            let authRepository = SupabaseAuthRepository(client: supabase)
            _authSession = StateObject(wrappedValue: AuthSessionStore(authRepository: authRepository))

            self.dependencies = AppDependencies(
                supabase: supabase,
                authRepository: authRepository,
                eventRepository: SupabaseEventRepository(client: supabase),
                eventImageUploadService: SupabaseEventImageUploadService(client: supabase)
            )
        } catch {
            // Fallback for previews / misconfigurations.
            let preview = AppDependencies.preview()
            _authSession = StateObject(wrappedValue: AuthSessionStore(authRepository: preview.authRepository))
            self.dependencies = preview
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView(dependencies: dependencies)
                .environmentObject(authSession)
        }
        .modelContainer(sharedModelContainer)
    }
}
