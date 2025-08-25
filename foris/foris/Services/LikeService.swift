import Foundation
import Combine

/// Service for managing like operations
/// Handles liking/unliking posts with optimistic UI updates
@MainActor
final class LikeService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LikeService()
    
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
    
    // MARK: - Like Operations
    
    /// Toggles like status for a post with optimistic UI updates
    /// - Parameter postId: Post ID to toggle like for
    /// - Returns: Updated like status
    /// - Throws: AppError if operation fails
    func toggleLike(for postId: String) async throws -> Bool {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        // Check current like status
        let isCurrentlyLiked = try await isPostLiked(postId: postId, userId: currentUser.id)
        
        if isCurrentlyLiked {
            return try await unlikePost(postId: postId)
        } else {
            return try await likePost(postId: postId)
        }
    }
    
    /// Likes a post
    /// - Parameter postId: Post ID to like
    /// - Returns: True if successfully liked
    /// - Throws: AppError if operation fails
    func likePost(postId: String) async throws -> Bool {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Optimistically update cache first
            let like = Like(
                userId: currentUser.id,
                postId: postId,
                user: currentUser,
                post: Post(
                    id: postId,
                    title: "Placeholder",
                    content: nil,
                    authorId: "",
                    author: nil,
                    createdAt: Date(),
                    likeCount: 0,
                    commentCount: 0,
                    isLiked: false
                )
            )
            try cacheService.cacheLike(like)
            
            // Check if online
            if NetworkMonitor.shared.isConnected {
                // TODO: Implement GraphQL likePost mutation
                // For now, simulate the operation
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                return true
            } else {
                // Queue for offline processing
                let actionData = LikePostActionData(postId: postId, isLiked: true)
                let data = try JSONEncoder().encode(actionData)
                let action = OfflineAction(type: .likePost, data: data)
                
                await OfflineQueueService.shared.queueAction(action)
                
                return true
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Unlikes a post
    /// - Parameter postId: Post ID to unlike
    /// - Returns: False (unliked status)
    /// - Throws: AppError if operation fails
    func unlikePost(postId: String) async throws -> Bool {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Optimistically update cache first
            try cacheService.removeLike(userId: currentUser.id, postId: postId)
            
            // Check if online
            if NetworkMonitor.shared.isConnected {
                // TODO: Implement GraphQL unlikePost mutation
                // For now, simulate the operation
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                return false
            } else {
                // Queue for offline processing
                let actionData = LikePostActionData(postId: postId, isLiked: false)
                let data = try JSONEncoder().encode(actionData)
                let action = OfflineAction(type: .unlikePost, data: data)
                
                await OfflineQueueService.shared.queueAction(action)
                
                return false
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Checks if a post is liked by a specific user
    /// - Parameters:
    ///   - postId: Post ID to check
    ///   - userId: User ID to check
    /// - Returns: True if post is liked by user
    /// - Throws: AppError if operation fails
    func isPostLiked(postId: String, userId: String) async throws -> Bool {
        do {
            // Check cache first
            return try cacheService.isPostLiked(postId: postId, userId: userId)
            
        } catch {
            // If cache fails, return false (not liked)
            return false
        }
    }
    
    /// Gets likes for a specific post
    /// - Parameter postId: Post ID to get likes for
    /// - Returns: Array of likes
    /// - Throws: AppError if operation fails
    func getLikes(for postId: String) async throws -> [Like] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedLikes = try cacheService.getCachedLikes(for: postId)
            
            if !cachedLikes.isEmpty {
                return cachedLikes
            }
            
            // TODO: Implement GraphQL postLikes query
            // For now, return empty array
            return []
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets like count for a specific post
    /// - Parameter postId: Post ID to get like count for
    /// - Returns: Number of likes
    /// - Throws: AppError if operation fails
    func getLikeCount(for postId: String) async throws -> Int {
        do {
            let likes = try await getLikes(for: postId)
            return likes.count
            
        } catch {
            // If operation fails, return 0
            return 0
        }
    }
    
    /// Gets posts liked by a specific user
    /// - Parameter userId: User ID to get liked posts for
    /// - Returns: Array of liked posts
    /// - Throws: AppError if operation fails
    func getLikedPosts(for userId: String) async throws -> [Post] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedLikedPosts = try cacheService.getCachedLikedPosts(for: userId)
            
            if !cachedLikedPosts.isEmpty {
                return cachedLikedPosts
            }
            
            // TODO: Implement GraphQL userLikedPosts query
            // For now, return empty array
            return []
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        error = nil
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockLikeService: LikeService {
    var shouldFailOperations = false
    var operationDelay: TimeInterval = 0.3
    private var mockLikes: Set<String> = [] // Set of "userId-postId" strings
    
    override init() {
        super.init()
        generateMockData()
    }
    
    private func generateMockData() {
        // Add some mock likes
        mockLikes.insert("user1-post1")
        mockLikes.insert("user1-post3")
        mockLikes.insert("user2-post1")
        mockLikes.insert("user2-post2")
    }
    
    override func toggleLike(for postId: String) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        let likeKey = "\(currentUser.id)-\(postId)"
        
        if mockLikes.contains(likeKey) {
            mockLikes.remove(likeKey)
            return false
        } else {
            mockLikes.insert(likeKey)
            return true
        }
    }
    
    override func isPostLiked(postId: String, userId: String) async throws -> Bool {
        let likeKey = "\(userId)-\(postId)"
        return mockLikes.contains(likeKey)
    }
    
    override func getLikeCount(for postId: String) async throws -> Int {
        return mockLikes.filter { $0.hasSuffix("-\(postId)") }.count
    }
}
#endif