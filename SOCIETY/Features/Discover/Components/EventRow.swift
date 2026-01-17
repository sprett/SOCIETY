//
//  EventRow.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 16/01/2026.
//

import SwiftUI

struct EventRow: View {
    let event: Event
    let dateText: String

    var body: some View {
        HStack(spacing: 12) {
            // 1:1 Image
            EventImageView(imageNameOrURL: event.imageNameOrURL, category: event.category)
                .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text(dateText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)

                Text("\(event.venueName) · \(event.neighborhood)")
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)
            }

            Spacer()

            Text(distanceText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(.vertical, 14)
        .padding(.trailing, 14)

    }

    private var distanceText: String {
        String(format: "%.1f km", event.distanceKm)
    }
}
