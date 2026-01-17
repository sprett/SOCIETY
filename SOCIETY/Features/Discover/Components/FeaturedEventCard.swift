//
//  FeaturedEventCard.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 16/01/2026.
//

import SwiftUI

struct FeaturedEventCard: View {
    let event: Event
    let dateText: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(backgroundGradient)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            AppColors.overlay,
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text(dateText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)

                Text(event.category)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.elevatedSurface)
                    .clipShape(Capsule())
            }
            .padding(16)
        }
        .frame(width: 280, height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

    }

    private var backgroundGradient: LinearGradient {
        // Use a gradient that works well in both light and dark mode
        LinearGradient(
            colors: [
                AppColors.accent.opacity(0.7),
                AppColors.accent.opacity(0.4),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
