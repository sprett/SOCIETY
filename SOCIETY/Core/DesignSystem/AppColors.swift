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

    /// Onboarding subtitle accent (violet #5B21B6) to match reference design
    static var onboardingAccent: Color {
        Color(red: 91 / 255, green: 33 / 255, blue: 182 / 255)
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

    /// Tech category color (yellow)
    static var tech: Color {
        Color(red: 1.0, green: 0.84, blue: 0.0)
    }

    /// AI category color (purple)
    static var ai: Color {
        Color(red: 0.85, green: 0.42, blue: 1.0)
    }

    /// Climate category color (green)
    static var climate: Color {
        Color(red: 0.3, green: 0.78, blue: 0.5)
    }

    /// Fitness category color (orange)
    static var fitness: Color {
        Color(red: 1.0, green: 0.55, blue: 0.3)
    }

    /// Food & Drink category color (yellow/orange)
    static var food: Color {
        Color(red: 1.0, green: 0.78, blue: 0.33)
    }

    /// Arts & Culture category color (purple)
    static var arts: Color {
        Color(red: 0.84, green: 0.64, blue: 1.0)
    }

    /// Wellness category color (teal/green)
    static var wellness: Color {
        Color(red: 0.3, green: 0.7, blue: 0.7)
    }

    /// Returns the category-specific color for a given category name.
    /// Covers both legacy static names and new DB-driven category names.
    static func color(for category: String) -> Color? {
        switch category {
        case "Tech":
            return tech
        case "AI":
            return ai
        case "Climate", "Climate & Sustainability":
            return climate
        case "Fitness":
            return fitness
        case "Food & Drink", "Food & Drinks":
            return food
        case "Arts & Culture":
            return arts
        case "Wellness":
            return wellness
        case "Music":
            return Color(red: 0.88, green: 0.25, blue: 0.98)   // #E040FB
        case "Nature & Outdoors":
            return Color(red: 0.4, green: 0.73, blue: 0.42)    // #66BB6A
        case "Education":
            return Color(red: 0.26, green: 0.65, blue: 0.96)   // #42A5F5
        case "Personal Growth":
            return Color(red: 0.67, green: 0.28, blue: 0.74)   // #AB47BC
        case "Social & Community":
            return Color(red: 0.15, green: 0.78, blue: 0.85)   // #26C6DA
        case "Business & Networking":
            return Color(red: 0.47, green: 0.56, blue: 0.61)   // #78909C
        case "Gaming":
            return Color(red: 0.49, green: 0.3, blue: 1.0)     // #7C4DFF
        case "Film":
            return Color(red: 0.99, green: 0.85, blue: 0.21)   // #FDD835
        case "Culture":
            return Color(red: 0.93, green: 0.25, blue: 0.48)   // #EC407A
        case "Family & Lifestyle":
            return Color(red: 1.0, green: 0.65, blue: 0.15)    // #FFA726
        default:
            return nil
        }
    }
}

// MARK: - Color Extension for Light/Dark Mode

extension Color {
    /// Creates a color that adapts to light and dark mode from Color values
    /// Dark mode is the default/primary mode
    init(lightColor: Color, darkColor: Color) {
        #if os(iOS)
            self.init(
                uiColor: UIColor { traitCollection in
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
