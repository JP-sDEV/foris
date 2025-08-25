import Foundation

/// Generic API response wrapper that can contain any type of data
/// This model provides a consistent structure for all API responses from the backend
struct APIResponse<T: Codable>: Codable {
    /// The actual data payload from the API
    let data: T?
    
    /// Optional message from the server (success or error message)
    let message: String?
    
    /// Indicates whether the API request was successful
    let success: Bool
    
    /// HTTP status code from the response
    let statusCode: Int?
    
    /// Timestamp when the response was created (optional)
    let timestamp: Date?
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case data
        case message
        case success
        case statusCode = "status_code"
        case timestamp
    }
    
    // MARK: - Initializers
    
    /// Initialize with all parameters
    init(data: T?, message: String?, success: Bool, statusCode: Int? = nil, timestamp: Date? = nil) {
        self.data = data
        self.message = message
        self.success = success
        self.statusCode = statusCode
        self.timestamp = timestamp
    }
    
    /// Initialize for successful response with data
    init(data: T, message: String? = nil) {
        self.data = data
        self.message = message
        self.success = true
        self.statusCode = 200
        self.timestamp = Date()
    }
    
    /// Initialize for error response
    init(error: String, statusCode: Int = 400) {
        self.data = nil
        self.message = error
        self.success = false
        self.statusCode = statusCode
        self.timestamp = Date()
    }
}

// MARK: - Convenience Extensions

extension APIResponse {
    /// Returns true if the response contains valid data
    var hasData: Bool {
        return data != nil && success
    }
    
    /// Returns the error message if the response failed
    var errorMessage: String {
        return message ?? "Unknown error occurred"
    }
    
    /// Returns a user-friendly status description
    var statusDescription: String {
        if success {
            return message ?? "Request completed successfully"
        } else {
            return errorMessage
        }
    }
}

// MARK: - Custom Decoding

extension APIResponse {
    /// Custom decoder that handles various response formats from different APIs
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode data - it might be null/nil
        data = try container.decodeIfPresent(T.self, forKey: .data)
        
        // Decode message - might be null/nil
        message = try container.decodeIfPresent(String.self, forKey: .message)
        
        // Decode success - default to true if not present
        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? true
        
        // Decode status code - might not be present
        statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
        
        // Decode timestamp - handle different date formats
        if let timestampString = try container.decodeIfPresent(String.self, forKey: .timestamp) {
            let formatter = ISO8601DateFormatter()
            timestamp = formatter.date(from: timestampString)
        } else {
            timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
        }
    }
}

// MARK: - Debug Description

extension APIResponse: CustomStringConvertible where T: CustomStringConvertible {
    var description: String {
        return """
        APIResponse(
            success: \(success),
            statusCode: \(statusCode ?? -1),
            message: \(message ?? "nil"),
            data: \(data?.description ?? "nil"),
            timestamp: \(timestamp?.description ?? "nil")
        )
        """
    }
}