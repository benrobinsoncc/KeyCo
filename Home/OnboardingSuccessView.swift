import SwiftUI
import UIKit

struct OnboardingSuccessView: View {
    let onDone: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Video space at top - fills available space (same structure as setup screen)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.green)
                    )
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .frame(maxHeight: .infinity)
            
                // Success message and CTA at bottom
                VStack(spacing: 0) {
                    // Success message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You're good to go!")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color(uiColor: .label))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        (Text("Tap the ") + Text(Image(systemName: "globe")) + Text(" icon on your keyboard to switch to Keyboard Copilot wherever you type."))
                            .font(.body)
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    
                    // Done CTA
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        onDone()
                    }) {
                        Text("Done")
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
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.bottom, 16)
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

#Preview {
    OnboardingSuccessView(onDone: {})
}

