import SwiftUI
import UIKit
import AVFoundation
import AVKit

// MARK: - Video Player Component

class VideoPlayerContainerView: UIView {
    var playerLayer: AVPlayerLayer?
    var player: AVQueuePlayer?
    var playerLooper: AVPlayerLooper?
    var videoSize: CGSize?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePlayerLayerFrame()
    }
    
    func updatePlayerLayerFrame() {
        guard let playerLayer = playerLayer, bounds.width > 0, bounds.height > 0 else {
            if bounds.width == 0 || bounds.height == 0 {
                NSLog("[VideoPlayerContainerView] ⚠️ Bounds not set yet: width=\(bounds.width), height=\(bounds.height)")
            }
            return
        }
        
        let containerHeight = bounds.height
        let containerWidth = bounds.width
        
        // Get video aspect ratio - use actual video size if available, otherwise assume 9:16 portrait
        let videoAspectRatio: CGFloat
        if let videoSize = videoSize, videoSize.width > 0 {
            videoAspectRatio = videoSize.width / videoSize.height
            NSLog("[VideoPlayerContainerView] 📐 Using actual video size: \(videoSize.width)x\(videoSize.height), aspect ratio: \(videoAspectRatio)")
        } else {
            // Default portrait aspect ratio (9:16)
            videoAspectRatio = 9.0 / 16.0
            NSLog("[VideoPlayerContainerView] 📐 Using default aspect ratio: \(videoAspectRatio)")
        }
        
        // Use fixed margins: 40pt top, left and right
        let topMargin: CGFloat = 40.0
        let sideMargin: CGFloat = 40.0
        let sideMargins = sideMargin * 2 // left + right
        
        // Calculate video width based on container width minus side margins
        let videoWidth = containerWidth - sideMargins
        let videoHeight = videoWidth / videoAspectRatio
        
        // Position video with margins
        let videoX = sideMargin // left margin
        let videoY = topMargin
        
        NSLog("[VideoPlayerContainerView] 🎬 Container: \(containerWidth)x\(containerHeight), Video layer: \(videoWidth)x\(videoHeight), position: (\(videoX), \(videoY))")
        
        // Position video layer with margins
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = CGRect(
            x: videoX,
            y: videoY,
            width: videoWidth,
            height: videoHeight
        )
        // Add corner radius to video (32pt)
        playerLayer.cornerRadius = 32.0
        playerLayer.masksToBounds = true
        CATransaction.commit()
        
        // Ensure layer is visible and properly configured
        playerLayer.isHidden = false
    }
    
    deinit {
        playerLooper?.disableLooping()
        player?.pause()
    }
}

struct LoopingVideoPlayer: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    
    private var videoName: String {
        colorScheme == .dark ? "SetupKeyboardDark" : "SetupKeyboard"
    }
    private let videoExtension: String = "mov"
    
    func makeUIView(context: Context) -> UIView {
        let containerView = VideoPlayerContainerView()
        containerView.backgroundColor = UIColor.systemGray5 // Grey background for container
        containerView.clipsToBounds = true
        
        // Load video from bundle (use computed videoName based on color scheme)
        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            NSLog("[LoopingVideoPlayer] ❌ Error: Could not find video file \(videoName).\(videoExtension) in bundle")
            // Show error label
            let errorLabel = UILabel()
            errorLabel.text = "Video not found"
            errorLabel.textColor = .systemRed
            errorLabel.textAlignment = .center
            errorLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(errorLabel)
            NSLayoutConstraint.activate([
                errorLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                errorLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])
            return containerView
        }
        
        NSLog("[LoopingVideoPlayer] ✅ Found video at: \(url.path)")
        
        // Create player item and player
        let playerItem = AVPlayerItem(url: url)
        let player = AVQueuePlayer(playerItem: playerItem)
        
        // Get video track to determine actual dimensions
        let asset = AVAsset(url: url)
        let videoTracks = asset.tracks(withMediaType: .video)
        if let videoTrack = videoTracks.first {
            let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
            let videoSize = CGSize(width: abs(size.width), height: abs(size.height))
            containerView.videoSize = videoSize
            NSLog("[LoopingVideoPlayer] 📹 Video dimensions: \(videoSize.width)x\(videoSize.height)")
        }
        
        // Create looper for seamless looping
        let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        // Store references
        containerView.player = player
        containerView.playerLooper = playerLooper
        context.coordinator.player = player
        context.coordinator.playerLooper = playerLooper
        
        // Create player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.cornerRadius = 32.0
        playerLayer.masksToBounds = true
        containerView.layer.addSublayer(playerLayer)
        containerView.playerLayer = playerLayer
        context.coordinator.playerLayer = playerLayer
        
        // Keep grey background for container
        
        // Update frame (will be called again in layoutSubviews when bounds are set)
        containerView.updatePlayerLayerFrame()
        
        // Start playing
        player.play()
        
        // Observe when video is ready to play
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            NSLog("[LoopingVideoPlayer] Video finished, should loop")
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Check if color scheme changed and switch video if needed
        let currentVideoName = colorScheme == .dark ? "SetupKeyboardDark" : "SetupKeyboard"
        if let containerView = uiView as? VideoPlayerContainerView,
           let currentPlayer = containerView.player,
           let currentPlayerItem = currentPlayer.currentItem,
           let currentURL = currentPlayerItem.asset as? AVURLAsset {
            let currentFileName = currentURL.url.deletingPathExtension().lastPathComponent
            if currentFileName != currentVideoName {
                // Color scheme changed, switch video
                NSLog("[LoopingVideoPlayer] 🎨 Color scheme changed, switching video from \(currentFileName) to \(currentVideoName)")
                switchVideo(in: containerView, to: currentVideoName, context: context)
            }
        }
        
        // Frame updates are handled by layoutSubviews in VideoPlayerContainerView
        if let containerView = uiView as? VideoPlayerContainerView {
            containerView.updatePlayerLayerFrame()
        }
    }
    
    private func switchVideo(in containerView: VideoPlayerContainerView, to videoName: String, context: Context) {
        // Stop current player
        containerView.playerLooper?.disableLooping()
        containerView.player?.pause()
        
        // Remove old player layer
        containerView.playerLayer?.removeFromSuperlayer()
        
        // Load new video from bundle
        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            NSLog("[LoopingVideoPlayer] ❌ Error: Could not find video file \(videoName).\(videoExtension) in bundle")
            return
        }
        
        NSLog("[LoopingVideoPlayer] ✅ Switching to video at: \(url.path)")
        
        // Create new player item and player
        let playerItem = AVPlayerItem(url: url)
        let player = AVQueuePlayer(playerItem: playerItem)
        
        // Get video track to determine actual dimensions
        let asset = AVAsset(url: url)
        let videoTracks = asset.tracks(withMediaType: .video)
        if let videoTrack = videoTracks.first {
            let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
            let videoSize = CGSize(width: abs(size.width), height: abs(size.height))
            containerView.videoSize = videoSize
            NSLog("[LoopingVideoPlayer] 📹 New video dimensions: \(videoSize.width)x\(videoSize.height)")
        }
        
        // Create new looper for seamless looping
        let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        // Store references
        containerView.player = player
        containerView.playerLooper = playerLooper
        context.coordinator.player = player
        context.coordinator.playerLooper = playerLooper
        
        // Create new player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.cornerRadius = 32.0
        playerLayer.masksToBounds = true
        containerView.layer.addSublayer(playerLayer)
        containerView.playerLayer = playerLayer
        context.coordinator.playerLayer = playerLayer
        
        // Update frame
        containerView.updatePlayerLayerFrame()
        
        // Start playing
        player.play()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var player: AVQueuePlayer?
        var playerLooper: AVPlayerLooper?
        var playerLayer: AVPlayerLayer?
    }
}

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

