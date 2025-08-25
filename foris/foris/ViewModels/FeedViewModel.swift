import Foundation
import Combine

/// ViewModel for the main feed displaying posts
/// Handles post loading, pagination, and user interactions
@MainActor
final class FeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isRefreshing = false
    @Published var error: AppError?
    @Published var showError = false
    @Published var hasMorePosts = true
    @Published var lastUpdateDate: Date?
    
    // MARK: - Private Properties
    
    private let postService: PostService
    private let likeService: LikeService
    private var cancellables = Set<AnyCancellable>()
    private var currentOffset = 0
    private let pageSize = 20
    
    // MARK: - Computed Properties
    
    var isEmpty: Bool {
        return posts.isEmpty && !isLoading
    }
    
    var canLoadMore: Bool {
        return hasMorePosts && !isLoading && !isLoadingMore
    }
    
    // MARK: - Initialization
    
    init(
        postService: PostService = PostService.shared,
        likeService: LikeService = LikeService.shared
    ) {
        self.postService = postService
        self.likeService = likeService
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind post service errors
        postService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
        
        // Bind like service errors
        likeService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Post Loading
    
    /// Loads initial posts
    func loadPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        currentOffset = 0
        hasMorePosts = true
        
        do {
            let newPosts = try await postService.getPosts(limit: pageSize, offset: 0)
            posts = newPosts
            currentOffset = newPosts.count
            hasMorePosts = newPosts.count == pageSize
            lastUpdateDate = Date()
            
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
        
        isLoading = false
    }
    
    /// Refreshes posts (pull-to-refresh)
    func refreshPosts() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        currentOffset = 0
        hasMorePosts = true
        
        do {
            let refreshedPosts = try await postService.refreshPosts()
            posts = refreshedPosts
            currentOffset = refreshedPosts.count
            hasMorePosts = refreshedPosts.count == pageSize
            lastUpdateDate = Date()
            
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
        
        isRefreshing = false
    }
    
    /// Loads more posts (pagination)
    func loadMorePosts() async {
        guard canLoadMore else { return }
        
        isLoadingMore = true
        
        do {
            let morePosts = try await postService.getPosts(limit: pageSize, offset: currentOffset)
            posts.append(contentsOf: morePosts)
            currentOffset += morePosts.count
            hasMorePosts = morePosts.count == pageSize
            
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
        
        isLoadingMore = false
    }
    
    /// Loads posts if needed (called when view appears)
    func loadPostsIfNeeded() async {
        if posts.isEmpty {
            await loadPosts()
        }
    }
    
    // MARK: - Post Actions
    
    /// Toggles like status for a post
    /// - Parameter postId: Post ID to toggle like
    func toggleLike(for postId: String) async {
        // Find the post and update optimistically
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        
        let post = posts[index]
        let newLikeCount = post.isLiked ? post.likeCount - 1 : post.likeCount + 1
        let newIsLiked = !post.isLiked
        
        // Update UI optimistically
        posts[index] = Post(
            id: post.id,
            title: post.title,
            content: post.content,
            authorId: post.authorId,
            author: post.author,
            createdAt: post.createdAt,
            likeCount: newLikeCount,
            commentCount: post.commentCount,
            isLiked: newIsLiked
        )
        
        // Perform actual like/unlike operation
        do {
            let actualIsLiked = try await likeService.toggleLike(for: postId)
            
            // Update with actual result (in case of discrepancy)
            posts[index] = Post(
                id: post.id,
                title: post.title,
                content: post.content,
                authorId: post.authorId,
                author: post.author,
                createdAt: post.createdAt,
                likeCount: post.likeCount + (actualIsLiked ? 1 : -1),
                commentCount: post.commentCount,
                isLiked: actualIsLiked
            )
            
        } catch {
            // Revert optimistic update on failure
            posts[index] = post
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    /// Deletes a post
    /// - Parameter postId: Post ID to delete
    func deletePost(_ postId: String) async {
        do {
            try await postService.deletePost(id: postId)
            
            // Remove from local list
            posts.removeAll { $0.id == postId }
            
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    /// Adds a new post to the beginning of the feed
    /// - Parameter post: Post to add
    func addPost(_ post: Post) {
        posts.insert(post, at: 0)
        currentOffset += 1
    }
    
    /// Updates an existing post in the feed
    /// - Parameter post: Updated post
    func updatePost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index] = post
    }
    
    // MARK: - Error Handling
    
    private func showError(_ error: AppError) {
        self.error = error
        showError = true
    }
    
    /// Dismisses the current error
    func dismissError() {
        showError = false
        error = nil
        postService.clearError()
        likeService.clearError()
    }
    
    // MARK: - Utility Methods
    
    /// Returns the post at the specified index
    /// - Parameter index: Index of the post
    /// - Returns: Post if found
    func post(at index: Int) -> Post? {
        guard index >= 0 && index < posts.count else { return nil }
        return posts[index]
    }
    
    /// Checks if we should load more posts when reaching a certain index
    /// - Parameter index: Current index being displayed
    func checkForLoadMore(at index: Int) {
        // Load more when we're 5 posts from the end
        if index >= posts.count - 5 && canLoadMore {
            Task {
                await loadMorePosts()
            }
        }
    }
    
    /// Gets the relative time string for a post
    /// - Parameter post: Post to get time for
    /// - Returns: Relative time string
    func relativeTime(for post: Post) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: post.createdAt, relativeTo: Date())
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
extension FeedViewModel {
    /// Creates a mock FeedViewModel for testing and previews
    /// - Parameters:
    ///   - posts: Posts to display
    ///   - isLoading: Whether to show loading state
    ///   - isEmpty: Whether to show empty state
    /// - Returns: Configured mock FeedViewModel
    static func mock(
        posts: [Post] = [],
        isLoading: Bool = false,
        isEmpty: Bool = false
    ) -> FeedViewModel {
        let mockPostService = MockPostService()
        let mockLikeService = MockLikeService()
        let viewModel = FeedViewModel(postService: mockPostService, likeService: mockLikeService)
        
        if isEmpty {
            viewModel.posts = []
        } else if posts.isEmpty {
            // Generate mock posts
            viewModel.posts = (0..<5).map { index in
                Post(
                    id: "mock-\(index)",
                    title: "Mock Post \(index + 1)",
                    content: "This is mock content for post \(index + 1).",
                    authorId: index % 2 == 0 ? User.mock.id : User.mockWithAvatar.id,
                    author: index % 2 == 0 ? User.mock : User.mockWithAvatar,
                    createdAt: Date().addingTimeInterval(-Double(index * 3600)),
                    likeCount: Int.random(in: 0...20),
                    commentCount: Int.random(in: 0...5),
                    isLiked: Bool.random()
                )
            }
        } else {
            viewModel.posts = posts
        }
        
        viewModel.isLoading = isLoading
        
        return viewModel
    }
    
    /// Creates a mock FeedViewModel in loading state
    /// - Returns: Configured mock FeedViewModel
    static func mockLoading() -> FeedViewModel {
        return mock(isLoading: true)
    }
    
    /// Creates a mock FeedViewModel in empty state
    /// - Returns: Configured mock FeedViewModel
    static func mockEmpty() -> FeedViewModel {
        return mock(isEmpty: true)
    }
    
    /// Creates a mock FeedViewModel with error state
    /// - Parameter error: Error to display
    /// - Returns: Configured mock FeedViewModel
    static func mockError(_ error: AppError = AppError.network(.serverError(500))) -> FeedViewModel {
        let viewModel = mock()
        viewModel.error = error
        viewModel.showError = true
        return viewModel
    }
}
#endif