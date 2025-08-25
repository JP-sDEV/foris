import SwiftUI
import UIKit

/// Accessibility enhancements and utilities for the Foris app
/// Provides comprehensive accessibility support including VoiceOver, Dynamic Type, and more
struct AccessibilityEnhancements {
    
    // MARK: - Dynamic Type Support
    
    /// Checks if the user has enabled larger accessibility text sizes
    static var isAccessibilityTextSize: Bool {
        UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
    }
    
    /// Gets the current content size category
    static var contentSizeCategory: ContentSizeCategory {
        ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
    }
    
    /// Calculates appropriate spacing based on content size category
    static func adaptiveSpacing(base: CGFloat) -> CGFloat {
        let multiplier = isAccessibilityTextSize ? 1.5 : 1.0
        return base * multiplier
    }
    
    /// Calculates appropriate padding based on content size category
    static func adaptivePadding(base: CGFloat) -> CGFloat {
        let multiplier = isAccessibilityTextSize ? 1.3 : 1.0
        return base * multiplier
    }
}

// MARK: - Accessibility View Modifiers

extension View {
    
    // MARK: - VoiceOver Support
    
    /// Adds comprehensive VoiceOver support with custom label and hint
    func accessibilityEnhanced(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityValue(value ?? "")
    }
    
    /// Marks view as a button with proper accessibility support
    func accessibilityButton(
        label: String,
        hint: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double tap to activate")
            .accessibilityAddTraits(.isButton)
            .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
            .accessibilityAddTraits(isEnabled ? [] : .isStaticText)
    }
    
    /// Marks view as a header with proper accessibility support
    func accessibilityHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// Adds accessibility support for interactive elements
    func accessibilityInteractive(
        label: String,
        hint: String,
        action: String = "activate"
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint("Double tap to \(action). \(hint)")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Adds accessibility support for toggle elements
    func accessibilityToggle(
        label: String,
        isOn: Bool,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityHint(hint ?? "Double tap to toggle")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Adds accessibility support for adjustable elements (like sliders)
    func accessibilityAdjustable(
        label: String,
        value: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "Swipe up or down to adjust")
            .accessibilityAddTraits(.adjustsNumerically)
    }
    
    // MARK: - Dynamic Type Support
    
    /// Adds Dynamic Type support with minimum and maximum scale factors
    func dynamicTypeSupport(
        minScaleFactor: CGFloat = 0.8,
        maxScaleFactor: CGFloat = 2.0
    ) -> some View {
        self
            .minimumScaleFactor(minScaleFactor)
            .lineLimit(AccessibilityEnhancements.isAccessibilityTextSize ? nil : 1)
    }
    
    /// Adapts layout for accessibility text sizes
    func accessibilityAdaptiveLayout() -> some View {
        self
            .padding(AccessibilityEnhancements.adaptivePadding(base: 16))
    }
    
    /// Adapts spacing for accessibility
    func accessibilityAdaptiveSpacing() -> some View {
        if AccessibilityEnhancements.isAccessibilityTextSize {
            return AnyView(
                VStack(spacing: AccessibilityEnhancements.adaptiveSpacing(base: 8)) {
                    self
                }
            )
        } else {
            return AnyView(self)
        }
    }
    
    // MARK: - Focus Management
    
    /// Announces content changes to VoiceOver users
    func announceContentChange(_ message: String, delay: TimeInterval = 0.5) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }
    
    /// Announces screen changes to VoiceOver users
    func announceScreenChange(_ message: String? = nil, delay: TimeInterval = 0.1) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                UIAccessibility.post(
                    notification: .screenChanged,
                    argument: message
                )
            }
        }
    }
    
    /// Announces layout changes to VoiceOver users
    func announceLayoutChange(_ message: String? = nil, delay: TimeInterval = 0.1) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                UIAccessibility.post(
                    notification: .layoutChanged,
                    argument: message
                )
            }
        }
    }
    
    // MARK: - Keyboard Navigation
    
    /// Adds keyboard navigation support
    func keyboardNavigable(
        onUpArrow: (() -> Void)? = nil,
        onDownArrow: (() -> Void)? = nil,
        onLeftArrow: (() -> Void)? = nil,
        onRightArrow: (() -> Void)? = nil,
        onEnter: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        self
            .focusable()
            .onKeyPress(.upArrow) {
                onUpArrow?()
                return .handled
            }
            .onKeyPress(.downArrow) {
                onDownArrow?()
                return .handled
            }
            .onKeyPress(.leftArrow) {
                onLeftArrow?()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                onRightArrow?()
                return .handled
            }
            .onKeyPress(.return) {
                onEnter?()
                return .handled
            }
            .onKeyPress(.escape) {
                onEscape?()
                return .handled
            }
    }
    
    // MARK: - Reduce Motion Support
    
    /// Respects user's reduce motion preference
    func respectReduceMotion<T: Equatable>(
        animation: Animation?,
        value: T,
        fallbackAnimation: Animation? = nil
    ) -> some View {
        let shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
        let finalAnimation = shouldReduceMotion ? fallbackAnimation : animation
        
        return self.animation(finalAnimation, value: value)
    }
    
    /// Provides alternative to animations when reduce motion is enabled
    func reduceMotionAlternative<Content: View>(
        @ViewBuilder alternative: @escaping () -> Content
    ) -> some View {
        Group {
            if UIAccessibility.isReduceMotionEnabled {
                alternative()
            } else {
                self
            }
        }
    }
    
    // MARK: - High Contrast Support
    
    /// Adapts colors for high contrast mode
    func highContrastAdaptive(
        normalColor: Color,
        highContrastColor: Color
    ) -> some View {
        let isHighContrast = UIAccessibility.isDarkerSystemColorsEnabled || 
                           UIAccessibility.isInvertColorsEnabled
        
        return self.foregroundColor(isHighContrast ? highContrastColor : normalColor)
    }
    
    /// Adds high contrast border when needed
    func highContrastBorder(
        color: Color = .primary,
        width: CGFloat = 1
    ) -> some View {
        let needsBorder = UIAccessibility.isDarkerSystemColorsEnabled ||
                         UIAccessibility.isInvertColorsEnabled
        
        return self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: needsBorder ? width : 0)
        )
    }
}

// MARK: - Accessibility-Aware Components

/// Button that adapts to accessibility settings
struct AccessibleButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    let accessibilityLabel: String
    let accessibilityHint: String?
    
    init(
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button(action: action, label: label)
            .accessibilityButton(
                label: accessibilityLabel,
                hint: accessibilityHint
            )
            .dynamicTypeSupport()
            .accessibilityAdaptiveLayout()
            .highContrastBorder()
    }
}

/// Text that adapts to accessibility settings
struct AccessibleText: View {
    let text: String
    let font: Font
    let color: Color
    let isHeader: Bool
    
    init(
        _ text: String,
        font: Font = .body,
        color: Color = .primary,
        isHeader: Bool = false
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.isHeader = isHeader
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .dynamicTypeSupport()
            .accessibilityAdaptiveSpacing()
            .modifier(HeaderModifier(isHeader: isHeader))
            .highContrastAdaptive(
                normalColor: color,
                highContrastColor: color == .secondary ? .primary : color
            )
    }
}

private struct HeaderModifier: ViewModifier {
    let isHeader: Bool
    
    func body(content: Content) -> some View {
        if isHeader {
            content.accessibilityAddTraits(.isHeader)
        } else {
            content
        }
    }
}

/// Image that provides proper accessibility support
struct AccessibleImage: View {
    let systemName: String?
    let imageName: String?
    let accessibilityLabel: String
    let isDecorative: Bool
    
    init(
        systemName: String,
        accessibilityLabel: String,
        isDecorative: Bool = false
    ) {
        self.systemName = systemName
        self.imageName = nil
        self.accessibilityLabel = accessibilityLabel
        self.isDecorative = isDecorative
    }
    
    init(
        imageName: String,
        accessibilityLabel: String,
        isDecorative: Bool = false
    ) {
        self.systemName = nil
        self.imageName = imageName
        self.accessibilityLabel = accessibilityLabel
        self.isDecorative = isDecorative
    }
    
    var body: some View {
        Group {
            if let systemName = systemName {
                Image(systemName: systemName)
            } else if let imageName = imageName {
                Image(imageName)
            }
        }
        .accessibilityLabel(isDecorative ? "" : accessibilityLabel)
        .accessibilityHidden(isDecorative)
        .highContrastAdaptive(
            normalColor: .primary,
            highContrastColor: .primary
        )
    }
}

// MARK: - Accessibility Testing Helpers

#if DEBUG
struct AccessibilityTestingView: View {
    @State private var isToggleOn = false
    @State private var sliderValue: Double = 50
    
    var body: some View {
        ScrollView {
            VStack(spacing: AccessibilityEnhancements.adaptiveSpacing(base: 20)) {
                AccessibleText(
                    "Accessibility Testing",
                    font: .title,
                    isHeader: true
                )
                
                AccessibleButton(
                    accessibilityLabel: "Test Button",
                    accessibilityHint: "This is a test button for accessibility"
                ) {
                    print("Button tapped")
                } label: {
                    Text("Tap Me")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Toggle("Test Toggle", isOn: $isToggleOn)
                    .accessibilityToggle(
                        label: "Test Toggle",
                        isOn: isToggleOn,
                        hint: "This toggles a test setting"
                    )
                
                Slider(value: $sliderValue, in: 0...100)
                    .accessibilityAdjustable(
                        label: "Test Slider",
                        value: "\(Int(sliderValue)) percent"
                    )
                
                AccessibleImage(
                    systemName: "heart.fill",
                    accessibilityLabel: "Favorite heart icon"
                )
                .font(.largeTitle)
                .foregroundColor(.red)
                
                AccessibleImage(
                    systemName: "star.fill",
                    accessibilityLabel: "Decorative star",
                    isDecorative: true
                )
                .font(.title)
                .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 8) {
                    AccessibleText("Dynamic Type Test", font: .headline, isHeader: true)
                    AccessibleText("This text should scale with Dynamic Type settings.", font: .body)
                    AccessibleText("Small caption text", font: .caption, color: .secondary)
                }
                .accessibilityAdaptiveLayout()
            }
            .padding()
        }
        .announceScreenChange("Accessibility testing screen loaded")
    }
}

#Preview("Accessibility Testing") {
    AccessibilityTestingView()
}

#Preview("Accessibility Testing - Large Text") {
    AccessibilityTestingView()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

#Preview("Accessibility Testing - Dark Mode") {
    AccessibilityTestingView()
        .preferredColorScheme(.dark)
}
#endif