//
//  EventImageView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 16/01/2026.
//

import SwiftUI

struct EventImageView: View {
    let imageNameOrURL: String
    let category: String

    var body: some View {
        ZStack {
            if isURL {
                AsyncImage(url: URL(string: imageNameOrURL.eventThumbnailURL)) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: 80, height: 80)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var isURL: Bool {
        imageNameOrURL.hasPrefix("http://") || imageNameOrURL.hasPrefix("https://")
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(imageGradient)
            .frame(width: 80, height: 80)
    }

    private var imageGradient: LinearGradient {
        let startColor: Color
        let endColor: Color

        switch category.lowercased() {
        case "tech":
            startColor = AppColors.tech
            endColor = AppColors.tech.opacity(0.6)
        case "ai":
            startColor = AppColors.ai
            endColor = AppColors.ai.opacity(0.6)
        case "fitness":
            startColor = AppColors.fitness
            endColor = AppColors.fitness.opacity(0.6)
        case "food & drink", "food":
            startColor = AppColors.food
            endColor = AppColors.food.opacity(0.6)
        case "arts & culture", "arts":
            startColor = AppColors.arts
            endColor = AppColors.arts.opacity(0.6)
        case "music":
            startColor = AppColors.accent
            endColor = AppColors.accent.opacity(0.6)
        default:
            startColor = AppColors.accent
            endColor = AppColors.accent.opacity(0.6)
        }

        return LinearGradient(
            colors: [startColor, endColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
