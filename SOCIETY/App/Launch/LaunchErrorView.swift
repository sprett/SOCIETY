import SwiftUI

struct LaunchErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Something went wrong")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Retry", action: onRetry)
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
    LaunchErrorView(message: "Please check your connection and try again.", onRetry: {})
}
