import Foundation
import Combine

/// ViewModel for authentication screens and flows
/// Manages authentication state and user interactions
@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var authState: AuthState = .unauthenticated
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isAuthenticated: Bool {
        authState.isAuthenticated
    }
    
    var currentUser: User? {
        authState.user
    }
    
    var canSignIn: Bool {
        !isLoading && !isAuthenticated
    }
    
    var availableProviders: [OAuthProvider] {
        return OAuthProvider.allCases
    }
    
    // MARK: - Initialization
    
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
        setupBindings()
    }
    
    // MARK: - Private Setup
    
    private func setupBindings() {
        // Bind auth service state to local state
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$authState)
        
        // Update loading state based on auth state
        $authState
            .map { state in
                state.isLoading
            }
            .assign(to: &$isLoading)
        
        // Handle error states
        $authState
            .compactMap { state -> String? in
                if case .error(let error) = state {
                    return error.localizedDescription
                }
                return nil
            }
            .sink { [weak self] errorMessage in
                self?.showError(errorMessage)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Actions
    
    /// Initiates sign-in flow with the specified provider
    /// - Parameter provider: OAuth provider to use for authentication
    func signIn(with provider: OAuthProvider) {
        guard canSignIn else { return }
        
        Task {
            do {
                _ = try await authService.signIn(with: provider)
                // Success is handled by state binding
            } catch {
                // Error is handled by state binding
                print("Sign-in failed: \(error)")
            }
        }
    }
    
    /// Signs out the current user
    func signOut() {
        Task {
            do {
                try await authService.signOut()
                // Success is handled by state binding
            } catch {
                showError("Failed to sign out: \(error.localizedDescription)")
            }
        }
    }
    
    /// Refreshes authentication tokens
    func refreshAuthentication() {
        Task {
            do {
                _ = try await authService.refreshTokens()
                // Success is handled by state binding
            } catch {
                // Error is handled by state binding
                print("Token refresh failed: \(error)")
            }
        }
    }
    
    /// Checks current authentication status
    func checkAuthenticationStatus() {
        Task {
            await authService.checkAuthenticationStatus()
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    /// Dismisses the current error
    func dismissError() {
        showError = false
        errorMessage = nil
    }
    
    // MARK: - Helper Methods
    
    /// Returns the display name for a provider
    /// - Parameter provider: OAuth provider
    /// - Returns: User-friendly display name
    func displayName(for provider: OAuthProvider) -> String {
        return provider.displayName
    }
    
    /// Returns the icon name for a provider
    /// - Parameter provider: OAuth provider
    /// - Returns: SF Symbol name for the provider icon
    func iconName(for provider: OAuthProvider) -> String {
        return provider.iconName
    }
    
    /// Returns whether a specific provider is available
    /// - Parameter provider: OAuth provider to check
    /// - Returns: True if the provider is available on this device
    func isProviderAvailable(_ provider: OAuthProvider) -> Bool {
        switch provider {
        case .apple:
            // Apple Sign-In is available on iOS 13+
            return true
        case .google:
            // Google Sign-In availability would be checked here
            // For now, assume it's available
            return true
        }
    }
    
    /// Returns a user-friendly error message for the current state
    var currentErrorMessage: String? {
        if case .error(let error) = authState {
            return error.localizedDescription
        }
        return nil
    }
    
    /// Returns recovery suggestion for the current error
    var currentRecoverySuggestion: String? {
        if case .error(let error) = authState {
            return error.recoverySuggestion
        }
        return nil
    }
    
    /// Returns whether the current error suggests retry
    var shouldRetryCurrentError: Bool {
        if case .error(let error) = authState {
            return error.shouldRetry
        }
        return false
    }
}

// MARK: - AuthService Publisher Extension

extension AuthServiceProtocol {
    var authStatePublisher: AnyPublisher<AuthState, Never> {
        if let authService = self as? AuthService {
            return authService.$authState.eraseToAnyPublisher()
        } else if let mockService = self as? MockAuthService {
            return mockService.$authState.eraseToAnyPublisher()
        } else {
            // Fallback for other implementations
            return Just(.unauthenticated).eraseToAnyPublisher()
        }
    }
}

// MARK: - Mock ViewModel for Testing

#if DEBUG
extension AuthViewModel {
    /// Creates a mock AuthViewModel for testing and previews
    /// - Parameters:
    ///   - authState: Initial authentication state
    ///   - isLoading: Whether the view model should show loading state
    /// - Returns: Configured mock AuthViewModel
    static func mock(
        authState: AuthState = .unauthenticated,
        isLoading: Bool = false
    ) -> AuthViewModel {
        let mockService = MockAuthService()
        mockService.authState = authState
        
        let viewModel = AuthViewModel(authService: mockService)
        viewModel.isLoading = isLoading
        
        return viewModel
    }
    
    /// Creates a mock AuthViewModel in authenticated state
    /// - Parameter user: User to authenticate with
    /// - Returns: Configured mock AuthViewModel
    static func mockAuthenticated(user: User = .mock) -> AuthViewModel {
        return mock(authState: .authenticated(user))
    }
    
    /// Creates a mock AuthViewModel in loading state
    /// - Parameter provider: Provider being used for authentication
    /// - Returns: Configured mock AuthViewModel
    static func mockLoading(provider: OAuthProvider = .google) -> AuthViewModel {
        return mock(authState: .authenticating(provider), isLoading: true)
    }
    
    /// Creates a mock AuthViewModel in error state
    /// - Parameter error: Authentication error to display
    /// - Returns: Configured mock AuthViewModel
    static func mockError(_ error: AuthError = .oauthFailed("Google")) -> AuthViewModel {
        return mock(authState: .error(error))
    }
}
#endif