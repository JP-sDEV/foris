import Foundation
import Network

/// Singleton class managing URLSession configuration and network monitoring
/// Provides centralized network management with proper timeouts and logging
final class NetworkManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NetworkManager()
    
    // MARK: - Properties
    
    /// URLSession configured for API requests
    private(set) var session: URLSession
    
    /// Network path monitor for connectivity checking
    private let pathMonitor = NWPathMonitor()
    
    /// Queue for network monitoring
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    /// Published property for network connectivity status
    @Published var isConnected: Bool = true
    
    /// Published property for connection type
    @Published var connectionType: NWInterface.InterfaceType?
    
    // MARK: - Configuration
    
    /// Request timeout interval in seconds
    static let timeoutInterval: TimeInterval = 30.0
    
    /// Base URL for the REST API
    static let baseURL = "http://localhost:3000"
    
    /// GraphQL endpoint URL
    static let graphqlURL = "http://localhost:3000/graphql"
    
    // MARK: - Initialization
    
    private init() {
        // Configure URLSession
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Self.timeoutInterval
        configuration.timeoutIntervalForResource = Self.timeoutInterval * 2
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024)
        
        // Add default headers
        configuration.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "iOS-Frontend/1.0"
        ]
        
        self.session = URLSession(configuration: configuration)
        
        // Start network monitoring
        startNetworkMonitoring()
    }
    
    deinit {
        pathMonitor.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                
                #if DEBUG
                self?.logNetworkStatus(path)
                #endif
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }
    
    #if DEBUG
    private func logNetworkStatus(_ path: NWPath) {
        let status = path.status == .satisfied ? "Connected" : "Disconnected"
        let type = connectionType?.description ?? "Unknown"
        print("🌐 Network Status: \(status) via \(type)")
    }
    #endif
    
    // MARK: - Request Methods
    
    /// Performs a generic network request
    /// - Parameters:
    ///   - request: URLRequest to perform
    ///   - completion: Completion handler with Result<Data, NetworkError>
    func performRequest(_ request: URLRequest, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        #if DEBUG
        logRequest(request)
        #endif
        
        // Check network connectivity
        guard isConnected else {
            completion(.failure(.networkUnavailable))
            return
        }
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleResponse(data: data, response: response, error: error, completion: completion)
            }
        }.resume()
    }
    
    /// Performs a network request with async/await
    /// - Parameter request: URLRequest to perform
    /// - Returns: Data from the response
    /// - Throws: NetworkError if the request fails
    func performRequest(_ request: URLRequest) async throws -> Data {
        #if DEBUG
        logRequest(request)
        #endif
        
        // Check network connectivity
        guard isConnected else {
            throw NetworkError.networkUnavailable
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            return try handleResponse(data: data, response: response)
        } catch {
            throw NetworkError.fromError(error)
        }
    }
    
    // MARK: - Response Handling
    
    private func handleResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        #if DEBUG
        logResponse(data: data, response: response, error: error)
        #endif
        
        // Handle network error
        if let error = error {
            completion(.failure(NetworkError.fromError(error)))
            return
        }
        
        // Handle HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(.unknown(nil)))
            return
        }
        
        // Check status code
        guard 200...299 ~= httpResponse.statusCode else {
            completion(.failure(NetworkError.fromHTTPStatusCode(httpResponse.statusCode)))
            return
        }
        
        // Handle data
        guard let data = data else {
            completion(.failure(.noData))
            return
        }
        
        completion(.success(data))
    }
    
    private func handleResponse(data: Data, response: URLResponse) throws -> Data {
        #if DEBUG
        logResponse(data: data, response: response, error: nil)
        #endif
        
        // Handle HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(nil)
        }
        
        // Check status code
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.fromHTTPStatusCode(httpResponse.statusCode)
        }
        
        return data
    }
    
    // MARK: - Request Building
    
    /// Creates a URLRequest for the given endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - method: HTTP method
    ///   - body: Request body data
    /// - Returns: Configured URLRequest
    /// - Throws: NetworkError.invalidURL if URL is invalid
    func createRequest(endpoint: String, method: HTTPMethod = .GET, body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: Self.baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        return request
    }
    
    // MARK: - Logging
    
    #if DEBUG
    private func logRequest(_ request: URLRequest) {
        print("🚀 Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "Unknown URL")")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("📋 Headers: \(headers)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Body: \(bodyString)")
        }
    }
    
    private func logResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            print("❌ Response Error: \(error.localizedDescription)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            let statusEmoji = httpResponse.statusCode < 400 ? "✅" : "❌"
            print("\(statusEmoji) Response: \(httpResponse.statusCode)")
        }
        
        if let data = data {
            print("📥 Response Data: \(data.count) bytes")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Response Body: \(responseString)")
            }
        }
    }
    #endif
}

// MARK: - HTTP Method Enum

extension NetworkManager {
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        case PATCH = "PATCH"
    }
}

// MARK: - NWInterface.InterfaceType Extension

extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
}