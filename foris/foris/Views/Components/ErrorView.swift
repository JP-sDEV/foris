import SwiftUI

/// Reusable error view component with retry functionality
/// Provides proper accessibility support and haptic feedback
struct ErrorView: View {
    
    // MARK: - Properties
    
    /// The error to display
    let error: NetworkError
    
    /// Retry action closure
    let retryAction: () -> Void
    
    /// Optional custom title
    let customTitle: String?
    
    /// Whether to show the retry button
    let showRetryButton: Bool
    
    // MARK: - Initialization
    
    /// Initialize with error and retry action
    /// - Parameters:
    ///   - error: The network error to display
    ///   - retryAction: Action to perform when retry is tapped
    init(error: NetworkError, retryAction: @escaping () -> Void) {
        self.error = error
        self.retryAction = retryAction
        self.customTitle = nil
        self.showRetryButton = error.shouldRetry
    }
    
    /// Initialize with full customization
    /// - Parameters:
    ///   - error: The network error to display
    ///   - customTitle: Optional custom title override
    ///   - showRetryButton: Whether to show the retry button
    ///   - retryAction: Action to perform when retry is tapped
    init(
        error: NetworkError,
        customTitle: String? = nil,
        showRetryButton: Bool? = nil,
        retryAction: @escaping () -> Void
    ) {
        self.error = error
        self.retryAction = retryAction
        self.customTitle = customTitle
        self.showRetryButton = showRetryButton ?? error.shouldRetry
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            errorIcon
                .font(.system(size: 60))
                .foregroundColor(errorColor)
                .accessibilityLabel("Error icon")
            
            // Error Content
            VStack(spacing: 12) {
                // Title
                Text(errorTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                // Description
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Recovery Suggestion
                if let recoverySuggestion = error.recoverySuggestion {
                    Text(recoverySuggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            
            // Retry Button
            if showRetryButton {
                Button(action: handleRetryTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor)
                    )
                }
                .accessibilityLabel("Retry button")
                .accessibilityHint("Tap to try the operation again")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Computed Properties
    
    private var errorIcon: Image {
        switch error {
        case .networkUnavailable:
            return Image(systemName: "wifi.slash")
        case .timeout:
            return Image(systemName: "clock.badge.exclamationmark")
        case .serverError, .internalServerError, .badGateway, .serviceUnavailable:
            return Image(systemName: "server.rack")
        case .unauthorized:
            return Image(systemName: "lock.shield")
        case .forbidden:
            return Image(systemName: "hand.raised")
        case .notFound:
            return Image(systemName: "questionmark.folder")
        case .tooManyRequests:
            return Image(systemName: "exclamationmark.triangle")
        default:
            return Image(systemName: "exclamationmark.circle")
        }
    }
    
    private var errorColor: Color {
        switch error {
        case .networkUnavailable:
            return .orange
        case .unauthorized, .forbidden:
            return .red
        case .timeout:
            return .yellow
        default:
            return .red
        }
    }
    
    private var errorTitle: String {
        if let customTitle = customTitle {
            return customTitle
        }
        
        switch error {
        case .networkUnavailable:
            return "No Internet Connection"
        case .timeout:
            return "Request Timed Out"
        case .serverError, .internalServerError:
            return "Server Error"
        case .unauthorized:
            return "Authentication Required"
        case .forbidden:
            return "Access Denied"
        case .notFound:
            return "Not Found"
        case .tooManyRequests:
            return "Too Many Requests"
        case .serviceUnavailable:
            return "Service Unavailable"
        case .badGateway:
            return "Connection Error"
        default:
            return "Something Went Wrong"
        }
    }
    
    // MARK: - Actions
    
    private func handleRetryTap() {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Announce retry to accessibility users
        UIAccessibility.post(notification: .announcement, argument: "Retrying...")
        
        // Perform retry action
        retryAction()
    }
}

// MARK: - Convenience Initializers

extension ErrorView {
    /// Creates an error view for network unavailable
    static func networkUnavailable(retryAction: @escaping () -> Void) -> ErrorView {
        ErrorView(error: .networkUnavailable, retryAction: retryAction)
    }
    
    /// Creates an error view for timeout
    static func timeout(retryAction: @escaping () -> Void) -> ErrorView {
        ErrorView(error: .timeout, retryAction: retryAction)
    }
    
    /// Creates an error view for server error
    static func serverError(retryAction: @escaping () -> Void) -> ErrorView {
        ErrorView(error: .internalServerError, retryAction: retryAction)
    }
    
    /// Creates an error view without retry button
    static func noRetry(error: NetworkError) -> ErrorView {
        ErrorView(error: error, showRetryButton: false) { }
    }
}

// MARK: - View Modifiers

extension ErrorView {
    /// Adds a card-style background
    func withCardBackground() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .padding()
    }
    
    /// Adds a compact layout for smaller spaces
    func compactLayout() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                errorIcon
                    .font(.system(size: 24))
                    .foregroundColor(errorColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(errorTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            if showRetryButton {
                Button("Retry", action: handleRetryTap)
                    .font(.caption)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Accessibility Enhancements

extension ErrorView {
    /// Adds enhanced accessibility support
    func accessibilityEnhanced() -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(errorTitle). \(error.localizedDescription)")
            .accessibilityHint(error.recoverySuggestion ?? "")
            .onAppear {
                // Announce error to accessibility users
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "Error: \(error.localizedDescription)"
                    )
                }
            }
    }
}

// MARK: - Animation Enhancements

extension ErrorView {
    /// Adds shake animation for error appearance
    func withShakeAnimation() -> some View {
        self
            .modifier(ShakeEffect())
    }
    
    /// Adds fade-in animation
    func withFadeInAnimation() -> some View {
        self
            .opacity(0)
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    // Animation handled by opacity modifier
                }
            }
    }
}

// MARK: - Shake Effect Modifier

private struct ShakeEffect: ViewModifier {
    @State private var shakeOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                    shakeOffset = 10
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shakeOffset = 0
                }
            }
    }
}

// MARK: - Preview Provider

#Preview("Network Error") {
    ErrorView(error: .networkUnavailable) {
        print("Retry tapped")
    }
}

#Preview("Server Error") {
    ErrorView(error: .internalServerError) {
        print("Retry tapped")
    }
}

#Preview("Timeout Error") {
    ErrorView(error: .timeout) {
        print("Retry tapped")
    }
}

#Preview("No Retry Button") {
    ErrorView.noRetry(error: .unauthorized)
}

#Preview("Custom Title") {
    ErrorView(
        error: .networkUnavailable,
        customTitle: "Connection Problem"
    ) {
        print("Retry tapped")
    }
}

#Preview("Card Background") {
    ErrorView(error: .serverError(500)) {
        print("Retry tapped")
    }
    .withCardBackground()
    .background(Color.gray.opacity(0.1))
}

#Preview("Compact Layout") {
    VStack {
        ErrorView(error: .networkUnavailable) {
            print("Retry tapped")
        }
        .compactLayout()
        
        Spacer()
    }
    .padding()
}

#Preview("Dark Mode") {
    ErrorView(error: .serviceUnavailable) {
        print("Retry tapped")
    }
    .preferredColorScheme(.dark)
}

#Preview("Multiple Error Types") {
    ScrollView {
        VStack(spacing: 20) {
            ErrorView.networkUnavailable { }
                .compactLayout()
            
            ErrorView.timeout { }
                .compactLayout()
            
            ErrorView.serverError { }
                .compactLayout()
            
            ErrorView.noRetry(error: .forbidden)
                .compactLayout()
        }
        .padding()
    }
}