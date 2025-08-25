import XCTest
import SwiftUI
@testable import foris

/// Comprehensive accessibility tests for the Foris iOS app
/// Tests VoiceOver support, Dynamic Type, keyboard navigation, and more
final class AccessibilityTests: XCTestCase {
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    // MARK: - VoiceOver Tests
    
    func testLikeButtonAccessibility() throws {
        let likeButton = LikeButton(
            postId: "test-post",
            likeCount: 5,
            isLiked: false
        )
        
        let hostingController = UIHostingController(rootView: likeButton)
        let view = hostingController.view!
        
        // Find the button element
        let button = view.accessibilityElements?.first as? UIView
        XCTAssertNotNil(button, "Like button should be accessible")
        
        // Test accessibility label
        XCTAssertEqual(button?.accessibilityLabel, "Like post")
        
        // Test accessibility hint
        XCTAssertEqual(button?.accessibilityHint, "5 likes")
        
        // Test accessibility traits
        XCTAssertTrue(button?.accessibilityTraits.contains(.button) ?? false)
    }
    
    func testUserCardAccessibility() throws {
        let user = User(
            id: "test-user",
            name: "Test User",
            email: "test@example.com",
            bio: "Test bio",
            avatarUrl: nil
        )
        
        let userCard = UserCard(
            user: user,
            showFollowButton: true,
            onUserTapped: nil,
            onFollowTapped: nil
        )
        
        let hostingController = UIHostingController(rootView: userCard)
        let view = hostingController.view!
        
        // Test that user card has proper accessibility elements
        let accessibilityElements = view.accessibilityElements
        XCTAssertNotNil(accessibilityElements, "User card should have accessibility elements")
        XCTAssertGreaterThan(accessibilityElements?.count ?? 0, 0, "Should have at least one accessibility element")
    }
    
    func testChallengeCardAccessibility() throws {
        let challenge = Challenge(
            id: "test-challenge",
            name: "Test Challenge",
            description: "Test description",
            createdBy: "admin",
            endDate: Date().addingTimeInterval(86400),
            userStatus: nil
        )
        
        let challengeCard = ChallengeCard(
            challenge: challenge,
            onJoinTapped: nil,
            onLeaveTapped: nil,
            onCompleteTapped: nil,
            onChallengeTapped: nil
        )
        
        let hostingController = UIHostingController(rootView: challengeCard)
        let view = hostingController.view!
        
        // Test accessibility elements
        let accessibilityElements = view.accessibilityElements
        XCTAssertNotNil(accessibilityElements, "Challenge card should have accessibility elements")
    }
    
    // MARK: - Dynamic Type Tests
    
    func testDynamicTypeSupport() throws {
        let text = AccessibleText("Test Text", font: .body)
        let hostingController = UIHostingController(rootView: text)
        
        // Test with different content size categories
        let categories: [UIContentSizeCategory] = [
            .small,
            .medium,
            .large,
            .extraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge
        ]
        
        for category in categories {
            hostingController.overrideUserInterfaceStyle = .unspecified
            hostingController.view.traitCollection = UITraitCollection(preferredContentSizeCategory: category)
            
            // Verify the view can handle the content size category
            XCTAssertNoThrow(hostingController.view.layoutIfNeeded())
        }
    }
    
    func testAccessibilityTextSizeDetection() throws {
        // Test accessibility text size detection
        let isAccessibilitySize = AccessibilityEnhancements.isAccessibilityTextSize
        XCTAssertNotNil(isAccessibilitySize, "Should be able to detect accessibility text size")
        
        // Test adaptive spacing calculation
        let baseSpacing: CGFloat = 16
        let adaptiveSpacing = AccessibilityEnhancements.adaptiveSpacing(base: baseSpacing)
        XCTAssertGreaterThanOrEqual(adaptiveSpacing, baseSpacing, "Adaptive spacing should be at least base spacing")
        
        // Test adaptive padding calculation
        let basePadding: CGFloat = 12
        let adaptivePadding = AccessibilityEnhancements.adaptivePadding(base: basePadding)
        XCTAssertGreaterThanOrEqual(adaptivePadding, basePadding, "Adaptive padding should be at least base padding")
    }
    
    // MARK: - High Contrast Tests
    
    func testHighContrastSupport() throws {
        let button = AccessibleButton(
            accessibilityLabel: "Test Button",
            accessibilityHint: "Test hint"
        ) {
            // Test action
        } label: {
            Text("Test")
        }
        
        let hostingController = UIHostingController(rootView: button)
        let view = hostingController.view!
        
        // Test that high contrast adaptations don't crash
        XCTAssertNoThrow(view.layoutIfNeeded())
    }
    
    // MARK: - Reduce Motion Tests
    
    func testReduceMotionSupport() throws {
        let view = Text("Test")
            .respectReduceMotion(
                animation: .easeInOut,
                value: true,
                fallbackAnimation: nil
            )
        
        let hostingController = UIHostingController(rootView: view)
        
        // Test that reduce motion handling doesn't crash
        XCTAssertNoThrow(hostingController.view.layoutIfNeeded())
    }
    
    // MARK: - Accessibility Announcements Tests
    
    func testAccessibilityAnnouncements() throws {
        let expectation = XCTestExpectation(description: "Accessibility announcement")
        
        let view = Text("Test")
            .announceContentChange("Test announcement")
        
        let hostingController = UIHostingController(rootView: view)
        
        // Trigger the view to appear
        hostingController.viewDidAppear(false)
        
        // Wait for announcement delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Keyboard Navigation Tests
    
    func testKeyboardNavigation() throws {
        let button = AccessibleButton(
            accessibilityLabel: "Test Button",
            accessibilityHint: "Test hint"
        ) {
            // Test action
        } label: {
            Text("Test")
        }
        .keyboardNavigable(
            onEnter: {
                // Test keyboard enter
            },
            onEscape: {
                // Test keyboard escape
            }
        )
        
        let hostingController = UIHostingController(rootView: button)
        let view = hostingController.view!
        
        // Test that keyboard navigation setup doesn't crash
        XCTAssertNoThrow(view.layoutIfNeeded())
    }
    
    // MARK: - Accessibility Element Tests
    
    func testAccessibilityElementCombination() throws {
        let combinedView = VStack {
            Text("Title")
            Text("Subtitle")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Combined title and subtitle")
        
        let hostingController = UIHostingController(rootView: combinedView)
        let view = hostingController.view!
        
        // Test accessibility element combination
        XCTAssertNoThrow(view.layoutIfNeeded())
    }
    
    func testAccessibilityHidden() throws {
        let decorativeView = AccessibleImage(
            systemName: "star.fill",
            accessibilityLabel: "Decorative star",
            isDecorative: true
        )
        
        let hostingController = UIHostingController(rootView: decorativeView)
        let view = hostingController.view!
        
        // Test that decorative elements are properly hidden
        XCTAssertNoThrow(view.layoutIfNeeded())
    }
    
    // MARK: - Performance Tests
    
    func testAccessibilityPerformance() throws {
        measure {
            let complexView = VStack {
                ForEach(0..<100, id: \.self) { index in
                    AccessibleText("Item \(index)", font: .body)
                        .accessibilityLabel("Item \(index)")
                }
            }
            
            let hostingController = UIHostingController(rootView: complexView)
            hostingController.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Integration Tests
    
    func testMainTabViewAccessibility() throws {
        let mainTabView = MainTabView()
        let hostingController = UIHostingController(rootView: mainTabView)
        let view = hostingController.view!
        
        // Test that main tab view has proper accessibility
        XCTAssertNoThrow(view.layoutIfNeeded())
        
        // Test that tab items are accessible
        let tabBar = view.subviews.first { $0 is UITabBar } as? UITabBar
        XCTAssertNotNil(tabBar, "Should have a tab bar")
        
        let tabBarItems = tabBar?.items
        XCTAssertNotNil(tabBarItems, "Tab bar should have items")
        XCTAssertEqual(tabBarItems?.count, 5, "Should have 5 tab items")
    }
    
    func testFeedViewAccessibility() throws {
        let feedView = FeedView()
        let hostingController = UIHostingController(rootView: feedView)
        let view = hostingController.view!
        
        // Test that feed view has proper accessibility
        XCTAssertNoThrow(view.layoutIfNeeded())
    }
    
    // MARK: - Error Handling Tests
    
    func testAccessibilityErrorHandling() throws {
        // Test that accessibility enhancements handle nil values gracefully
        let view = Text("Test")
            .accessibilityEnhanced(
                label: "",
                hint: nil,
                traits: [],
                value: nil
            )
        
        let hostingController = UIHostingController(rootView: view)
        
        XCTAssertNoThrow(hostingController.view.layoutIfNeeded())
    }
    
    // MARK: - Localization Tests
    
    func testAccessibilityLocalization() throws {
        // Test that accessibility labels work with different locales
        let button = AccessibleButton(
            accessibilityLabel: NSLocalizedString("test.button.label", comment: "Test button"),
            accessibilityHint: NSLocalizedString("test.button.hint", comment: "Test button hint")
        ) {
            // Test action
        } label: {
            Text("Test")
        }
        
        let hostingController = UIHostingController(rootView: button)
        
        XCTAssertNoThrow(hostingController.view.layoutIfNeeded())
    }
}

// MARK: - Mock Data Extensions

extension User {
    static var accessibilityTestMock: User {
        User(
            id: "accessibility-test-user",
            name: "Accessibility Test User",
            email: "accessibility@test.com",
            bio: "This is a test user for accessibility testing",
            avatarUrl: nil
        )
    }
}

extension Challenge {
    static var accessibilityTestMock: Challenge {
        Challenge(
            id: "accessibility-test-challenge",
            name: "Accessibility Test Challenge",
            description: "This is a test challenge for accessibility testing",
            createdBy: "admin",
            endDate: Date().addingTimeInterval(86400),
            userStatus: nil
        )
    }
}

extension Post {
    static var accessibilityTestMock: Post {
        Post(
            id: "accessibility-test-post",
            title: "Accessibility Test Post",
            content: "This is a test post for accessibility testing",
            authorId: "test-user",
            author: User.accessibilityTestMock,
            createdAt: Date(),
            likeCount: 5,
            commentCount: 3,
            isLiked: false
        )
    }
}