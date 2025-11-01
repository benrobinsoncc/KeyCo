import UIKit

/// Interactive 2D tone map for adjusting message tone (Casual↔Formal) and length (Detailed↔Brief)
final class ToneMapView: UIView {
    
    // MARK: - Properties
    
    var onPositionChanged: ((_ x: Float, _ y: Float) -> Void)?
    var onGestureEnded: ((_ x: Float, _ y: Float) -> Void)?
    var isEnabled: Bool = true {
        didSet {
            selector.isUserInteractionEnabled = isEnabled
            isUserInteractionEnabled = isEnabled
        }
    }
    
    // Normalized position (0.0 to 1.0 for both axes)
    // x: 0 = Casual (left), 1 = Formal (right)
    // y: 0 = Detailed (top), 1 = Brief (bottom)
    var position: (x: Float, y: Float) = (0.5, 0.5) {
        didSet {
            updateSelectorPosition(animated: shouldAnimatePosition)
        }
    }
    
    // Track previous position for grid line crossing detection
    private var lastGridPosition: (x: Int, y: Int) = (2, 2)
    private var shouldAnimatePosition: Bool = false
    private var isDragging: Bool = false
    
    // MARK: - UI Components
    
    private let gradientLayer = CAGradientLayer()
    private let gridLayer = CAShapeLayer()
    private let selector = UIView()
    private let selectorDot = UIView()
    private let loadingSpinner = UIActivityIndicatorView(style: .medium)
    
    // Labels for cardinal positions
    private let detailedLabel = UILabel()
    private let friendlyLabel = UILabel()
    private let formalLabel = UILabel()
    private let briefLabel = UILabel()
    
    // MARK: - Constants
    
    private let selectorSize: CGFloat = 44
    private let selectorDotSize: CGFloat = 16
    private let labelHeight: CGFloat = 24
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .clear
        layer.cornerRadius = 16
        // Round only top corners (top left and top right)
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.masksToBounds = true
        
        // Make sure the view can receive touches
        isUserInteractionEnabled = true
        
        // Match action bar button background color
        // Same grey as buttons in ActionContainerView
        backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.tertiarySystemBackground : UIColor.secondarySystemBackground
        }
        
        // Optional: Ultra-subtle gradient for minimal depth (disabled to match buttons)
        // Uncomment below if you want a very subtle gradient overlay
        // gradientLayer.colors = [
        //     UIColor.systemGray6.cgColor,
        //     UIColor.systemGray5.cgColor
        // ]
        // gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        // gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        // gradientLayer.opacity = 0.2
        // layer.addSublayer(gradientLayer)
        
        // Grid lines - visible in both light and dark mode
        // More visible in dark mode for better contrast
        updateGridColor()
        gridLayer.lineWidth = 0.5
        gridLayer.fillColor = UIColor.clear.cgColor
        // Solid lines for cleaner minimal look (removed dashed pattern)
        layer.addSublayer(gridLayer)
        
        // Setup selector - modern, elevated appearance
        // Match action bar background color (darker than buttons)
        selector.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground
        }
        selector.layer.cornerRadius = selectorSize / 2
        // More subtle, modern shadow
        selector.layer.shadowColor = UIColor.black.cgColor
        selector.layer.shadowOffset = CGSize(width: 0, height: 1)
        selector.layer.shadowRadius = 6
        selector.layer.shadowOpacity = 0.15
        selector.layer.borderWidth = 0.5
        selector.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        selector.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selector)
        
        // Setup selector dot - refined appearance with subtle depth
        selectorDot.backgroundColor = .label
        selectorDot.layer.cornerRadius = selectorDotSize / 2
        selectorDot.layer.shadowColor = UIColor.black.cgColor
        selectorDot.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        selectorDot.layer.shadowRadius = 2
        selectorDot.layer.shadowOpacity = 0.2
        selectorDot.translatesAutoresizingMaskIntoConstraints = false
        selector.addSubview(selectorDot)
        
        // Setup loading spinner
        loadingSpinner.hidesWhenStopped = true
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        selector.addSubview(loadingSpinner)
        
        // Setup labels - refined typography for better readability
        let labelFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let labelTextColor = UIColor.label.withAlphaComponent(0.85)
        
        detailedLabel.text = "Detailed"
        detailedLabel.font = labelFont
        detailedLabel.textColor = labelTextColor
        detailedLabel.textAlignment = .center
        detailedLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailedLabel)
        
        friendlyLabel.text = "Friendly"
        friendlyLabel.font = labelFont
        friendlyLabel.textColor = labelTextColor
        friendlyLabel.textAlignment = .center
        friendlyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(friendlyLabel)
        
        formalLabel.text = "Formal"
        formalLabel.font = labelFont
        formalLabel.textColor = labelTextColor
        formalLabel.textAlignment = .center
        formalLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(formalLabel)
        
        briefLabel.text = "Brief"
        briefLabel.font = labelFont
        briefLabel.textColor = labelTextColor
        briefLabel.textAlignment = .center
        briefLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(briefLabel)
        
        // Initial position
        updateSelectorPosition()
    }
    
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // Update grid color when switching between light/dark mode
            updateGridColor()
            // Update selector background to match action bar background color
            selector.backgroundColor = UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground
            }
        }
    }
    
    private func updateGridColor() {
        // More visible in dark mode, subtle in light mode
        if traitCollection.userInterfaceStyle == .dark {
            // Dark mode: more visible with higher opacity
            gridLayer.strokeColor = UIColor.separator.withAlphaComponent(0.4).cgColor
        } else {
            // Light mode: subtle but visible
            gridLayer.strokeColor = UIColor.separator.withAlphaComponent(0.15).cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        updateGridLines()
        updateSelectorPosition()
        
        // Add gesture recognizer once after layout is complete
        if panGestureRecognizer == nil {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            addGestureRecognizer(panGesture)
            panGestureRecognizer = panGesture
            NSLog("[ToneMap] Added pan gesture recognizer")
        }
    }
    
    private func updateGridLines() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // Update grid color when redrawing to match current mode
        updateGridColor()
        
        let path = UIBezierPath()
        
        // Draw 3 vertical lines (dividing into 4 sections horizontally)
        for i in 1...3 {
            let x = bounds.width * CGFloat(i) / 4.0
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: bounds.height))
        }
        
        // Draw 3 horizontal lines (dividing into 4 sections vertically)
        for i in 1...3 {
            let y = bounds.height * CGFloat(i) / 4.0
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: bounds.width, y: y))
        }
        
        gridLayer.path = path.cgPath
        gridLayer.frame = bounds
    }
    
    
    // MARK: - Gesture Handling
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        NSLog("[ToneMap] handlePan called, state: \(gesture.state.rawValue), isEnabled: \(isEnabled)")
        
        // Don't guard on isEnabled - we'll let the handler decide what to do
        
        let location = gesture.location(in: self)
        
        // Clamp position to bounds
        let x = max(0, min(bounds.width, location.x))
        let y = max(0, min(bounds.height, location.y))
        
        // Convert to normalized coordinates (0-1)
        let normalizedX = Float(x / bounds.width)
        let normalizedY = Float(y / bounds.height)
        
        NSLog("[ToneMap] Normalized position: x=\(normalizedX), y=\(normalizedY)")
        
        position = (normalizedX, normalizedY)
        
        // Always call the callback when position changes, regardless of gesture state
        NSLog("[ToneMap] Calling onPositionChanged callback with x=\(normalizedX), y=\(normalizedY)")
        onPositionChanged?(normalizedX, normalizedY)
        
        // Handle gesture states
        switch gesture.state {
        case .began:
            NSLog("[ToneMap] Gesture began")
            isDragging = true
            shouldAnimatePosition = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            // Initialize grid position tracking
            lastGridPosition = (Int(normalizedX * 4.0), Int(normalizedY * 4.0))
            // Animate selector scale on drag start - bigger scale for more dramatic effect
            UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction, .curveEaseOut], animations: {
                self.selector.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            }, completion: nil)
        case .changed:
            NSLog("[ToneMap] Gesture changed")
            // Provide subtle haptic feedback when crossing grid lines
            let gridX = Int(normalizedX * 4.0)
            let gridY = Int(normalizedY * 4.0)
            if gridX != lastGridPosition.x || gridY != lastGridPosition.y {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                lastGridPosition = (gridX, gridY)
            }
        case .ended, .cancelled:
            NSLog("[ToneMap] Gesture ended/cancelled")
            isDragging = false
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            // Temporarily shrink to loading scale, then setLoading will handle the final animation
            // This creates a smooth transition from drag -> loading -> done
            UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                self.selector.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            }, completion: nil)
            // Call onGestureEnded callback when user releases
            NSLog("[ToneMap] Calling onGestureEnded callback")
            onGestureEnded?(normalizedX, normalizedY)
        default:
            break
        }
    }
    
    // MARK: - Updates
    
    private func updateSelectorPosition(animated: Bool = false) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        let x = CGFloat(position.x) * bounds.width
        let y = CGFloat(position.y) * bounds.height
        let newCenter = CGPoint(x: x, y: y)
        
        if animated {
            // Animate position changes smoothly (for programmatic changes like reset)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
                self.selector.center = newCenter
            }, completion: nil)
        } else {
            // Update immediately (for drag gestures)
            selector.center = newCenter
        }
    }
    
    /// Set position with optional animation (for programmatic changes like reset)
    func setPosition(_ newPosition: (x: Float, y: Float), animated: Bool) {
        shouldAnimatePosition = animated
        position = newPosition
        shouldAnimatePosition = false
    }
    
    /// Reset selector to center position and stop loading state
    func reset() {
        // Stop any loading spinner (this will animate transform reset if loading was active)
        let wasLoading = loadingSpinner.isAnimating
        setLoading(false)
        
        // Reset position to center (0.5, 0.5) immediately (no animation)
        setPosition((0.5, 0.5), animated: false)
        
        // Reset drag state
        isDragging = false
        
        // Reset grid position tracking
        lastGridPosition = (2, 2)
        
        // Reset selector transform to ensure it's not stuck in a scaled state
        // If loading was active, setLoading(false) will animate this, but we ensure it's reset
        // If loading was not active, we reset it immediately
        if !wasLoading {
            selector.transform = .identity
        } else {
            // If loading was active, setLoading will animate the reset, but ensure it completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.selector.transform = .identity
            }
        }
    }
    
    func setLoading(_ loading: Bool) {
        if loading {
            // Transition: dot fades out with rotation and scale → spinner fades in with rotation
            // First: animate dot out with dramatic effects
            UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [.curveEaseIn], animations: {
                // Dot rotates, scales down dramatically, and fades
                let rotation = CGAffineTransform(rotationAngle: .pi / 2)
                let scale = CGAffineTransform(scaleX: 0.3, y: 0.3)
                self.selectorDot.transform = rotation.concatenating(scale)
                self.selectorDot.alpha = 0
                
                // Selector scales up smoothly during transition
                self.selector.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            }, completion: { _ in
                self.selectorDot.isHidden = true
                
                // Prepare spinner: start at scale 0.3 and rotated, then animate in
                self.loadingSpinner.alpha = 0
                let startRotation = CGAffineTransform(rotationAngle: -.pi / 2)
                let startScale = CGAffineTransform(scaleX: 0.3, y: 0.3)
                self.loadingSpinner.transform = startRotation.concatenating(startScale)
                self.loadingSpinner.startAnimating()
                
                // Spinner fades in with rotation and scale up (opposite rotation from dot)
                UIView.animate(withDuration: 0.35, delay: 0.05, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.4, options: [.curveEaseOut], animations: {
                    self.loadingSpinner.alpha = 1.0
                    self.loadingSpinner.transform = .identity
                }, completion: nil)
            })
        } else {
            // Transition: spinner fades out with rotation → dot fades in with rotation
            UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [.curveEaseIn], animations: {
                // Spinner rotates out and scales down dramatically
                let rotation = CGAffineTransform(rotationAngle: -.pi / 2)
                let scale = CGAffineTransform(scaleX: 0.3, y: 0.3)
                self.loadingSpinner.transform = rotation.concatenating(scale)
                self.loadingSpinner.alpha = 0
            }, completion: { _ in
                self.loadingSpinner.stopAnimating()
                
                // Prepare dot: start from opposite position
                self.selectorDot.isHidden = false
                self.selectorDot.alpha = 0
                let startRotation = CGAffineTransform(rotationAngle: .pi / 2)
                let startScale = CGAffineTransform(scaleX: 0.3, y: 0.3)
                self.selectorDot.transform = startRotation.concatenating(startScale)
                
                // Simultaneously animate: selector shrinks back, dot rotates/spins in
                UIView.animate(withDuration: 0.4, delay: 0.05, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.6, options: [.allowUserInteraction], animations: {
                    // Selector smoothly returns to normal
                    self.selector.transform = .identity
                    
                    // Dot rotates in and scales up smoothly
                    self.selectorDot.alpha = 1.0
                    self.selectorDot.transform = .identity
                }, completion: nil)
            })
        }
    }
    
    // MARK: - Constraints
    
    override func updateConstraints() {
        guard selector.constraints.isEmpty else {
            super.updateConstraints()
            return
        }
        
        NSLayoutConstraint.activate([
            // Selector
            selector.widthAnchor.constraint(equalToConstant: selectorSize),
            selector.heightAnchor.constraint(equalToConstant: selectorSize),
            
            // Selector dot (centered)
            selectorDot.centerXAnchor.constraint(equalTo: selector.centerXAnchor),
            selectorDot.centerYAnchor.constraint(equalTo: selector.centerYAnchor),
            selectorDot.widthAnchor.constraint(equalToConstant: selectorDotSize),
            selectorDot.heightAnchor.constraint(equalToConstant: selectorDotSize),
            
            // Loading spinner (centered, same as dot)
            loadingSpinner.centerXAnchor.constraint(equalTo: selector.centerXAnchor),
            loadingSpinner.centerYAnchor.constraint(equalTo: selector.centerYAnchor),
            
            // Labels
            detailedLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            detailedLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            detailedLabel.widthAnchor.constraint(equalToConstant: 80),
            detailedLabel.heightAnchor.constraint(equalToConstant: labelHeight),
            
            friendlyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            friendlyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            friendlyLabel.widthAnchor.constraint(equalToConstant: 70),
            friendlyLabel.heightAnchor.constraint(equalToConstant: labelHeight),
            
            formalLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            formalLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            formalLabel.widthAnchor.constraint(equalToConstant: 70),
            formalLabel.heightAnchor.constraint(equalToConstant: labelHeight),
            
            briefLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            briefLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            briefLabel.widthAnchor.constraint(equalToConstant: 60),
            briefLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        // Halo and feedback label positioned programmatically, no constraints needed
        
        super.updateConstraints()
    }
}
