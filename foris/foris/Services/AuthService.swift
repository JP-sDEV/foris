import Foundation
import Combine
import AuthenticationServices
import GoogleSignIn

/// Protocol defining authentication operations for the Foris app
protocol AuthServiceProtocol: ObservableObject {
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    var authState: AuthState { get }
    
    func signIn(with provider: OAuthProvider) async throws -> AuthResult
    func signOut() async throws
    func refreshTokens() async throws -> AuthResult
    func getCurrentUser() async throws -> User
    func checkAuthenticationStatus() async
}

/// Authentication service implementation handling OAuth flows and token management
/// Integrates with Google Sign-In, Apple Sign-In, and the GraphQL backend
@MainActor
final class AuthService: AuthServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = AuthService()
    
    // MARK: - Published Properties
    
    @Published var authState: AuthState = .unauthenticated
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?
    
    // MARK: - Private Properties
    
    private let graphqlService: GraphQLServiceProtocol
    private let keychainService: KeychainService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        graphqlService: GraphQLServiceProtocol = GraphQLService.shared,
        keychainService: KeychainService = KeychainService.shared
    ) {
        self.graphqlService = graphqlService
        self.keychainService = keychainService
        
        setupStateObservation()
        
        // Check for existing authentication on init
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    // MARK: - Private Setup
    
    private func setupStateObservation() {
        $authState
            .map { state in
                state.isAuthenticated
            }
            .assign(to: &$isAuthenticated)
        
        $authState
            .map { state in
                state.user
            }
            .assign(to: &$currentUser)
    }
    
    // MARK: - Authentication Status
    
    func checkAuthenticationStatus() async {
        do {
            // Check if we have stored tokens
            let tokens = try keychainService.retrieveTokens()
            
            guard let refreshToken = tokens.refreshToken else {
                authState = .unauthenticated
                return
            }
            
            // Try to get user profile from cache first
            if let cachedUser = try keychainService.retrieveUserProfile() {
                authState = .authenticated(cachedUser)
                
                // Update GraphQL service with any stored access token
                if let accessToken = tokens.accessToken {
                    updateGraphQLAuthentication(accessToken)
                }
                
                // Optionally refresh user data in background
                Task {
                    try? await refreshUserProfile()
                }
                return
            }
            
            // If no cached user, try to refresh tokens
            authState = .refreshing
            let authResult = try await performTokenRefresh(refreshToken: refreshToken)
            
            // Store updated user profile
            try keychainService.storeUserProfile(authResult.user)
            
            authState = .authenticated(authResult.user)
            
        } catch {
            // Clear any invalid stored data
            try? keychainService.clearAuthenticationData()
            authState = .unauthenticated
        }
    }
    
    // MARK: - Sign In
    
    func signIn(with provider: OAuthProvider) async throws -> AuthResult {
        authState = .authenticating(provider)
        
        do {
            let credential = try await performOAuthFlow(provider: provider)
            let authResult = try await authenticateWithBackend(credential: credential)
            
            // Store tokens and user profile
            try keychainService.storeTokens(
                refreshToken: authResult.refreshToken,
                accessToken: authResult.accessToken
            )
            try keychainService.storeUserProfile(authResult.user)
            
            // Update GraphQL service authentication
            updateGraphQLAuthentication(authResult.accessToken ?? authResult.refreshToken)
            
            authState = .authenticated(authResult.user)
            return authResult
            
        } catch {
            let authError = error as? AuthError ?? AuthError.oauthFailed(provider.displayName)
            authState = .error(authError)
            throw authError
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        do {
            // Clear stored authentication data
            try keychainService.clearAuthenticationData()
            
            // Clear GraphQL authentication
            updateGraphQLAuthentication(nil)
            
            // Sign out from OAuth providers
            await signOutFromProviders()
            
            authState = .unauthenticated
            
        } catch {
            throw StorageError.keychainError("Failed to clear authentication data")
        }
    }
    
    // MARK: - Token Refresh
    
    func refreshTokens() async throws -> AuthResult {
        guard let refreshToken = try keychainService.retrieveTokens().refreshToken else {
            throw AuthError.notAuthenticated
        }
        
        authState = .refreshing
        
        do {
            let authResult = try await performTokenRefresh(refreshToken: refreshToken)
            
            // Store updated tokens and user profile
            try keychainService.storeTokens(
                refreshToken: authResult.refreshToken,
                accessToken: authResult.accessToken
            )
            try keychainService.storeUserProfile(authResult.user)
            
            // Update GraphQL service authentication
            updateGraphQLAuthentication(authResult.accessToken ?? authResult.refreshToken)
            
            authState = .authenticated(authResult.user)
            return authResult
            
        } catch {
            let authError = error as? AuthError ?? AuthError.refreshFailed
            authState = .error(authError)
            throw authError
        }
    }
    
    // MARK: - User Profile
    
    func getCurrentUser() async throws -> User {
        // TODO: Implement GraphQL query to get current user
        // For now, return cached user or throw error
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        return user
    }
    
    private func refreshUserProfile() async throws {
        // TODO: Implement GraphQL query to refresh user profile
        // This would call the 'me' query and update the cached user
    }
    
    // MARK: - Private OAuth Methods
    
    private func performOAuthFlow(provider: OAuthProvider) async throws -> OAuthCredential {
        switch provider {
        case .google:
            return try await performGoogleSignIn()
        case .apple:
            return try await performAppleSignIn()
        }
    }
    
    private func performGoogleSignIn() async throws -> OAuthCredential {
        // TODO: Implement Google Sign-In flow
        // This requires GoogleSignIn SDK integration
        
        // For now, return mock credential for development
        #if DEBUG
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        return OAuthCredential.mockGoogle
        #else
        throw AuthError.providerNotAvailable
        #endif
    }
    
    private func performAppleSignIn() async throws -> OAuthCredential {
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate { result in
                continuation.resume(with: result)
            }
            
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
        }
    }
    
    private func authenticateWithBackend(credential: OAuthCredential) async throws -> AuthResult {
        // TODO: Implement GraphQL createAuth mutation
        // For now, return mock result for development
        
        #if DEBUG
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
        return AuthResult.mock
        #else
        throw AuthError.oauthFailed(credential.provider.displayName)
        #endif
    }
    
    private func performTokenRefresh(refreshToken: String) async throws -> AuthResult {
        // TODO: Implement GraphQL refreshToken mutation
        // For now, return mock result for development
        
        #if DEBUG
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
        return AuthResult.mock
        #else
        throw AuthError.refreshFailed
        #endif
    }
    
    private func signOutFromProviders() async {
        // Sign out from Google
        GIDSignIn.sharedInstance.signOut()
        
        // Apple Sign-In doesn't require explicit sign out
    }
    
    private func updateGraphQLAuthentication(_ token: String?) {
        if let graphqlService = graphqlService as? GraphQLService {
            graphqlService.setAuthenticationToken(token)
        }
    }
}

// MARK: - Apple Sign-In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private let completion: (Result<OAuthCredential, AuthError>) -> Void
    
    init(completion: @escaping (Result<OAuthCredential, AuthError>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion(.failure(.oauthFailed("Apple")))
            return
        }
        
        let userID = appleIDCredential.user
        let email = appleIDCredential.email ?? ""
        let fullName = appleIDCredential.fullName
        let name = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        var idToken: String?
        if let identityTokenData = appleIDCredential.identityToken {
            idToken = String(data: identityTokenData, encoding: .utf8)
        }
        
        let credential = OAuthCredential(
            provider: .apple,
            providerUserId: userID,
            idToken: idToken,
            accessToken: nil,
            email: email,
            name: name.isEmpty ? email : name
        )
        
        completion(.success(credential))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                completion(.failure(.userCancelled))
            case .unknown:
                completion(.failure(.oauthFailed("Apple")))
            case .invalidResponse:
                completion(.failure(.oauthFailed("Apple")))
            case .notHandled:
                completion(.failure(.providerNotAvailable))
            case .failed:
                completion(.failure(.oauthFailed("Apple")))
            @unknown default:
                completion(.failure(.oauthFailed("Apple")))
            }
        } else {
            completion(.failure(.oauthFailed("Apple")))
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
/// Mock authentication service for testing and previews
class MockAuthService: AuthServiceProtocol {
    @Published var authState: AuthState = .unauthenticated
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    var shouldFailSignIn = false
    var shouldFailRefresh = false
    var signInDelay: TimeInterval = 1.0
    
    func signIn(with provider: OAuthProvider) async throws -> AuthResult {
        authState = .authenticating(provider)
        
        try await Task.sleep(nanoseconds: UInt64(signInDelay * 1_000_000_000))
        
        if shouldFailSignIn {
            let error = AuthError.oauthFailed(provider.displayName)
            authState = .error(error)
            throw error
        }
        
        let result = AuthResult.mock
        authState = .authenticated(result.user)
        isAuthenticated = true
        currentUser = result.user
        
        return result
    }
    
    func signOut() async throws {
        authState = .unauthenticated
        isAuthenticated = false
        currentUser = nil
    }
    
    func refreshTokens() async throws -> AuthResult {
        authState = .refreshing
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if shouldFailRefresh {
            let error = AuthError.refreshFailed
            authState = .error(error)
            throw error
        }
        
        let result = AuthResult.mock
        authState = .authenticated(result.user)
        
        return result
    }
    
    func getCurrentUser() async throws -> User {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        return user
    }
    
    func checkAuthenticationStatus() async {
        // Mock implementation - can be configured for testing
        if isAuthenticated {
            authState = .authenticated(currentUser ?? User.mock)
        } else {
            authState = .unauthenticated
        }
    }
    
    // Test helpers
    func setAuthenticated(_ user: User) {
        authState = .authenticated(user)
        isAuthenticated = true
        currentUser = user
    }
    
    func setUnauthenticated() {
        authState = .unauthenticated
        isAuthenticated = false
        currentUser = nil
    }
}
#endif