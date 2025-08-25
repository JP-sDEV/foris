import Foundation

/// Model representing the response from the backend's "Hello World" endpoint
/// The NestJS backend returns a simple string, so this model handles that format
struct HelloResponse: Codable, Equatable {
    /// The hello message from the backend
    let message: String
    
    // MARK: - Initializers
    
    /// Initialize with a message
    init(message: String) {
        self.message = message
    }
    
    /// Initialize with default "Hello World!" message
    init() {
        self.message = "Hello World!"
    }
}

// MARK: - Custom Decoding

extension HelloResponse {
    /// Custom decoder to handle the backend's direct string response
    /// The NestJS backend returns just a string, not a JSON object
    init(from decoder: Decoder) throws {
        // Try to decode as a single string value first (direct string response)
        if let container = try? decoder.singleValueContainer() {
            if let stringValue = try? container.decode(String.self) {
                self.message = stringValue
                return
            }
        }
        
        // Fallback: try to decode as an object with a message property
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decode(String.self, forKey: .message)
    }
    
    /// Custom encoder to match the expected format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
    }
    
    private enum CodingKeys: String, CodingKey {
        case message
    }
}

// MARK: - Convenience Extensions

extension HelloResponse {
    /// Returns true if the response contains a valid message
    var isValid: Bool {
        return !message.isEmpty
    }
    
    /// Returns a formatted display message
    var displayMessage: String {
        return message.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns true if this is the default "Hello World!" message
    var isDefaultMessage: Bool {
        return message == "Hello World!"
    }
}

// MARK: - Static Factory Methods

extension HelloResponse {
    /// Creates a HelloResponse from a raw string (for direct API string responses)
    static func fromString(_ string: String) -> HelloResponse {
        return HelloResponse(message: string)
    }
    
    /// Creates a default HelloResponse
    static func `default`() -> HelloResponse {
        return HelloResponse()
    }
    
    /// Creates a HelloResponse for testing purposes
    static func mock(message: String = "Mock Hello Response") -> HelloResponse {
        return HelloResponse(message: message)
    }
}

// MARK: - CustomStringConvertible

extension HelloResponse: CustomStringConvertible {
    var description: String {
        return "HelloResponse(message: \"\(message)\")"
    }
}

// MARK: - Hashable

extension HelloResponse: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(message)
    }
}