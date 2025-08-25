import SwiftUI
import UIKit

/// Service for accessibility testing and validation
/// Provides runtime accessibility checks and testing utilities
class AccessibilityTestingService: ObservableObject {
    
    static let shared = AccessibilityTestingService()
    
    // MARK: - Properties
    
    @Published var isAccessibilityTestingEnabled = false
    @Published var accessibilityIssues: [AccessibilityIssue] = []
    
    private init() {
        #if DEBUG
        // Enable accessibility testing in debug builds
        isAccessibilityTestingEnabled = ProcessInfo.processInfo.arguments.contains("--accessibility-testing")
        #endif
    }
    
    // MARK: - Accessibility Issue Types
    
    struct AccessibilityIssue: Identifiable, Equatable {
        let id = UUID()
        let type: IssueType
        let description: String
        let severity: Severity
        let element: String?
        let suggestion: String
        
        enum IssueType {
            case missingLabel
            case missingHint
            case improperTraits
            case lowContrast
            case tooSmallTouchTarget
            case missingHeading
            case improperFocus
        }
        
        enum Severity {
            case low
            case medium
            case high
            case critical
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validates accessibility of a SwiftUI view
    func validateView<Content: View>(_ view: Content) -> [AccessibilityIssue] {
        guard isAccessibilityTestingEnabled else { return [] }
        
        var issues: [AccessibilityIssue] = []
        let hostingController = UIHostingController(rootView: view)
        let uiView = hostingController.view!
        
        // Validate accessibility elements
        issues.append(contentsOf: validateAccessibilityElements(in: uiView))
        
        // Validate touch targets
        issues.append(contentsOf: validateTouchTargets(in: uiView))
        
        // Validate color contrast (basic check)
        issues.append(contentsOf: validateColorContrast(in: uiView))
        
        return issues
    }
    
    /// Validates accessibility elements in a UIView hierarchy
    private func validateAccessibilityElements(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // Check current view
        if view.isAccessibilityElement {
            issues.append(contentsOf: validateSingleElement(view))
        }
        
        // Recursively check subviews
        for subview in view.subviews {
            issues.append(contentsOf: validateAccessibilityElements(in: subview))
        }
        
        return issues
    }
    
    /// Validates a single accessibility element
    private func validateSingleElement(_ element: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        let elementDescription = String(describing: type(of: element))
        
        // Check for missing accessibility label
        if let label = element.accessibilityLabel, label.isEmpty {
            issues.append(AccessibilityIssue(
                type: .missingLabel,
                description: "Element has empty accessibility label",
                severity: .high,
                element: elementDescription,
                suggestion: "Provide a descriptive accessibility label"
            ))
        } else if element.accessibilityLabel == nil && element.accessibilityTraits.contains(.button) {
            issues.append(AccessibilityIssue(
                type: .missingLabel,
                description: "Button element missing accessibility label",
                severity: .critical,
                element: elementDescription,
                suggestion: "Add accessibility label to button"
            ))
        }
        
        // Check for proper button traits
        if element.accessibilityTraits.contains(.button) {
            if element.accessibilityHint?.isEmpty ?? true {
                issues.append(AccessibilityIssue(
                    type: .missingHint,
                    description: "Button missing accessibility hint",
                    severity: .medium,
                    element: elementDescription,
                    suggestion: "Add accessibility hint to explain button action"
                ))
            }
        }
        
        // Check for proper heading structure
        if let label = element.accessibilityLabel,
           (label.contains("title") || label.contains("heading")) &&
           !element.accessibilityTraits.contains(.header) {
            issues.append(AccessibilityIssue(
                type: .missingHeading,
                description: "Potential heading element missing header trait",
                severity: .medium,
                element: elementDescription,
                suggestion: "Add .header accessibility trait to heading elements"
            ))
        }
        
        return issues
    }
    
    /// Validates touch target sizes
    private func validateTouchTargets(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        let minimumTouchTargetSize: CGFloat = 44.0 // Apple's recommended minimum
        
        if view.isAccessibilityElement && view.accessibilityTraits.contains(.button) {
            let frame = view.frame
            if frame.width < minimumTouchTargetSize || frame.height < minimumTouchTargetSize {
                issues.append(AccessibilityIssue(
                    type: .tooSmallTouchTarget,
                    description: "Touch target smaller than recommended 44x44 points",
                    severity: .high,
                    element: String(describing: type(of: view)),
                    suggestion: "Increase touch target size to at least 44x44 points"
                ))
            }
        }
        
        // Check subviews
        for subview in view.subviews {
            issues.append(contentsOf: validateTouchTargets(in: subview))
        }
        
        return issues
    }
    
    /// Basic color contrast validation
    private func validateColorContrast(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // This is a simplified contrast check
        // In a real implementation, you'd want more sophisticated color analysis
        if let backgroundColor = view.backgroundColor,
           let textColor = view.tintColor {
            
            let contrast = calculateContrastRatio(backgroundColor, textColor)
            if contrast < 4.5 { // WCAG AA standard for normal text
                issues.append(AccessibilityIssue(
                    type: .lowContrast,
                    description: "Color contrast ratio below WCAG AA standard",
                    severity: .medium,
                    element: String(describing: type(of: view)),
                    suggestion: "Increase color contrast to at least 4.5:1 ratio"
                ))
            }
        }
        
        return issues
    }
    
    /// Calculate contrast ratio between two colors (simplified)
    private func calculateContrastRatio(_ color1: UIColor, _ color2: UIColor) -> CGFloat {
        // Simplified contrast calculation
        // In practice, you'd want to use proper luminance calculations
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let luminance1 = 0.299 * r1 + 0.587 * g1 + 0.114 * b1
        let luminance2 = 0.299 * r2 + 0.587 * g2 + 0.114 * b2
        
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    // MARK: - Testing Utilities
    
    /// Simulates VoiceOver navigation through a view hierarchy
    func simulateVoiceOverNavigation<Content: View>(in view: Content) -> [String] {
        let hostingController = UIHostingController(rootView: view)
        let uiView = hostingController.view!
        
        var voiceOverElements: [String] = []
        collectVoiceOverElements(from: uiView, into: &voiceOverElements)
        
        return voiceOverElements
    }
    
    /// Collects VoiceOver-accessible elements in order
    private func collectVoiceOverElements(from view: UIView, into elements: inout [String]) {
        if view.isAccessibilityElement {
            let label = view.accessibilityLabel ?? "Unlabeled element"
            let hint = view.accessibilityHint ?? ""
            let value = view.accessibilityValue ?? ""
            
            var description = label
            if !value.isEmpty {
                description += ", \(value)"
            }
            if !hint.isEmpty {
                description += ". \(hint)"
            }
            
            elements.append(description)
        }
        
        // Process subviews in order
        for subview in view.subviews {
            collectVoiceOverElements(from: subview, into: &elements)
        }
    }
    
    /// Tests Dynamic Type scaling
    func testDynamicTypeScaling<Content: View>(
        _ view: Content,
        categories: [UIContentSizeCategory] = [
            .small, .medium, .large, .extraLarge,
            .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge
        ]
    ) -> [String] {
        var results: [String] = []
        
        for category in categories {
            let hostingController = UIHostingController(rootView: view)
            hostingController.overrideUserInterfaceStyle = .unspecified
            
            // Simulate content size category change
            let traitCollection = UITraitCollection(preferredContentSizeCategory: category)
            hostingController.setOverrideTraitCollection(traitCollection, forChild: nil)
            
            // Layout the view
            hostingController.view.layoutIfNeeded()
            
            // Check if layout is still valid
            let isValid = !hostingController.view.subviews.isEmpty
            results.append("Category \(category.rawValue): \(isValid ? "Valid" : "Invalid")")
        }
        
        return results
    }
    
    /// Generates accessibility report
    func generateAccessibilityReport<Content: View>(for view: Content) -> AccessibilityReport {
        let issues = validateView(view)
        let voiceOverElements = simulateVoiceOverNavigation(in: view)
        let dynamicTypeResults = testDynamicTypeScaling(view)
        
        return AccessibilityReport(
            issues: issues,
            voiceOverElements: voiceOverElements,
            dynamicTypeResults: dynamicTypeResults,
            timestamp: Date()
        )
    }
    
    // MARK: - Reporting
    
    struct AccessibilityReport {
        let issues: [AccessibilityIssue]
        let voiceOverElements: [String]
        let dynamicTypeResults: [String]
        let timestamp: Date
        
        var criticalIssueCount: Int {
            issues.filter { $0.severity == .critical }.count
        }
        
        var highIssueCount: Int {
            issues.filter { $0.severity == .high }.count
        }
        
        var mediumIssueCount: Int {
            issues.filter { $0.severity == .medium }.count
        }
        
        var lowIssueCount: Int {
            issues.filter { $0.severity == .low }.count
        }
        
        var overallScore: Double {
            let totalIssues = issues.count
            if totalIssues == 0 { return 100.0 }
            
            let weightedScore = Double(criticalIssueCount * 4 + highIssueCount * 3 + mediumIssueCount * 2 + lowIssueCount * 1)
            let maxPossibleScore = Double(totalIssues * 4)
            
            return max(0, 100.0 - (weightedScore / maxPossibleScore * 100.0))
        }
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// Prints accessibility report to console
    func printAccessibilityReport<Content: View>(for view: Content) {
        let report = generateAccessibilityReport(for: view)
        
        print("=== Accessibility Report ===")
        print("Timestamp: \(report.timestamp)")
        print("Overall Score: \(String(format: "%.1f", report.overallScore))%")
        print("Issues: Critical: \(report.criticalIssueCount), High: \(report.highIssueCount), Medium: \(report.mediumIssueCount), Low: \(report.lowIssueCount)")
        print("")
        
        if !report.issues.isEmpty {
            print("Issues Found:")
            for issue in report.issues {
                print("- [\(issue.severity)] \(issue.description)")
                print("  Element: \(issue.element ?? "Unknown")")
                print("  Suggestion: \(issue.suggestion)")
                print("")
            }
        }
        
        print("VoiceOver Elements (\(report.voiceOverElements.count)):")
        for (index, element) in report.voiceOverElements.enumerated() {
            print("\(index + 1). \(element)")
        }
        print("")
        
        print("Dynamic Type Results:")
        for result in report.dynamicTypeResults {
            print("- \(result)")
        }
        print("=== End Report ===")
    }
    #endif
}

// MARK: - SwiftUI Integration

extension View {
    /// Validates accessibility and prints report in debug builds
    func validateAccessibility() -> some View {
        #if DEBUG
        return self.onAppear {
            if AccessibilityTestingService.shared.isAccessibilityTestingEnabled {
                AccessibilityTestingService.shared.printAccessibilityReport(for: self)
            }
        }
        #else
        return self
        #endif
    }
    
    /// Adds accessibility testing overlay in debug builds
    func accessibilityTestingOverlay() -> some View {
        #if DEBUG
        return self.overlay(
            AccessibilityTestingOverlay()
                .opacity(AccessibilityTestingService.shared.isAccessibilityTestingEnabled ? 1 : 0)
        )
        #else
        return self
        #endif
    }
}

#if DEBUG
/// Debug overlay showing accessibility information
struct AccessibilityTestingOverlay: View {
    @StateObject private var testingService = AccessibilityTestingService.shared
    @State private var showReport = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("A11y") {
                    showReport.toggle()
                }
                .font(.caption)
                .padding(4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showReport) {
            AccessibilityReportView()
        }
    }
}

/// View displaying accessibility report
struct AccessibilityReportView: View {
    @StateObject private var testingService = AccessibilityTestingService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Issues") {
                    if testingService.accessibilityIssues.isEmpty {
                        Text("No accessibility issues found")
                            .foregroundColor(.green)
                    } else {
                        ForEach(testingService.accessibilityIssues) { issue in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(issue.description)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(issue.severity)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(severityColor(issue.severity))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                
                                if let element = issue.element {
                                    Text("Element: \(element)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(issue.suggestion)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Accessibility Report")
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
    
    private func severityColor(_ severity: AccessibilityTestingService.AccessibilityIssue.Severity) -> Color {
        switch severity {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
}
#endif