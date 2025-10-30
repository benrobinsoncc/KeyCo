import SwiftUI
import StoreKit
import MessageUI

struct HomeView: View {
    @StateObject private var appState = AppState.shared
    @State private var showingOnboarding = false
    @State private var isKeyboardActive = false
    @State private var showingHowToUse = false
    @State private var showingAppIcon = false
    @State private var showingTheme = false
    @State private var showingFeedback = false
    @State private var showingSupport = false
    @State private var showingSnippets = false
    @AppStorage("isShowingOnboardingFromHome") private var isShowingOnboardingFromHome = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Section - Centered
                    HStack(spacing: 12) {
                        Image(systemName: isKeyboardActive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(isKeyboardActive ? .green : .orange)

                        Text(isKeyboardActive ? "Keyboard active" : "Keyboard inactive")
                            .font(.headline)
                            .foregroundStyle(isKeyboardActive ? .green : .orange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Setup Section - 2 cards side by side
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Setup")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        HStack(spacing: 16) {
                            // Left Card: Show onboarding
                            CardButton(
                                icon: "questionmark.circle.fill",
                                title: "Show onboarding",
                                subtitle: "Learn the basics"
                            ) {
                                appState.currentOnboardingStep = "welcome"
                                showingOnboarding = true
                            }
                            
                            // Right Card: Test your keyboard
                            CardButton(
                                icon: "square.and.pencil",
                                title: "Test keyboard",
                                subtitle: "Try it out"
                            ) {
                                showingHowToUse = true
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Snippets Management Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Management")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            Button(action: {
                                showingSnippets = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Manage Snippets")
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

                    // Customization Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Customise")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            Button(action: {
                                showingAppIcon = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("App icon")
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
                                showingTheme = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "paintbrush.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(uiColor: .label))
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    Text("Theme")
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
            .navigationTitle("KeyCo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSnippets = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("Snippets")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingSnippets) {
                SnippetsManagementView()
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
                NSLog("🎬 Creating OnboardingCoordinator")
                return OnboardingCoordinator(isPresented: $showingOnboarding)
                    .id("onboarding-flow")
            }
            .onChange(of: showingOnboarding) { newValue in
                isShowingOnboardingFromHome = newValue
            }
            .sheet(isPresented: $showingHowToUse) {
                NavigationStack {
                    KeyboardTestView(onComplete: { showingHowToUse = false }, onSkip: { showingHowToUse = false })
                }
            }
            .sheet(isPresented: $showingAppIcon) {
                NavigationStack {
                    LogoSelectionView(onContinue: { showingAppIcon = false }, isOnboarding: false)
                }
            }
            .sheet(isPresented: $showingTheme) {
                NavigationStack {
                    ThemeSelectionView(onContinue: { showingTheme = false }, isOnboarding: false)
                }
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
        isKeyboardActive = KeyboardDetectionHelper.shared.isKeyboardEnabled()
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
    
    private func openKeyboard() {
        // Opens the keyboard settings where user can enable the keyboard
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

struct CardButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color(uiColor: .label))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
