import XCTest
import SwiftUI
@testable import foris

/// UI tests for critical user flows and error scenarios
/// Tests complete user journeys through the app interface
final class CriticalUserFlowTests: XCTestCase {
    
    // MARK: - Properties
    
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Configure app for testing
        app.launchArguments.append("--ui-testing")
        app.launchArguments.append("--reset-state")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Authentication Flow Tests
    
    func testCompleteAuthenticationFlow() throws {
        // Given - App launches to authentication screen
        let authScreen = app.otherElements["authentication_screen"]
        XCTAssertTrue(authScreen.waitForExistence(timeout: 5.0))
        
        // When - User taps Google sign in
        let googleSignInButton = app.buttons["google_sign_in_button"]
        XCTAssertTrue(googleSignInButton.exists)
        googleSignInButton.tap()
        
        // Then - Should navigate to main app
        let mainTabView = app.tabBars["main_tab_bar"]
        XCTAssertTrue(mainTabView.waitForExistence(timeout: 10.0))
        
        // Verify all tabs are present
        XCTAssertTrue(app.buttons["Feed tab"].exists)
        XCTAssertTrue(app.buttons["Challenges tab"].exists)
        XCTAssertTrue(app.buttons["Leagues tab"].exists)
        XCTAssertTrue(app.buttons["Social tab"].exists)
        XCTAssertTrue(app.buttons["Profile tab"].exists)
    }
    
    func testAuthenticationErrorHandling() throws {
        // Given - Configure app to simulate auth failure
        app.terminate()
        app.launchArguments.append("--simulate-auth-failure")
        app.launch()
        
        let authScreen = app.otherElements["authentication_screen"]
        XCTAssertTrue(authScreen.waitForExistence(timeout: 5.0))
        
        // When - User attempts to sign in
        let googleSignInButton = app.buttons["google_sign_in_button"]
        googleSignInButton.tap()
        
        // Then - Should show error alert
        let errorAlert = app.alerts["Authentication Error"]
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5.0))
        
        let errorMessage = errorAlert.staticTexts.element(boundBy: 1)
        XCTAssertTrue(errorMessage.label.contains("failed") || errorMessage.label.contains("error"))
        
        // Dismiss error and try again
        let okButton = errorAlert.buttons["OK"]
        okButton.tap()
        
        XCTAssertTrue(authScreen.exists)
        XCTAssertTrue(googleSignInButton.exists)
    }
    
    func testSignOutFlow() throws {
        // Given - User is authenticated
        authenticateUser()
        
        // Navigate to profile tab
        let profileTab = app.buttons["Profile tab"]
        profileTab.tap()
        
        let profileScreen = app.otherElements["profile_screen"]
        XCTAssertTrue(profileScreen.waitForExistence(timeout: 5.0))
        
        // When - User taps sign out
        let signOutButton = app.buttons["sign_out_button"]
        XCTAssertTrue(signOutButton.exists)
        signOutButton.tap()
        
        // Confirm sign out
        let confirmAlert = app.alerts["Sign Out"]
        if confirmAlert.exists {
            let confirmButton = confirmAlert.buttons["Sign Out"]
            confirmButton.tap()
        }
        
        // Then - Should return to authentication screen
        let authScreen = app.otherElements["authentication_screen"]
        XCTAssertTrue(authScreen.waitForExistence(timeout: 5.0))
    }
    
    // MARK: - Feed Flow Tests
    
    func testCreatePostFlow() throws {
        // Given - User is authenticated and on feed tab
        authenticateUser()
        
        let feedTab = app.buttons["Feed tab"]
        feedTab.tap()
        
        // When - User creates a new post
        let createPostButton = app.buttons["create_post_button"]
        XCTAssertTrue(createPostButton.waitForExistence(timeout: 5.0))
        createPostButton.tap()
        
        let createPostScreen = app.otherElements["create_post_screen"]
        XCTAssertTrue(createPostScreen.waitForExistence(timeout: 5.0))
        
        // Fill in post details
        let titleField = app.textFields["post_title_field"]
        XCTAssertTrue(titleField.exists)
        titleField.tap()
        titleField.typeText("Test Post Title")
        
        let contentField = app.textViews["post_content_field"]
        XCTAssertTrue(contentField.exists)
        contentField.tap()
        contentField.typeText("This is a test post content.")
        
        // Submit post
        let submitButton = app.buttons["submit_post_button"]
        XCTAssertTrue(submitButton.exists)
        submitButton.tap()
        
        // Then - Should return to feed with new post
        let feedScreen = app.otherElements["feed_screen"]
        XCTAssertTrue(feedScreen.waitForExistence(timeout: 5.0))
        
        // Verify post appears in feed
        let postTitle = app.staticTexts["Test Post Title"]
        XCTAssertTrue(postTitle.waitForExistence(timeout: 5.0))
    }
    
    func testLikePostFlow() throws {
        // Given - User is authenticated with posts in feed
        authenticateUser()
        navigateToFeedWithPosts()
        
        // When - User likes a post
        let firstLikeButton = app.buttons.matching(identifier: "like_button").element(boundBy: 0)
        XCTAssertTrue(firstLikeButton.waitForExistence(timeout: 5.0))
        
        let initialLikeCount = getLikeCount(for: firstLikeButton)
        firstLikeButton.tap()
        
        // Then - Like count should increase and button state should change
        let updatedLikeCount = getLikeCount(for: firstLikeButton)
        XCTAssertEqual(updatedLikeCount, initialLikeCount + 1)
        
        // Verify button shows liked state
        XCTAssertTrue(firstLikeButton.label.contains("Unlike") || firstLikeButton.isSelected)
    }
    
    func testPostDetailFlow() throws {
        // Given - User is authenticated with posts in feed
        authenticateUser()
        navigateToFeedWithPosts()
        
        // When - User taps on a post
        let firstPost = app.otherElements.matching(identifier: "post_card").element(boundBy: 0)
        XCTAssertTrue(firstPost.waitForExistence(timeout: 5.0))
        firstPost.tap()
        
        // Then - Should navigate to post detail
        let postDetailScreen = app.otherElements["post_detail_screen"]
        XCTAssertTrue(postDetailScreen.waitForExistence(timeout: 5.0))
        
        // Verify post details are shown
        XCTAssertTrue(app.staticTexts.matching(identifier: "post_title").element.exists)
        XCTAssertTrue(app.staticTexts.matching(identifier: "post_content").element.exists)
        XCTAssertTrue(app.buttons["like_button"].exists)
        XCTAssertTrue(app.buttons["comment_button"].exists)
        
        // Navigate back
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        backButton.tap()
        
        let feedScreen = app.otherElements["feed_screen"]
        XCTAssertTrue(feedScreen.waitForExistence(timeout: 5.0))
    }
    
    // MARK: - Challenge Flow Tests
    
    func testJoinChallengeFlow() throws {
        // Given - User is authenticated
        authenticateUser()
        
        // Navigate to challenges tab
        let challengesTab = app.buttons["Challenges tab"]
        challengesTab.tap()
        
        let challengesScreen = app.otherElements["challenges_screen"]
        XCTAssertTrue(challengesScreen.waitForExistence(timeout: 5.0))
        
        // When - User joins a challenge
        let firstJoinButton = app.buttons.matching(identifier: "join_challenge_button").element(boundBy: 0)
        XCTAssertTrue(firstJoinButton.waitForExistence(timeout: 5.0))
        firstJoinButton.tap()
        
        // Confirm join if needed
        let confirmAlert = app.alerts["Join Challenge"]
        if confirmAlert.exists {
            let confirmButton = confirmAlert.buttons["Join"]
            confirmButton.tap()
        }
        
        // Then - Button should change to show joined state
        let joinedButton = app.buttons.matching(identifier: "leave_challenge_button").element(boundBy: 0)
        XCTAssertTrue(joinedButton.waitForExistence(timeout: 5.0))
        
        // Verify challenge appears in "My Challenges" section
        let myChallengesSection = app.otherElements["my_challenges_section"]
        if myChallengesSection.exists {
            XCTAssertGreaterThan(myChallengesSection.otherElements.count, 0)
        }
    }
    
    func testCreateChallengeFlow() throws {
        // Given - User is authenticated
        authenticateUser()
        
        let challengesTab = app.buttons["Challenges tab"]
        challengesTab.tap()
        
        // When - User creates a new challenge
        let createChallengeButton = app.buttons["create_challenge_button"]
        XCTAssertTrue(createChallengeButton.waitForExistence(timeout: 5.0))
        createChallengeButton.tap()
        
        let createChallengeScreen = app.otherElements["create_challenge_screen"]
        XCTAssertTrue(createChallengeScreen.waitForExistence(timeout: 5.0))
        
        // Fill in challenge details
        let nameField = app.textFields["challenge_name_field"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("Test Challenge")
        
        let descriptionField = app.textViews["challenge_description_field"]
        XCTAssertTrue(descriptionField.exists)
        descriptionField.tap()
        descriptionField.typeText("This is a test challenge description.")
        
        // Set end date
        let endDatePicker = app.datePickers["challenge_end_date_picker"]
        if endDatePicker.exists {
            endDatePicker.tap()
            // Select a future date
            let futureDate = app.buttons["Next Month"]
            if futureDate.exists {
                futureDate.tap()
            }
        }
        
        // Submit challenge
        let submitButton = app.buttons["submit_challenge_button"]
        XCTAssertTrue(submitButton.exists)
        submitButton.tap()
        
        // Then - Should return to challenges list with new challenge
        let challengesScreen = app.otherElements["challenges_screen"]
        XCTAssertTrue(challengesScreen.waitForExistence(timeout: 5.0))
        
        let challengeTitle = app.staticTexts["Test Challenge"]
        XCTAssertTrue(challengeTitle.waitForExistence(timeout: 5.0))
    }
    
    // MARK: - Profile Flow Tests
    
    func testEditProfileFlow() throws {
        // Given - User is authenticated
        authenticateUser()
        
        // Navigate to profile tab
        let profileTab = app.buttons["Profile tab"]
        profileTab.tap()
        
        let profileScreen = app.otherElements["profile_screen"]
        XCTAssertTrue(profileScreen.waitForExistence(timeout: 5.0))
        
        // When - User edits profile
        let editProfileButton = app.buttons["edit_profile_button"]
        XCTAssertTrue(editProfileButton.exists)
        editProfileButton.tap()
        
        let editProfileScreen = app.otherElements["edit_profile_screen"]
        XCTAssertTrue(editProfileScreen.waitForExistence(timeout: 5.0))
        
        // Update name
        let nameField = app.textFields["profile_name_field"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.clearAndEnterText("Updated Name")
        
        // Update bio
        let bioField = app.textViews["profile_bio_field"]
        XCTAssertTrue(bioField.exists)
        bioField.tap()
        bioField.clearAndEnterText("Updated bio description")
        
        // Save changes
        let saveButton = app.buttons["save_profile_button"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()
        
        // Then - Should return to profile with updated info
        XCTAssertTrue(profileScreen.waitForExistence(timeout: 5.0))
        
        let updatedName = app.staticTexts["Updated Name"]
        XCTAssertTrue(updatedName.waitForExistence(timeout: 5.0))
        
        let updatedBio = app.staticTexts["Updated bio description"]
        XCTAssertTrue(updatedBio.waitForExistence(timeout: 5.0))
    }
    
    // MARK: - Social Flow Tests
    
    func testUserSearchAndFollowFlow() throws {
        // Given - User is authenticated
        authenticateUser()
        
        // Navigate to social tab
        let socialTab = app.buttons["Social tab"]
        socialTab.tap()
        
        let socialScreen = app.otherElements["social_screen"]
        XCTAssertTrue(socialScreen.waitForExistence(timeout: 5.0))
        
        // When - User searches for other users
        let searchField = app.searchFields["user_search_field"]
        XCTAssertTrue(searchField.exists)
        searchField.tap()
        searchField.typeText("test user")
        
        // Wait for search results
        let searchResults = app.otherElements["search_results"]
        XCTAssertTrue(searchResults.waitForExistence(timeout: 5.0))
        
        // Follow a user
        let firstFollowButton = app.buttons.matching(identifier: "follow_button").element(boundBy: 0)
        XCTAssertTrue(firstFollowButton.waitForExistence(timeout: 5.0))
        firstFollowButton.tap()
        
        // Then - Button should change to "Following"
        let followingButton = app.buttons.matching(identifier: "unfollow_button").element(boundBy: 0)
        XCTAssertTrue(followingButton.waitForExistence(timeout: 5.0))
        
        // Verify user appears in following list
        let followingTab = app.buttons["following_tab"]
        if followingTab.exists {
            followingTab.tap()
            let followingList = app.otherElements["following_list"]
            XCTAssertTrue(followingList.waitForExistence(timeout: 5.0))
            XCTAssertGreaterThan(followingList.otherElements.count, 0)
        }
    }
    
    // MARK: - Error Scenario Tests
    
    func testNetworkErrorHandling() throws {
        // Given - User is authenticated but network fails
        authenticateUser()
        
        // Simulate network failure
        app.terminate()
        app.launchArguments.append("--simulate-network-failure")
        app.launch()
        
        // Navigate to feed
        let feedTab = app.buttons["Feed tab"]
        feedTab.tap()
        
        // When - App tries to load data
        let feedScreen = app.otherElements["feed_screen"]
        XCTAssertTrue(feedScreen.waitForExistence(timeout: 5.0))
        
        // Then - Should show error state
        let errorView = app.otherElements["error_view"]
        XCTAssertTrue(errorView.waitForExistence(timeout: 10.0))
        
        let errorMessage = app.staticTexts.matching(identifier: "error_message").element
        XCTAssertTrue(errorMessage.exists)
        XCTAssertTrue(errorMessage.label.contains("network") || errorMessage.label.contains("connection"))
        
        // Test retry functionality
        let retryButton = app.buttons["retry_button"]
        XCTAssertTrue(retryButton.exists)
        retryButton.tap()
        
        // Should attempt to reload
        XCTAssertTrue(app.activityIndicators.element.waitForExistence(timeout: 5.0))
    }
    
    func testOfflineStateHandling() throws {
        // Given - User is authenticated but goes offline
        authenticateUser()
        
        // Simulate offline state
        app.terminate()
        app.launchArguments.append("--simulate-offline")
        app.launch()
        
        // When - User navigates through app
        let feedTab = app.buttons["Feed tab"]
        feedTab.tap()
        
        // Then - Should show offline indicator
        let offlineIndicator = app.otherElements["offline_indicator"]
        XCTAssertTrue(offlineIndicator.waitForExistence(timeout: 5.0))
        
        // Should show cached content if available
        let feedScreen = app.otherElements["feed_screen"]
        XCTAssertTrue(feedScreen.exists)
        
        // Offline actions should be queued
        let createPostButton = app.buttons["create_post_button"]
        if createPostButton.exists {
            createPostButton.tap()
            
            // Fill and submit post
            let titleField = app.textFields["post_title_field"]
            if titleField.exists {
                titleField.tap()
                titleField.typeText("Offline Post")
                
                let submitButton = app.buttons["submit_post_button"]
                submitButton.tap()
                
                // Should show queued indicator
                let queuedIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'queued' OR label CONTAINS 'pending'")).element
                XCTAssertTrue(queuedIndicator.waitForExistence(timeout: 5.0))
            }
        }
    }
    
    func testValidationErrorHandling() throws {
        // Given - User is authenticated
        authenticateUser()
        
        let feedTab = app.buttons["Feed tab"]
        feedTab.tap()
        
        // When - User tries to create post with invalid data
        let createPostButton = app.buttons["create_post_button"]
        createPostButton.tap()
        
        let createPostScreen = app.otherElements["create_post_screen"]
        XCTAssertTrue(createPostScreen.waitForExistence(timeout: 5.0))
        
        // Leave title empty and try to submit
        let submitButton = app.buttons["submit_post_button"]
        submitButton.tap()
        
        // Then - Should show validation error
        let validationError = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'required' OR label CONTAINS 'empty'")).element
        XCTAssertTrue(validationError.waitForExistence(timeout: 5.0))
        
        // Should not navigate away from create screen
        XCTAssertTrue(createPostScreen.exists)
        
        // Fix validation error
        let titleField = app.textFields["post_title_field"]
        titleField.tap()
        titleField.typeText("Valid Title")
        
        submitButton.tap()
        
        // Should now succeed
        let feedScreen = app.otherElements["feed_screen"]
        XCTAssertTrue(feedScreen.waitForExistence(timeout: 5.0))
    }
    
    // MARK: - Accessibility Tests
    
    func testVoiceOverNavigation() throws {
        // Given - VoiceOver is enabled
        app.terminate()
        app.launchArguments.append("--enable-voiceover")
        app.launch()
        
        authenticateUser()
        
        // When - Navigate using VoiceOver
        let feedTab = app.buttons["Feed tab"]
        XCTAssertTrue(feedTab.isAccessibilityElement)
        XCTAssertFalse(feedTab.accessibilityLabel?.isEmpty ?? true)
        feedTab.tap()
        
        // Then - All elements should be accessible
        let createPostButton = app.buttons["create_post_button"]
        XCTAssertTrue(createPostButton.isAccessibilityElement)
        XCTAssertNotNil(createPostButton.accessibilityLabel)
        XCTAssertNotNil(createPostButton.accessibilityHint)
        
        // Test post cards accessibility
        let postCards = app.otherElements.matching(identifier: "post_card")
        if postCards.count > 0 {
            let firstPost = postCards.element(boundBy: 0)
            XCTAssertTrue(firstPost.isAccessibilityElement)
            XCTAssertNotNil(firstPost.accessibilityLabel)
        }
    }
    
    // MARK: - Helper Methods
    
    private func authenticateUser() {
        let authScreen = app.otherElements["authentication_screen"]
        if authScreen.waitForExistence(timeout: 5.0) {
            let googleSignInButton = app.buttons["google_sign_in_button"]
            googleSignInButton.tap()
            
            let mainTabView = app.tabBars["main_tab_bar"]
            XCTAssertTrue(mainTabView.waitForExistence(timeout: 10.0))
        }
    }
    
    private func navigateToFeedWithPosts() {
        let feedTab = app.buttons["Feed tab"]
        feedTab.tap()
        
        let feedScreen = app.otherElements["feed_screen"]
        XCTAssertTrue(feedScreen.waitForExistence(timeout: 5.0))
        
        // Wait for posts to load
        let postCards = app.otherElements.matching(identifier: "post_card")
        XCTAssertTrue(postCards.element(boundBy: 0).waitForExistence(timeout: 10.0))
    }
    
    private func getLikeCount(for likeButton: XCUIElement) -> Int {
        let label = likeButton.label
        let components = label.components(separatedBy: " ")
        
        for component in components {
            if let count = Int(component) {
                return count
            }
        }
        
        return 0
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non-string value")
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}