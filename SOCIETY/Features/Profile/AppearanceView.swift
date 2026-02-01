//
//  AppearanceView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI

/// Stored in UserDefaults; use same key in SOCIETYApp for preferredColorScheme.
enum AppearanceMode: String, CaseIterable {
    case light
    case dark
    case system

    static let storageKey = "appearanceMode"

    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

struct AppearanceView: View {
    @AppStorage(AppearanceMode.storageKey) private var storedMode: String = AppearanceMode.system.rawValue

    private var selectedMode: AppearanceMode {
        get { AppearanceMode(rawValue: storedMode) ?? .system }
        set { storedMode = newValue.rawValue }
    }

    var body: some View {
        List {
            ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        storedMode = mode.rawValue
                    }
                } label: {
                    HStack {
                        Label(mode.title, systemImage: mode.icon)
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        if selectedMode == mode {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(AppColors.background)
        .animation(.easeInOut(duration: 0.35), value: storedMode)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
}
