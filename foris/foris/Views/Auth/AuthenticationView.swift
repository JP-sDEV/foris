import SwiftUI

/// Root authentication view that manages authentication state
/// Shows sign-in screen when unauthenticated, main app when authenticated
struct AuthenticationView<AuthenticatedContent: View>: View {
    
    // MARK: - Properties
    
    @StateObject private var authViewModel = AuthViewModel()
    private let authenticatedContent: () -> AuthenticatedContent
    
    // MARK: - Initialization
    
    init(@ViewBuilder authenticatedContent: @escaping () -> AuthenticatedContent) {
        self.authenticatedContent = authenticatedContent
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                authenticatedContent()
                    .environmentObject(authViewModel)
                    .transition(.opacity.combined(with: .scale))
            } else {
                SignInView()
                    .environmentObject(authViewModel)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .onAppear {
            authViewModel.checkAuthenticationStatus()
        }
    }
}

// MARK: - Authentication State View

/// View that displays different content based on authentication state
struct AuthStateView<UnauthenticatedContent: View, AuthenticatedContent: View, LoadingContent: View>: View {
    
    // MARK: - Properties
    
    @ObservedObject var authViewModel: AuthViewModel
    private let unauthenticatedContent: () -> UnauthenticatedContent
    private let authenticatedContent: (User) -> AuthenticatedContent
    private let loadingContent: () -> LoadingContent
    
    // MARK: - Initialization
    
    init(
        authViewModel: AuthViewModel,
        @ViewBuilder unauthenticated: @escaping () -> UnauthenticatedContent,
        @ViewBuilder authenticated: @escaping (User) -> AuthenticatedContent,
        @ViewBuilder loading: @escaping () -> LoadingContent = { ProgressView("Loading...") }
    ) {
        self.authViewModel = authViewModel
        self.unauthenticatedContent = unauthenticated
        self.authenticatedContent = authenticated
        self.loadingContent = loading
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .unauthenticated:
                unauthenticatedContent()
                    .transition(.opacity)
                
            case .authenticated(let user):
                authenticatedContent(user)
                    .transition(.opacity.combined(with: .scale))
                
            case .authenticating, .refreshing:
                loadingContent()
                    .transition(.opacity)
                
            case .error:
                unauthenticatedContent()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.authState)
    }
}

// MARK: - Authentication Loading View

/// Loading view shown during authentication processes
struct AuthLoadingView: View {
    let message: String
    
    init(message: String = "Authenticating...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Authentication Error View

/// Error view shown when authentication fails
struct AuthErrorView: View {
    let error: AuthError
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .accessibilityLabel("Error icon")
            
            // Error message
            VStack(spacing: 8) {
                Text("Authentication Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let recoverySuggestion = error.recoverySuggestion {
                    Text(recoverySuggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            
            // Action buttons
            VStack(spacing: 12) {
                if error.shouldRetry {
                    Button("Try Again") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Authentication failed. \(error.localizedDescription)")
    }
}

// MARK: - Preview Provider

#Preview("Authentication View - Unauthenticated") {
    AuthenticationView {
        Text("Main App Content")
            .font(.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.green.opacity(0.1))
    }
}

#Preview("Authentication View - Authenticated") {
    let viewModel = AuthViewModel.mockAuthenticated()
    return AuthenticationView {
        Text("Main App Content")
            .font(.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.green.opacity(0.1))
    }
    .environmentObject(viewModel)
}

#Preview("Auth State View - Loading") {
    let viewModel = AuthViewModel.mockLoading()
    return AuthStateView(
        authViewModel: viewModel,
        unauthenticated: {
            Text("Sign In Required")
        },
        authenticated: { user in
            Text("Welcome, \(user.name)!")
        },
        loading: {
            AuthLoadingView(message: "Signing in with Google...")
        }
    )
}

#Preview("Auth Loading View") {
    AuthLoadingView(message: "Signing in with Apple...")
}

#Preview("Auth Error View") {
    AuthErrorView(
        error: .oauthFailed("Google"),
        onRetry: {},
        onDismiss: {}
    )
}

#Preview("Auth Error View - Dark Mode") {
    AuthErrorView(
        error: .tokenExpired,
        onRetry: {},
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}