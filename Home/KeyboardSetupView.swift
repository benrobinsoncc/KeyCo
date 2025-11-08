import SwiftUI
import UIKit

struct KeyboardSetupView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
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
    }
    
    private func openSettings() {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
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

#Preview {
    KeyboardSetupView()
}
