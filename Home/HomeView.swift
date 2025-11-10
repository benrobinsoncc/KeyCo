import SwiftUI
import MessageUI
import UIKit

struct HomeView: View {
    @StateObject private var appState = AppState.shared
    @State private var showingOnboarding = false
    @State private var isKeyboardActive = false
    @State private var showingHowToUse = false
    @State private var showingSnippets = false
    @State private var showingKeyboardSetup = false
    @State private var showingMailComposer = false
    @AppStorage("isShowingOnboardingFromHome") private var isShowingOnboardingFromHome = false
    @AppStorage("onboarding_current_step") private var onboardingCurrentStep: String = "splash"
    @AppStorage("onboarding_has_opened_settings") private var onboardingHasOpenedSettings: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Group 1: Keyboard Status & Snippets Cards - Side by Side
                    HStack(spacing: 16) {
                        // Keyboard Status Card
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.prepare()
                            generator.impactOccurred()
                            showingKeyboardSetup = true
                        }) {
                            VStack(alignment: .leading, spacing: 0) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "keyboard.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(Color(uiColor: .label))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Status")
                                        .font(.headline)
                                        .foregroundStyle(Color(uiColor: .label))
                                    Text("Manage keyboard")
                                        .font(.subheadline)
                                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .frame(height: 120)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // Snippets Card
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.prepare()
                            generator.impactOccurred()
                            showingSnippets = true
                        }) {
                            VStack(alignment: .leading, spacing: 0) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(Color(uiColor: .label))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Snippets")
                                        .font(.headline)
                                        .foregroundStyle(Color(uiColor: .label))
                                    Text("Manage snippets")
                                        .font(.subheadline)
                                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .frame(height: 120)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .padding(.bottom, 20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Keyboard Copilot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        // Reset onboarding state to ensure it starts from the first step
                        onboardingCurrentStep = "splash"
                        onboardingHasOpenedSettings = false
                        showingOnboarding = true
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(uiColor: .label))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        if MFMailComposeViewController.canSendMail() {
                            showingMailComposer = true
                        } else {
                            // Fallback: open mailto link
                            if let url = URL(string: "mailto:benrobinsoncc@gmail.com?subject=Support%20/%20feedback&body=Request%20support%20or%20share%20feedback%20below%20↓%0A%0A%0A") {
                                UIApplication.shared.open(url)
                            }
                        }
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(uiColor: .label))
                    }
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView(
                    recipient: "benrobinsoncc@gmail.com",
                    subject: "Support / feedback",
                    messageBody: """
                    Request support or share feedback below ↓
                    
                    
                    """,
                    isPresented: $showingMailComposer
                )
            }
            .sheet(isPresented: $showingKeyboardSetup) {
                KeyboardSetupView()
            }
            .sheet(isPresented: $showingSnippets) {
                SnippetsManagementView()
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingFlowView()
            }
            .onAppear {
                // Simple keyboard check - always show active for now
                isKeyboardActive = true
            }
        }
    }

    private func openKeyboard() {
        // Opens the keyboard settings
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}


#Preview {
    HomeView()
}
