import Foundation
import Combine

/// Service for managing comment operations
/// Handles comment creation, fetching, updating, and deletion
@MainActor
final class CommentService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = CommentService()
    
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
    
    // MARK: - Comment Operations
    
    /// Creates a new comment on a post
    /// - Parameters:
    ///   - postId: Post ID to comment on
    ///   - content: Comment content
    /// - Returns: Created comment
    /// - Throws: AppError if operation fails
    func createComment(postId: String, content: String) async throws -> Comment {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate input
            try validateCommentContent(content)
            
            // Create comment for optimistic update
            let tempId = UUID().uuidString
            let comment = Comment(
                id: tempId,
                content: content,
                createdAt: Date(),
                updatedAt: Date(),
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
            
            // Cache the comment
            try cacheService.cacheComment(comment)
            
            // Check if online
            if NetworkMonitor.shared.isConnected {
                // TODO: Implement GraphQL createComment mutation
                // For now, just return the cached comment
                return comment
            } else {
                // Queue for offline processing
                let actionData = CreateCommentActionData(postId: postId, content: content, tempId: tempId)
                let data = try JSONEncoder().encode(actionData)
                let action = OfflineAction(type: .createComment, data: data)
                
                await OfflineQueueService.shared.queueAction(action)
                
                return comment
            }
            
            return comment
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets comments for a specific post
    /// - Parameters:
    ///   - postId: Post ID to get comments for
    ///   - limit: Maximum number of comments to return
    ///   - offset: Number of comments to skip
    /// - Returns: Array of comments
    /// - Throws: AppError if operation fails
    func getComments(for postId: String, limit: Int = 20, offset: Int = 0) async throws -> [Comment] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedComments = try cacheService.getCachedComments(for: postId, limit: limit, offset: offset)
            
            if !cachedComments.isEmpty {
                return cachedComments
            }
            
            // TODO: Implement GraphQL postComments query
            // For now, return mock comments
            return generateMockComments(for: postId, limit: limit)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets a specific comment by ID
    /// - Parameter commentId: Comment ID
    /// - Returns: Comment if found
    /// - Throws: AppError if operation fails
    func getComment(id commentId: String) async throws -> Comment {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            if let cachedComment = try cacheService.getCachedComment(id: commentId) {
                return cachedComment
            }
            
            // TODO: Implement GraphQL comment query
            // For now, return mock comment
            return generateMockComments(for: "mock-post", limit: 1).first!
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Updates an existing comment
    /// - Parameters:
    ///   - commentId: Comment ID to update
    ///   - content: New comment content
    /// - Returns: Updated comment
    /// - Throws: AppError if operation fails
    func updateComment(id commentId: String, content: String) async throws -> Comment {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate input
            try validateCommentContent(content)
            
            // TODO: Implement GraphQL updateComment mutation
            // For now, return mock updated comment
            let updatedComment = Comment(
                id: commentId,
                content: content,
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                updatedAt: Date(),
                user: currentUser,
                post: Post(
                    id: "mock-post",
                    title: "Mock Post",
                    content: nil,
                    authorId: "",
                    author: nil,
                    createdAt: Date(),
                    likeCount: 0,
                    commentCount: 0,
                    isLiked: false
                )
            )
            
            // Cache the updated comment
            try cacheService.cacheComment(updatedComment)
            
            return updatedComment
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Deletes a comment
    /// - Parameter commentId: Comment ID to delete
    /// - Throws: AppError if operation fails
    func deleteComment(id commentId: String) async throws {
        guard authService.currentUser != nil else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement GraphQL deleteComment mutation
            // For now, just simulate the operation
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Remove from cache
            try cacheService.removeComment(id: commentId)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets comment count for a specific post
    /// - Parameter postId: Post ID to get comment count for
    /// - Returns: Number of comments
    /// - Throws: AppError if operation fails
    func getCommentCount(for postId: String) async throws -> Int {
        do {
            let comments = try await getComments(for: postId)
            return comments.count
            
        } catch {
            // If operation fails, return 0
            return 0
        }
    }
    
    /// Gets comments by a specific user
    /// - Parameter userId: User ID to get comments for
    /// - Returns: Array of user's comments
    /// - Throws: AppError if operation fails
    func getUserComments(userId: String) async throws -> [Comment] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedComments = try cacheService.getCachedComments(byUserId: userId)
            
            if !cachedComments.isEmpty {
                return cachedComments
            }
            
            // TODO: Implement GraphQL userComments query
            // For now, return empty array
            return []
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    // MARK: - Validation
    
    private func validateCommentContent(_ content: String) throws {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedContent.isEmpty else {
            throw AppError.validation(.required("Comment content"))
        }
        
        guard trimmedContent.count >= 1 else {
            throw AppError.validation(.tooShort("Comment", 1))
        }
        
        guard trimmedContent.count <= 500 else {
            throw AppError.validation(.tooLong("Comment", 500))
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockComments(for postId: String, limit: Int) -> [Comment] {
        let mockUsers = [User.mock, User.mockWithAvatar]
        let mockComments = [
            "Great post! Thanks for sharing.",
            "This is really inspiring. Keep it up!",
            "I totally agree with this approach.",
            "Thanks for the motivation!",
            "Love seeing content like this.",
            "This really resonates with me.",
            "Excellent point about consistency.",
            "I needed to hear this today."
        ]
        
        return (0..<limit).map { index in
            Comment(
                id: "mock-comment-\(postId)-\(index)",
                content: mockComments[index % mockComments.count],
                createdAt: Date().addingTimeInterval(-Double(index * 1800)), // 30 minutes apart
                updatedAt: Date().addingTimeInterval(-Double(index * 1800)),
                user: mockUsers[index % mockUsers.count],
                post: Post(
                    id: postId,
                    title: "Mock Post",
                    content: nil,
                    authorId: "",
                    author: nil,
                    createdAt: Date(),
                    likeCount: 0,
                    commentCount: 0,
                    isLiked: false
                )
            )
        }
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        error = nil
    }
}

// MARK: - Comment Data Structures

/// Data structure for creating comments
struct CommentCreationData {
    let postId: String
    let content: String
    
    init(postId: String, content: String) {
        self.postId = postId
        self.content = content
    }
    
    /// Returns true if the data is valid for creation
    var isValid: Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedContent.isEmpty &&
               trimmedContent.count >= 1 &&
               trimmedContent.count <= 500
    }
}

/// Data structure for updating comments
struct CommentUpdateData {
    let content: String
    
    init(content: String) {
        self.content = content
    }
    
    /// Returns true if the data is valid for update
    var isValid: Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedContent.isEmpty &&
               trimmedContent.count >= 1 &&
               trimmedContent.count <= 500
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockCommentService: CommentService {
    var shouldFailOperations = false
    var operationDelay: TimeInterval = 0.5
    var mockComments: [String: [Comment]] = [:] // postId -> [Comment]
    
    override init() {
        super.init()
        generateMockData()
    }
    
    private func generateMockData() {
        // Add some mock comments for different posts
        let mockUsers = [User.mock, User.mockWithAvatar]
        
        for postIndex in 0..<5 {
            let postId = "mock-post-\(postIndex)"
            let commentCount = Int.random(in: 0...5)
            
            mockComments[postId] = (0..<commentCount).map { commentIndex in
                Comment(
                    id: "mock-comment-\(postId)-\(commentIndex)",
                    content: "This is a mock comment \(commentIndex + 1) for post \(postIndex + 1)",
                    createdAt: Date().addingTimeInterval(-Double(commentIndex * 1800)),
                    updatedAt: Date().addingTimeInterval(-Double(commentIndex * 1800)),
                    user: mockUsers[commentIndex % mockUsers.count],
                    post: Post(
                        id: postId,
                        title: "Mock Post \(postIndex + 1)",
                        content: nil,
                        authorId: "",
                        author: nil,
                        createdAt: Date(),
                        likeCount: 0,
                        commentCount: 0,
                        isLiked: false
                    )
                )
            }
        }
    }
    
    override func createComment(postId: String, content: String) async throws -> Comment {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.validation(.required("Comment content"))
        }
        
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        let newComment = Comment(
            id: "mock-new-comment-\(UUID().uuidString)",
            content: content,
            createdAt: Date(),
            updatedAt: Date(),
            user: currentUser,
            post: Post(
                id: postId,
                title: "Mock Post",
                content: nil,
                authorId: "",
                author: nil,
                createdAt: Date(),
                likeCount: 0,
                commentCount: 0,
                isLiked: false
            )
        )
        
        if mockComments[postId] == nil {
            mockComments[postId] = []
        }
        mockComments[postId]?.insert(newComment, at: 0)
        
        return newComment
    }
    
    override func getComments(for postId: String, limit: Int = 20, offset: Int = 0) async throws -> [Comment] {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        let comments = mockComments[postId] ?? []
        let endIndex = min(offset + limit, comments.count)
        let startIndex = min(offset, comments.count)
        
        return Array(comments[startIndex..<endIndex])
    }
    
    override func getCommentCount(for postId: String) async throws -> Int {
        return mockComments[postId]?.count ?? 0
    }
}
#endif