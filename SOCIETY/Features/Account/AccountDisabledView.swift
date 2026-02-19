import SwiftUI

struct AccountDisabledView: View {
    let reason: String
    let onSignOut: () -> Void
    let onContactSupport: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("Account unavailable")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            Text(reason)
                .font(.body)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                Button("Sign out", action: onSignOut)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.primaryText, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button("Contact support", action: onContactSupport)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
    }
}

#Preview {
    AccountDisabledView(
        reason: "Your account is disabled.",
        onSignOut: {},
        onContactSupport: {}
    )
}
