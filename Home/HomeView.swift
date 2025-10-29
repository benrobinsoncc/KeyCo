import SwiftUI
import StoreKit
import MessageUI

struct HomeView: View {
    @StateObject private var appState = AppState.shared
    @State private var showingOnboarding = false
    @State private var isKeyboardActive = false
    @State private var showingFeedback = false
    @State private var showingSupport = false
    @AppStorage("isShowingOnboardingFromHome") private var isShowingOnboardingFromHome = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Add top padding since we removed the status section
                    Spacer()
                        .frame(height: 8)

                    // Setup Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Setup")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        HStack(spacing: 12) {
                            // Show onboarding card
                            Button(action: {
                                // Reset to start of onboarding when manually opening it
                                appState.currentOnboardingStep = "welcome"
                                showingOnboarding = true
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack {
                                        Image(systemName: "questionmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color(uiColor: .label))
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                        Spacer()
                                    }
                                    .padding(.top, 16)
                                    .padding(.leading, 16)
                                    
                                    Spacer()
                                    
                                    Text("Show onboarding")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .padding(.bottom, 16)
                                        .padding(.leading, 16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)
                    }

                    // Support Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Support")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            Button(action: shareApp) {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.and.arrow.up.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Share app")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }

                            Divider()
                                .padding(.leading, 52)

                            Button(action: requestReview) {
                                HStack(spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Rate us")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }

                            Divider()
                                .padding(.leading, 52)

                            Button(action: {
                                showingFeedback = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bubble.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Send feedback")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }

                            Divider()
                                .padding(.leading, 52)

                            Button(action: {
                                showingSupport = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Contact support")
                                        .foregroundStyle(Color(uiColor: .label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Keyboard Copilot")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isKeyboardActive ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(isKeyboardActive ? "Active" : "Inactive")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isKeyboardActive ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    )
                }
            }
            .onAppear {
                checkKeyboardStatus()
                // Restore onboarding sheet if it was showing when app went to background
                NSLog("🏠 HomeView onAppear - isShowingOnboardingFromHome: \(isShowingOnboardingFromHome), showingOnboarding: \(showingOnboarding)")
                if isShowingOnboardingFromHome && !showingOnboarding {
                    NSLog("🏠 Restoring onboarding sheet")
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        showingOnboarding = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                NSLog("🎬 Creating WelcomeView")
                return WelcomeView(onContinue: { showingOnboarding = false })
                    .id("onboarding-flow")
            }
            .onChange(of: showingOnboarding) { _, newValue in
                isShowingOnboardingFromHome = newValue
            }
            .sheet(isPresented: $showingFeedback) {
                MailComposeView(recipient: "benrobinsoncc@gmail.com", subject: "Feedback for KeyCo", isPresented: $showingFeedback)
            }
            .sheet(isPresented: $showingSupport) {
                MailComposeView(recipient: "benrobinsoncc@gmail.com", subject: "Support request for KeyCo", isPresented: $showingSupport)
            }
        }
    }

    private func checkKeyboardStatus() {
        // Keyboard detection not available - always show as enabled
        isKeyboardActive = true
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func shareApp() {
        // Share app link
        let appURL = URL(string: "https://apps.apple.com/app/keyco")! // Replace with actual App Store link
        let activityVC = UIActivityViewController(activityItems: [appURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    HomeView()
}
