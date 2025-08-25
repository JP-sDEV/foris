import Foundation
import Combine

/// Service for managing post operations
/// Handles post creation, fetching, updating, and deletion
@MainActor
final class PostService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = PostService()
    
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
    
    // MARK: - Post Operations
    
    /// Creates a new post
    /// - Parameter postData: Post creation data
    /// - Returns: Created post
    /// - Throws: AppError if operation fails
    func createPost(_ postData: PostCreationData) async throws -> Post {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate input
            try validatePostCreation(postData)
            
            // Check if online
            if NetworkMonitor.shared.isConnected {
                // TODO: Implement GraphQL createPost mutation
                // For now, create mock post
                let post = Post(
                    id: UUID().uuidString,
                    title: postData.title,
                    content: postData.content,
                    authorId: currentUser.id,
                    author: currentUser,
                    createdAt: Date(),
                    likeCount: 0,
                    commentCount: 0,
                    isLiked: false
                )
                
                // Cache the post
                try cacheService.cachePost(post)
                
                return post
            } else {
                // Queue for offline processing
                let tempId = UUID().uuidString
                let actionData = CreatePostActionData(title: postData.title, content: postData.content, tempId: tempId)
                let data = try JSONEncoder().encode(actionData)
                let action = OfflineAction(type: .createPost, data: data)
                
                await OfflineQueueService.shared.queueAction(action)
                
                // Create temporary post for optimistic UI
                let tempPost = Post(
                    id: tempId,
                    title: postData.title,
                    content: postData.content,
                    authorId: currentUser.id,
                    author: currentUser,
                    createdAt: Date(),
                    likeCount: 0,
                    commentCount: 0,
                    isLiked: false
                )
                
                // Cache temporarily
                try cacheService.cachePost(tempPost)
                
                return tempPost
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets posts with pagination
    /// - Parameters:
    ///   - limit: Maximum number of posts to return
    ///   - offset: Number of posts to skip
    /// - Returns: Array of posts
    /// - Throws: AppError if operation fails
    func getPosts(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedPosts = try cacheService.getCachedPosts(limit: limit, offset: offset)
            
            if !cachedPosts.isEmpty {
                return cachedPosts
            }
            
            // TODO: Implement GraphQL posts query
            // For now, return mock posts
            return generateMockPosts(limit: limit)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets a specific post by ID
    /// - Parameter postId: Post ID
    /// - Returns: Post if found
    /// - Throws: AppError if operation fails
    func getPost(id postId: String) async throws -> Post {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement GraphQL post query
            // For now, return mock post
            return generateMockPosts(limit: 1).first!
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets posts by a specific user
    /// - Parameter userId: User ID
    /// - Returns: Array of user's posts
    /// - Throws: AppError if operation fails
    func getUserPosts(userId: String) async throws -> [Post] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedPosts = try cacheService.getCachedPosts(byUserId: userId)
            
            if !cachedPosts.isEmpty {
                return cachedPosts
            }
            
            // TODO: Implement GraphQL userPosts query
            // For now, return mock posts
            return generateMockPosts(limit: 5, authorId: userId)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Updates an existing post
    /// - Parameters:
    ///   - postId: Post ID to update
    ///   - updateData: Post update data
    /// - Returns: Updated post
    /// - Throws: AppError if operation fails
    func updatePost(id postId: String, updateData: PostUpdateData) async throws -> Post {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate input
            try validatePostUpdate(updateData)
            
            // TODO: Implement GraphQL updatePost mutation
            // For now, return mock updated post
            let updatedPost = Post(
                id: postId,
                title: updateData.title ?? "Updated Title",
                content: updateData.content,
                authorId: currentUser.id,
                author: currentUser,
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                likeCount: 5,
                commentCount: 2,
                isLiked: false
            )
            
            // Cache the updated post
            try cacheService.cachePost(updatedPost)
            
            return updatedPost
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Deletes a post
    /// - Parameter postId: Post ID to delete
    /// - Throws: AppError if operation fails
    func deletePost(id postId: String) async throws {
        guard authService.currentUser != nil else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement GraphQL deletePost mutation
            // For now, just simulate the operation
            try await Task.sleep(nanoseconds: 500_000_000)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Creates a post directly (used by offline queue service)
    /// - Parameters:
    ///   - title: Post title
    ///   - content: Post content
    /// - Returns: Created post
    /// - Throws: AppError if operation fails
    func createPost(title: String, content: String?) async throws -> Post {
        let postData = PostCreationData(title: title, content: content)
        return try await createPost(postData)
    }
    
    /// Gets all posts (used by sync service)
    /// - Returns: Array of all posts
    /// - Throws: AppError if operation fails
    func getAllPosts() async throws -> [Post] {
        // TODO: Implement GraphQL query to get all posts
        return try await getPosts(limit: 100, offset: 0)
    }
    
    /// Refreshes posts from the server
    /// - Returns: Array of refreshed posts
    /// - Throws: AppError if operation fails
    func refreshPosts() async throws -> [Post] {
        // Clear cache and fetch fresh data
        return try await getPosts(limit: 20, offset: 0)
    }
    
    // MARK: - Validation
    
    private func validatePostCreation(_ postData: PostCreationData) throws {
        guard !postData.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.validation(.required("Title"))
        }
        
        guard postData.title.count >= 3 else {
            throw AppError.validation(.tooShort("Title", 3))
        }
        
        guard postData.title.count <= 200 else {
            throw AppError.validation(.tooLong("Title", 200))
        }
        
        if let content = postData.content {
            guard content.count <= 2000 else {
                throw AppError.validation(.tooLong("Content", 2000))
            }
        }
    }
    
    private func validatePostUpdate(_ updateData: PostUpdateData) throws {
        if let title = updateData.title {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AppError.validation(.required("Title"))
            }
            
            guard title.count >= 3 else {
                throw AppError.validation(.tooShort("Title", 3))
            }
            
            guard title.count <= 200 else {
                throw AppError.validation(.tooLong("Title", 200))
            }
        }
        
        if let content = updateData.content {
            guard content.count <= 2000 else {
                throw AppError.validation(.tooLong("Content", 2000))
            }
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockPosts(limit: Int, authorId: String? = nil) -> [Post] {
        let mockUsers = [User.mock, User.mockWithAvatar]
        let mockTitles = [
            "Morning Workout Complete! 💪",
            "New Personal Record Today",
            "Beautiful Trail Run",
            "Gym Session Highlights",
            "Healthy Meal Prep Sunday",
            "Yoga and Mindfulness",
            "Team Training Session",
            "Recovery Day Stretches"
        ]
        
        let mockContents = [
            "Just finished an amazing workout session. Feeling energized and ready for the day!",
            "Hit a new PR on deadlifts today. All that consistent training is paying off.",
            "Discovered a beautiful new trail today. Nature therapy at its finest.",
            "Great session focusing on compound movements. Form over ego always!",
            "Spent the morning preparing healthy meals for the week. Nutrition is key!",
            "Started the day with some peaceful yoga. Mind-body connection is everything.",
            "Training with the team always pushes me to new levels. Grateful for great partners.",
            "Taking time for proper recovery. Rest days are just as important as training days."
        ]
        
        return (0..<limit).map { index in
            let author = authorId != nil ? 
                mockUsers.first { $0.id == authorId } ?? mockUsers[0] :
                mockUsers[index % mockUsers.count]
            
            return Post(
                id: "mock-post-\(index)",
                title: mockTitles[index % mockTitles.count],
                content: mockContents[index % mockContents.count],
                authorId: author.id,
                author: author,
                createdAt: Date().addingTimeInterval(-Double(index * 3600)), // Hours ago
                likeCount: Int.random(in: 0...50),
                commentCount: Int.random(in: 0...10),
                isLiked: Bool.random()
            )
        }
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        error = nil
    }
}

// MARK: - Post Data Structures

/// Data structure for creating posts
struct PostCreationData {
    let title: String
    let content: String?
    
    init(title: String, content: String? = nil) {
        self.title = title
        self.content = content
    }
    
    /// Returns true if the data is valid for creation
    var isValid: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               title.count >= 3 &&
               title.count <= 200 &&
               (content?.count ?? 0) <= 2000
    }
}

/// Data structure for updating posts
struct PostUpdateData {
    let title: String?
    let content: String?
    
    init(title: String? = nil, content: String? = nil) {
        self.title = title
        self.content = content
    }
    
    /// Returns true if any field has been updated
    var hasChanges: Bool {
        return title != nil || content != nil
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockPostService: PostService {
    var shouldFailOperations = false
    var operationDelay: TimeInterval = 0.5
    var mockPosts: [Post] = []
    
    override init() {
        super.init()
        generateMockData()
    }
    
    private func generateMockData() {
        mockPosts = (0..<10).map { index in
            Post(
                id: "mock-post-\(index)",
                title: "Mock Post \(index + 1)",
                content: "This is mock content for post \(index + 1). It contains some sample text to demonstrate the post display.",
                authorId: index % 2 == 0 ? User.mock.id : User.mockWithAvatar.id,
                author: index % 2 == 0 ? User.mock : User.mockWithAvatar,
                createdAt: Date().addingTimeInterval(-Double(index * 3600)),
                likeCount: Int.random(in: 0...50),
                commentCount: Int.random(in: 0...10),
                isLiked: Bool.random()
            )
        }
    }
    
    override func createPost(_ postData: PostCreationData) async throws -> Post {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.validation(.required("Title"))
        }
        
        let newPost = Post(
            id: "mock-new-post",
            title: postData.title,
            content: postData.content,
            authorId: User.mock.id,
            author: User.mock,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            isLiked: false
        )
        
        mockPosts.insert(newPost, at: 0)
        return newPost
    }
    
    override func getPosts(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        let endIndex = min(offset + limit, mockPosts.count)
        let startIndex = min(offset, mockPosts.count)
        
        return Array(mockPosts[startIndex..<endIndex])
    }
    
    override func getUserPosts(userId: String) async throws -> [Post] {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.notFound)
        }
        
        return mockPosts.filter { $0.authorId == userId }
    }
}
#endif