import SwiftUI

struct KeyboardSetupView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Video space at top
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.gray.opacity(0.5))
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        Spacer()
                            .frame(minHeight: 100)
                    }
                }
                
                // Instructions and CTA at bottom
                VStack(spacing: 0) {
                    // 3 Steps Instructions
                    VStack(alignment: .leading, spacing: 20) {
                        StepView(
                            number: 1,
                            title: "Tap Open Settings button",
                            description: nil
                        )
                        
                        StepView(
                            number: 2,
                            title: "Tap Keyboards",
                            description: nil
                        )
                        
                        StepView(
                            number: 3,
                            title: "Turn on access",
                            description: "Toggle Keyboard Copilot & Allow Full Access"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                    
                    // Open Settings CTA
                    Button(action: openSettings) {
                        Text("Open Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.black)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Setup keyboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

struct StepView: View {
    let number: Int
    let title: String
    let description: String?
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
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

#Preview {
    KeyboardSetupView()
}

