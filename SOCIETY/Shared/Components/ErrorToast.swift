//
//  ErrorToast.swift
//  SOCIETY
//

import SwiftUI

struct ErrorToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.92))
        )
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
    }
}

extension View {
    /// Shows an `ErrorToast` anchored to the bottom of the view that auto-dismisses
    /// 3 seconds after `message` becomes non-nil.
    func errorToast(message: Binding<String?>) -> some View {
        modifier(ErrorToastModifier(message: message))
    }
}

private struct ErrorToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    ErrorToast(message: message)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task(id: message) {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            withAnimation(.easeOut(duration: 0.2)) {
                                self.message = nil
                            }
                        }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: message)
    }
}
