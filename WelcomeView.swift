import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon or hero image
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 100, weight: .regular))
                .foregroundStyle(.tint)
                .padding(.bottom, 40)

            // Header
            Text("Welcome to\nKeyCo")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            // Subheader
            Text("Your AI-powered keyboard assistant.\nReply, rewrite, search, and chat with ease.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // CTA button
            PrimaryButton(title: "Get started") {
                onContinue()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
