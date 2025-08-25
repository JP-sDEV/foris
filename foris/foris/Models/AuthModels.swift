import Foundation

// MARK: - OAuth Provider

/// Supported OAuth providers for authentication
enum OAuthProvider: String, CaseIterable {
    case google = "google"
    case apple = "apple"
    
    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .apple:
            return "Apple"
        }
    }
    
    var iconName: String {
        switch self {
        case .google:
            return "globe" // Will be replaced with Google icon
        case .apple:
            return "applelogo"
        }
    }
}

// MARK: - Authentication Models

/// User model matching the GraphQL User type
struct User: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let email: String
    let bio: String?
    let avatarUrl: String?
    
    // Computed properties for UI
    var displayName: String {
        return name.isEmpty ? email : name
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
    
    var hasAvatar: Bool {
        return avatarUrl != nil && !avatarUrl!.isEmpty
    }
}

/// Authentication result containing user and tokens
struct AuthResult: Codable {
    let user: User
    let refreshToken: String
    let accessToken: String? // JWT access token (if provided separately)
    
    init(user: User, refreshToken: String, accessToken: String? = nil) {
        self.user = user
        self.refreshToken = refreshToken
        self.accessToken = accessToken
    }
}

/// OAuth credential information
struct OAuthCredential {
    let provider: OAuthProvider
    let providerUserId: String
    let idToken: String?
    let accessToken: String?
    let email: String
    let name: String
    
    /// Creates the input for the GraphQL createAuth mutation
    var createAuthInput: CreateAuthInput {
        return CreateAuthInput(
            email: email,
            idToken: idToken,
            name: name,
            provider: provider.rawValue,
            providerUserId: providerUserId
        )
    }
}

/// Input for creating authentication (matches GraphQL schema)
struct CreateAuthInput: Codable {
    let email: String
    let idToken: String?
    let name: String
    let provider: String
    let providerUserId: String
}

// MARK: - Authentication State

/// Current authentication state of the app
enum AuthState: Equatable {
    case unauthenticated
    case authenticating(OAuthProvider)
    case authenticated(User)
    case refreshing
    case error(AuthError)
    
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    var user: User? {
        if case .authenticated(let user) = self {
            return user
        }
        return nil
    }
    
    var isLoading: Bool {
        switch self {
        case .authenticating, .refreshing:
            return true
        default:
            return false
        }
    }
}

// MARK: - Keychain Keys

/// Keys used for storing authentication data in Keychain
enum KeychainKey: String {
    case refreshToken = "foris.auth.refreshToken"
    case accessToken = "foris.auth.accessToken"
    case userProfile = "foris.auth.userProfile"
    
    var key: String {
        return rawValue
    }
}

// MARK: - Authentication Events

/// Events that can occur during authentication flow
enum AuthEvent {
    case signInRequested(OAuthProvider)
    case signInSucceeded(AuthResult)
    case signInFailed(AuthError)
    case signOutRequested
    case signOutCompleted
    case tokenRefreshSucceeded(AuthResult)
    case tokenRefreshFailed(AuthError)
    case userProfileUpdated(User)
}

// MARK: - Mock Data for Testing

#if DEBUG
extension User {
    static let mock = User(
        id: "mock-user-id",
        name: "John Doe",
        email: "john.doe@example.com",
        bio: "Fitness enthusiast and challenge lover",
        avatarUrl: nil
    )
    
    static let mockWithAvatar = User(
        id: "mock-user-id-2",
        name: "Jane Smith",
        email: "jane.smith@example.com",
        bio: "Running coach and league organizer",
        avatarUrl: "https://example.com/avatar.jpg"
    )
}

extension AuthResult {
    static let mock = AuthResult(
        user: .mock,
        refreshToken: "mock-refresh-token",
        accessToken: "mock-access-token"
    )
}

extension OAuthCredential {
    static let mockGoogle = OAuthCredential(
        provider: .google,
        providerUserId: "google-user-123",
        idToken: "mock-google-id-token",
        accessToken: "mock-google-access-token",
        email: "john.doe@gmail.com",
        name: "John Doe"
    )
    
    static let mockApple = OAuthCredential(
        provider: .apple,
        providerUserId: "apple-user-456",
        idToken: "mock-apple-id-token",
        accessToken: nil,
        email: "jane.smith@icloud.com",
        name: "Jane Smith"
    )
}
#endif