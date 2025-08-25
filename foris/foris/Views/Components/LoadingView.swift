import SwiftUI

/// Reusable loading view component with native iOS activity indicator
/// Provides proper accessibility support and customizable appearance
struct LoadingView: View {
    
    // MARK: - Properties
    
    /// Loading message to display
    let message: String
    
    /// Size of the activity indicator
    let indicatorSize: IndicatorSize
    
    /// Color scheme for the loading view
    let colorScheme: ColorScheme?
    
    // MARK: - Initialization
    
    /// Initialize with default message
    init() {
        self.message = "Loading..."
        self.indicatorSize = .medium
        self.colorScheme = nil
    }
    
    /// Initialize with custom message
    /// - Parameter message: Custom loading message
    init(message: String) {
        self.message = message
        self.indicatorSize = .medium
        self.colorScheme = nil
    }
    
    /// Initialize with full customization
    /// - Parameters:
    ///   - message: Loading message to display
    ///   - indicatorSize: Size of the activity indicator
    ///   - colorScheme: Optional color scheme override
    init(message: String = "Loading...", indicatorSize: IndicatorSize = .medium, colorScheme: ColorScheme? = nil) {
        self.message = message
        self.indicatorSize = indicatorSize
        self.colorScheme = colorScheme
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Activity Indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                .scaleEffect(indicatorSize.scale)
                .accessibilityLabel("Loading indicator")
                .accessibilityValue("Content is loading")
            
            // Loading Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityLabel(message)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .preferredColorScheme(colorScheme)
    }
    
    // MARK: - Computed Properties
    
    private var accentColor: Color {
        Color.accentColor
    }
    
    private var backgroundColor: Color {
        Color(UIColor.systemBackground)
    }
}

// MARK: - Indicator Size Enum

extension LoadingView {
    enum IndicatorSize {
        case small
        case medium
        case large
        
        var scale: CGFloat {
            switch self {
            case .small:
                return 0.8
            case .medium:
                return 1.0
            case .large:
                return 1.5
            }
        }
    }
}

// MARK: - Convenience Initializers

extension LoadingView {
    /// Creates a small loading view
    static func small(message: String = "Loading...") -> LoadingView {
        LoadingView(message: message, indicatorSize: .small)
    }
    
    /// Creates a large loading view
    static func large(message: String = "Loading...") -> LoadingView {
        LoadingView(message: message, indicatorSize: .large)
    }
    
    /// Creates a loading view for API requests
    static func apiLoading() -> LoadingView {
        LoadingView(message: "Fetching data...")
    }
    
    /// Creates a loading view for network operations
    static func networkLoading() -> LoadingView {
        LoadingView(message: "Connecting...")
    }
    
    /// Creates a loading view for refresh operations
    static func refreshLoading() -> LoadingView {
        LoadingView(message: "Refreshing...")
    }
}

// MARK: - View Modifiers

extension LoadingView {
    /// Adds a background blur effect
    func withBlurBackground() -> some View {
        self
            .background(
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            )
    }
    
    /// Adds a card-style background
    func withCardBackground() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(radius: 8)
            )
            .padding()
    }
    
    /// Makes the loading view overlay the entire screen
    func fullScreenOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            self
                .withCardBackground()
        }
    }
}

// MARK: - Accessibility Enhancements

extension LoadingView {
    /// Adds custom accessibility traits
    func accessibilityLoadingState() -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.updatesFrequently)
            .accessibilityRemoveTraits(.isButton)
    }
    
    /// Adds accessibility announcement for loading start
    func announceLoadingStart() -> some View {
        self
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIAccessibility.post(notification: .announcement, argument: message)
                }
            }
    }
}

// MARK: - Animation Enhancements

extension LoadingView {
    /// Adds fade-in animation
    func withFadeInAnimation() -> some View {
        self
            .opacity(0)
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    // Animation will be handled by the opacity modifier
                }
            }
    }
    
    /// Adds scale animation
    func withScaleAnimation() -> some View {
        self
            .scaleEffect(0.8)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    // Animation will be handled by the scaleEffect modifier
                }
            }
    }
}

// MARK: - Preview Provider

#Preview("Default Loading") {
    LoadingView()
}

#Preview("Custom Message") {
    LoadingView(message: "Fetching your data...")
}

#Preview("Small Size") {
    LoadingView.small(message: "Please wait...")
}

#Preview("Large Size") {
    LoadingView.large(message: "Loading content...")
}

#Preview("With Card Background") {
    LoadingView(message: "Connecting to server...")
        .withCardBackground()
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("Full Screen Overlay") {
    ZStack {
        // Simulated background content
        VStack {
            Text("Background Content")
            Button("Some Button") { }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.1))
        
        // Loading overlay
        LoadingView(message: "Processing...")
            .fullScreenOverlay()
    }
}

#Preview("Dark Mode") {
    LoadingView(message: "Loading in dark mode...")
        .preferredColorScheme(.dark)
}

#Preview("API Loading States") {
    VStack(spacing: 20) {
        LoadingView.apiLoading()
        LoadingView.networkLoading()
        LoadingView.refreshLoading()
    }
    .padding()
}