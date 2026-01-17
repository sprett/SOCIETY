//
//  CategoryChip.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 16/01/2026.
//

import SwiftUI

struct CategoryChip: View {
    let title: String
    let systemImageName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule()
                    .fill(isSelected ? AppColors.elevatedSurface : Color.clear)

                Capsule()
                    .strokeBorder(isSelected ? Color.clear : AppColors.divider, lineWidth: 1)

                HStack(spacing: 6) {
                    Image(systemName: systemImageName)
                        .font(.footnote.weight(.semibold))
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .foregroundStyle(AppColors.primaryText)
        }
        .buttonStyle(.plain)
    }
}
