import SwiftUI
import UIKit
import AVFoundation
import AVKit

// MARK: - Keyboard Switch Video Player Component

class KeyboardSwitchVideoContainerView: UIView {
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
                NSLog("[KeyboardSwitchVideoContainerView] ⚠️ Bounds not set yet: width=\(bounds.width), height=\(bounds.height)")
            }
            return
        }
        
        let containerHeight = bounds.height
        let containerWidth = bounds.width
        
        // Get video aspect ratio - use actual video size if available, otherwise assume 9:16 portrait
        let videoAspectRatio: CGFloat
        if let videoSize = videoSize, videoSize.width > 0 {
            videoAspectRatio = videoSize.width / videoSize.height
            NSLog("[KeyboardSwitchVideoContainerView] 📐 Using actual video size: \(videoSize.width)x\(videoSize.height), aspect ratio: \(videoAspectRatio)")
        } else {
            // Default portrait aspect ratio (9:16)
            videoAspectRatio = 9.0 / 16.0
            NSLog("[KeyboardSwitchVideoContainerView] 📐 Using default aspect ratio: \(videoAspectRatio)")
        }
        
        // Use fixed margins: 40pt bottom, left and right
        let bottomMargin: CGFloat = 40.0
        let sideMargin: CGFloat = 40.0
        let sideMargins = sideMargin * 2 // left + right
        
        // Calculate video width based on container width minus side margins
        let videoWidth = containerWidth - sideMargins
        let videoHeight = videoWidth / videoAspectRatio
        
        // Position video with margins (bottom, left, right)
        let videoX = sideMargin // left margin
        let videoY = containerHeight - videoHeight - bottomMargin // position from bottom
        
        NSLog("[KeyboardSwitchVideoContainerView] 🎬 Container: \(containerWidth)x\(containerHeight), Video layer: \(videoWidth)x\(videoHeight), position: (\(videoX), \(videoY))")
        
        // Position video layer with margins
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = CGRect(
            x: videoX,
            y: videoY,
            width: videoWidth,
            height: videoHeight
        )
        // Add corner radius to video (32pt matching setup screen)
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

struct KeyboardSwitchVideoPlayer: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    
    private var videoName: String {
        colorScheme == .dark ? "KeyboardSwitchDark" : "KeyboardSwitch"
    }
    private let videoExtension: String = "mov"
    
    func makeUIView(context: Context) -> UIView {
        let containerView = KeyboardSwitchVideoContainerView()
        containerView.backgroundColor = UIColor.systemGray5 // Grey background for container (matching setup screen)
        containerView.clipsToBounds = true
        
        // Load video from bundle (use computed videoName based on color scheme)
        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            NSLog("[KeyboardSwitchVideoPlayer] ❌ Error: Could not find video file \(videoName).\(videoExtension) in bundle")
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
        
        NSLog("[KeyboardSwitchVideoPlayer] ✅ Found video at: \(url.path)")
        
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
            NSLog("[KeyboardSwitchVideoPlayer] 📹 Video dimensions: \(videoSize.width)x\(videoSize.height)")
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
        
        // Update frame (will be called again in layoutSubviews when bounds are set)
        containerView.updatePlayerLayerFrame()
        
        // Start playing
        player.play()
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Check if color scheme changed and switch video if needed
        let currentVideoName = colorScheme == .dark ? "KeyboardSwitchDark" : "KeyboardSwitch"
        if let containerView = uiView as? KeyboardSwitchVideoContainerView,
           let currentPlayer = containerView.player,
           let currentPlayerItem = currentPlayer.currentItem,
           let currentURL = currentPlayerItem.asset as? AVURLAsset {
            let currentFileName = currentURL.url.deletingPathExtension().lastPathComponent
            if currentFileName != currentVideoName {
                // Color scheme changed, switch video
                NSLog("[KeyboardSwitchVideoPlayer] 🎨 Color scheme changed, switching video from \(currentFileName) to \(currentVideoName)")
                switchVideo(in: containerView, to: currentVideoName, context: context)
            }
        }
        
        // Frame updates are handled by layoutSubviews in KeyboardSwitchVideoContainerView
        if let containerView = uiView as? KeyboardSwitchVideoContainerView {
            containerView.updatePlayerLayerFrame()
        }
    }
    
    private func switchVideo(in containerView: KeyboardSwitchVideoContainerView, to videoName: String, context: Context) {
        // Stop current player
        containerView.playerLooper?.disableLooping()
        containerView.player?.pause()
        
        // Remove old player layer
        containerView.playerLayer?.removeFromSuperlayer()
        
        // Load new video from bundle
        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            NSLog("[KeyboardSwitchVideoPlayer] ❌ Error: Could not find video file \(videoName).\(videoExtension) in bundle")
            return
        }
        
        NSLog("[KeyboardSwitchVideoPlayer] ✅ Switching to video at: \(url.path)")
        
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
            NSLog("[KeyboardSwitchVideoPlayer] 📹 New video dimensions: \(videoSize.width)x\(videoSize.height)")
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

// MARK: - Onboarding Success View

struct OnboardingSuccessView: View {
    let onDone: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Video space at top - fills available space (same structure as setup screen)
                KeyboardSwitchVideoPlayer()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .frame(maxHeight: .infinity)
            
                // Success message and CTA at bottom
                VStack(spacing: 0) {
                    // Success message
                    VStack(alignment: .leading, spacing: 8) {
                        // Green checkmark above the header
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.green)
                            .offset(x: -2) // Align with text below
                        
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
                    PrimaryCTAButton(title: "Done", action: onDone)
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

