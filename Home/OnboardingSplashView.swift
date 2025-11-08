import SwiftUI

struct OnboardingSplashView: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Hero content at top
                VStack(spacing: 24) {
                    // App icon or hero image
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.system(size: 100, weight: .regular))
                        .foregroundStyle(Color(uiColor: .label))
                        .padding(.bottom, 20)
                    
                    // Header
                    Text("Welcome to\nKeyboard Copilot")
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(uiColor: .label))
                        .padding(.bottom, 12)
                    
                    // Subheader
                    Text("Your AI-powered keyboard assistant.\nReply, rewrite, search, and chat with ease.")
                        .font(.title3)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxHeight: .infinity)
            
                // CTA button at bottom
                VStack(spacing: 0) {
                    PrimaryCTAButton(title: "Begin", action: onGetStarted)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

#Preview {
    OnboardingSplashView(onGetStarted: {})
}

