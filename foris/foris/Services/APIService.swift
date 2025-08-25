import Foundation

/// Centralized service for all API communications with the NestJS backend
/// Provides async/await methods for API calls with proper error handling
final class APIService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = APIService()
    
    // MARK: - Properties
    
    private let networkManager: NetworkManager
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    
    // MARK: - Initialization
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
        
        // Configure JSON decoder
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
        
        // Configure JSON encoder
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Hello World Endpoint
    
    /// Fetches the hello message from the backend
    /// - Returns: HelloResponse containing the message
    /// - Throws: NetworkError if the request fails
    func getHello() async throws -> HelloResponse {
        let request = try networkManager.createRequest(endpoint: "/", method: .GET)
        let data = try await networkManager.performRequest(request)
        
        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 Raw API Response: '\(responseString)'")
            print("🔍 Response Data Length: \(data.count) bytes")
        }
        
        do {
            // Try to decode as HelloResponse first
            let response = try jsonDecoder.decode(HelloResponse.self, from: data)
            print("✅ Successfully decoded as HelloResponse: \(response.message)")
            return response
        } catch {
            print("⚠️ JSON decode failed: \(error)")
            // If that fails, try to decode as a direct string
            if let responseString = String(data: data, encoding: .utf8) {
                // Remove quotes if present (JSON string format)
                let cleanString = responseString.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                print("✅ Using direct string: '\(cleanString)'")
                return HelloResponse(message: cleanString)
            }
            throw NetworkError.decodingError("Failed to decode hello response: \(error.localizedDescription)")
        }
    }
    
    /// Fetches the hello message with completion handler
    /// - Parameter completion: Completion handler with Result<HelloResponse, NetworkError>
    func getHello(completion: @escaping (Result<HelloResponse, NetworkError>) -> Void) {
        Task {
            do {
                let response = try await getHello()
                await MainActor.run {
                    completion(.success(response))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(NetworkError.fromError(error)))
                }
            }
        }
    }
    
    // MARK: - Generic API Methods
    
    /// Performs a GET request to the specified endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - responseType: Type to decode the response to
    /// - Returns: Decoded response of the specified type
    /// - Throws: NetworkError if the request fails
    func get<T: Codable>(_ endpoint: String, responseType: T.Type) async throws -> T {
        let request = try networkManager.createRequest(endpoint: endpoint, method: .GET)
        let data = try await networkManager.performRequest(request)
        
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError("Failed to decode \(T.self): \(error.localizedDescription)")
        }
    }
    
    /// Performs a POST request to the specified endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - body: Request body object to encode
    ///   - responseType: Type to decode the response to
    /// - Returns: Decoded response of the specified type
    /// - Throws: NetworkError if the request fails
    func post<T: Codable, U: Codable>(_ endpoint: String, body: T, responseType: U.Type) async throws -> U {
        let bodyData: Data
        do {
            bodyData = try jsonEncoder.encode(body)
        } catch {
            throw NetworkError.encodingError("Failed to encode request body: \(error.localizedDescription)")
        }
        
        let request = try networkManager.createRequest(endpoint: endpoint, method: .POST, body: bodyData)
        let data = try await networkManager.performRequest(request)
        
        do {
            return try jsonDecoder.decode(U.self, from: data)
        } catch {
            throw NetworkError.decodingError("Failed to decode \(U.self): \(error.localizedDescription)")
        }
    }
    
    /// Performs a PUT request to the specified endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - body: Request body object to encode
    ///   - responseType: Type to decode the response to
    /// - Returns: Decoded response of the specified type
    /// - Throws: NetworkError if the request fails
    func put<T: Codable, U: Codable>(_ endpoint: String, body: T, responseType: U.Type) async throws -> U {
        let bodyData: Data
        do {
            bodyData = try jsonEncoder.encode(body)
        } catch {
            throw NetworkError.encodingError("Failed to encode request body: \(error.localizedDescription)")
        }
        
        let request = try networkManager.createRequest(endpoint: endpoint, method: .PUT, body: bodyData)
        let data = try await networkManager.performRequest(request)
        
        do {
            return try jsonDecoder.decode(U.self, from: data)
        } catch {
            throw NetworkError.decodingError("Failed to decode \(U.self): \(error.localizedDescription)")
        }
    }
    
    /// Performs a DELETE request to the specified endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - responseType: Type to decode the response to
    /// - Returns: Decoded response of the specified type
    /// - Throws: NetworkError if the request fails
    func delete<T: Codable>(_ endpoint: String, responseType: T.Type) async throws -> T {
        let request = try networkManager.createRequest(endpoint: endpoint, method: .DELETE)
        let data = try await networkManager.performRequest(request)
        
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError("Failed to decode \(T.self): \(error.localizedDescription)")
        }
    }
    
    // MARK: - APIResponse Wrapper Methods
    
    /// Performs a GET request expecting an APIResponse wrapper
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - dataType: Type of the data inside the APIResponse
    /// - Returns: APIResponse containing the decoded data
    /// - Throws: NetworkError if the request fails
    func getWrapped<T: Codable>(_ endpoint: String, dataType: T.Type) async throws -> APIResponse<T> {
        let request = try networkManager.createRequest(endpoint: endpoint, method: .GET)
        let data = try await networkManager.performRequest(request)
        
        do {
            return try jsonDecoder.decode(APIResponse<T>.self, from: data)
        } catch {
            throw NetworkError.decodingError("Failed to decode APIResponse<\(T.self)>: \(error.localizedDescription)")
        }
    }
    
    /// Performs a POST request expecting an APIResponse wrapper
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - body: Request body object to encode
    ///   - dataType: Type of the data inside the APIResponse
    /// - Returns: APIResponse containing the decoded data
    /// - Throws: NetworkError if the request fails
    func postWrapped<T: Codable, U: Codable>(_ endpoint: String, body: T, dataType: U.Type) async throws -> APIResponse<U> {
        let bodyData: Data
        do {
            bodyData = try jsonEncoder.encode(body)
        } catch {
            throw NetworkError.encodingError("Failed to encode request body: \(error.localizedDescription)")
        }
        
        let request = try networkManager.createRequest(endpoint: endpoint, method: .POST, body: bodyData)
        let data = try await networkManager.performRequest(request)
        
        do {
            return try jsonDecoder.decode(APIResponse<U>.self, from: data)
        } catch {
            throw NetworkError.decodingError("Failed to decode APIResponse<\(U.self)>: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Checks if the API is reachable
    /// - Returns: True if the API responds, false otherwise
    func checkAPIHealth() async -> Bool {
        do {
            _ = try await getHello()
            return true
        } catch {
            return false
        }
    }
    
    /// Gets the current network connectivity status
    /// - Returns: True if connected, false otherwise
    var isNetworkAvailable: Bool {
        return networkManager.isConnected
    }
    
    /// Gets the current connection type
    /// - Returns: Connection type if available
    var connectionType: String? {
        return networkManager.connectionType?.description
    }
}

// MARK: - Convenience Extensions

extension APIService {
    /// Convenience method to get hello message as a simple string
    /// - Returns: The hello message string
    /// - Throws: NetworkError if the request fails
    func getHelloMessage() async throws -> String {
        let response = try await getHello()
        return response.message
    }
    
    /// Convenience method to get hello message with completion handler
    /// - Parameter completion: Completion handler with Result<String, NetworkError>
    func getHelloMessage(completion: @escaping (Result<String, NetworkError>) -> Void) {
        getHello { result in
            switch result {
            case .success(let response):
                completion(.success(response.message))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}