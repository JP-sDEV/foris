import SwiftUI
import UIKit

/// Manager for handling app appearance and dark mode support
/// Provides utilities for consistent theming across the app
final class AppearanceManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppearanceManager()
    
    // MARK: - Published Properties
    
    @Published var currentColorScheme: ColorScheme = .light
    @Published var userPreferredScheme: UserColorScheme = .system
    
    // MARK: - Initialization
    
    private init() {
        updateCurrentColorScheme()
        observeSystemChanges()
    }
    
    // MARK: - Color Scheme Management
    
    /// Sets the user's preferred color scheme
    /// - Parameter scheme: The preferred color scheme
    func setPreferredColorScheme(_ scheme: UserColorScheme) {
        userPreferredScheme = scheme
        UserDefaults.standard.set(scheme.rawValue, forKey: "UserPreferredColorScheme")
        applyColorScheme()
    }
    
    /// Applies the current color scheme to the app
    private func applyColorScheme() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let interfaceStyle: UIUserInterfaceStyle
            
            switch self.userPreferredScheme {
            case .light:
                interfaceStyle = .light
                self.currentColorScheme = .light
            case .dark:
                interfaceStyle = .dark
                self.currentColorScheme = .dark
            case .system:
                interfaceStyle = .unspecified
                self.updateCurrentColorScheme()
            }
            
            // Apply to all windows with smooth transition
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { window in
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                        window.overrideUserInterfaceStyle = interfaceStyle
                    }
                }
            
            // Provide haptic feedback for theme changes
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    /// Updates the current color scheme based on system settings
    private func updateCurrentColorScheme() {
        if userPreferredScheme == .system {
            currentColorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        }
    }
    
    /// Observes system color scheme changes
    private func observeSystemChanges() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateCurrentColorScheme()
        }
    }
    
    // MARK: - Theme Colors
    
    /// Primary background color that adapts to color scheme
    var primaryBackgroundColor: Color {
        Color(UIColor.systemBackground)
    }
    
    /// Secondary background color that adapts to color scheme
    var secondaryBackgroundColor: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    /// Tertiary background color that adapts to color scheme
    var tertiaryBackgroundColor: Color {
        Color(UIColor.tertiarySystemBackground)
    }
    
    /// Primary text color that adapts to color scheme
    var primaryTextColor: Color {
        Color(UIColor.label)
    }
    
    /// Secondary text color that adapts to color scheme
    var secondaryTextColor: Color {
        Color(UIColor.secondaryLabel)
    }
    
    /// Accent color that maintains consistency across themes
    var accentColor: Color {
        Color.accentColor
    }
    
    /// Success color that adapts to color scheme
    var successColor: Color {
        currentColorScheme == .dark ? Color.green.opacity(0.8) : Color.green
    }
    
    /// Error color that adapts to color scheme
    var errorColor: Color {
        currentColorScheme == .dark ? Color.red.opacity(0.8) : Color.red
    }
    
    /// Warning color that adapts to color scheme
    var warningColor: Color {
        currentColorScheme == .dark ? Color.orange.opacity(0.8) : Color.orange
    }
}

// MARK: - User Color Scheme Enum

extension AppearanceManager {
    enum UserColorScheme: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            case .system:
                return "System"
            }
        }
        
        var icon: String {
            switch self {
            case .light:
                return "sun.max"
            case .dark:
                return "moon"
            case .system:
                return "circle.lefthalf.filled"
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies consistent theming using AppearanceManager
    func themedBackground() -> some View {
        self.background(AppearanceManager.shared.primaryBackgroundColor)
    }
    
    /// Applies secondary background theming
    func themedSecondaryBackground() -> some View {
        self.background(AppearanceManager.shared.secondaryBackgroundColor)
    }
    
    /// Applies primary text color theming
    func themedPrimaryText() -> some View {
        self.foregroundColor(AppearanceManager.shared.primaryTextColor)
    }
    
    /// Applies secondary text color theming
    func themedSecondaryText() -> some View {
        self.foregroundColor(AppearanceManager.shared.secondaryTextColor)
    }
}

// MARK: - Theme Preview Helper

struct ThemePreviewHelper: View {
    @StateObject private var appearanceManager = AppearanceManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Theme Preview")
                .font(.title)
                .themedPrimaryText()
            
            VStack(spacing: 12) {
                ForEach(AppearanceManager.UserColorScheme.allCases, id: \.self) { scheme in
                    Button(action: {
                        appearanceManager.setPreferredColorScheme(scheme)
                    }) {
                        HStack {
                            Image(systemName: scheme.icon)
                            Text(scheme.displayName)
                            Spacer()
                            if appearanceManager.userPreferredScheme == scheme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .themedSecondaryBackground()
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Color samples
            VStack(spacing: 8) {
                Text("Color Samples")
                    .font(.headline)
                    .themedPrimaryText()
                
                HStack(spacing: 12) {
                    ColorSample(color: appearanceManager.successColor, name: "Success")
                    ColorSample(color: appearanceManager.errorColor, name: "Error")
                    ColorSample(color: appearanceManager.warningColor, name: "Warning")
                    ColorSample(color: appearanceManager.accentColor, name: "Accent")
                }
            }
        }
        .padding()
        .themedBackground()
    }
}

private struct ColorSample: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
            
            Text(name)
                .font(.caption)
                .themedSecondaryText()
        }
    }
}

// MARK: - Preview Provider

#Preview("Theme Manager") {
    ThemePreviewHelper()
}

#Preview("Light Mode") {
    ThemePreviewHelper()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ThemePreviewHelper()
        .preferredColorScheme(.dark)
}