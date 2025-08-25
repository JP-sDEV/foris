import SwiftUI

/// Toast notification system for displaying temporary messages to users
/// Provides consistent feedback for user actions and system events
struct ToastNotificationView: View {
    
    // MARK: - Properties
    
    let toast: ToastNotification
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: toast.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(toast.iconColor)
                .accessibilityLabel("\(toast.type.rawValue) icon")
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                if let title = toast.title {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text(toast.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Dismiss button
            if toast.isDismissible {
                Button(action: {
                    HapticFeedbackService.shared.lightImpact()
                    dismissToast()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Dismiss notification")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(toast.backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(toast.borderColor, lineWidth: 1)
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            presentToast()
        }
        .onTapGesture {
            if toast.isDismissible {
                HapticFeedbackService.shared.lightImpact()
                dismissToast()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(toast.type.rawValue) notification: \(toast.message)")
    }
    
    // MARK: - Animation Methods
    
    private func presentToast() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            offset = 0
            opacity = 1
        }
        
        // Provide haptic feedback based on toast type
        switch toast.type {
        case .success:
            HapticFeedbackService.shared.success()
        case .error:
            HapticFeedbackService.shared.error()
        case .warning:
            HapticFeedbackService.shared.warning()
        case .info:
            HapticFeedbackService.shared.lightImpact()
        }
        
        // Auto-dismiss after duration
        if toast.duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                dismissToast()
            }
        }
        
        // Announce to accessibility users
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(
                notification: .announcement,
                argument: "\(toast.type.rawValue): \(toast.message)"
            )
        }
    }
    
    private func dismissToast() {
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = -100
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Toast Notification Model

struct ToastNotification: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String?
    let message: String
    let duration: TimeInterval
    let isDismissible: Bool
    
    init(
        type: ToastType,
        title: String? = nil,
        message: String,
        duration: TimeInterval = 3.0,
        isDismissible: Bool = true
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
        self.isDismissible = isDismissible
    }
    
    // MARK: - Computed Properties
    
    var icon: String {
        switch type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch type {
        case .success:
            return .green
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        }
    }
    
    var backgroundColor: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    var borderColor: Color {
        switch type {
        case .success:
            return .green.opacity(0.3)
        case .error:
            return .red.opacity(0.3)
        case .warning:
            return .orange.opacity(0.3)
        case .info:
            return .blue.opacity(0.3)
        }
    }
    
    static func == (lhs: ToastNotification, rhs: ToastNotification) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Type Enum

enum ToastType: String, CaseIterable {
    case success = "Success"
    case error = "Error"
    case warning = "Warning"
    case info = "Info"
}

// MARK: - Toast Manager

final class ToastManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ToastManager()
    
    // MARK: - Published Properties
    
    @Published var toasts: [ToastNotification] = []
    
    // MARK: - Configuration
    
    private let maxToasts = 3
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Shows a toast notification
    /// - Parameter toast: The toast notification to show
    func show(_ toast: ToastNotification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Remove oldest toast if at max capacity
            if self.toasts.count >= self.maxToasts {
                self.toasts.removeFirst()
            }
            
            self.toasts.append(toast)
        }
    }
    
    /// Dismisses a specific toast
    /// - Parameter toast: The toast to dismiss
    func dismiss(_ toast: ToastNotification) {
        DispatchQueue.main.async { [weak self] in
            self?.toasts.removeAll { $0.id == toast.id }
        }
    }
    
    /// Dismisses all toasts
    func dismissAll() {
        DispatchQueue.main.async { [weak self] in
            self?.toasts.removeAll()
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Shows a success toast
    func showSuccess(title: String? = nil, message: String, duration: TimeInterval = 3.0) {
        let toast = ToastNotification(type: .success, title: title, message: message, duration: duration)
        show(toast)
    }
    
    /// Shows an error toast
    func showError(title: String? = nil, message: String, duration: TimeInterval = 4.0) {
        let toast = ToastNotification(type: .error, title: title, message: message, duration: duration)
        show(toast)
    }
    
    /// Shows a warning toast
    func showWarning(title: String? = nil, message: String, duration: TimeInterval = 3.5) {
        let toast = ToastNotification(type: .warning, title: title, message: message, duration: duration)
        show(toast)
    }
    
    /// Shows an info toast
    func showInfo(title: String? = nil, message: String, duration: TimeInterval = 3.0) {
        let toast = ToastNotification(type: .info, title: title, message: message, duration: duration)
        show(toast)
    }
    
    // MARK: - Context-Specific Methods
    
    /// Shows a post creation success toast
    func showPostCreated() {
        showSuccess(message: "Post created successfully!")
    }
    
    /// Shows a post deletion success toast
    func showPostDeleted() {
        showSuccess(message: "Post deleted")
    }
    
    /// Shows a like action toast
    func showLikeToggled(isLiked: Bool) {
        let message = isLiked ? "Post liked!" : "Post unliked"
        showInfo(message: message, duration: 2.0)
    }
    
    /// Shows a follow action toast
    func showFollowToggled(isFollowing: Bool, userName: String) {
        let message = isFollowing ? "Now following \(userName)" : "Unfollowed \(userName)"
        showSuccess(message: message)
    }
    
    /// Shows a challenge join toast
    func showChallengeJoined(challengeName: String) {
        showSuccess(message: "Joined \(challengeName)!")
    }
    
    /// Shows a challenge completion toast
    func showChallengeCompleted(challengeName: String) {
        showSuccess(title: "Challenge Completed! 🎉", message: "You completed \(challengeName)")
    }
    
    /// Shows a league join toast
    func showLeagueJoined(leagueName: String) {
        showSuccess(message: "Joined \(leagueName) league!")
    }
    
    /// Shows a network error toast
    func showNetworkError() {
        showError(message: "Network connection failed. Please try again.")
    }
    
    /// Shows an authentication error toast
    func showAuthError() {
        showError(message: "Authentication failed. Please sign in again.")
    }
    
    /// Shows a validation error toast
    func showValidationError(_ message: String) {
        showWarning(message: message)
    }
    
    /// Shows an offline mode toast
    func showOfflineMode() {
        showWarning(title: "Offline Mode", message: "Some features may be limited", duration: 5.0)
    }
    
    /// Shows a sync success toast
    func showSyncCompleted() {
        showSuccess(message: "Data synchronized successfully")
    }
}

// MARK: - Toast Container View

struct ToastContainerView<Content: View>: View {
    let content: Content
    @StateObject private var toastManager = ToastManager.shared
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
            
            // Toast notifications overlay
            VStack(spacing: 8) {
                ForEach(toastManager.toasts) { toast in
                    ToastNotificationView(toast: toast) {
                        toastManager.dismiss(toast)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

// MARK: - View Modifiers

extension View {
    /// Adds toast notification support to any view
    func withToastNotifications() -> some View {
        ToastContainerView {
            self
        }
    }
    
    /// Shows a toast notification
    func showToast(_ toast: ToastNotification) -> some View {
        self.onAppear {
            ToastManager.shared.show(toast)
        }
    }
    
    /// Shows a success toast
    func showSuccessToast(_ message: String) -> some View {
        self.onAppear {
            ToastManager.shared.showSuccess(message: message)
        }
    }
    
    /// Shows an error toast
    func showErrorToast(_ message: String) -> some View {
        self.onAppear {
            ToastManager.shared.showError(message: message)
        }
    }
}

// MARK: - Preview Provider

#Preview("Toast Notifications") {
    struct ToastDemo: View {
        @StateObject private var toastManager = ToastManager.shared
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Toast Notification Demo")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 12) {
                    Button("Success Toast") {
                        toastManager.showSuccess(message: "Operation completed successfully!")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Error Toast") {
                        toastManager.showError(title: "Error", message: "Something went wrong. Please try again.")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button("Warning Toast") {
                        toastManager.showWarning(message: "Please check your internet connection.")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    
                    Button("Info Toast") {
                        toastManager.showInfo(title: "Tip", message: "You can swipe to dismiss notifications.")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    Button("Multiple Toasts") {
                        toastManager.showSuccess(message: "First notification")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            toastManager.showInfo(message: "Second notification")
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            toastManager.showWarning(message: "Third notification")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Clear All") {
                        toastManager.dismissAll()
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                }
                
                Spacer()
            }
            .padding()
            .withToastNotifications()
        }
    }
    
    return ToastDemo()
}

#Preview("Dark Mode Toasts") {
    struct DarkModeToastDemo: View {
        var body: some View {
            VStack(spacing: 20) {
                Text("Dark Mode Toast Demo")
                    .font(.title)
                    .foregroundColor(.white)
                
                Button("Show Success") {
                    ToastManager.shared.showSuccess(message: "Dark mode success!")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .withToastNotifications()
        }
    }
    
    return DarkModeToastDemo()
        .preferredColorScheme(.dark)
}