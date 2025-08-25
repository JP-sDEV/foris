import SwiftUI

/// Sign-in screen presenting OAuth provider options
/// Provides a clean, accessible interface for user authentication
struct SignInView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                // Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerView
                        
                        // Sign-in options
                        signInOptionsView
                        
                        // Footer
                        footerView
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Sign In Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
            
            if viewModel.shouldRetryCurrentError {
                Button("Retry") {
                    // Retry logic would go here
                    viewModel.dismissError()
                }
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                if let errorMessage = viewModel.currentErrorMessage {
                    Text(errorMessage)
                }
                
                if let recoverySuggestion = viewModel.currentRecoverySuggestion {
                    Text(recoverySuggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            viewModel.checkAuthenticationStatus()
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.1),
                Color.accentColor.opacity(0.05),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // App icon/logo
            Image(systemName: "figure.run")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.accentColor)
                .accessibilityLabel("Foris app icon")
            
            // App name
            Text("Foris")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Tagline
            Text("Your fitness journey starts here")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Foris. Your fitness journey starts here.")
    }
    
    // MARK: - Sign-In Options
    
    private var signInOptionsView: some View {
        VStack(spacing: 16) {
            // Title
            Text("Sign in to continue")
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            // Provider buttons
            VStack(spacing: 12) {
                ForEach(viewModel.availableProviders, id: \.rawValue) { provider in
                    SignInButton(
                        provider: provider,
                        isLoading: viewModel.isLoading,
                        isEnabled: viewModel.canSignIn && viewModel.isProviderAvailable(provider)
                    ) {
                        viewModel.signIn(with: provider)
                    }
                }
            }
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        VStack(spacing: 16) {
            // Privacy notice
            Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Loading indicator
            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    if case .authenticating(let provider) = viewModel.authState {
                        Text("Signing in with \(provider.displayName)...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Signing in, please wait")
            }
        }
    }
}

// MARK: - Sign-In Button

struct SignInButton: View {
    let provider: OAuthProvider
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Provider icon
                Image(systemName: provider.iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                // Button text
                Text("Continue with \(provider.displayName)")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                Spacer()
                
                // Loading indicator for this specific provider
                if isLoading && !isEnabled {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .accessibilityLabel("Sign in with \(provider.displayName)")
        .accessibilityAddTraits(isEnabled ? .isButton : [.isButton, .isNotEnabled])
    }
    
    // MARK: - Colors
    
    private var backgroundColor: Color {
        switch provider {
        case .apple:
            return Color.primary
        case .google:
            return Color.white
        }
    }
    
    private var textColor: Color {
        switch provider {
        case .apple:
            return Color.white
        case .google:
            return Color.black
        }
    }
    
    private var iconColor: Color {
        switch provider {
        case .apple:
            return Color.white
        case .google:
            return Color.black
        }
    }
    
    private var borderColor: Color {
        switch provider {
        case .apple:
            return Color.clear
        case .google:
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Preview Provider

#Preview("Default") {
    SignInView()
}

#Preview("Loading") {
    let viewModel = AuthViewModel.mockLoading(provider: .google)
    return SignInView()
        .environmentObject(viewModel)
}

#Preview("Error") {
    let viewModel = AuthViewModel.mockError(.oauthFailed("Google"))
    return SignInView()
        .environmentObject(viewModel)
}

#Preview("Dark Mode") {
    SignInView()
        .preferredColorScheme(.dark)
}

#Preview("iPad") {
    SignInView()
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}

#Preview("Accessibility Large Text") {
    SignInView()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}