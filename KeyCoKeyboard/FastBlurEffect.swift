import SwiftUI
import AnimateText

/// Custom fast blur effect for quicker text animations
public struct FastBlurEffect: ATTextAnimateEffect {
    public var data: ATElementData
    public var userInfo: Any?

    public init(_ data: ATElementData, _ userInfo: Any?) {
        self.data = data
        self.userInfo = userInfo
    }

    public func body(content: Content) -> some View {
        content
            .opacity(data.value)
            .blur(radius: 15 - 15 * data.value) // Slightly less blur
            .animation(.easeInOut(duration: 0.25).delay(Double(data.index) * 0.02), value: data.value) // Much faster!
    }
}
