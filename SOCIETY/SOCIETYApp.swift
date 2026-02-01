//
//  SOCIETYApp.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 11/01/2026.
//

import Supabase
import SwiftData
import SwiftUI
import UIKit

@main
struct SOCIETYApp: App {
    private let dependencies: AppDependencies
    @StateObject private var authSession: AuthSessionStore
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode: String = AppearanceMode
        .system.rawValue

    init() {
        Self.configureTabBarAppearance()

        do {
            let config = try AppConfig.load()
            let supabase = SupabaseClient(
                supabaseURL: config.supabaseURL,
                supabaseKey: config.supabaseAnonKey,
                options: SupabaseClientOptions(auth: .init(emitLocalSessionAsInitialSession: true))
            )

            let authRepository = SupabaseAuthRepository(client: supabase)
            _authSession = StateObject(
                wrappedValue: AuthSessionStore(authRepository: authRepository))

            self.dependencies = AppDependencies(
                supabase: supabase,
                authRepository: authRepository,
                eventRepository: SupabaseEventRepository(client: supabase),
                rsvpRepository: SupabaseRsvpRepository(client: supabase),
                eventImageUploadService: SupabaseEventImageUploadService(client: supabase),
                profileImageUploadService: SupabaseProfileImageUploadService(client: supabase),
                locationManager: LocationManager()
            )
        } catch {
            // Fallback for previews / misconfigurations.
            let preview = AppDependencies.preview()
            _authSession = StateObject(
                wrappedValue: AuthSessionStore(authRepository: preview.authRepository))
            self.dependencies = preview
        }
    }

    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
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
            Group {
                if authSession.isAuthenticated {
                    MainTabView(dependencies: dependencies)
                        .environmentObject(authSession)
                } else {
                    WelcomeView(
                        authRepository: dependencies.authRepository,
                        authSession: authSession
                    )
                }
            }
            .preferredColorScheme(preferredColorScheme)
            .animation(.easeInOut(duration: 0.35), value: appearanceMode)
            .onAppear { applyWindowAppearance() }
            .onChange(of: appearanceMode) { _, newValue in
                applyWindowAppearance()
                if AppearanceMode(rawValue: newValue) == .system {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        applyWindowAppearance()
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private var preferredColorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    /// Apply appearance to all windows so sheets (e.g. Settings) update when switching to System.
    private func applyWindowAppearance() {
        let style: UIUserInterfaceStyle = {
            switch AppearanceMode(rawValue: appearanceMode) ?? .system {
            case .light: return .light
            case .dark: return .dark
            case .system: return .unspecified
            }
        }()
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}
