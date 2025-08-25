import Foundation
import Apollo
import ApolloAPI

/// Protocol defining GraphQL operations for the Foris app
/// Provides async/await methods for queries, mutations, and subscriptions
protocol GraphQLServiceProtocol {
    /// Performs a GraphQL query
    /// - Parameter query: The GraphQL query to execute
    /// - Returns: The query result data
    /// - Throws: GraphQLError if the operation fails
    func fetch<Query: GraphQLQuery>(_ query: Query) async throws -> Query.Data
    
    /// Performs a GraphQL mutation
    /// - Parameter mutation: The GraphQL mutation to execute
    /// - Returns: The mutation result data
    /// - Throws: GraphQLError if the operation fails
    func perform<Mutation: GraphQLMutation>(_ mutation: Mutation) async throws -> Mutation.Data
    
    /// Creates a subscription for real-time updates
    /// - Parameter subscription: The GraphQL subscription to execute
    /// - Returns: AsyncThrowingStream of subscription data
    func subscribe<Subscription: GraphQLSubscription>(_ subscription: Subscription) -> AsyncThrowingStream<Subscription.Data, Error>
}

/// GraphQL service implementation using Apollo iOS
/// Handles all GraphQL operations with proper error handling and authentication
final class GraphQLService: GraphQLServiceProtocol, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = GraphQLService()
    
    // MARK: - Properties
    
    private let apollo: ApolloClient
    private let networkTransport: RequestChainNetworkTransport
    
    // MARK: - Configuration
    
    private static let graphqlEndpoint = "http://localhost:3000/graphql"
    
    // MARK: - Initialization
    
    private init() {
        // Create URL for GraphQL endpoint
        guard let url = URL(string: Self.graphqlEndpoint) else {
            fatalError("Invalid GraphQL endpoint URL")
        }
        
        // Create network transport with authentication
        let store = ApolloStore()
        let client = URLSessionClient()
        let provider = DefaultInterceptorProvider(client: client, store: store)
        
        self.networkTransport = RequestChainNetworkTransport(
            interceptorProvider: provider,
            endpointURL: url
        )
        
        // Create Apollo client
        self.apollo = ApolloClient(networkTransport: networkTransport, store: store)
        
        // Configure authentication interceptor
        configureAuthentication()
    }
    
    // MARK: - Authentication Configuration
    
    private func configureAuthentication() {
        // Add authentication headers to all requests
        networkTransport.additionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    /// Updates the authentication token for all future requests
    /// - Parameter token: JWT token to use for authentication
    func setAuthenticationToken(_ token: String?) {
        var headers = networkTransport.additionalHeaders
        
        if let token = token {
            headers["Authorization"] = "Bearer \(token)"
        } else {
            headers.removeValue(forKey: "Authorization")
        }
        
        networkTransport.additionalHeaders = headers
    }
    
    // MARK: - GraphQL Operations
    
    func fetch<Query: GraphQLQuery>(_ query: Query) async throws -> Query.Data {
        return try await withCheckedThrowingContinuation { continuation in
            apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data {
                        continuation.resume(returning: data)
                    } else if let errors = graphQLResult.errors {
                        let error = GraphQLError.queryFailed(errors.map { $0.localizedDescription }.joined(separator: ", "))
                        continuation.resume(throwing: AppError.graphql(error))
                    } else {
                        continuation.resume(throwing: AppError.graphql(GraphQLError.noData))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AppError.graphql(GraphQLError.networkError(error)))
                }
            }
        }
    }
    
    func perform<Mutation: GraphQLMutation>(_ mutation: Mutation) async throws -> Mutation.Data {
        return try await withCheckedThrowingContinuation { continuation in
            apollo.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data {
                        continuation.resume(returning: data)
                    } else if let errors = graphQLResult.errors {
                        let error = GraphQLError.mutationFailed(errors.map { $0.localizedDescription }.joined(separator: ", "))
                        continuation.resume(throwing: AppError.graphql(error))
                    } else {
                        continuation.resume(throwing: AppError.graphql(GraphQLError.noData))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AppError.graphql(GraphQLError.networkError(error)))
                }
            }
        }
    }
    
    func subscribe<Subscription: GraphQLSubscription>(_ subscription: Subscription) -> AsyncThrowingStream<Subscription.Data, Error> {
        return AsyncThrowingStream { continuation in
            let cancellable = apollo.subscribe(subscription: subscription) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data {
                        continuation.yield(data)
                    } else if let errors = graphQLResult.errors {
                        let error = GraphQLError.subscriptionFailed(errors.map { $0.localizedDescription }.joined(separator: ", "))
                        continuation.finish(throwing: AppError.graphql(error))
                    }
                case .failure(let error):
                    continuation.finish(throwing: AppError.graphql(GraphQLError.networkError(error)))
                }
            }
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
    
    // MARK: - Cache Management
    
    /// Clears the Apollo cache
    func clearCache() async throws {
        try await apollo.clearCache()
    }
    
    /// Gets the current cache size in bytes
    func getCacheSize() -> Int {
        // This would need to be implemented based on Apollo's cache implementation
        return 0
    }
}

// MARK: - GraphQL Error Types

/// Comprehensive GraphQL error enum for handling various GraphQL failure scenarios
enum GraphQLError: Error, LocalizedError {
    case networkError(Error)
    case queryFailed(String)
    case mutationFailed(String)
    case subscriptionFailed(String)
    case noData
    case invalidResponse
    case authenticationRequired
    case rateLimited
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .mutationFailed(let message):
            return "Mutation failed: \(message)"
        case .subscriptionFailed(let message):
            return "Subscription failed: \(message)"
        case .noData:
            return "No data received from server"
        case .invalidResponse:
            return "Invalid response format"
        case .authenticationRequired:
            return "Authentication required"
        case .rateLimited:
            return "Too many requests - please try again later"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .networkError:
            return "Unable to connect to the server"
        case .queryFailed, .mutationFailed, .subscriptionFailed:
            return "The GraphQL operation failed"
        case .noData:
            return "The server did not return any data"
        case .invalidResponse:
            return "The server response was not in the expected format"
        case .authenticationRequired:
            return "You need to be logged in to perform this action"
        case .rateLimited:
            return "You have made too many requests in a short time"
        case .serverError:
            return "The server encountered an error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .queryFailed, .mutationFailed, .subscriptionFailed:
            return "Please try again or contact support if the problem persists"
        case .noData, .invalidResponse:
            return "Please try again later"
        case .authenticationRequired:
            return "Please log in and try again"
        case .rateLimited:
            return "Please wait a moment before trying again"
        case .serverError:
            return "Please try again later or contact support"
        }
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
/// Mock GraphQL service for testing and previews
class MockGraphQLService: GraphQLServiceProtocol {
    var shouldFail = false
    var mockDelay: TimeInterval = 0.5
    var mockResponses: [String: Any] = [:]
    
    func fetch<Query: GraphQLQuery>(_ query: Query) async throws -> Query.Data {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFail {
            throw AppError.graphql(GraphQLError.queryFailed("Mock error"))
        }
        
        // This would need to be implemented with actual mock data
        // For now, we'll throw an error to indicate this needs implementation
        throw AppError.graphql(GraphQLError.noData)
    }
    
    func perform<Mutation: GraphQLMutation>(_ mutation: Mutation) async throws -> Mutation.Data {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFail {
            throw AppError.graphql(GraphQLError.mutationFailed("Mock error"))
        }
        
        // This would need to be implemented with actual mock data
        throw AppError.graphql(GraphQLError.noData)
    }
    
    func subscribe<Subscription: GraphQLSubscription>(_ subscription: Subscription) -> AsyncThrowingStream<Subscription.Data, Error> {
        return AsyncThrowingStream { continuation in
            if shouldFail {
                continuation.finish(throwing: AppError.graphql(GraphQLError.subscriptionFailed("Mock error")))
            } else {
                continuation.finish()
            }
        }
    }
}
#endif