import Foundation

/// Comprehensive network error enum covering all possible network failure scenarios
/// Implements LocalizedError for user-friendly error messages
enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case noData
    case decodingError(String)
    case encodingError(String)
    case networkUnavailable
    case serverError(Int)
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case tooManyRequests
    case internalServerError
    case badGateway
    case serviceUnavailable
    case unknown(Error?)
    
    // MARK: - LocalizedError Implementation
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Invalid URL", comment: "Invalid URL error")
        case .noData:
            return NSLocalizedString("No data received", comment: "No data error")
        case .decodingError(let details):
            return NSLocalizedString("Failed to decode response: \(details)", comment: "Decoding error")
        case .encodingError(let details):
            return NSLocalizedString("Failed to encode request: \(details)", comment: "Encoding error")
        case .networkUnavailable:
            return NSLocalizedString("Network unavailable", comment: "Network unavailable error")
        case .serverError(let code):
            return NSLocalizedString("Server error (Code: \(code))", comment: "Server error")
        case .timeout:
            return NSLocalizedString("Request timed out", comment: "Timeout error")
        case .unauthorized:
            return NSLocalizedString("Unauthorized access", comment: "Unauthorized error")
        case .forbidden:
            return NSLocalizedString("Access forbidden", comment: "Forbidden error")
        case .notFound:
            return NSLocalizedString("Resource not found", comment: "Not found error")
        case .tooManyRequests:
            return NSLocalizedString("Too many requests", comment: "Rate limit error")
        case .internalServerError:
            return NSLocalizedString("Internal server error", comment: "Internal server error")
        case .badGateway:
            return NSLocalizedString("Bad gateway", comment: "Bad gateway error")
        case .serviceUnavailable:
            return NSLocalizedString("Service unavailable", comment: "Service unavailable error")
        case .unknown(let error):
            if let error = error {
                return NSLocalizedString("Unknown error: \(error.localizedDescription)", comment: "Unknown error with details")
            } else {
                return NSLocalizedString("Unknown error occurred", comment: "Unknown error")
            }
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("The URL provided is not valid", comment: "Invalid URL failure reason")
        case .noData:
            return NSLocalizedString("The server did not return any data", comment: "No data failure reason")
        case .decodingError:
            return NSLocalizedString("The response data could not be parsed", comment: "Decoding failure reason")
        case .encodingError:
            return NSLocalizedString("The request data could not be encoded", comment: "Encoding failure reason")
        case .networkUnavailable:
            return NSLocalizedString("No internet connection is available", comment: "Network unavailable failure reason")
        case .serverError:
            return NSLocalizedString("The server encountered an error", comment: "Server error failure reason")
        case .timeout:
            return NSLocalizedString("The request took too long to complete", comment: "Timeout failure reason")
        case .unauthorized:
            return NSLocalizedString("Authentication is required", comment: "Unauthorized failure reason")
        case .forbidden:
            return NSLocalizedString("You don't have permission to access this resource", comment: "Forbidden failure reason")
        case .notFound:
            return NSLocalizedString("The requested resource was not found", comment: "Not found failure reason")
        case .tooManyRequests:
            return NSLocalizedString("You have made too many requests in a short time", comment: "Rate limit failure reason")
        case .internalServerError:
            return NSLocalizedString("The server is experiencing technical difficulties", comment: "Internal server error failure reason")
        case .badGateway:
            return NSLocalizedString("The server received an invalid response", comment: "Bad gateway failure reason")
        case .serviceUnavailable:
            return NSLocalizedString("The service is temporarily unavailable", comment: "Service unavailable failure reason")
        case .unknown:
            return NSLocalizedString("An unexpected error occurred", comment: "Unknown error failure reason")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Please check the URL and try again", comment: "Invalid URL recovery suggestion")
        case .noData:
            return NSLocalizedString("Please try again later", comment: "No data recovery suggestion")
        case .decodingError, .encodingError:
            return NSLocalizedString("Please contact support if this problem persists", comment: "Coding error recovery suggestion")
        case .networkUnavailable:
            return NSLocalizedString("Please check your internet connection and try again", comment: "Network unavailable recovery suggestion")
        case .serverError, .internalServerError, .badGateway:
            return NSLocalizedString("Please try again later or contact support", comment: "Server error recovery suggestion")
        case .timeout:
            return NSLocalizedString("Please check your connection and try again", comment: "Timeout recovery suggestion")
        case .unauthorized:
            return NSLocalizedString("Please log in and try again", comment: "Unauthorized recovery suggestion")
        case .forbidden:
            return NSLocalizedString("Please contact support for access", comment: "Forbidden recovery suggestion")
        case .notFound:
            return NSLocalizedString("Please check the URL or try again later", comment: "Not found recovery suggestion")
        case .tooManyRequests:
            return NSLocalizedString("Please wait a moment before trying again", comment: "Rate limit recovery suggestion")
        case .serviceUnavailable:
            return NSLocalizedString("Please try again in a few minutes", comment: "Service unavailable recovery suggestion")
        case .unknown:
            return NSLocalizedString("Please try again or contact support", comment: "Unknown error recovery suggestion")
        }
    }
}

// MARK: - Static Factory Methods

extension NetworkError {
    /// Creates a NetworkError from an HTTP status code
    static func fromHTTPStatusCode(_ statusCode: Int) -> NetworkError {
        switch statusCode {
        case 400...499:
            switch statusCode {
            case 401:
                return .unauthorized
            case 403:
                return .forbidden
            case 404:
                return .notFound
            case 429:
                return .tooManyRequests
            default:
                return .serverError(statusCode)
            }
        case 500...599:
            switch statusCode {
            case 500:
                return .internalServerError
            case 502:
                return .badGateway
            case 503:
                return .serviceUnavailable
            default:
                return .serverError(statusCode)
            }
        default:
            return .serverError(statusCode)
        }
    }
    
    /// Creates a NetworkError from a URLError
    static func fromURLError(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .badURL, .unsupportedURL:
            return .invalidURL
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .badServerResponse:
            return .serverError(0)
        default:
            return .unknown(urlError)
        }
    }
    
    /// Creates a NetworkError from a generic Error
    static func fromError(_ error: Error) -> NetworkError {
        if let urlError = error as? URLError {
            return fromURLError(urlError)
        } else if let networkError = error as? NetworkError {
            return networkError
        } else {
            return .unknown(error)
        }
    }
}

// MARK: - Convenience Properties

extension NetworkError {
    /// Returns true if this is a client-side error (4xx)
    var isClientError: Bool {
        switch self {
        case .unauthorized, .forbidden, .notFound, .tooManyRequests:
            return true
        case .serverError(let code):
            return code >= 400 && code < 500
        default:
            return false
        }
    }
    
    /// Returns true if this is a server-side error (5xx)
    var isServerError: Bool {
        switch self {
        case .internalServerError, .badGateway, .serviceUnavailable:
            return true
        case .serverError(let code):
            return code >= 500 && code < 600
        default:
            return false
        }
    }
    
    /// Returns true if this error suggests the user should retry
    var shouldRetry: Bool {
        switch self {
        case .timeout, .networkUnavailable, .serviceUnavailable, .badGateway:
            return true
        case .serverError(let code):
            return code >= 500
        default:
            return false
        }
    }
    
    /// Returns the HTTP status code if available
    var statusCode: Int? {
        switch self {
        case .serverError(let code):
            return code
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .tooManyRequests:
            return 429
        case .internalServerError:
            return 500
        case .badGateway:
            return 502
        case .serviceUnavailable:
            return 503
        default:
            return nil
        }
    }
}

// MARK: - Equatable Implementation

extension NetworkError {
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noData, .noData),
             (.networkUnavailable, .networkUnavailable),
             (.timeout, .timeout),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.tooManyRequests, .tooManyRequests),
             (.internalServerError, .internalServerError),
             (.badGateway, .badGateway),
             (.serviceUnavailable, .serviceUnavailable):
            return true
        case (.decodingError(let lhsDetails), .decodingError(let rhsDetails)):
            return lhsDetails == rhsDetails
        case (.encodingError(let lhsDetails), .encodingError(let rhsDetails)):
            return lhsDetails == rhsDetails
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError?.localizedDescription == rhsError?.localizedDescription
        default:
            return false
        }
    }
}