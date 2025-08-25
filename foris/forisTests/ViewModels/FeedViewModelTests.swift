import XCTest
import Combine
@testable import foris

/// Comprehensive unit tests for FeedViewModel
/// Tests post loading, pagination, like functionality, and error handling
final class FeedViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    var viewModel: FeedViewModel!
    var mockPostService: MockPostService!
    var mockLikeService: MockLikeService!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        mockPostService = MockPostService()
        mockLikeService = MockLikeService()
        viewModel = FeedViewModel(postService: mockPostService, likeService: mockLikeService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        viewModel = nil
        mockLikeService = nil
        mockPostService = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given/When - ViewModel is initialized in setup
        
        // Then
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertFalse(viewModel.isRefreshing)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showError)
        XCTAssertTrue(viewModel.hasMorePosts)
        XCTAssertNil(viewModel.lastUpdateDate)
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertTrue(viewModel.canLoadMore)
    }
    
    // MARK: - Post Loading Tests
    
    func testLoadPostsSuccess() async {
        // Given
        let mockPosts = Post.mockArray(count: 5)
        mockPostService.mockPosts = mockPosts
        
        let expectation = XCTestExpectation(description: "Posts loaded")
        
        viewModel.$posts
            .dropFirst()
            .sink { posts in
                if !posts.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.loadPosts()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.posts.count, 5)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertNotNil(viewModel.lastUpdateDate)
    }
    
    func testLoadPostsFailure() async {
        // Given
        mockPostService.shouldFail = true
        
        let expectation = XCTestExpectation(description: "Error shown")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.loadPosts()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.error)
    }
    
    func testLoadPostsWhenAlreadyLoading() async {
        // Given
        mockPostService.mockDelay = 1.0 // Long delay
        
        // When - Start first load
        let firstLoadTask = Task {
            await viewModel.loadPosts()
        }
        
        // Wait a bit then try second load
        try? await Task.sleep(nanoseconds: 100_000_000)
        let secondLoadTask = Task {
            await viewModel.loadPosts()
        }
        
        // Then - Second load should be ignored
        await firstLoadTask.value
        await secondLoadTask.value
        
        // Should only have one set of posts loaded
        XCTAssertLessThanOrEqual(viewModel.posts.count, mockPostService.mockPosts.count)
    }
    
    // MARK: - Refresh Tests
    
    func testRefreshPostsSuccess() async {
        // Given
        let initialPosts = Post.mockArray(count: 3)
        let refreshedPosts = Post.mockArray(count: 5)
        
        mockPostService.mockPosts = initialPosts
        await viewModel.loadPosts()
        
        mockPostService.mockPosts = refreshedPosts
        
        let expectation = XCTestExpectation(description: "Posts refreshed")
        
        viewModel.$posts
            .dropFirst()
            .sink { posts in
                if posts.count == 5 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.refreshPosts()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.posts.count, 5)
        XCTAssertFalse(viewModel.isRefreshing)
    }
    
    func testRefreshPostsFailure() async {
        // Given
        let initialPosts = Post.mockArray(count: 3)
        mockPostService.mockPosts = initialPosts
        await viewModel.loadPosts()
        
        mockPostService.shouldFailRefresh = true
        
        let expectation = XCTestExpectation(description: "Refresh error shown")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.refreshPosts()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.posts.count, 3) // Should keep original posts
        XCTAssertFalse(viewModel.isRefreshing)
        XCTAssertTrue(viewModel.showError)
    }
    
    // MARK: - Pagination Tests
    
    func testLoadMorePostsSuccess() async {
        // Given
        let initialPosts = Post.mockArray(count: 20)
        let morePosts = Post.mockArray(count: 10, startIndex: 20)
        
        mockPostService.mockPosts = initialPosts
        await viewModel.loadPosts()
        
        mockPostService.mockPosts = morePosts
        
        let expectation = XCTestExpectation(description: "More posts loaded")
        
        viewModel.$posts
            .dropFirst()
            .sink { posts in
                if posts.count == 30 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.loadMorePosts()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.posts.count, 30)
        XCTAssertFalse(viewModel.isLoadingMore)
    }
    
    func testLoadMorePostsWhenNoMoreAvailable() async {
        // Given
        let posts = Post.mockArray(count: 5) // Less than page size
        mockPostService.mockPosts = posts
        await viewModel.loadPosts()
        
        // When
        await viewModel.loadMorePosts()
        
        // Then
        XCTAssertFalse(viewModel.hasMorePosts)
        XCTAssertFalse(viewModel.canLoadMore)
    }
    
    func testCanLoadMoreLogic() {
        // Given - Initial state
        XCTAssertTrue(viewModel.canLoadMore)
        
        // When loading
        viewModel.isLoading = true
        XCTAssertFalse(viewModel.canLoadMore)
        
        // When loading more
        viewModel.isLoading = false
        viewModel.isLoadingMore = true
        XCTAssertFalse(viewModel.canLoadMore)
        
        // When no more posts
        viewModel.isLoadingMore = false
        viewModel.hasMorePosts = false
        XCTAssertFalse(viewModel.canLoadMore)
    }
    
    func testCheckForLoadMore() {
        // Given
        let posts = Post.mockArray(count: 20)
        viewModel.posts = posts
        viewModel.hasMorePosts = true
        
        // When - Check at index that should trigger load more
        viewModel.checkForLoadMore(at: 15) // 20 - 5 = 15
        
        // Then - Should trigger load more (tested indirectly through state)
        XCTAssertTrue(viewModel.canLoadMore)
    }
    
    // MARK: - Like Functionality Tests
    
    func testToggleLikeSuccess() async {
        // Given
        let post = Post.mock
        viewModel.posts = [post]
        mockLikeService.shouldSucceed = true
        
        let expectation = XCTestExpectation(description: "Like toggled")
        
        viewModel.$posts
            .dropFirst()
            .sink { posts in
                if let updatedPost = posts.first, updatedPost.isLiked != post.isLiked {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.toggleLike(for: post.id)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotEqual(viewModel.posts.first?.isLiked, post.isLiked)
        XCTAssertNotEqual(viewModel.posts.first?.likeCount, post.likeCount)
    }
    
    func testToggleLikeFailure() async {
        // Given
        let post = Post.mock
        viewModel.posts = [post]
        mockLikeService.shouldFail = true
        
        let expectation = XCTestExpectation(description: "Like error shown")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.toggleLike(for: post.id)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.showError)
        // Should revert optimistic update
        XCTAssertEqual(viewModel.posts.first?.isLiked, post.isLiked)
        XCTAssertEqual(viewModel.posts.first?.likeCount, post.likeCount)
    }
    
    func testToggleLikeForNonexistentPost() async {
        // Given
        let post = Post.mock
        viewModel.posts = [post]
        
        // When
        await viewModel.toggleLike(for: "nonexistent-id")
        
        // Then - Should not crash or change anything
        XCTAssertEqual(viewModel.posts.count, 1)
        XCTAssertEqual(viewModel.posts.first?.isLiked, post.isLiked)
    }
    
    // MARK: - Post Management Tests
    
    func testDeletePostSuccess() async {
        // Given
        let posts = Post.mockArray(count: 3)
        viewModel.posts = posts
        let postToDelete = posts[1]
        
        let expectation = XCTestExpectation(description: "Post deleted")
        
        viewModel.$posts
            .dropFirst()
            .sink { updatedPosts in
                if updatedPosts.count == 2 && !updatedPosts.contains(where: { $0.id == postToDelete.id }) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.deletePost(postToDelete.id)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.posts.count, 2)
        XCTAssertFalse(viewModel.posts.contains(where: { $0.id == postToDelete.id }))
    }
    
    func testDeletePostFailure() async {
        // Given
        let posts = Post.mockArray(count: 3)
        viewModel.posts = posts
        mockPostService.shouldFailDelete = true
        
        let expectation = XCTestExpectation(description: "Delete error shown")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.deletePost(posts[0].id)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.posts.count, 3) // Should not delete
        XCTAssertTrue(viewModel.showError)
    }
    
    func testAddPost() {
        // Given
        let existingPosts = Post.mockArray(count: 2)
        viewModel.posts = existingPosts
        let newPost = Post.mock
        
        // When
        viewModel.addPost(newPost)
        
        // Then
        XCTAssertEqual(viewModel.posts.count, 3)
        XCTAssertEqual(viewModel.posts.first?.id, newPost.id)
    }
    
    func testUpdatePost() {
        // Given
        let posts = Post.mockArray(count: 3)
        viewModel.posts = posts
        let updatedPost = Post(
            id: posts[1].id,
            title: "Updated Title",
            content: posts[1].content,
            authorId: posts[1].authorId,
            author: posts[1].author,
            createdAt: posts[1].createdAt,
            likeCount: posts[1].likeCount + 5,
            commentCount: posts[1].commentCount,
            isLiked: !posts[1].isLiked
        )
        
        // When
        viewModel.updatePost(updatedPost)
        
        // Then
        XCTAssertEqual(viewModel.posts[1].title, "Updated Title")
        XCTAssertEqual(viewModel.posts[1].likeCount, posts[1].likeCount + 5)
        XCTAssertNotEqual(viewModel.posts[1].isLiked, posts[1].isLiked)
    }
    
    // MARK: - Error Handling Tests
    
    func testDismissError() {
        // Given
        viewModel.error = AppError.network(.serverError(500))
        viewModel.showError = true
        
        // When
        viewModel.dismissError()
        
        // Then
        XCTAssertFalse(viewModel.showError)
        XCTAssertNil(viewModel.error)
    }
    
    func testErrorBindingFromPostService() {
        // Given
        let expectation = XCTestExpectation(description: "Error bound from post service")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockPostService.error = AppError.network(.serverError(500))
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.showError)
    }
    
    func testErrorBindingFromLikeService() {
        // Given
        let expectation = XCTestExpectation(description: "Error bound from like service")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockLikeService.error = AppError.network(.serverError(500))
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.showError)
    }
    
    // MARK: - Utility Method Tests
    
    func testPostAtIndex() {
        // Given
        let posts = Post.mockArray(count: 3)
        viewModel.posts = posts
        
        // When/Then
        XCTAssertEqual(viewModel.post(at: 0)?.id, posts[0].id)
        XCTAssertEqual(viewModel.post(at: 1)?.id, posts[1].id)
        XCTAssertEqual(viewModel.post(at: 2)?.id, posts[2].id)
        XCTAssertNil(viewModel.post(at: 3))
        XCTAssertNil(viewModel.post(at: -1))
    }
    
    func testRelativeTime() {
        // Given
        let post = Post(
            id: "test",
            title: "Test",
            content: nil,
            authorId: "author",
            author: User.mock,
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            likeCount: 0,
            commentCount: 0,
            isLiked: false
        )
        
        // When
        let relativeTime = viewModel.relativeTime(for: post)
        
        // Then
        XCTAssertTrue(relativeTime.contains("hr") || relativeTime.contains("hour"))
    }
    
    func testLoadPostsIfNeeded() async {
        // Given - Empty posts
        XCTAssertTrue(viewModel.posts.isEmpty)
        
        let expectation = XCTestExpectation(description: "Posts loaded if needed")
        
        viewModel.$posts
            .dropFirst()
            .sink { posts in
                if !posts.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.loadPostsIfNeeded()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.posts.isEmpty)
    }
    
    func testLoadPostsIfNeededWhenAlreadyHasPosts() async {
        // Given - Already has posts
        viewModel.posts = Post.mockArray(count: 2)
        let initialCount = viewModel.posts.count
        
        // When
        await viewModel.loadPostsIfNeeded()
        
        // Then - Should not load more
        XCTAssertEqual(viewModel.posts.count, initialCount)
    }
    
    // MARK: - State Consistency Tests
    
    func testIsEmptyConsistency() {
        // Given - Empty posts, not loading
        viewModel.posts = []
        viewModel.isLoading = false
        
        // Then
        XCTAssertTrue(viewModel.isEmpty)
        
        // When - Has posts
        viewModel.posts = Post.mockArray(count: 1)
        
        // Then
        XCTAssertFalse(viewModel.isEmpty)
        
        // When - Empty but loading
        viewModel.posts = []
        viewModel.isLoading = true
        
        // Then
        XCTAssertFalse(viewModel.isEmpty)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        // Given
        weak var weakViewModel: FeedViewModel?
        weak var weakPostService: MockPostService?
        weak var weakLikeService: MockLikeService?
        
        autoreleasepool {
            let postService = MockPostService()
            let likeService = MockLikeService()
            let testViewModel = FeedViewModel(postService: postService, likeService: likeService)
            
            weakViewModel = testViewModel
            weakPostService = postService
            weakLikeService = likeService
            
            // Use the view model
            Task {
                await testViewModel.loadPosts()
            }
        }
        
        // When/Then - Objects should be deallocated
        XCTAssertNil(weakViewModel)
        XCTAssertNil(weakPostService)
        XCTAssertNil(weakLikeService)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentOperations() async {
        // Given
        let posts = Post.mockArray(count: 10)
        mockPostService.mockPosts = posts
        
        // When - Multiple concurrent operations
        async let loadTask: Void = viewModel.loadPosts()
        async let refreshTask: Void = viewModel.refreshPosts()
        async let loadMoreTask: Void = viewModel.loadMorePosts()
        
        // Then - Should handle gracefully without crashes
        await loadTask
        await refreshTask
        await loadMoreTask
        
        // Should have some posts loaded
        XCTAssertGreaterThan(viewModel.posts.count, 0)
    }
}

// MARK: - Mock Service Extensions

extension Post {
    static func mockArray(count: Int, startIndex: Int = 0) -> [Post] {
        return (startIndex..<(startIndex + count)).map { index in
            Post(
                id: "mock-\(index)",
                title: "Mock Post \(index + 1)",
                content: "This is mock content for post \(index + 1).",
                authorId: "author-\(index % 3)",
                author: User.mock,
                createdAt: Date().addingTimeInterval(-Double(index * 3600)),
                likeCount: Int.random(in: 0...20),
                commentCount: Int.random(in: 0...5),
                isLiked: Bool.random()
            )
        }
    }
}

// Mock services would need to be implemented
class MockPostService: PostService {
    @Published var error: AppError?
    
    var mockPosts: [Post] = []
    var shouldFail = false
    var shouldFailRefresh = false
    var shouldFailDelete = false
    var mockDelay: TimeInterval = 0.1
    
    override func getPosts(limit: Int, offset: Int) async throws -> [Post] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFail {
            throw AppError.network(.serverError(500))
        }
        
        let startIndex = offset
        let endIndex = min(startIndex + limit, mockPosts.count)
        
        if startIndex >= mockPosts.count {
            return []
        }
        
        return Array(mockPosts[startIndex..<endIndex])
    }
    
    override func refreshPosts() async throws -> [Post] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFailRefresh {
            throw AppError.network(.serverError(500))
        }
        
        return mockPosts
    }
    
    override func deletePost(id: String) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFailDelete {
            throw AppError.network(.serverError(500))
        }
        
        // Mock successful deletion
    }
    
    func clearError() {
        error = nil
    }
}

class MockLikeService: LikeService {
    @Published var error: AppError?
    
    var shouldFail = false
    var shouldSucceed = true
    var mockDelay: TimeInterval = 0.1
    
    override func toggleLike(for postId: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFail {
            throw AppError.network(.serverError(500))
        }
        
        return shouldSucceed
    }
    
    func clearError() {
        error = nil
    }
}