import SwiftUI

/// A reusable toolbar button component that wraps buttons in rounded containers
/// Provides consistent styling across the app's toolbar buttons
struct ToolbarButton: View {
    let title: String
    let action: () -> Void
    let style: Style
    
    enum Style {
        case primary    // Accent color background with white text
        case secondary  // Secondary background with primary text
        case destructive // Red background for destructive actions
    }
    
    init(_ title: String, style: Style = .secondary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticFeedbackManager.shared.selection()
            action()
        }) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color.accentColor
        case .secondary:
            return Color(uiColor: .secondarySystemBackground)
        case .destructive:
            return Color.red
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return .white
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            ToolbarButton("Skip") { }
            ToolbarButton("Done", style: .primary) { }
            ToolbarButton("Cancel", style: .destructive) { }
        }
        
        Text("Toolbar Button Styles")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}
