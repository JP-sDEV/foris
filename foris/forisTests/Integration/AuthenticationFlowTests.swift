import XCTest
import Combine
@testable import foris

/// Integration tests for complete authentication flows
/// Tests end-to-end authentication scenarios with mock providers
final class AuthenticationFlowTests: XCTestCase {
    
    // MARK: - Properties
    
    var authService: AuthService!
    var authViewModel: AuthViewModel!
    var mockGraphQLService: MockGraphQLService!
    var mockKeychainService: MockKeychainService!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        mockGraphQLService = MockGraphQLService()
        mockKeychainService = MockKeychainService()
        authService = AuthService(
            graphqlService: mockGraphQLService,
            keychainService: mockKeychainService
        )
        authViewModel = AuthViewModel(authService: authService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        authViewModel = nil
        authService = nil
        mockKeychainService = nil
        mockGraphQLService = nil
    }
    
    // MARK: - Complete Authentication Flow Tests
    
    func testCompleteGoogleSignInFlow() async {
        // Given
        mockKeychainService.shouldSucceed = true
        
        let stateExpectation = XCTestExpectation(description: "Authentication state progression")
        stateExpectation.expectedFulfillmentCount = 3 // unauthenticated -> authenticating -> authenticated
        
        var stateChanges: [AuthState] = []
        
        authViewModel.$authState
            .sink { state in
                stateChanges.append(state)
                stateExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        authViewModel.signIn(with: .google)
        
        // Then
        await fulfillment(of: [stateExpectation], timeout: 3.0)
        
        // Verify state progression
        XCTAssertEqual(stateChanges.count, 3)
        XCTAssertEqual(stateChanges[0], .unauthenticated)
        
        if case .authenticating(let provider) = stateChanges[1] {
            XCTAssertEqual(provider, .google)
        } else {
            XCTFail("Expected authenticating state")
        }
        
        if case .authenticated(let user) = stateChanges[2] {
            XCTAssertNotNil(user)
        } else {
            XCTFail("Expected authenticated state")
        }
        
        // Verify final state
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertNotNil(authViewModel.currentUser)
        XCTAssertFalse(authViewModel.canSignIn)
        
        // Verify keychain operations
        XCTAssertTrue(mockKeychainService.storeTokensCalled)
        XCTAssertTrue(mockKeychainService.storeUserProfileCalled)
    }
    
    func testCompleteAppleSignInFlow() async {
        // Given
        mockKeychainService.shouldSucceed = true
        
        let authExpectation = XCTestExpectation(description: "Apple authentication completed")
        
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    authExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        authViewModel.signIn(with: .apple)
        
        // Then
        await fulfillment(of: [authExpectation], timeout: 3.0)
        
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertNotNil(authViewModel.currentUser)
        
        // Verify keychain operations
        XCTAssertTrue(mockKeychainService.storeTokensCalled)
        XCTAssertTrue(mockKeychainService.storeUserProfileCalled)
    }
    
    func testSignInFailureFlow() async {
        // Given
        mockKeychainService.shouldSucceed = false
        
        let errorExpectation = XCTestExpectation(description: "Authentication error shown")
        
        authViewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    errorExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        authViewModel.signIn(with: .google)
        
        // Then
        await fulfillment(of: [errorExpectation], timeout: 3.0)
        
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.currentUser)
        XCTAssertTrue(authViewModel.showError)
        XCTAssertNotNil(authViewModel.errorMessage)
        
        // Verify error state
        if case .error(let error) = authViewModel.authState {
            XCTAssertTrue(error is AuthError)
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testCompleteSignOutFlow() async {
        // Given - Start authenticated
        mockKeychainService.shouldSucceed = true
        authViewModel.signIn(with: .google)
        
        // Wait for authentication to complete
        let authExpectation = XCTestExpectation(description: "Authentication completed")
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    authExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [authExpectation], timeout: 2.0)
        
        // Now test sign out
        let signOutExpectation = XCTestExpectation(description: "Sign out completed")
        
        authViewModel.$authState
            .dropFirst()
            .sink { state in
                if case .unauthenticated = state {
                    signOutExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        authViewModel.signOut()
        
        // Then
        await fulfillment(of: [signOutExpectation], timeout: 2.0)
        
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.currentUser)
        XCTAssertTrue(authViewModel.canSignIn)
        
        // Verify keychain cleanup
        XCTAssertTrue(mockKeychainService.clearAuthenticationDataCalled)
    }
    
    // MARK: - Token Refresh Flow Tests
    
    func testAutomaticTokenRefreshFlow() async {
        // Given - Existing tokens in keychain
        let existingTokens = AuthTokens(accessToken: "old_access", refreshToken: "valid_refresh")
        let existingUser = User.mock
        
        mockKeychainService.storedTokens = existingTokens
        mockKeychainService.storedUser = existingUser
        mockKeychainService.shouldSucceed = true
        
        let authExpectation = XCTestExpectation(description: "Auto authentication completed")
        
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    authExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Check authentication status (simulates app launch)
        authViewModel.checkAuthenticationStatus()
        
        // Then
        await fulfillment(of: [authExpectation], timeout: 2.0)
        
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertEqual(authViewModel.currentUser?.id, existingUser.id)
        
        // Verify token retrieval was called
        XCTAssertTrue(mockKeychainService.retrieveTokensCalled)
        XCTAssertTrue(mockKeychainService.retrieveUserProfileCalled)
    }
    
    func testTokenRefreshFailureFlow() async {
        // Given - Invalid refresh token
        let invalidTokens = AuthTokens(accessToken: nil, refreshToken: "invalid_refresh")
        mockKeychainService.storedTokens = invalidTokens
        mockKeychainService.shouldFailRefresh = true
        
        let unauthExpectation = XCTestExpectation(description: "Unauthenticated after failed refresh")
        
        authViewModel.$authState
            .dropFirst()
            .sink { state in
                if case .unauthenticated = state {
                    unauthExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        authViewModel.checkAuthenticationStatus()
        
        // Then
        await fulfillment(of: [unauthExpectation], timeout: 2.0)
        
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.currentUser)
        
        // Verify cleanup was called
        XCTAssertTrue(mockKeychainService.clearAuthenticationDataCalled)
    }
    
    func testManualTokenRefreshFlow() async {
        // Given - Authenticated user
        mockKeychainService.shouldSucceed = true
        let user = User.mock
        authService.authState = .authenticated(user)
        
        let refreshExpectation = XCTestExpectation(description: "Token refresh completed")
        
        authViewModel.$authState
            .dropFirst()
            .sink { state in
                if case .authenticated = state {
                    refreshExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        authViewModel.refreshAuthentication()
        
        // Then
        await fulfillment(of: [refreshExpectation], timeout: 2.0)
        
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertNotNil(authViewModel.currentUser)
    }
    
    // MARK: - Error Recovery Flow Tests
    
    func testErrorDismissalAndRetry() async {
        // Given - Failed authentication
        mockKeychainService.shouldSucceed = false
        authViewModel.signIn(with: .google)
        
        // Wait for error
        let errorExpectation = XCTestExpectation(description: "Error shown")
        authViewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    errorExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [errorExpectation], timeout: 2.0)
        
        // When - Dismiss error and retry
        authViewModel.dismissError()
        XCTAssertFalse(authViewModel.showError)
        XCTAssertNil(authViewModel.errorMessage)
        
        // Fix the issue and retry
        mockKeychainService.shouldSucceed = true
        
        let retryExpectation = XCTestExpectation(description: "Retry successful")
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    retryExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        authViewModel.signIn(with: .google)
        
        // Then
        await fulfillment(of: [retryExpectation], timeout: 2.0)
        
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.showError)
    }
    
    // MARK: - Session Persistence Tests
    
    func testSessionPersistenceAcrossAppLaunches() async {
        // Given - Simulate first app launch with sign in
        mockKeychainService.shouldSucceed = true
        
        let firstAuthExpectation = XCTestExpectation(description: "First authentication")
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    firstAuthExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        authViewModel.signIn(with: .google)
        await fulfillment(of: [firstAuthExpectation], timeout: 2.0)
        
        let firstUser = authViewModel.currentUser
        XCTAssertNotNil(firstUser)
        
        // Simulate app restart - create new instances
        let newAuthService = AuthService(
            graphqlService: mockGraphQLService,
            keychainService: mockKeychainService
        )
        let newAuthViewModel = AuthViewModel(authService: newAuthService)
        
        let persistenceExpectation = XCTestExpectation(description: "Session persisted")
        newAuthViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    persistenceExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Check authentication status on "app launch"
        newAuthViewModel.checkAuthenticationStatus()
        
        // Then
        await fulfillment(of: [persistenceExpectation], timeout: 2.0)
        
        XCTAssertTrue(newAuthViewModel.isAuthenticated)
        XCTAssertEqual(newAuthViewModel.currentUser?.id, firstUser?.id)
    }
    
    // MARK: - Multiple Provider Tests
    
    func testSwitchingBetweenProviders() async {
        // Given - Sign in with Google first
        mockKeychainService.shouldSucceed = true
        
        let googleAuthExpectation = XCTestExpectation(description: "Google authentication")
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    googleAuthExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        authViewModel.signIn(with: .google)
        await fulfillment(of: [googleAuthExpectation], timeout: 2.0)
        
        let googleUser = authViewModel.currentUser
        XCTAssertNotNil(googleUser)
        
        // When - Sign out and sign in with Apple
        let signOutExpectation = XCTestExpectation(description: "Sign out completed")
        authViewModel.$authState
            .dropFirst()
            .sink { state in
                if case .unauthenticated = state {
                    signOutExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        authViewModel.signOut()
        await fulfillment(of: [signOutExpectation], timeout: 2.0)
        
        let appleAuthExpectation = XCTestExpectation(description: "Apple authentication")
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    appleAuthExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        authViewModel.signIn(with: .apple)
        
        // Then
        await fulfillment(of: [appleAuthExpectation], timeout: 2.0)
        
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertNotNil(authViewModel.currentUser)
        
        // User should be different (different provider)
        XCTAssertNotEqual(authViewModel.currentUser?.id, googleUser?.id)
    }
    
    // MARK: - Network Connectivity Tests
    
    func testAuthenticationWithNetworkIssues() async {
        // Given - Network issues
        mockGraphQLService.shouldFail = true
        mockGraphQLService.mockError = GraphQLError.networkError(URLError(.notConnectedToInternet))
        
        let errorExpectation = XCTestExpectation(description: "Network error shown")
        authViewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    errorExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        authViewModel.signIn(with: .google)
        
        // Then
        await fulfillment(of: [errorExpectation], timeout: 2.0)
        
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertTrue(authViewModel.showError)
        
        // Verify error is network-related
        XCTAssertTrue(authViewModel.errorMessage?.contains("Network") == true ||
                     authViewModel.errorMessage?.contains("connection") == true)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentAuthenticationAttempts() async {
        // Given
        mockKeychainService.shouldSucceed = true
        
        // When - Multiple concurrent authentication attempts
        let task1 = Task { authViewModel.signIn(with: .google) }
        let task2 = Task { authViewModel.signIn(with: .apple) }
        let task3 = Task { authViewModel.refreshAuthentication() }
        
        // Wait for all tasks to complete
        await task1.value
        await task2.value
        await task3.value
        
        // Then - Should handle gracefully without crashes
        // Final state should be consistent
        XCTAssertTrue(authViewModel.isAuthenticated || authViewModel.showError)
        
        // Should not be in an inconsistent state
        if authViewModel.isAuthenticated {
            XCTAssertNotNil(authViewModel.currentUser)
        } else {
            XCTAssertNil(authViewModel.currentUser)
        }
    }
    
    // MARK: - Memory and Performance Tests
    
    func testAuthenticationFlowMemoryUsage() async {
        // Given
        weak var weakAuthService: AuthService?
        weak var weakAuthViewModel: AuthViewModel?
        
        await withCheckedContinuation { continuation in
            autoreleasepool {
                let testAuthService = AuthService(
                    graphqlService: mockGraphQLService,
                    keychainService: mockKeychainService
                )
                let testAuthViewModel = AuthViewModel(authService: testAuthService)
                
                weakAuthService = testAuthService
                weakAuthViewModel = testAuthViewModel
                
                // Perform authentication flow
                testAuthViewModel.signIn(with: .google)
                
                // Wait a bit for async operations
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    continuation.resume()
                }
            }
        }
        
        // When/Then - Objects should be deallocated
        XCTAssertNil(weakAuthService)
        XCTAssertNil(weakAuthViewModel)
    }
    
    func testAuthenticationFlowPerformance() {
        // Given
        mockKeychainService.shouldSucceed = true
        
        // When/Then
        measure {
            let expectation = XCTestExpectation(description: "Authentication performance")
            
            authViewModel.$isAuthenticated
                .dropFirst()
                .sink { isAuthenticated in
                    if isAuthenticated {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            authViewModel.signIn(with: .google)
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testAuthenticationWithMissingKeychain() async {
        // Given - Keychain unavailable
        mockKeychainService.shouldFailTokenRetrieval = true
        
        let unauthExpectation = XCTestExpectation(description: "Unauthenticated due to keychain failure")
        authViewModel.$authState
            .dropFirst()
            .sink { state in
                if case .unauthenticated = state {
                    unauthExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        authViewModel.checkAuthenticationStatus()
        
        // Then
        await fulfillment(of: [unauthExpectation], timeout: 2.0)
        
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.currentUser)
    }
    
    func testAuthenticationWithCorruptedData() async {
        // Given - Corrupted stored data
        mockKeychainService.storedTokens = AuthTokens(accessToken: "", refreshToken: "")
        mockKeychainService.storedUser = nil
        
        let unauthExpectation = XCTestExpectation(description: "Unauthenticated due to corrupted data")
        authViewModel.$authState
            .dropFirst()
            .sink { state in
                if case .unauthenticated = state {
                    unauthExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        authViewModel.checkAuthenticationStatus()
        
        // Then
        await fulfillment(of: [unauthExpectation], timeout: 2.0)
        
        XCTAssertFalse(authViewModel.isAuthenticated)
        
        // Should clean up corrupted data
        XCTAssertTrue(mockKeychainService.clearAuthenticationDataCalled)
    }
}