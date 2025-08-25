import Foundation

/// Comprehensive app error enum covering all possible error scenarios in Foris
/// Implements LocalizedError for user-friendly error messages
enum AppError: Error, LocalizedError, Equatable {
    case authentication(AuthError)
    case network(NetworkError)
    case graphql(GraphQLError)
    case validation(ValidationError)
    case storage(StorageError)
    case unknown(String?)
    
    // MARK: - LocalizedError Implementation
    
    var errorDescription: String? {
        switch self {
        case .authentication(let authError):
            return authError.errorDescription
        case .network(let networkError):
            return networkError.errorDescription
        case .graphql(let graphqlError):
            return graphqlError.errorDescription
        case .validation(let validationError):
            return validationError.errorDescription
        case .storage(let storageError):
            return storageError.errorDescription
        case .unknown(let message):
            return message ?? NSLocalizedString("An unknown error occurred", comment: "Unknown error")
        }
    }
    
    var failureReason: String? {
        switch self {
        case .authentication(let authError):
            return authError.failureReason
        case .network(let networkError):
            return networkError.failureReason
        case .graphql(let graphqlError):
            return graphqlError.failureReason
        case .validation(let validationError):
            return validationError.failureReason
        case .storage(let storageError):
            return storageError.failureReason
        case .unknown:
            return NSLocalizedString("An unexpected error occurred", comment: "Unknown error failure reason")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authentication(let authError):
            return authError.recoverySuggestion
        case .network(let networkError):
            return networkError.recoverySuggestion
        case .graphql(let graphqlError):
            return graphqlError.recoverySuggestion
        case .validation(let validationError):
            return validationError.recoverySuggestion
        case .storage(let storageError):
            return storageError.recoverySuggestion
        case .unknown:
            return NSLocalizedString("Please try again or contact support", comment: "Unknown error recovery suggestion")
        }
    }
    
    // MARK: - Convenience Properties
    
    /// Returns true if this error suggests the user should retry
    var shouldRetry: Bool {
        switch self {
        case .network(let networkError):
            return networkError.shouldRetry
        case .graphql(let graphqlError):
            return graphqlError.shouldRetry
        case .authentication(let authError):
            return authError.shouldRetry
        case .storage(let storageError):
            return storageError.shouldRetry
        default:
            return false
        }
    }
    
    /// Returns true if this error requires user authentication
    var requiresAuthentication: Bool {
        switch self {
        case .authentication:
            return true
        case .network(let networkError):
            return networkError == .unauthorized
        case .graphql(let graphqlError):
            return graphqlError == .authenticationRequired
        default:
            return false
        }
    }
    
    /// Returns the severity level of the error
    var severity: ErrorSeverity {
        switch self {
        case .authentication:
            return .high
        case .network(let networkError):
            return networkError.isServerError ? .high : .medium
        case .graphql:
            return .medium
        case .validation:
            return .low
        case .storage:
            return .medium
        case .unknown:
            return .high
        }
    }
}

// MARK: - Error Severity

enum ErrorSeverity {
    case low    // User input validation, minor issues
    case medium // Network issues, recoverable errors
    case high   // Authentication, server errors, critical failures
}

// MARK: - Authentication Errors

enum AuthError: Error, LocalizedError {
    case notAuthenticated
    case tokenExpired
    case tokenInvalid
    case refreshFailed
    case oauthFailed(String)
    case keychainError(String)
    case userCancelled
    case providerNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return NSLocalizedString("Not authenticated", comment: "Not authenticated error")
        case .tokenExpired:
            return NSLocalizedString("Session expired", comment: "Token expired error")
        case .tokenInvalid:
            return NSLocalizedString("Invalid authentication", comment: "Token invalid error")
        case .refreshFailed:
            return NSLocalizedString("Failed to refresh session", comment: "Refresh failed error")
        case .oauthFailed(let provider):
            return NSLocalizedString("Failed to sign in with \(provider)", comment: "OAuth failed error")
        case .keychainError(let message):
            return NSLocalizedString("Keychain error: \(message)", comment: "Keychain error")
        case .userCancelled:
            return NSLocalizedString("Sign in cancelled", comment: "User cancelled error")
        case .providerNotAvailable:
            return NSLocalizedString("Sign in provider not available", comment: "Provider not available error")
        }
    }
    
    var failureReason: String? {
        switch self {
        case .notAuthenticated:
            return NSLocalizedString("You are not signed in", comment: "Not authenticated failure reason")
        case .tokenExpired:
            return NSLocalizedString("Your session has expired", comment: "Token expired failure reason")
        case .tokenInvalid:
            return NSLocalizedString("Your authentication is no longer valid", comment: "Token invalid failure reason")
        case .refreshFailed:
            return NSLocalizedString("Unable to refresh your session", comment: "Refresh failed failure reason")
        case .oauthFailed:
            return NSLocalizedString("The sign in process failed", comment: "OAuth failed failure reason")
        case .keychainError:
            return NSLocalizedString("Unable to access secure storage", comment: "Keychain error failure reason")
        case .userCancelled:
            return NSLocalizedString("You cancelled the sign in process", comment: "User cancelled failure reason")
        case .providerNotAvailable:
            return NSLocalizedString("The selected sign in method is not available", comment: "Provider not available failure reason")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated, .tokenExpired, .tokenInvalid, .refreshFailed:
            return NSLocalizedString("Please sign in again", comment: "Auth error recovery suggestion")
        case .oauthFailed:
            return NSLocalizedString("Please try signing in again or use a different method", comment: "OAuth failed recovery suggestion")
        case .keychainError:
            return NSLocalizedString("Please restart the app and try again", comment: "Keychain error recovery suggestion")
        case .userCancelled:
            return NSLocalizedString("Please try signing in again", comment: "User cancelled recovery suggestion")
        case .providerNotAvailable:
            return NSLocalizedString("Please try a different sign in method", comment: "Provider not available recovery suggestion")
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .refreshFailed, .oauthFailed, .keychainError:
            return true
        default:
            return false
        }
    }
}

// MARK: - Validation Errors

enum ValidationError: Error, LocalizedError {
    case required(String)
    case invalidFormat(String)
    case tooShort(String, Int)
    case tooLong(String, Int)
    case invalidEmail
    case invalidURL
    case custom(String)
    case invalid(String)
    case unsupportedAction
    
    var errorDescription: String? {
        switch self {
        case .required(let field):
            return NSLocalizedString("\(field) is required", comment: "Required field error")
        case .invalidFormat(let field):
            return NSLocalizedString("\(field) format is invalid", comment: "Invalid format error")
        case .tooShort(let field, let minLength):
            return NSLocalizedString("\(field) must be at least \(minLength) characters", comment: "Too short error")
        case .tooLong(let field, let maxLength):
            return NSLocalizedString("\(field) must be no more than \(maxLength) characters", comment: "Too long error")
        case .invalidEmail:
            return NSLocalizedString("Please enter a valid email address", comment: "Invalid email error")
        case .invalidURL:
            return NSLocalizedString("Please enter a valid URL", comment: "Invalid URL error")
        case .custom(let message):
            return message
        case .invalid(let message):
            return message
        case .unsupportedAction:
            return NSLocalizedString("This action is not supported", comment: "Unsupported action error")
        }
    }
    
    var failureReason: String? {
        return NSLocalizedString("The input provided is not valid", comment: "Validation error failure reason")
    }
    
    var recoverySuggestion: String? {
        return NSLocalizedString("Please correct the input and try again", comment: "Validation error recovery suggestion")
    }
    
    var shouldRetry: Bool {
        return false // Validation errors require user input correction
    }
}

// MARK: - Storage Errors

enum StorageError: Error, LocalizedError {
    case coreDataError(String)
    case keychainError(String)
    case fileSystemError(String)
    case cacheFull
    case migrationFailed
    case corruptedData
    
    var errorDescription: String? {
        switch self {
        case .coreDataError(let message):
            return NSLocalizedString("Database error: \(message)", comment: "Core Data error")
        case .keychainError(let message):
            return NSLocalizedString("Secure storage error: \(message)", comment: "Keychain error")
        case .fileSystemError(let message):
            return NSLocalizedString("File system error: \(message)", comment: "File system error")
        case .cacheFull:
            return NSLocalizedString("Storage is full", comment: "Cache full error")
        case .migrationFailed:
            return NSLocalizedString("Data migration failed", comment: "Migration failed error")
        case .corruptedData:
            return NSLocalizedString("Data is corrupted", comment: "Corrupted data error")
        }
    }
    
    var failureReason: String? {
        switch self {
        case .coreDataError, .keychainError, .fileSystemError:
            return NSLocalizedString("Unable to access local storage", comment: "Storage error failure reason")
        case .cacheFull:
            return NSLocalizedString("Device storage is full", comment: "Cache full failure reason")
        case .migrationFailed:
            return NSLocalizedString("Unable to update app data", comment: "Migration failed failure reason")
        case .corruptedData:
            return NSLocalizedString("App data is corrupted", comment: "Corrupted data failure reason")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .coreDataError, .keychainError, .fileSystemError:
            return NSLocalizedString("Please restart the app and try again", comment: "Storage error recovery suggestion")
        case .cacheFull:
            return NSLocalizedString("Please free up storage space on your device", comment: "Cache full recovery suggestion")
        case .migrationFailed:
            return NSLocalizedString("Please update the app or contact support", comment: "Migration failed recovery suggestion")
        case .corruptedData:
            return NSLocalizedString("Please reinstall the app or contact support", comment: "Corrupted data recovery suggestion")
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .coreDataError, .keychainError, .fileSystemError:
            return true
        default:
            return false
        }
    }
}

// MARK: - Equatable Implementation

extension AppError {
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.authentication(let lhsAuth), .authentication(let rhsAuth)):
            return lhsAuth == rhsAuth
        case (.network(let lhsNetwork), .network(let rhsNetwork)):
            return lhsNetwork == rhsNetwork
        case (.graphql(let lhsGraphQL), .graphql(let rhsGraphQL)):
            return lhsGraphQL == rhsGraphQL
        case (.validation(let lhsValidation), .validation(let rhsValidation)):
            return lhsValidation == rhsValidation
        case (.storage(let lhsStorage), .storage(let rhsStorage)):
            return lhsStorage == rhsStorage
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

extension AuthError: Equatable {
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated),
             (.tokenExpired, .tokenExpired),
             (.tokenInvalid, .tokenInvalid),
             (.refreshFailed, .refreshFailed),
             (.userCancelled, .userCancelled),
             (.providerNotAvailable, .providerNotAvailable):
            return true
        case (.oauthFailed(let lhsProvider), .oauthFailed(let rhsProvider)):
            return lhsProvider == rhsProvider
        case (.keychainError(let lhsMessage), .keychainError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

extension ValidationError: Equatable {
    static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.required(let lhsField), .required(let rhsField)):
            return lhsField == rhsField
        case (.invalidFormat(let lhsField), .invalidFormat(let rhsField)):
            return lhsField == rhsField
        case (.tooShort(let lhsField, let lhsLength), .tooShort(let rhsField, let rhsLength)):
            return lhsField == rhsField && lhsLength == rhsLength
        case (.tooLong(let lhsField, let lhsLength), .tooLong(let rhsField, let rhsLength)):
            return lhsField == rhsField && lhsLength == rhsLength
        case (.invalidEmail, .invalidEmail),
             (.invalidURL, .invalidURL):
            return true
        case (.custom(let lhsMessage), .custom(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

extension StorageError: Equatable {
    static func == (lhs: StorageError, rhs: StorageError) -> Bool {
        switch (lhs, rhs) {
        case (.coreDataError(let lhsMessage), .coreDataError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.keychainError(let lhsMessage), .keychainError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.fileSystemError(let lhsMessage), .fileSystemError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.cacheFull, .cacheFull),
             (.migrationFailed, .migrationFailed),
             (.corruptedData, .corruptedData):
            return true
        default:
            return false
        }
    }
}

// MARK: - GraphQLError Extension

extension GraphQLError: Equatable {
    static func == (lhs: GraphQLError, rhs: GraphQLError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.queryFailed(let lhsMessage), .queryFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.mutationFailed(let lhsMessage), .mutationFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.subscriptionFailed(let lhsMessage), .subscriptionFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.serverError(let lhsMessage), .serverError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.noData, .noData),
             (.invalidResponse, .invalidResponse),
             (.authenticationRequired, .authenticationRequired),
             (.rateLimited, .rateLimited):
            return true
        default:
            return false
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .networkError, .rateLimited, .serverError:
            return true
        case .authenticationRequired:
            return false
        default:
            return true
        }
    }
}