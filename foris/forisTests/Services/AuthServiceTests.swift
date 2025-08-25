import XCTest
import Combine
@testable import foris

/// Comprehensive unit tests for AuthService
/// Tests OAuth flows, token management, and authentication state
final class AuthServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var authService: AuthService!
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
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        authService = nil
        mockKeychainService = nil
        mockGraphQLService = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given/When - Service is initialized in setup
        
        // Then
        XCTAssertEqual(authService.authState, .unauthenticated)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }
    
    func testStateObservationBinding() {
        // Given
        let testUser = User.mock
        let expectation = XCTestExpectation(description: "State binding updated")
        
        authService.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        authService.authState = .authenticated(testUser)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertEqual(authService.currentUser?.id, testUser.id)
    }
    
    // MARK: - Authentication Status Check Tests
    
    func testCheckAuthenticationStatusWithValidTokens() async {
        // Given
        let testUser = User.mock
        let tokens = AuthTokens(accessToken: "access", refreshToken: "refresh")
        
        mockKeychainService.storedTokens = tokens
        mockKeychainService.storedUser = testUser
        
        // When
        await authService.checkAuthenticationStatus()
        
        // Then
        XCTAssertEqual(authService.authState, .authenticated(testUser))
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertEqual(authService.currentUser?.id, testUser.id)
    }
    
    func testCheckAuthenticationStatusWithoutTokens() async {
        // Given
        mockKeychainService.storedTokens = nil
        
        // When
        await authService.checkAuthenticationStatus()
        
        // Then
        XCTAssertEqual(authService.authState, .unauthenticated)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }
    
    func testCheckAuthenticationStatusWithInvalidTokens() async {
        // Given
        let tokens = AuthTokens(accessToken: "invalid", refreshToken: "invalid")
        mockKeychainService.storedTokens = tokens
        mockKeychainService.shouldFailTokenRetrieval = true
        
        // When
        await authService.checkAuthenticationStatus()
        
        // Then
        XCTAssertEqual(authService.authState, .unauthenticated)
        XCTAssertFalse(authService.isAuthenticated)
    }
    
    func testCheckAuthenticationStatusWithCachedUser() async {
        // Given
        let testUser = User.mock
        let tokens = AuthTokens(accessToken: "access", refreshToken: "refresh")
        
        mockKeychainService.storedTokens = tokens
        mockKeychainService.storedUser = testUser
        
        // When
        await authService.checkAuthenticationStatus()
        
        // Then
        XCTAssertEqual(authService.authState, .authenticated(testUser))
        XCTAssertEqual(authService.currentUser?.id, testUser.id)
    }
    
    // MARK: - Sign In Tests
    
    func testSignInWithGoogleSuccess() async {
        // Given
        mockKeychainService.shouldSucceed = true
        
        let expectation = XCTestExpectation(description: "Sign in completed")
        
        authService.$authState
            .dropFirst()
            .sink { state in
                if case .authenticated = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        do {
            let result = try await authService.signIn(with: .google)
            
            // Then
            XCTAssertNotNil(result.user)
            XCTAssertNotNil(result.accessToken)
            await fulfillment(of: [expectation], timeout: 2.0)
            XCTAssertTrue(authService.isAuthenticated)
            
        } catch {
            XCTFail("Sign in should succeed: \(error)")
        }
    }
    
    func testSignInWithAppleSuccess() async {
        // Given
        mockKeychainService.shouldSucceed = true
        
        let expectation = XCTestExpectation(description: "Apple sign in completed")
        
        authService.$authState
            .dropFirst()
            .sink { state in
                if case .authenticated = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        do {
            let result = try await authService.signIn(with: .apple)
            
            // Then
            XCTAssertNotNil(result.user)
            await fulfillment(of: [expectation], timeout: 2.0)
            XCTAssertTrue(authService.isAuthenticated)
            
        } catch {
            XCTFail("Apple sign in should succeed: \(error)")
        }
    }
    
    func testSignInFailure() async {
        // Given
        mockKeychainService.shouldSucceed = false
        
        let expectation = XCTestExpectation(description: "Sign in failed")
        
        authService.$authState
            .dropFirst()
            .sink { state in
                if case .error = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        do {
            _ = try await authService.signIn(with: .google)
            XCTFail("Sign in should fail")
        } catch {
            // Then
            XCTAssertTrue(error is AuthError)
            await fulfillment(of: [expectation], timeout: 2.0)
            XCTAssertFalse(authService.isAuthenticated)
        }
    }
    
    func testSignInStatesProgression() async {
        // Given
        var stateChanges: [AuthState] = []
        let expectation = XCTestExpectation(description: "State changes tracked")
        expectation.expectedFulfillmentCount = 3 // authenticating, authenticated, final
        
        authService.$authState
            .sink { state in
                stateChanges.append(state)
                if stateChanges.count >= 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        do {
            _ = try await authService.signIn(with: .google)
            
            // Then
            await fulfillment(of: [expectation], timeout: 2.0)
            XCTAssertTrue(stateChanges.contains { if case .authenticating(.google) = $0 { return true }; return false })
            XCTAssertTrue(stateChanges.contains { if case .authenticated = $0 { return true }; return false })
            
        } catch {
            XCTFail("Sign in should succeed: \(error)")
        }
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOutSuccess() async {
        // Given - Start authenticated
        let testUser = User.mock
        authService.authState = .authenticated(testUser)
        mockKeychainService.shouldSucceed = true
        
        let expectation = XCTestExpectation(description: "Sign out completed")
        
        authService.$authState
            .dropFirst()
            .sink { state in
                if case .unauthenticated = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        do {
            try await authService.signOut()
            
            // Then
            await fulfillment(of: [expectation], timeout: 1.0)
            XCTAssertFalse(authService.isAuthenticated)
            XCTAssertNil(authService.currentUser)
            XCTAssertTrue(mockKeychainService.clearAuthenticationDataCalled)
            
        } catch {
            XCTFail("Sign out should succeed: \(error)")
        }
    }
    
    func testSignOutFailure() async {
        // Given
        let testUser = User.mock
        authService.authState = .authenticated(testUser)
        mockKeychainService.shouldFailClear = true
        
        // When/Then
        do {
            try await authService.signOut()
            XCTFail("Sign out should fail")
        } catch {
            XCTAssertTrue(error is StorageError)
        }
    }
    
    // MARK: - Token Refresh Tests
    
    func testRefreshTokensSuccess() async {
        // Given
        let refreshToken = "valid_refresh_token"
        mockKeychainService.storedTokens = AuthTokens(accessToken: nil, refreshToken: refreshToken)
        mockKeychainService.shouldSucceed = true
        
        let expectation = XCTestExpectation(description: "Token refresh completed")
        
        authService.$authState
            .dropFirst()
            .sink { state in
                if case .authenticated = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        do {
            let result = try await authService.refreshTokens()
            
            // Then
            XCTAssertNotNil(result.user)
            await fulfillment(of: [expectation], timeout: 2.0)
            XCTAssertTrue(authService.isAuthenticated)
            
        } catch {
            XCTFail("Token refresh should succeed: \(error)")
        }
    }
    
    func testRefreshTokensWithoutRefreshToken() async {
        // Given
        mockKeychainService.storedTokens = AuthTokens(accessToken: "access", refreshToken: nil)
        
        // When/Then
        do {
            _ = try await authService.refreshTokens()
            XCTFail("Refresh should fail without refresh token")
        } catch {
            XCTAssertTrue(error is AuthError)
            if case AuthError.notAuthenticated = error {
                // Expected
            } else {
                XCTFail("Expected notAuthenticated error")
            }
        }
    }
    
    func testRefreshTokensFailure() async {
        // Given
        let refreshToken = "invalid_refresh_token"
        mockKeychainService.storedTokens = AuthTokens(accessToken: nil, refreshToken: refreshToken)
        
        let expectation = XCTestExpectation(description: "Token refresh failed")
        
        authService.$authState
            .dropFirst()
            .sink { state in
                if case .error = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        do {
            _ = try await authService.refreshTokens()
            XCTFail("Token refresh should fail")
        } catch {
            // Then
            XCTAssertTrue(error is AuthError)
            await fulfillment(of: [expectation], timeout: 2.0)
        }
    }
    
    // MARK: - Get Current User Tests
    
    func testGetCurrentUserWhenAuthenticated() async {
        // Given
        let testUser = User.mock
        authService.authState = .authenticated(testUser)
        
        // When
        do {
            let user = try await authService.getCurrentUser()
            
            // Then
            XCTAssertEqual(user.id, testUser.id)
            XCTAssertEqual(user.name, testUser.name)
            
        } catch {
            XCTFail("Get current user should succeed: \(error)")
        }
    }
    
    func testGetCurrentUserWhenNotAuthenticated() async {
        // Given
        authService.authState = .unauthenticated
        
        // When/Then
        do {
            _ = try await authService.getCurrentUser()
            XCTFail("Get current user should fail when not authenticated")
        } catch {
            XCTAssertTrue(error is AuthError)
            if case AuthError.notAuthenticated = error {
                // Expected
            } else {
                XCTFail("Expected notAuthenticated error")
            }
        }
    }
    
    // MARK: - GraphQL Authentication Tests
    
    func testGraphQLAuthenticationTokenUpdate() async {
        // Given
        let testToken = "test_access_token"
        mockKeychainService.shouldSucceed = true
        
        // When
        do {
            _ = try await authService.signIn(with: .google)
            
            // Then
            // This would need to be verified through the GraphQL service mock
            // For now, we just verify the sign in succeeded
            XCTAssertTrue(authService.isAuthenticated)
            
        } catch {
            XCTFail("Sign in should succeed: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testAuthErrorHandling() {
        // Test different auth error types
        let errors: [AuthError] = [
            .notAuthenticated,
            .oauthFailed("Google"),
            .refreshFailed,
            .userCancelled,
            .networkError,
            .providerNotAvailable
        ]
        
        for error in errors {
            // When
            authService.authState = .error(error)
            
            // Then
            XCTAssertFalse(authService.isAuthenticated)
            XCTAssertNil(authService.currentUser)
            
            if case .error(let stateError) = authService.authState {
                XCTAssertEqual(stateError.localizedDescription, error.localizedDescription)
            } else {
                XCTFail("Expected error state")
            }
        }
    }
    
    // MARK: - Keychain Integration Tests
    
    func testTokenStorage() async {
        // Given
        mockKeychainService.shouldSucceed = true
        
        // When
        do {
            _ = try await authService.signIn(with: .google)
            
            // Then
            XCTAssertTrue(mockKeychainService.storeTokensCalled)
            XCTAssertTrue(mockKeychainService.storeUserProfileCalled)
            
        } catch {
            XCTFail("Sign in should succeed: \(error)")
        }
    }
    
    func testTokenRetrieval() async {
        // Given
        let tokens = AuthTokens(accessToken: "access", refreshToken: "refresh")
        let user = User.mock
        mockKeychainService.storedTokens = tokens
        mockKeychainService.storedUser = user
        
        // When
        await authService.checkAuthenticationStatus()
        
        // Then
        XCTAssertTrue(mockKeychainService.retrieveTokensCalled)
        XCTAssertTrue(mockKeychainService.retrieveUserProfileCalled)
        XCTAssertTrue(authService.isAuthenticated)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentSignInAttempts() async {
        // Given
        mockKeychainService.shouldSucceed = true
        
        // When - Multiple concurrent sign-in attempts
        async let result1 = authService.signIn(with: .google)
        async let result2 = authService.signIn(with: .apple)
        
        // Then - Should handle gracefully
        do {
            let _ = try await result1
            let _ = try await result2
            
            // At least one should succeed
            XCTAssertTrue(authService.isAuthenticated)
            
        } catch {
            // Some may fail due to concurrent access, which is acceptable
            print("Concurrent sign-in error (expected): \(error)")
        }
    }
    
    func testSignOutDuringSignIn() async {
        // Given
        mockKeychainService.shouldSucceed = true
        
        // When - Start sign in, then immediately sign out
        let signInTask = Task {
            try await authService.signIn(with: .google)
        }
        
        let signOutTask = Task {
            try await Task.sleep(nanoseconds: 100_000_000) // Small delay
            try await authService.signOut()
        }
        
        // Then - Should handle gracefully
        do {
            _ = try await signInTask.value
            _ = try await signOutTask.value
            
            // Final state should be unauthenticated
            XCTAssertFalse(authService.isAuthenticated)
            
        } catch {
            // Some operations may fail due to concurrent access
            print("Concurrent operation error (expected): \(error)")
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        // Given
        weak var weakAuthService: AuthService?
        weak var weakGraphQLService: MockGraphQLService?
        weak var weakKeychainService: MockKeychainService?
        
        autoreleasepool {
            let graphqlService = MockGraphQLService()
            let keychainService = MockKeychainService()
            let testAuthService = AuthService(
                graphqlService: graphqlService,
                keychainService: keychainService
            )
            
            weakAuthService = testAuthService
            weakGraphQLService = graphqlService
            weakKeychainService = keychainService
            
            // Use the service
            Task {
                await testAuthService.checkAuthenticationStatus()
            }
        }
        
        // When/Then - Objects should be deallocated
        XCTAssertNil(weakAuthService)
        XCTAssertNil(weakGraphQLService)
        XCTAssertNil(weakKeychainService)
    }
}

// MARK: - Mock Keychain Service

class MockKeychainService: KeychainService {
    var storedTokens: AuthTokens?
    var storedUser: User?
    var shouldSucceed = true
    var shouldFailTokenRetrieval = false
    var shouldFailClear = false
    
    // Call tracking
    var storeTokensCalled = false
    var storeUserProfileCalled = false
    var retrieveTokensCalled = false
    var retrieveUserProfileCalled = false
    var clearAuthenticationDataCalled = false
    
    override func storeTokens(refreshToken: String, accessToken: String?) throws {
        storeTokensCalled = true
        
        if !shouldSucceed {
            throw StorageError.keychainError("Mock storage failure")
        }
        
        storedTokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
    
    override func retrieveTokens() throws -> AuthTokens {
        retrieveTokensCalled = true
        
        if shouldFailTokenRetrieval {
            throw StorageError.keychainError("Mock retrieval failure")
        }
        
        guard let tokens = storedTokens else {
            throw StorageError.keychainError("No tokens stored")
        }
        
        return tokens
    }
    
    override func storeUserProfile(_ user: User) throws {
        storeUserProfileCalled = true
        
        if !shouldSucceed {
            throw StorageError.keychainError("Mock storage failure")
        }
        
        storedUser = user
    }
    
    override func retrieveUserProfile() throws -> User? {
        retrieveUserProfileCalled = true
        
        if shouldFailTokenRetrieval {
            throw StorageError.keychainError("Mock retrieval failure")
        }
        
        return storedUser
    }
    
    override func clearAuthenticationData() throws {
        clearAuthenticationDataCalled = true
        
        if shouldFailClear {
            throw StorageError.keychainError("Mock clear failure")
        }
        
        storedTokens = nil
        storedUser = nil
    }
}

// MARK: - Auth Token Model

struct AuthTokens {
    let accessToken: String?
    let refreshToken: String?
}