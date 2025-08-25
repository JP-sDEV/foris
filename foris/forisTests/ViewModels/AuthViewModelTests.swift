import XCTest
import Combine
@testable import foris

/// Comprehensive unit tests for AuthViewModel
/// Tests authentication flows, state management, and error handling
final class AuthViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    var viewModel: AuthViewModel!
    var mockAuthService: MockAuthService!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        viewModel = nil
        mockAuthService = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given/When - ViewModel is initialized in setup
        
        // Then
        XCTAssertEqual(viewModel.authState, .unauthenticated)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertTrue(viewModel.canSignIn)
        XCTAssertFalse(viewModel.showError)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testAvailableProviders() {
        // When
        let providers = viewModel.availableProviders
        
        // Then
        XCTAssertEqual(providers.count, 2)
        XCTAssertTrue(providers.contains(.google))
        XCTAssertTrue(providers.contains(.apple))
    }
    
    // MARK: - Authentication State Tests
    
    func testAuthStateBinding() {
        // Given
        let expectation = XCTestExpectation(description: "Auth state updated")
        let testUser = User.mock
        
        viewModel.$authState
            .dropFirst() // Skip initial value
            .sink { state in
                if case .authenticated(let user) = state {
                    XCTAssertEqual(user.id, testUser.id)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockAuthService.setAuthenticated(testUser)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.currentUser?.id, testUser.id)
        XCTAssertFalse(viewModel.canSignIn)
    }
    
    func testLoadingStateBinding() {
        // Given
        let expectation = XCTestExpectation(description: "Loading state updated")
        
        viewModel.$isLoading
            .dropFirst() // Skip initial value
            .sink { isLoading in
                if isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockAuthService.authState = .authenticating(.google)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isLoading)
    }
    
    // MARK: - Sign In Tests
    
    func testSuccessfulSignIn() async {
        // Given
        mockAuthService.shouldFailSignIn = false
        mockAuthService.signInDelay = 0.1
        
        let expectation = XCTestExpectation(description: "Sign in completed")
        
        viewModel.$authState
            .dropFirst()
            .sink { state in
                if case .authenticated = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.signIn(with: .google)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testFailedSignIn() async {
        // Given
        mockAuthService.shouldFailSignIn = true
        mockAuthService.signInDelay = 0.1
        
        let expectation = XCTestExpectation(description: "Sign in failed")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.signIn(with: .google)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testSignInWithDifferentProviders() async {
        // Given
        mockAuthService.shouldFailSignIn = false
        mockAuthService.signInDelay = 0.1
        
        // Test Google Sign-In
        let googleExpectation = XCTestExpectation(description: "Google sign in")
        
        viewModel.$authState
            .dropFirst()
            .sink { state in
                if case .authenticated = state {
                    googleExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.signIn(with: .google)
        
        // Then
        await fulfillment(of: [googleExpectation], timeout: 2.0)
        
        // Reset for Apple test
        mockAuthService.setUnauthenticated()
        
        // Test Apple Sign-In
        let appleExpectation = XCTestExpectation(description: "Apple sign in")
        
        viewModel.$authState
            .dropFirst()
            .sink { state in
                if case .authenticated = state {
                    appleExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.signIn(with: .apple)
        
        // Then
        await fulfillment(of: [appleExpectation], timeout: 2.0)
    }
    
    func testCannotSignInWhenLoading() {
        // Given
        mockAuthService.authState = .authenticating(.google)
        
        // When
        let canSignIn = viewModel.canSignIn
        
        // Then
        XCTAssertFalse(canSignIn)
    }
    
    func testCannotSignInWhenAuthenticated() {
        // Given
        mockAuthService.setAuthenticated(User.mock)
        
        // When
        let canSignIn = viewModel.canSignIn
        
        // Then
        XCTAssertFalse(canSignIn)
    }
    
    // MARK: - Sign Out Tests
    
    func testSuccessfulSignOut() async {
        // Given
        mockAuthService.setAuthenticated(User.mock)
        
        let expectation = XCTestExpectation(description: "Sign out completed")
        
        viewModel.$authState
            .dropFirst()
            .sink { state in
                if case .unauthenticated = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.signOut()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
    }
    
    // MARK: - Token Refresh Tests
    
    func testSuccessfulTokenRefresh() async {
        // Given
        mockAuthService.shouldFailRefresh = false
        mockAuthService.setAuthenticated(User.mock)
        
        let expectation = XCTestExpectation(description: "Token refresh completed")
        
        viewModel.$authState
            .dropFirst()
            .sink { state in
                if case .authenticated = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.refreshAuthentication()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isAuthenticated)
    }
    
    func testFailedTokenRefresh() async {
        // Given
        mockAuthService.shouldFailRefresh = true
        mockAuthService.setAuthenticated(User.mock)
        
        let expectation = XCTestExpectation(description: "Token refresh failed")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.refreshAuthentication()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorDismissal() {
        // Given
        viewModel.errorMessage = "Test error"
        viewModel.showError = true
        
        // When
        viewModel.dismissError()
        
        // Then
        XCTAssertFalse(viewModel.showError)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testCurrentErrorMessage() {
        // Given
        let testError = AuthError.oauthFailed("Google")
        mockAuthService.authState = .error(testError)
        
        // When
        let errorMessage = viewModel.currentErrorMessage
        
        // Then
        XCTAssertNotNil(errorMessage)
        XCTAssertEqual(errorMessage, testError.localizedDescription)
    }
    
    func testCurrentRecoverySuggestion() {
        // Given
        let testError = AuthError.networkError
        mockAuthService.authState = .error(testError)
        
        // When
        let recoverySuggestion = viewModel.currentRecoverySuggestion
        
        // Then
        XCTAssertNotNil(recoverySuggestion)
        XCTAssertEqual(recoverySuggestion, testError.recoverySuggestion)
    }
    
    func testShouldRetryCurrentError() {
        // Given
        let retryableError = AuthError.networkError
        let nonRetryableError = AuthError.userCancelled
        
        // Test retryable error
        mockAuthService.authState = .error(retryableError)
        XCTAssertTrue(viewModel.shouldRetryCurrentError)
        
        // Test non-retryable error
        mockAuthService.authState = .error(nonRetryableError)
        XCTAssertFalse(viewModel.shouldRetryCurrentError)
    }
    
    // MARK: - Provider Helper Tests
    
    func testProviderDisplayNames() {
        // When/Then
        XCTAssertEqual(viewModel.displayName(for: .google), "Google")
        XCTAssertEqual(viewModel.displayName(for: .apple), "Apple")
    }
    
    func testProviderIconNames() {
        // When/Then
        XCTAssertEqual(viewModel.iconName(for: .google), "globe")
        XCTAssertEqual(viewModel.iconName(for: .apple), "applelogo")
    }
    
    func testProviderAvailability() {
        // When/Then
        XCTAssertTrue(viewModel.isProviderAvailable(.google))
        XCTAssertTrue(viewModel.isProviderAvailable(.apple))
    }
    
    // MARK: - Authentication Status Check Tests
    
    func testCheckAuthenticationStatus() async {
        // Given
        let expectation = XCTestExpectation(description: "Auth status checked")
        
        viewModel.$authState
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        viewModel.checkAuthenticationStatus()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        // Given
        weak var weakViewModel: AuthViewModel?
        weak var weakMockService: MockAuthService?
        
        autoreleasepool {
            let mockService = MockAuthService()
            let testViewModel = AuthViewModel(authService: mockService)
            
            weakViewModel = testViewModel
            weakMockService = mockService
            
            // Use the view model
            testViewModel.signIn(with: .google)
        }
        
        // When/Then - Objects should be deallocated
        XCTAssertNil(weakViewModel)
        XCTAssertNil(weakMockService)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentSignInAttempts() async {
        // Given
        mockAuthService.signInDelay = 0.5
        
        // When - Multiple concurrent sign-in attempts
        async let result1: Void = viewModel.signIn(with: .google)
        async let result2: Void = viewModel.signIn(with: .apple)
        
        // Then - Should handle gracefully without crashes
        await result1
        await result2
        
        // Only one should succeed (the first one due to canSignIn check)
        XCTAssertTrue(viewModel.isAuthenticated || viewModel.showError)
    }
}

// MARK: - Mock Extensions for Testing

extension MockAuthService {
    func simulateNetworkDelay() async {
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
}