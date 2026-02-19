import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 14) {
                Image("OnboardingLogo")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 72, height: 72)

                Text("SOCIETY")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)

                ProgressView()
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    SplashView()
}
