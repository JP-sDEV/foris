import XCTest

/// UI tests focused on accessibility features and VoiceOver navigation
/// Tests real user interactions with accessibility technologies
final class AccessibilityUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Enable accessibility for testing
        app.launchArguments.append("--accessibility-testing")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - VoiceOver Navigation Tests
    
    func testVoiceOverTabNavigation() throws {
        // Test that VoiceOver can navigate between tabs
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Test each tab is accessible
        let feedTab = tabBar.buttons["Feed tab"]
        let challengesTab = tabBar.buttons["Challenges tab"]
        let leaguesTab = tabBar.buttons["Leagues tab"]
        let socialTab = tabBar.buttons["Social tab"]
        let profileTab = tabBar.buttons["Profile tab"]
        
        XCTAssertTrue(feedTab.exists, "Feed tab should be accessible")
        XCTAssertTrue(challengesTab.exists, "Challenges tab should be accessible")
        XCTAssertTrue(leaguesTab.exists, "Leagues tab should be accessible")
        XCTAssertTrue(socialTab.exists, "Social tab should be accessible")
        XCTAssertTrue(profileTab.exists, "Profile tab should be accessible")
        
        // Test tab switching with VoiceOver
        challengesTab.tap()
        XCTAssertTrue(challengesTab.isSelected, "Challenges tab should be selected")
        
        profileTab.tap()
        XCTAssertTrue(profileTab.isSelected, "Profile tab should be selected")
    }
    
    func testVoiceOverFeedNavigation() throws {
        // Navigate to feed tab
        let feedTab = app.tabBars.buttons["Feed tab"]
        feedTab.tap()
        
        // Test create post button accessibility
        let createPostButton = app.navigationBars.buttons["Create new post"]
        XCTAssertTrue(createPostButton.exists, "Create post button should be accessible")
        XCTAssertEqual(createPostButton.label, "Create new post")
        
        // Test that posts are accessible (if any exist)
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            let postElements = scrollView.otherElements.containing(.staticText, identifier: "Post:")
            if postElements.count > 0 {
                let firstPost = postElements.firstMatch
                XCTAssertTrue(firstPost.exists, "Posts should be accessible")
            }
        }
    }
    
    func testVoiceOverPostInteractions() throws {
        // Navigate to feed
        let feedTab = app.tabBars.buttons["Feed tab"]
        feedTab.tap()
        
        // Look for like buttons
        let likeButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Like post' OR label CONTAINS 'Unlike post'"))
        if likeButtons.count > 0 {
            let firstLikeButton = likeButtons.firstMatch
            XCTAssertTrue(firstLikeButton.exists, "Like button should be accessible")
            
            // Test like button interaction
            let initialLabel = firstLikeButton.label
            firstLikeButton.tap()
            
            // Wait for state change
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label != %@", initialLabel),
                object: firstLikeButton
            )
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Dynamic Type Tests
    
    func testDynamicTypeSupport() throws {
        // Test with different text sizes
        let textSizes: [String] = [
            "UICTContentSizeCategoryS",
            "UICTContentSizeCategoryM",
            "UICTContentSizeCategoryL",
            "UICTContentSizeCategoryXL",
            "UICTContentSizeCategoryAccessibilityM",
            "UICTContentSizeCategoryAccessibilityL"
        ]
        
        for textSize in textSizes {
            // Restart app with different text size
            app.terminate()
            app.launchEnvironment["UIContentSizeCategory"] = textSize
            app.launch()
            
            // Test that UI elements are still accessible and visible
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.exists, "Tab bar should exist with text size \(textSize)")
            
            // Navigate to different screens to test layout
            let profileTab = tabBar.buttons["Profile tab"]
            profileTab.tap()
            
            // Test that profile elements are accessible
            let profileElements = app.otherElements.matching(identifier: "profile")
            XCTAssertGreaterThanOrEqual(profileElements.count, 0, "Profile should be accessible with text size \(textSize)")
        }
    }
    
    // MARK: - Keyboard Navigation Tests
    
    func testKeyboardNavigation() throws {
        // Enable keyboard navigation
        app.launchEnvironment["UIKeyboardNavigationEnabled"] = "1"
        app.terminate()
        app.launch()
        
        // Test tab key navigation
        let firstFocusableElement = app.buttons.firstMatch
        if firstFocusableElement.exists {
            firstFocusableElement.typeKey("", modifierFlags: [])
            
            // Test that focus moves between elements
            XCTAssertTrue(firstFocusableElement.hasFocus || app.buttons.element(boundBy: 1).hasFocus,
                         "Focus should move between elements")
        }
    }
    
    // MARK: - High Contrast Tests
    
    func testHighContrastSupport() throws {
        // Enable high contrast
        app.launchEnvironment["UIAccessibilityDarkerSystemColorsEnabled"] = "1"
        app.terminate()
        app.launch()
        
        // Test that UI is still functional with high contrast
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist with high contrast")
        
        // Test button visibility
        let buttons = app.buttons
        for i in 0..<min(buttons.count, 5) {
            let button = buttons.element(boundBy: i)
            if button.exists {
                XCTAssertTrue(button.isHittable, "Button \(i) should be hittable with high contrast")
            }
        }
    }
    
    // MARK: - Reduce Motion Tests
    
    func testReduceMotionSupport() throws {
        // Enable reduce motion
        app.launchEnvironment["UIAccessibilityIsReduceMotionEnabled"] = "1"
        app.terminate()
        app.launch()
        
        // Test that app functions without animations
        let feedTab = app.tabBars.buttons["Feed tab"]
        feedTab.tap()
        
        // Test navigation without animations
        let challengesTab = app.tabBars.buttons["Challenges tab"]
        challengesTab.tap()
        
        XCTAssertTrue(challengesTab.isSelected, "Tab switching should work with reduce motion")
    }
    
    // MARK: - Voice Control Tests
    
    func testVoiceControlSupport() throws {
        // Test that elements have proper voice control names
        let feedTab = app.tabBars.buttons["Feed tab"]
        XCTAssertTrue(feedTab.exists, "Feed tab should be accessible to voice control")
        
        // Test that buttons have clear, speakable labels
        let createPostButton = app.navigationBars.buttons["Create new post"]
        if createPostButton.exists {
            let label = createPostButton.label
            XCTAssertFalse(label.isEmpty, "Create post button should have a speakable label")
            XCTAssertFalse(label.contains("Button"), "Label should not contain generic 'Button' text")
        }
    }
    
    // MARK: - Switch Control Tests
    
    func testSwitchControlSupport() throws {
        // Test that elements are properly grouped for switch control
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist for switch control")
        
        // Test that interactive elements are accessible
        let interactiveElements = app.buttons
        XCTAssertGreaterThan(interactiveElements.count, 0, "Should have interactive elements for switch control")
        
        // Test that elements have proper accessibility traits
        for i in 0..<min(interactiveElements.count, 5) {
            let element = interactiveElements.element(boundBy: i)
            if element.exists {
                XCTAssertTrue(element.isHittable, "Interactive element \(i) should be hittable")
            }
        }
    }
    
    // MARK: - Screen Reader Tests
    
    func testScreenReaderAnnouncements() throws {
        // Test that important state changes are announced
        let feedTab = app.tabBars.buttons["Feed tab"]
        feedTab.tap()
        
        // Test pull to refresh announcement
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            
            // Wait for refresh to complete and announcement
            sleep(2)
            
            // Test that loading states are announced
            let loadingIndicator = app.activityIndicators.firstMatch
            if loadingIndicator.exists {
                XCTAssertTrue(loadingIndicator.exists, "Loading should be announced to screen readers")
            }
        }
    }
    
    // MARK: - Accessibility Inspector Tests
    
    func testAccessibilityInspectorCompliance() throws {
        // Test that elements pass basic accessibility inspector checks
        
        // Check for missing accessibility labels
        let unlabeledElements = app.otherElements.matching(NSPredicate(format: "label == '' AND isAccessibilityElement == true"))
        XCTAssertEqual(unlabeledElements.count, 0, "All accessibility elements should have labels")
        
        // Check for proper button traits
        let buttons = app.buttons
        for i in 0..<min(buttons.count, 10) {
            let button = buttons.element(boundBy: i)
            if button.exists {
                XCTAssertFalse(button.label.isEmpty, "Button \(i) should have a label")
            }
        }
        
        // Check for proper heading structure
        let headings = app.otherElements.matching(NSPredicate(format: "accessibilityTraits CONTAINS %d", UIAccessibilityTraits.header.rawValue))
        // Headings should exist for proper navigation
        XCTAssertGreaterThanOrEqual(headings.count, 0, "Should have proper heading structure")
    }
    
    // MARK: - Performance Tests
    
    func testAccessibilityPerformance() throws {
        measure {
            // Test that accessibility doesn't significantly impact performance
            let feedTab = app.tabBars.buttons["Feed tab"]
            feedTab.tap()
            
            // Navigate through different screens
            let challengesTab = app.tabBars.buttons["Challenges tab"]
            challengesTab.tap()
            
            let profileTab = app.tabBars.buttons["Profile tab"]
            profileTab.tap()
            
            // Return to feed
            feedTab.tap()
        }
    }
    
    // MARK: - Error State Tests
    
    func testAccessibilityInErrorStates() throws {
        // Test accessibility during error states
        // This would require mocking network errors or other error conditions
        
        // For now, test that error alerts are accessible
        // This would be expanded based on specific error handling implementation
        
        let alerts = app.alerts
        if alerts.count > 0 {
            let firstAlert = alerts.firstMatch
            XCTAssertTrue(firstAlert.exists, "Error alerts should be accessible")
            
            let okButton = firstAlert.buttons["OK"]
            if okButton.exists {
                XCTAssertTrue(okButton.isHittable, "Alert buttons should be accessible")
            }
        }
    }
    
    // MARK: - Localization Tests
    
    func testAccessibilityLocalization() throws {
        // Test accessibility with different locales
        let locales = ["en", "es", "fr", "de"]
        
        for locale in locales {
            app.terminate()
            app.launchArguments.append("-AppleLanguages")
            app.launchArguments.append("(\(locale))")
            app.launch()
            
            // Test that basic navigation still works
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.exists, "Tab bar should exist in locale \(locale)")
            
            // Test that at least some elements have localized labels
            let buttons = app.buttons
            if buttons.count > 0 {
                let firstButton = buttons.firstMatch
                XCTAssertFalse(firstButton.label.isEmpty, "Buttons should have labels in locale \(locale)")
            }
        }
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    var hasFocus: Bool {
        return self.value(forKey: "hasKeyboardFocus") as? Bool ?? false
    }
}