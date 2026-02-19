import SwiftUI

struct AccountDeletedView: View {
    let onStartOver: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("Your account has been deleted")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            Text("If you feel this is incorrect, please reach out to us at support@society.com.")
                .font(.body)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Create new account", action: onStartOver)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppColors.primaryText, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
    }
}

#Preview {
    AccountDeletedView(onStartOver: {})
}
