//
//  UserAvatarView.swift
//  SOCIETY
//
//  Created by Dino Hukanovic on 31/01/2026.
//

import SwiftUI

struct UserAvatarView: View {
    let imageURL: String?
    let size: CGFloat

    init(imageURL: String? = nil, size: CGFloat = 44) {
        self.imageURL = imageURL
        self.size = size
    }

    var body: some View {
        if let imageURL = imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderView
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
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

    private var placeholderView: some View {
        Circle()
            .fill(AppColors.surface)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: size * 0.55))
                    .foregroundStyle(AppColors.secondaryText)
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        UserAvatarView(size: 44)
        UserAvatarView(
            imageURL:
                "https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?q=80&w=2034&auto=format&fit=crop",
            size: 44)
        UserAvatarView(size: 120)
    }
    .padding()
}
