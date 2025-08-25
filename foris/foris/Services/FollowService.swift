import Foundation
import Combine

/// Service for managing user follow relationships
/// Handles following/unfollowing users with optimistic UI updates
@MainActor
final class FollowService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = FollowService()
    
    // MARK: - Properties
    
    private let graphqlService: GraphQLServiceProtocol
    private let cacheService: CacheService
    private let authService: AuthServiceProtocol
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var error: AppError?
    
    // MARK: - Initialization
    
    init(
        graphqlService: GraphQLServiceProtocol = GraphQLService.shared,
        cacheService: CacheService = CacheService.shared,
        authService: AuthServiceProtocol = AuthService.shared
    ) {
        self.graphqlService = graphqlService
        self.cacheService = cacheService
        self.authService = authService
    }
    
    // MARK: - Follow Operations
    
    /// Toggles follow status for a user with optimistic UI updates
    /// - Parameter userId: User ID to toggle follow for
    /// - Returns: Updated follow status
    /// - Throws: AppError if operation fails
    func toggleFollow(for userId: String) async throws -> Bool {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        guard currentUser.id != userId else {
            throw AppError.validation(.invalid("Cannot follow yourself"))
        }
        
        // Check current follow status
        let isCurrentlyFollowing = try await isFollowing(userId: userId)
        
        if isCurrentlyFollowing {
            return try await unfollowUser(userId: userId)
        } else {
            return try await followUser(userId: userId)
        }
    }
    
    /// Follows a user
    /// - Parameter userId: User ID to follow
    /// - Returns: True if successfully followed
    /// - Throws: AppError if operation fails
    func followUser(userId: String) async throws -> Bool {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        guard currentUser.id != userId else {
            throw AppError.validation(.invalid("Cannot follow yourself"))
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Optimistically update cache first
            let userFollow = UserFollow(
                followerId: currentUser.id,
                followingId: userId,
                createdAt: Date(),
                follower: currentUser,
                following: nil // Will be populated when we have the user data
            )
            try cacheService.cacheUserFollow(userFollow)
            
            // Check if online
            if NetworkMonitor.shared.isConnected {
                // TODO: Implement GraphQL followUser mutation
                // For now, simulate the operation
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                return true
            } else {
                // Queue for offline processing
                let actionData = FollowUserActionData(userId: userId, isFollowing: true)
                let data = try JSONEncoder().encode(actionData)
                let action = OfflineAction(type: .followUser, data: data)
                
                await OfflineQueueService.shared.queueAction(action)
                
                return true
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Unfollows a user
    /// - Parameter userId: User ID to unfollow
    /// - Returns: False (unfollowed status)
    /// - Throws: AppError if operation fails
    func unfollowUser(userId: String) async throws -> Bool {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Optimistically update cache first
            try cacheService.removeUserFollow(followerId: currentUser.id, followingId: userId)
            
            // Check if online
            if NetworkMonitor.shared.isConnected {
                // TODO: Implement GraphQL unfollowUser mutation
                // For now, simulate the operation
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                return false
            } else {
                // Queue for offline processing
                let actionData = FollowUserActionData(userId: userId, isFollowing: false)
                let data = try JSONEncoder().encode(actionData)
                let action = OfflineAction(type: .unfollowUser, data: data)
                
                await OfflineQueueService.shared.queueAction(action)
                
                return false
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Checks if current user is following a specific user
    /// - Parameter userId: User ID to check
    /// - Returns: True if following
    /// - Throws: AppError if operation fails
    func isFollowing(userId: String) async throws -> Bool {
        guard let currentUser = authService.currentUser else {
            return false
        }
        
        do {
            // Check cache first
            return try cacheService.isUserFollowing(followerId: currentUser.id, followingId: userId)
            
        } catch {
            // If cache fails, return false (not following)
            return false
        }
    }
    
    /// Gets users that the current user is following
    /// - Parameters:
    ///   - limit: Maximum number of users to return
    ///   - offset: Number of users to skip
    /// - Returns: Array of users being followed
    /// - Throws: AppError if operation fails
    func getFollowing(limit: Int = 20, offset: Int = 0) async throws -> [User] {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedFollowing = try cacheService.getCachedFollowing(for: currentUser.id, limit: limit, offset: offset)
            
            if !cachedFollowing.isEmpty {
                return cachedFollowing
            }
            
            // TODO: Implement GraphQL userFollowing query
            // For now, return empty array
            return []
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets users that follow the current user
    /// - Parameters:
    ///   - limit: Maximum number of users to return
    ///   - offset: Number of users to skip
    /// - Returns: Array of followers
    /// - Throws: AppError if operation fails
    func getFollowers(limit: Int = 20, offset: Int = 0) async throws -> [User] {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedFollowers = try cacheService.getCachedFollowers(for: currentUser.id, limit: limit, offset: offset)
            
            if !cachedFollowers.isEmpty {
                return cachedFollowers
            }
            
            // TODO: Implement GraphQL userFollowers query
            // For now, return empty array
            return []
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets follow counts for a user
    /// - Parameter userId: User ID to get counts for
    /// - Returns: Tuple of (followers count, following count)
    /// - Throws: AppError if operation fails
    func getFollowCounts(for userId: String) async throws -> (followers: Int, following: Int) {
        do {
            let followersCount = try cacheService.getFollowersCount(for: userId)
            let followingCount = try cacheService.getFollowingCount(for: userId)
            
            return (followers: followersCount, following: followingCount)
            
        } catch {
            // If operation fails, return 0s
            return (followers: 0, following: 0)
        }
    }
    
    /// Gets all users that the current user is following (for sync)
    /// - Returns: Array of users being followed
    /// - Throws: AppError if operation fails
    func getFollowedUsers() async throws -> [User] {
        // TODO: Implement GraphQL query to get all followed users
        return try await getFollowing(limit: 1000, offset: 0)
    }
    
    /// Gets all follow relationships as UserFollow objects
    /// - Returns: Array of UserFollow relationships
    /// - Throws: AppError if operation fails
    func getFollowing() async throws -> [UserFollow] {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        // TODO: Implement GraphQL query to get UserFollow objects
        // For now, return empty array
        return []
    }
    
    /// Gets all followers as UserFollow objects
    /// - Returns: Array of UserFollow relationships
    /// - Throws: AppError if operation fails
    func getFollowers() async throws -> [UserFollow] {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        // TODO: Implement GraphQL query to get UserFollow objects
        // For now, return empty array
        return []
    }
    
    /// Searches for users by name or email
    /// - Parameters:
    ///   - query: Search query
    ///   - limit: Maximum number of results
    /// - Returns: Array of matching users
    /// - Throws: AppError if operation fails
    func searchUsers(query: String, limit: Int = 20) async throws -> [User] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement GraphQL searchUsers query
            // For now, return mock search results
            return generateMockSearchResults(for: query, limit: limit)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockSearchResults(for query: String, limit: Int) -> [User] {
        let mockUsers = [
            User(id: "user1", name: "Alice Johnson", email: "alice@example.com", bio: "Fitness enthusiast", avatarUrl: nil),
            User(id: "user2", name: "Bob Smith", email: "bob@example.com", bio: "Runner and cyclist", avatarUrl: "https://example.com/bob.jpg"),
            User(id: "user3", name: "Carol Davis", email: "carol@example.com", bio: "Yoga instructor", avatarUrl: nil),
            User(id: "user4", name: "David Wilson", email: "david@example.com", bio: "Personal trainer", avatarUrl: "https://example.com/david.jpg"),
            User(id: "user5", name: "Emma Brown", email: "emma@example.com", bio: "Marathon runner", avatarUrl: nil)
        ]
        
        let filteredUsers = mockUsers.filter { user in
            user.name.localizedCaseInsensitiveContains(query) ||
            user.email.localizedCaseInsensitiveContains(query) ||
            (user.bio?.localizedCaseInsensitiveContains(query) ?? false)
        }
        
        return Array(filteredUsers.prefix(limit))
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        error = nil
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockFollowService: FollowService {
    var shouldFailOperations = false
    var operationDelay: TimeInterval = 0.3
    private var mockFollows: Set<String> = [] // Set of "followerId-followingId" strings
    
    override init() {
        super.init()
        generateMockData()
    }
    
    private func generateMockData() {
        // Add some mock follow relationships
        mockFollows.insert("current-user-user1")
        mockFollows.insert("current-user-user3")
        mockFollows.insert("user2-current-user")
        mockFollows.insert("user4-current-user")
    }
    
    override func toggleFollow(for userId: String) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        let followKey = "\(currentUser.id)-\(userId)"
        
        if mockFollows.contains(followKey) {
            mockFollows.remove(followKey)
            return false
        } else {
            mockFollows.insert(followKey)
            return true
        }
    }
    
    override func isFollowing(userId: String) async throws -> Bool {
        guard let currentUser = authService.currentUser else {
            return false
        }
        
        let followKey = "\(currentUser.id)-\(userId)"
        return mockFollows.contains(followKey)
    }
    
    override func getFollowCounts(for userId: String) async throws -> (followers: Int, following: Int) {
        let followersCount = mockFollows.filter { $0.hasSuffix("-\(userId)") }.count
        let followingCount = mockFollows.filter { $0.hasPrefix("\(userId)-") }.count
        
        return (followers: followersCount, following: followingCount)
    }
}
#endif