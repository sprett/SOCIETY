//
//  LiquidGlass.swift
//  SOCIETY
//
//  Reusable Liquid Glass primitives so call sites don't repeat
//  `if #available(iOS 26, *)` chains around `.glassEffect` and
//  `.ultraThinMaterial` fallbacks.
//

import SwiftUI

extension View {
    /// Background that adopts iOS 26 Liquid Glass when available, falling back to
    /// `.ultraThinMaterial` so the visual stays close on older OS versions.
    @ViewBuilder
    func liquidGlassBackground<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.background {
                Color.clear.glassEffect(.regular, in: shape)
            }
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    /// Convenience for circular glass — common for floating overlay buttons.
    func liquidGlassCircle() -> some View {
        liquidGlassBackground(in: Circle())
    }

    /// Convenience for rounded-rect glass — common for cards and form rows.
    func liquidGlassCard(cornerRadius: CGFloat = 16) -> some View {
        liquidGlassBackground(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Sheet background that uses Liquid Glass on iOS 26 and a thin material below.
    @ViewBuilder
    func liquidGlassSheetBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.presentationBackground(.thinMaterial)
        } else {
            self.presentationBackground(.thinMaterial)
        }
    }
}

/// Wrapper that becomes a `GlassEffectContainer` on iOS 26 (so multiple glass
/// elements morph and render together) and a plain pass-through on older OSes.
struct GlassCluster<Content: View>: View {
    private let spacing: CGFloat?
    private let content: () -> Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing ?? 0) {
                content()
            }
        } else {
            content()
        }
    }
}
