import SwiftUI
import UIKit

struct OnboardingSetupView: View {
    let onSuccess: () -> Void
    let onSkip: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Video space at top - fills available space
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.gray.opacity(0.5))
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .frame(maxHeight: .infinity)
            
                // Instructions and CTA at bottom
                VStack(spacing: 0) {
                    // 4 Steps Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        StepView(
                            number: 1,
                            title: "Tap Open Settings below",
                            description: nil
                        )
                        
                        StepView(
                            number: 2,
                            title: "Tap Keyboards",
                            description: nil
                        )
                        
                        StepView(
                            number: 3,
                            title: "Toggle Keyboard Copilot",
                            description: nil
                        )
                        
                        StepView(
                            number: 4,
                            title: "Toggle Allow Full Access",
                            description: nil
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    
                    // Open Settings CTA
                    Button(action: {
                        // Trigger haptic feedback immediately
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        openSettings()
                    }) {
                        Text("Open Settings")
                            .font(.headline)
                            .foregroundColor(Color(uiColor: .systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(uiColor: .label))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
    
    private func openSettings() {
        // Notify parent that settings are being opened
        onOpenSettings()
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
}

#Preview {
    OnboardingSetupView(onSuccess: {}, onSkip: {}, onOpenSettings: {})
}

