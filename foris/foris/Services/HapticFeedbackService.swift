import UIKit
import SwiftUI

/// Service for managing haptic feedback throughout the app
/// Provides consistent haptic feedback patterns for different user interactions
final class HapticFeedbackService {
    
    // MARK: - Singleton
    
    static let shared = HapticFeedbackService()
    
    // MARK: - Feedback Generators
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // MARK: - Settings
    
    /// Whether haptic feedback is enabled (respects system settings)
    private var isHapticEnabled: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // MARK: - Initialization
    
    private init() {
        prepareGenerators()
    }
    
    // MARK: - Preparation
    
    /// Prepares all feedback generators for optimal performance
    private func prepareGenerators() {
        guard isHapticEnabled else { return }
        
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    // MARK: - Impact Feedback
    
    /// Provides light impact feedback for subtle interactions
    func lightImpact() {
        guard isHapticEnabled else { return }
        impactLight.impactOccurred()
        impactLight.prepare()
    }
    
    /// Provides medium impact feedback for standard interactions
    func mediumImpact() {
        guard isHapticEnabled else { return }
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }
    
    /// Provides heavy impact feedback for significant interactions
    func heavyImpact() {
        guard isHapticEnabled else { return }
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }
    
    // MARK: - Selection Feedback
    
    /// Provides selection feedback for picker-style interactions
    func selection() {
        guard isHapticEnabled else { return }
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }
    
    // MARK: - Notification Feedback
    
    /// Provides success notification feedback
    func success() {
        guard isHapticEnabled else { return }
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
    }
    
    /// Provides warning notification feedback
    func warning() {
        guard isHapticEnabled else { return }
        notificationFeedback.notificationOccurred(.warning)
        notificationFeedback.prepare()
    }
    
    /// Provides error notification feedback
    func error() {
        guard isHapticEnabled else { return }
        notificationFeedback.notificationOccurred(.error)
        notificationFeedback.prepare()
    }
    
    // MARK: - Contextual Feedback Methods
    
    /// Feedback for button taps
    func buttonTap() {
        lightImpact()
    }
    
    /// Feedback for important button taps (like submit, delete)
    func importantButtonTap() {
        mediumImpact()
    }
    
    /// Feedback for destructive actions
    func destructiveAction() {
        heavyImpact()
    }
    
    /// Feedback for toggle switches
    func toggle() {
        selection()
    }
    
    /// Feedback for tab selection
    func tabSelection() {
        selection()
    }
    
    /// Feedback for pull-to-refresh
    func pullToRefresh() {
        lightImpact()
    }
    
    /// Feedback for swipe actions
    func swipeAction() {
        mediumImpact()
    }
    
    /// Feedback for like/unlike actions
    func likeAction() {
        lightImpact()
    }
    
    /// Feedback for follow/unfollow actions
    func followAction() {
        mediumImpact()
    }
    
    /// Feedback for joining challenges/leagues
    func joinAction() {
        mediumImpact()
    }
    
    /// Feedback for completing challenges
    func challengeComplete() {
        success()
    }
    
    /// Feedback for posting content
    func postCreated() {
        success()
    }
    
    /// Feedback for successful operations
    func operationSuccess() {
        success()
    }
    
    /// Feedback for failed operations
    func operationFailed() {
        error()
    }
    
    /// Feedback for validation errors
    func validationError() {
        warning()
    }
    
    /// Feedback for network errors
    func networkError() {
        error()
    }
    
    /// Feedback for authentication success
    func authenticationSuccess() {
        success()
    }
    
    /// Feedback for authentication failure
    func authenticationFailed() {
        error()
    }
    
    /// Feedback for long press gestures
    func longPress() {
        mediumImpact()
    }
    
    /// Feedback for drag and drop operations
    func dragStart() {
        lightImpact()
    }
    
    /// Feedback for successful drop
    func dropSuccess() {
        mediumImpact()
    }
    
    /// Feedback for modal presentation
    func modalPresented() {
        lightImpact()
    }
    
    /// Feedback for modal dismissal
    func modalDismissed() {
        lightImpact()
    }
    
    /// Feedback for search results found
    func searchResults() {
        lightImpact()
    }
    
    /// Feedback for empty search results
    func noSearchResults() {
        warning()
    }
}

// MARK: - SwiftUI View Modifiers

extension View {
    /// Adds haptic feedback to button taps
    func hapticFeedback(_ feedbackType: HapticFeedbackType = .light) -> some View {
        self.onTapGesture {
            switch feedbackType {
            case .light:
                HapticFeedbackService.shared.lightImpact()
            case .medium:
                HapticFeedbackService.shared.mediumImpact()
            case .heavy:
                HapticFeedbackService.shared.heavyImpact()
            case .selection:
                HapticFeedbackService.shared.selection()
            case .success:
                HapticFeedbackService.shared.success()
            case .warning:
                HapticFeedbackService.shared.warning()
            case .error:
                HapticFeedbackService.shared.error()
            }
        }
    }
    
    /// Adds contextual haptic feedback for specific actions
    func contextualHaptic(_ context: HapticContext) -> some View {
        self.onTapGesture {
            switch context {
            case .buttonTap:
                HapticFeedbackService.shared.buttonTap()
            case .importantButton:
                HapticFeedbackService.shared.importantButtonTap()
            case .destructiveAction:
                HapticFeedbackService.shared.destructiveAction()
            case .toggle:
                HapticFeedbackService.shared.toggle()
            case .tabSelection:
                HapticFeedbackService.shared.tabSelection()
            case .likeAction:
                HapticFeedbackService.shared.likeAction()
            case .followAction:
                HapticFeedbackService.shared.followAction()
            case .joinAction:
                HapticFeedbackService.shared.joinAction()
            }
        }
    }
    
    /// Adds haptic feedback for long press gestures
    func longPressHaptic(minimumDuration: Double = 0.5, action: @escaping () -> Void) -> some View {
        self.onLongPressGesture(minimumDuration: minimumDuration) {
            HapticFeedbackService.shared.longPress()
            action()
        }
    }
    
    /// Adds haptic feedback for drag gestures
    func dragHaptic<V>(
        _ value: DragGesture.Value,
        onStart: @escaping () -> Void = {},
        onEnd: @escaping () -> Void = {}
    ) -> some View where V: Equatable {
        self.gesture(
            DragGesture()
                .onChanged { _ in
                    HapticFeedbackService.shared.dragStart()
                    onStart()
                }
                .onEnded { _ in
                    HapticFeedbackService.shared.dropSuccess()
                    onEnd()
                }
        )
    }
}

// MARK: - Haptic Feedback Types

enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error
}

// MARK: - Haptic Context Types

enum HapticContext {
    case buttonTap
    case importantButton
    case destructiveAction
    case toggle
    case tabSelection
    case likeAction
    case followAction
    case joinAction
}

// MARK: - Button Style with Haptic Feedback

struct HapticButtonStyle: ButtonStyle {
    let feedbackType: HapticFeedbackType
    
    init(_ feedbackType: HapticFeedbackType = .light) {
        self.feedbackType = feedbackType
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    switch feedbackType {
                    case .light:
                        HapticFeedbackService.shared.lightImpact()
                    case .medium:
                        HapticFeedbackService.shared.mediumImpact()
                    case .heavy:
                        HapticFeedbackService.shared.heavyImpact()
                    case .selection:
                        HapticFeedbackService.shared.selection()
                    case .success:
                        HapticFeedbackService.shared.success()
                    case .warning:
                        HapticFeedbackService.shared.warning()
                    case .error:
                        HapticFeedbackService.shared.error()
                    }
                }
            }
    }
}

// MARK: - Convenience Extensions

extension ButtonStyle where Self == HapticButtonStyle {
    /// Button style with light haptic feedback
    static var hapticLight: HapticButtonStyle {
        HapticButtonStyle(.light)
    }
    
    /// Button style with medium haptic feedback
    static var hapticMedium: HapticButtonStyle {
        HapticButtonStyle(.medium)
    }
    
    /// Button style with heavy haptic feedback
    static var hapticHeavy: HapticButtonStyle {
        HapticButtonStyle(.heavy)
    }
}

// MARK: - Haptic Feedback Manager for ViewModels

extension HapticFeedbackService {
    /// Provides feedback for ViewModel operations
    func viewModelOperation(_ operation: ViewModelOperation) {
        switch operation {
        case .loadingStarted:
            lightImpact()
        case .loadingCompleted:
            success()
        case .loadingFailed:
            error()
        case .dataRefreshed:
            lightImpact()
        case .itemCreated:
            success()
        case .itemUpdated:
            mediumImpact()
        case .itemDeleted:
            heavyImpact()
        case .validationError:
            warning()
        case .networkError:
            error()
        }
    }
}

// MARK: - ViewModel Operation Types

enum ViewModelOperation {
    case loadingStarted
    case loadingCompleted
    case loadingFailed
    case dataRefreshed
    case itemCreated
    case itemUpdated
    case itemDeleted
    case validationError
    case networkError
}

// MARK: - Preview Helper

#if DEBUG
struct HapticFeedbackPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Haptic Feedback Demo")
                .font(.title)
                .padding()
            
            VStack(spacing: 16) {
                Button("Light Impact") {
                    HapticFeedbackService.shared.lightImpact()
                }
                .buttonStyle(.hapticLight)
                
                Button("Medium Impact") {
                    HapticFeedbackService.shared.mediumImpact()
                }
                .buttonStyle(.hapticMedium)
                
                Button("Heavy Impact") {
                    HapticFeedbackService.shared.heavyImpact()
                }
                .buttonStyle(.hapticHeavy)
                
                Button("Selection") {
                    HapticFeedbackService.shared.selection()
                }
                
                Button("Success") {
                    HapticFeedbackService.shared.success()
                }
                .foregroundColor(.green)
                
                Button("Warning") {
                    HapticFeedbackService.shared.warning()
                }
                .foregroundColor(.orange)
                
                Button("Error") {
                    HapticFeedbackService.shared.error()
                }
                .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    HapticFeedbackPreview()
}
#endif