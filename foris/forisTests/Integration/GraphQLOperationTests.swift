import XCTest
import Apollo
import ApolloAPI
@testable import foris

/// Integration tests for GraphQL operations with mock responses
/// Tests complete GraphQL workflows including queries, mutations, and subscriptions
final class GraphQLOperationTests: XCTestCase {
    
    // MARK: - Properties
    
    var graphqlService: MockGraphQLService!
    var userService: UserService!
    var postService: PostService!
    var challengeService: ChallengeService!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        graphqlService = MockGraphQLService()
        userService = UserService(graphqlService: graphqlService)
        postService = PostService(graphqlService: graphqlService)
        challengeService = ChallengeService(graphqlService: graphqlService)
    }
    
    override func tearDownWithError() throws {
        challengeService = nil
        postService = nil
        userService = nil
        graphqlService = nil
    }
    
    // MARK: - User Operations Tests
    
    func testGetUserProfileOperation() async {
        // Given
        let expectedUser = User.mock
        graphqlService.mockResponses["GetUserProfile"] = GetUserProfileData(
            user: expectedUser
        )
        
        // When
        do {
            let user = try await userService.getUserProfile(id: expectedUser.id)
            
            // Then
            XCTAssertEqual(user.id, expectedUser.id)
            XCTAssertEqual(user.name, expectedUser.name)
            XCTAssertEqual(user.email, expectedUser.email)
            
        } catch {
            XCTFail("Get user profile should succeed: \(error)")
        }
    }
    
    func testUpdateUserProfileOperation() async {
        // Given
        let updatedUser = User(
            id: "user1",
            name: "Updated Name",
            email: "updated@example.com",
            bio: "Updated bio",
            avatarUrl: "https://example.com/avatar.jpg"
        )
        
        graphqlService.mockResponses["UpdateUserProfile"] = UpdateUserProfileData(
            updateUser: updatedUser
        )
        
        // When
        do {
            let result = try await userService.updateProfile(
                name: updatedUser.name,
                bio: updatedUser.bio,
                avatarUrl: updatedUser.avatarUrl
            )
            
            // Then
            XCTAssertEqual(result.id, updatedUser.id)
            XCTAssertEqual(result.name, updatedUser.name)
            XCTAssertEqual(result.bio, updatedUser.bio)
            XCTAssertEqual(result.avatarUrl, updatedUser.avatarUrl)
            
        } catch {
            XCTFail("Update user profile should succeed: \(error)")
        }
    }
    
    func testGetUserProfileNotFound() async {
        // Given
        graphqlService.shouldFail = true
        graphqlService.mockError = GraphQLError.queryFailed("User not found")
        
        // When/Then
        do {
            _ = try await userService.getUserProfile(id: "nonexistent")
            XCTFail("Should throw error for nonexistent user")
        } catch {
            if case AppError.graphql(GraphQLError.queryFailed(let message)) = error {
                XCTAssertTrue(message.contains("User not found"))
            } else {
                XCTFail("Expected query failed error")
            }
        }
    }
    
    // MARK: - Post Operations Tests
    
    func testGetPostsOperation() async {
        // Given
        let expectedPosts = Post.mockArray(count: 5)
        graphqlService.mockResponses["GetPosts"] = GetPostsData(
            posts: expectedPosts,
            hasMore: true
        )
        
        // When
        do {
            let posts = try await postService.getPosts(limit: 10, offset: 0)
            
            // Then
            XCTAssertEqual(posts.count, 5)
            XCTAssertEqual(posts.first?.id, expectedPosts.first?.id)
            XCTAssertEqual(posts.last?.id, expectedPosts.last?.id)
            
        } catch {
            XCTFail("Get posts should succeed: \(error)")
        }
    }
    
    func testCreatePostOperation() async {
        // Given
        let newPost = Post(
            id: "new-post",
            title: "New Post",
            content: "This is a new post",
            authorId: "user1",
            author: User.mock,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            isLiked: false
        )
        
        graphqlService.mockResponses["CreatePost"] = CreatePostData(
            createPost: newPost
        )
        
        // When
        do {
            let createdPost = try await postService.createPost(
                title: newPost.title,
                content: newPost.content
            )
            
            // Then
            XCTAssertEqual(createdPost.id, newPost.id)
            XCTAssertEqual(createdPost.title, newPost.title)
            XCTAssertEqual(createdPost.content, newPost.content)
            XCTAssertEqual(createdPost.likeCount, 0)
            XCTAssertFalse(createdPost.isLiked)
            
        } catch {
            XCTFail("Create post should succeed: \(error)")
        }
    }
    
    func testCreatePostValidationError() async {
        // Given
        graphqlService.shouldFail = true
        graphqlService.mockError = GraphQLError.mutationFailed("Title is required")
        
        // When/Then
        do {
            _ = try await postService.createPost(title: "", content: "Content")
            XCTFail("Should throw validation error")
        } catch {
            if case AppError.graphql(GraphQLError.mutationFailed(let message)) = error {
                XCTAssertTrue(message.contains("Title is required"))
            } else {
                XCTFail("Expected mutation failed error")
            }
        }
    }
    
    func testLikePostOperation() async {
        // Given
        let postId = "post1"
        graphqlService.mockResponses["LikePost"] = LikePostData(
            likePost: LikeResult(success: true, isLiked: true, likeCount: 5)
        )
        
        // When
        do {
            let result = try await postService.likePost(id: postId)
            
            // Then
            XCTAssertTrue(result.success)
            XCTAssertTrue(result.isLiked)
            XCTAssertEqual(result.likeCount, 5)
            
        } catch {
            XCTFail("Like post should succeed: \(error)")
        }
    }
    
    func testUnlikePostOperation() async {
        // Given
        let postId = "post1"
        graphqlService.mockResponses["UnlikePost"] = UnlikePostData(
            unlikePost: LikeResult(success: true, isLiked: false, likeCount: 4)
        )
        
        // When
        do {
            let result = try await postService.unlikePost(id: postId)
            
            // Then
            XCTAssertTrue(result.success)
            XCTAssertFalse(result.isLiked)
            XCTAssertEqual(result.likeCount, 4)
            
        } catch {
            XCTFail("Unlike post should succeed: \(error)")
        }
    }
    
    // MARK: - Challenge Operations Tests
    
    func testGetChallengesOperation() async {
        // Given
        let expectedChallenges = Challenge.mockArray(count: 3)
        graphqlService.mockResponses["GetChallenges"] = GetChallengesData(
            challenges: expectedChallenges
        )
        
        // When
        do {
            let challenges = try await challengeService.getChallenges()
            
            // Then
            XCTAssertEqual(challenges.count, 3)
            XCTAssertEqual(challenges.first?.id, expectedChallenges.first?.id)
            XCTAssertEqual(challenges.first?.name, expectedChallenges.first?.name)
            
        } catch {
            XCTFail("Get challenges should succeed: \(error)")
        }
    }
    
    func testJoinChallengeOperation() async {
        // Given
        let challengeId = "challenge1"
        graphqlService.mockResponses["JoinChallenge"] = JoinChallengeData(
            joinChallenge: ChallengeResult(
                success: true,
                userChallenge: UserChallenge(
                    id: "uc1",
                    challengeId: challengeId,
                    userId: "user1",
                    status: .inProgress,
                    joinedAt: Date()
                )
            )
        )
        
        // When
        do {
            let result = try await challengeService.joinChallenge(id: challengeId)
            
            // Then
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.userChallenge)
            XCTAssertEqual(result.userChallenge?.challengeId, challengeId)
            XCTAssertEqual(result.userChallenge?.status, .inProgress)
            
        } catch {
            XCTFail("Join challenge should succeed: \(error)")
        }
    }
    
    func testJoinChallengeAlreadyJoined() async {
        // Given
        graphqlService.shouldFail = true
        graphqlService.mockError = GraphQLError.mutationFailed("Already joined this challenge")
        
        // When/Then
        do {
            _ = try await challengeService.joinChallenge(id: "challenge1")
            XCTFail("Should throw error for already joined challenge")
        } catch {
            if case AppError.graphql(GraphQLError.mutationFailed(let message)) = error {
                XCTAssertTrue(message.contains("Already joined"))
            } else {
                XCTFail("Expected mutation failed error")
            }
        }
    }
    
    func testCompleteChallengeOperation() async {
        // Given
        let challengeId = "challenge1"
        graphqlService.mockResponses["CompleteChallenge"] = CompleteChallengeData(
            completeChallenge: ChallengeResult(
                success: true,
                userChallenge: UserChallenge(
                    id: "uc1",
                    challengeId: challengeId,
                    userId: "user1",
                    status: .completed,
                    joinedAt: Date().addingTimeInterval(-86400),
                    completedAt: Date()
                )
            )
        )
        
        // When
        do {
            let result = try await challengeService.completeChallenge(id: challengeId)
            
            // Then
            XCTAssertTrue(result.success)
            XCTAssertEqual(result.userChallenge?.status, .completed)
            XCTAssertNotNil(result.userChallenge?.completedAt)
            
        } catch {
            XCTFail("Complete challenge should succeed: \(error)")
        }
    }
    
    // MARK: - Authentication Operations Tests
    
    func testCreateAuthOperation() async {
        // Given
        let authResult = AuthResult(
            user: User.mock,
            accessToken: "access_token",
            refreshToken: "refresh_token"
        )
        
        graphqlService.mockResponses["CreateAuth"] = CreateAuthData(
            createAuth: authResult
        )
        
        // When
        do {
            let result = try await performCreateAuth(
                provider: "google",
                idToken: "google_id_token"
            )
            
            // Then
            XCTAssertNotNil(result.user)
            XCTAssertEqual(result.accessToken, "access_token")
            XCTAssertEqual(result.refreshToken, "refresh_token")
            
        } catch {
            XCTFail("Create auth should succeed: \(error)")
        }
    }
    
    func testRefreshTokenOperation() async {
        // Given
        let refreshResult = AuthResult(
            user: User.mock,
            accessToken: "new_access_token",
            refreshToken: "new_refresh_token"
        )
        
        graphqlService.mockResponses["RefreshToken"] = RefreshTokenData(
            refreshToken: refreshResult
        )
        
        // When
        do {
            let result = try await performRefreshToken(refreshToken: "old_refresh_token")
            
            // Then
            XCTAssertNotNil(result.user)
            XCTAssertEqual(result.accessToken, "new_access_token")
            XCTAssertEqual(result.refreshToken, "new_refresh_token")
            
        } catch {
            XCTFail("Refresh token should succeed: \(error)")
        }
    }
    
    func testRefreshTokenExpired() async {
        // Given
        graphqlService.shouldFail = true
        graphqlService.mockError = GraphQLError.authenticationRequired
        
        // When/Then
        do {
            _ = try await performRefreshToken(refreshToken: "expired_token")
            XCTFail("Should throw authentication error")
        } catch {
            if case AppError.graphql(GraphQLError.authenticationRequired) = error {
                // Expected
            } else {
                XCTFail("Expected authentication required error")
            }
        }
    }
    
    // MARK: - Subscription Operations Tests
    
    func testPostUpdatesSubscription() async {
        // Given
        let subscription = PostUpdatesSubscription()
        
        // When
        let stream = graphqlService.subscribe(subscription)
        
        // Then
        var receivedUpdates: [PostUpdateData] = []
        
        do {
            for try await update in stream {
                receivedUpdates.append(update)
                if receivedUpdates.count >= 2 {
                    break
                }
            }
            
            XCTAssertEqual(receivedUpdates.count, 2)
            
        } catch {
            XCTFail("Post updates subscription should succeed: \(error)")
        }
    }
    
    func testChallengeUpdatesSubscription() async {
        // Given
        let subscription = ChallengeUpdatesSubscription()
        
        // When
        let stream = graphqlService.subscribe(subscription)
        
        // Then
        var receivedUpdates: [ChallengeUpdateData] = []
        
        do {
            for try await update in stream {
                receivedUpdates.append(update)
                if receivedUpdates.count >= 1 {
                    break
                }
            }
            
            XCTAssertEqual(receivedUpdates.count, 1)
            
        } catch {
            XCTFail("Challenge updates subscription should succeed: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() async {
        // Given
        graphqlService.shouldFail = true
        graphqlService.mockError = GraphQLError.networkError(URLError(.notConnectedToInternet))
        
        // When/Then
        do {
            _ = try await userService.getUserProfile(id: "user1")
            XCTFail("Should throw network error")
        } catch {
            if case AppError.graphql(GraphQLError.networkError) = error {
                // Expected
            } else {
                XCTFail("Expected network error")
            }
        }
    }
    
    func testServerErrorHandling() async {
        // Given
        graphqlService.shouldFail = true
        graphqlService.mockError = GraphQLError.serverError("Internal server error")
        
        // When/Then
        do {
            _ = try await postService.getPosts(limit: 10, offset: 0)
            XCTFail("Should throw server error")
        } catch {
            if case AppError.graphql(GraphQLError.serverError(let message)) = error {
                XCTAssertTrue(message.contains("Internal server error"))
            } else {
                XCTFail("Expected server error")
            }
        }
    }
    
    func testRateLimitHandling() async {
        // Given
        graphqlService.shouldFail = true
        graphqlService.mockError = GraphQLError.rateLimited
        
        // When/Then
        do {
            _ = try await postService.createPost(title: "Test", content: "Content")
            XCTFail("Should throw rate limit error")
        } catch {
            if case AppError.graphql(GraphQLError.rateLimited) = error {
                // Expected
            } else {
                XCTFail("Expected rate limited error")
            }
        }
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentQueries() async {
        // Given
        let user1 = User.mock
        let user2 = User(id: "user2", name: "User 2", email: "user2@test.com", bio: nil, avatarUrl: nil)
        
        graphqlService.mockResponses["GetUserProfile"] = GetUserProfileData(user: user1)
        
        // When - Execute concurrent queries
        async let result1 = userService.getUserProfile(id: user1.id)
        async let result2 = userService.getUserProfile(id: user2.id)
        async let result3 = userService.getUserProfile(id: user1.id)
        
        // Then
        do {
            let (r1, r2, r3) = try await (result1, result2, result3)
            
            XCTAssertEqual(r1.id, user1.id)
            XCTAssertEqual(r2.id, user1.id) // Mock returns same user
            XCTAssertEqual(r3.id, user1.id)
            
        } catch {
            XCTFail("Concurrent queries should succeed: \(error)")
        }
    }
    
    func testConcurrentMutations() async {
        // Given
        let post1 = Post.mock
        let post2 = Post(
            id: "post2",
            title: "Post 2",
            content: "Content 2",
            authorId: "user1",
            author: User.mock,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            isLiked: false
        )
        
        graphqlService.mockResponses["CreatePost"] = CreatePostData(createPost: post1)
        
        // When - Execute concurrent mutations
        async let result1 = postService.createPost(title: post1.title, content: post1.content)
        async let result2 = postService.createPost(title: post2.title, content: post2.content)
        
        // Then
        do {
            let (r1, r2) = try await (result1, result2)
            
            XCTAssertEqual(r1.title, post1.title)
            XCTAssertEqual(r2.title, post1.title) // Mock returns same post
            
        } catch {
            XCTFail("Concurrent mutations should succeed: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testQueryPerformance() {
        // Given
        graphqlService.mockDelay = 0.01 // Very fast for performance testing
        graphqlService.mockResponses["GetPosts"] = GetPostsData(
            posts: Post.mockArray(count: 100),
            hasMore: false
        )
        
        // When/Then
        measure {
            let expectation = XCTestExpectation(description: "Query performance")
            
            Task {
                do {
                    _ = try await postService.getPosts(limit: 100, offset: 0)
                    expectation.fulfill()
                } catch {
                    XCTFail("Query should succeed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func performCreateAuth(provider: String, idToken: String) async throws -> AuthResult {
        // This would be implemented in the actual AuthService
        // For testing, we simulate the GraphQL operation
        let query = CreateAuthMutation(provider: provider, idToken: idToken)
        let data = try await graphqlService.perform(query)
        return data.createAuth
    }
    
    private func performRefreshToken(refreshToken: String) async throws -> AuthResult {
        // This would be implemented in the actual AuthService
        let mutation = RefreshTokenMutation(refreshToken: refreshToken)
        let data = try await graphqlService.perform(mutation)
        return data.refreshToken
    }
}

// MARK: - Mock GraphQL Data Types

struct GetUserProfileData: Codable {
    let user: User
}

struct UpdateUserProfileData: Codable {
    let updateUser: User
}

struct GetPostsData: Codable {
    let posts: [Post]
    let hasMore: Bool
}

struct CreatePostData: Codable {
    let createPost: Post
}

struct LikePostData: Codable {
    let likePost: LikeResult
}

struct UnlikePostData: Codable {
    let unlikePost: LikeResult
}

struct LikeResult: Codable {
    let success: Bool
    let isLiked: Bool
    let likeCount: Int
}

struct GetChallengesData: Codable {
    let challenges: [Challenge]
}

struct JoinChallengeData: Codable {
    let joinChallenge: ChallengeResult
}

struct CompleteChallengeData: Codable {
    let completeChallenge: ChallengeResult
}

struct ChallengeResult: Codable {
    let success: Bool
    let userChallenge: UserChallenge?
}

struct UserChallenge: Codable {
    let id: String
    let challengeId: String
    let userId: String
    let status: ChallengeStatus
    let joinedAt: Date
    let completedAt: Date?
}

enum ChallengeStatus: String, Codable {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case failed = "FAILED"
}

struct CreateAuthData: Codable {
    let createAuth: AuthResult
}

struct RefreshTokenData: Codable {
    let refreshToken: AuthResult
}

// MARK: - Mock GraphQL Operations

struct CreateAuthMutation: GraphQLMutation {
    static let operationName: String = "CreateAuth"
    static let operationDocument: ApolloAPI.OperationDocument = .init(definition: .init("mutation CreateAuth($provider: String!, $idToken: String!) { createAuth(provider: $provider, idToken: $idToken) { user { id name email } accessToken refreshToken } }"))
    
    let provider: String
    let idToken: String
    
    typealias Data = CreateAuthData
}

struct RefreshTokenMutation: GraphQLMutation {
    static let operationName: String = "RefreshToken"
    static let operationDocument: ApolloAPI.OperationDocument = .init(definition: .init("mutation RefreshToken($refreshToken: String!) { refreshToken(refreshToken: $refreshToken) { user { id name email } accessToken refreshToken } }"))
    
    let refreshToken: String
    
    typealias Data = RefreshTokenData
}

struct PostUpdatesSubscription: GraphQLSubscription {
    static let operationName: String = "PostUpdates"
    static let operationDocument: ApolloAPI.OperationDocument = .init(definition: .init("subscription PostUpdates { postUpdated { id title author { name } } }"))
    
    typealias Data = PostUpdateData
}

struct PostUpdateData: Codable {
    let postUpdated: Post
}

struct ChallengeUpdatesSubscription: GraphQLSubscription {
    static let operationName: String = "ChallengeUpdates"
    static let operationDocument: ApolloAPI.OperationDocument = .init(definition: .init("subscription ChallengeUpdates { challengeUpdated { id name } }"))
    
    typealias Data = ChallengeUpdateData
}

struct ChallengeUpdateData: Codable {
    let challengeUpdated: Challenge
}

// MARK: - Mock Extensions

extension Challenge {
    static func mockArray(count: Int) -> [Challenge] {
        return (0..<count).map { index in
            Challenge(
                id: "challenge\(index)",
                name: "Challenge \(index + 1)",
                description: "Description for challenge \(index + 1)",
                createdBy: "admin",
                endDate: Date().addingTimeInterval(Double(index + 1) * 86400),
                userStatus: nil
            )
        }
    }
}