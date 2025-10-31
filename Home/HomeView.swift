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
                    // Status Card at top
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Keyboard Copilot")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(uiColor: .label))
                            
                            Text(isKeyboardActive ? "Active" : "Inactive")
                                .font(.subheadline)
                                .foregroundStyle(isKeyboardActive ? .green : .orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 16)
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
                            // Left Card: How to use  
                            CardButton(
                                icon: "questionmark.circle.fill",
                                title: "How to use",
                                subtitle: "Learn the basics"
                            ) {
                                openKeyboard()
                            }
                            
                            // Right Card: Snippets
                            CardButton(
                                icon: "doc.on.doc",
                                title: "Snippets",
                                subtitle: "Manage shortcuts"
                            ) {
                                showingSnippets = true
                            }
                        }
                        .padding(.horizontal, 20)
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
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                                .frame(maxWidth: .infinity, alignment: .leading)
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSnippets) {
                SnippetsManagementView()
            }
            .onAppear {
                // Simple keyboard check - always show active for now
                isKeyboardActive = true
            }
        }
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func shareApp() {
        // Share app link
        let appURL = URL(string: "https://apps.apple.com/app/keyco")!
        let activityVC = UIActivityViewController(activityItems: [appURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func openKeyboard() {
        // Opens the keyboard settings
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
