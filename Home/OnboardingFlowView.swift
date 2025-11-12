import SwiftUI
import UIKit

struct PrimaryCTAButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(uiColor: .systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(uiColor: .label))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CircleBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 32, height: 32)

                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
            }
        }
    }
}

struct KeyboardSetupContentView: View {
    let onOpenSettings: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Video space at top - fills available space
                LoopingVideoPlayer()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                            title: "Tap Open Settings",
                            description: nil,
                            circleBackgroundColor: Color(uiColor: .systemGray5)
                        )
                        
                        StepView(
                            number: 2,
                            title: "Tap Keyboards",
                            description: nil,
                            circleBackgroundColor: Color(uiColor: .systemGray5)
                        )
                        
                        StepView(
                            number: 3,
                            title: "Toggle Keyboard Copilot",
                            description: nil,
                            circleBackgroundColor: Color(uiColor: .systemGray5)
                        )
                        
                        StepView(
                            number: 4,
                            title: "Toggle Allow Full Access",
                            description: nil,
                            circleBackgroundColor: Color(uiColor: .systemGray5)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    
                    // Open Settings CTA
                    PrimaryCTAButton(title: "Open Settings", action: onOpenSettings)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

struct StepView: View {
    let number: Int
    let title: String
    let description: String?
    let circleBackgroundColor: Color
    
    init(number: Int, title: String, description: String?, circleBackgroundColor: Color = Color(uiColor: .systemGray5)) {
        self.number = number
        self.title = title
        self.description = description
        self.circleBackgroundColor = circleBackgroundColor
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(circleBackgroundColor)
                    .frame(width: 26, height: 26)
                
                Text("\(number)")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: .label))
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color(uiColor: .label))
                
                if let description = description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            }
            
            Spacer()
        }
    }
}

enum OnboardingStep {
    case splash
    case setup
    case success
}

struct OnboardingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("onboarding_current_step") private var currentStepRaw: String = "splash"
    @AppStorage("onboarding_has_opened_settings") private var hasOpenedSettings: Bool = false
    @State private var hasAppearedOnce = false
    
    private var currentStep: OnboardingStep {
        switch currentStepRaw {
        case "setup": return .setup
        case "success": return .success
        default: return .splash
        }
    }
    
    private func setCurrentStep(_ step: OnboardingStep) {
        switch step {
        case .splash: currentStepRaw = "splash"
        case .setup: currentStepRaw = "setup"
        case .success: currentStepRaw = "success"
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .splash:
                    OnboardingSplashView {
                        withAnimation {
                            setCurrentStep(.setup)
                        }
                    }
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    
                case .setup:
                    OnboardingSetupView(
                        onSuccess: {
                            print("[OnboardingFlowView] onSuccess called, advancing to success step")
                            withAnimation {
                                setCurrentStep(.success)
                            }
                        },
                        onSkip: {
                            dismiss()
                        },
                        onOpenSettings: {
                            hasOpenedSettings = true
                            print("[OnboardingFlowView] Settings opened, hasOpenedSettings = true")
                        }
                    )
                    .navigationTitle("Setup keyboard")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            CircleBackButton {
                                withAnimation {
                                    setCurrentStep(.splash)
                                }
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Skip") {
                                // Reset state before dismissing
                                currentStepRaw = "splash"
                                hasOpenedSettings = false
                                dismiss()
                            }
                        }
                    }
                    
                case .success:
                    OnboardingSuccessView {
                        // Reset state before dismissing
                        currentStepRaw = "splash"
                        hasOpenedSettings = false
                        dismiss()
                    }
                    .navigationTitle("Setup complete")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            CircleBackButton {
                                withAnimation {
                                    setCurrentStep(.setup)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            print("[OnboardingFlowView] Scene phase: \(oldPhase) -> \(newPhase), currentStep: \(currentStep), hasOpenedSettings: \(hasOpenedSettings)")
            // When scene becomes active and we're on setup screen and settings were opened
            if oldPhase == .background && newPhase == .active {
                print("[OnboardingFlowView] Scene became active from background")
                print("[OnboardingFlowView] Checking conditions - currentStep: \(currentStep), hasOpenedSettings: \(hasOpenedSettings)")
                if currentStep == .setup && hasOpenedSettings {
                    print("[OnboardingFlowView] ✅ Conditions met! Advancing to success screen")
                    // Update immediately on main thread
                    DispatchQueue.main.async {
                        print("[OnboardingFlowView] Executing state change to success")
                        withAnimation {
                            setCurrentStep(.success)
                        }
                    }
                } else {
                    print("[OnboardingFlowView] ❌ Conditions not met - currentStep: \(currentStep), hasOpenedSettings: \(hasOpenedSettings)")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("[OnboardingFlowView] 🔔 didBecomeActiveNotification received")
            print("[OnboardingFlowView] Current state - currentStep: \(currentStep), hasOpenedSettings: \(hasOpenedSettings)")
            // Backup check - execute immediately
            if currentStep == .setup && hasOpenedSettings {
                print("[OnboardingFlowView] ✅ NotificationCenter: Conditions met! Advancing to success")
                DispatchQueue.main.async {
                    print("[OnboardingFlowView] NotificationCenter: Executing state change to success")
                    withAnimation {
                        setCurrentStep(.success)
                    }
                }
            } else {
                print("[OnboardingFlowView] ❌ NotificationCenter: Conditions not met")
            }
        }
        .onAppear {
            print("[OnboardingFlowView] View appeared - currentStep: \(currentStep), hasOpenedSettings: \(hasOpenedSettings)")
            // Reset to splash screen only on first appearance to ensure it always starts from the beginning
            // This handles cases where @AppStorage updates are asynchronous when opening from HomeView
            if !hasAppearedOnce {
                hasAppearedOnce = true
                if currentStepRaw != "splash" {
                    print("[OnboardingFlowView] Resetting to splash screen on first appear")
                    currentStepRaw = "splash"
                    hasOpenedSettings = false
                }
            }
        }
        .onDisappear {
            // Reset the flag when view disappears so it can reset again on next presentation
            hasAppearedOnce = false
        }
    }
}

#Preview {
    OnboardingFlowView()
}

