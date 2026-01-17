//
//  AppColors.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 16/01/2026.
//

import SwiftUI

/// Centralized color system for the app.
/// Colors are named by role, not visual value, to support easy theming and consistency.
enum AppColors {
    // MARK: - Backgrounds
    
    /// Main screen background
    static var background: Color {
        Color(lightColor: .white, darkColor: .black)
    }
    
    /// Surface color for cards, sheets, and rows
    static var surface: Color {
        Color(lightColor: Color(.systemGray6), darkColor: Color.white.opacity(0.06))
    }
    
    /// Elevated surface for featured cards and modals
    static var elevatedSurface: Color {
        Color(lightColor: Color(.systemBackground), darkColor: Color.white.opacity(0.12))
    }
    
    // MARK: - Text
    
    /// Primary text color for headings and important content
    static var primaryText: Color {
        Color(lightColor: .black, darkColor: .white)
    }
    
    /// Secondary text color for body content
    static var secondaryText: Color {
        Color(lightColor: Color(.secondaryLabel), darkColor: Color.white.opacity(0.75))
    }
    
    /// Tertiary text color for low emphasis content
    static var tertiaryText: Color {
        Color(lightColor: Color(.tertiaryLabel), darkColor: Color.white.opacity(0.6))
    }
    
    // MARK: - Accents & States
    
    /// Primary accent color for interactive elements
    static var accent: Color {
        Color(lightColor: Color(.systemBlue), darkColor: Color(red: 0.36, green: 0.6, blue: 1.0))
    }
    
    /// Success state color (e.g., "Going" RSVP status)
    static var success: Color {
        Color(lightColor: Color(.systemGreen), darkColor: Color(red: 0.3, green: 0.78, blue: 0.5))
    }
    
    /// Warning state color (e.g., "Maybe" RSVP status)
    static var warning: Color {
        Color(lightColor: Color(.systemOrange), darkColor: Color(red: 1.0, green: 0.55, blue: 0.3))
    }
    
    /// Danger state color (e.g., "Not Going" RSVP status)
    static var danger: Color {
        Color(lightColor: Color(.systemRed), darkColor: Color(red: 1.0, green: 0.4, blue: 0.4))
    }
    
    // MARK: - Dividers & Overlays
    
    /// Divider color for separating content
    static var divider: Color {
        Color(lightColor: Color(.separator), darkColor: Color.white.opacity(0.06))
    }
    
    /// Overlay color used for image gradients and dimming
    static var overlay: Color {
        Color(lightColor: Color.black.opacity(0.3), darkColor: Color.black.opacity(0.7))
    }
    
    // MARK: - Category Colors
    
    /// Tech category color
    static var tech: Color {
        Color(red: 0.36, green: 0.6, blue: 1.0)
    }
    
    /// AI category color
    static var ai: Color {
        Color(red: 0.85, green: 0.42, blue: 1.0)
    }
    
    /// Music category color
    static var music: Color {
        Color(red: 0.84, green: 0.64, blue: 1.0)
    }
    
    /// Food category color
    static var food: Color {
        Color(red: 1.0, green: 0.78, blue: 0.33)
    }
    
    /// Fitness category color
    static var fitness: Color {
        Color(red: 1.0, green: 0.55, blue: 0.3)
    }
    
    /// Arts category color
    static var arts: Color {
        Color(red: 0.84, green: 0.64, blue: 1.0)
    }
}

// MARK: - Color Extension for Light/Dark Mode

extension Color {
    /// Creates a color that adapts to light and dark mode from Color values
    /// Dark mode is the default/primary mode
    init(lightColor: Color, darkColor: Color) {
        #if os(iOS)
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light:
                return UIColor(lightColor)
            case .dark:
                return UIColor(darkColor)
            case .unspecified:
                return UIColor(darkColor)
            @unknown default:
                return UIColor(darkColor)
            }
        })
        #else
        self = darkColor
        #endif
    }
}
