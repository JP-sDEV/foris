import SwiftUI

/// Main feed view displaying posts in a scrollable list
/// Supports pull-to-refresh, infinite scrolling, and post interactions
struct FeedView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = FeedViewModel()
    @State private var showCreatePost = false
    @State private var selectedPost: Post?
    @State private var refreshTrigger = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    // Loading state with skeleton
                    VStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { index in
                            SkeletonLayouts.postCard()
                                .slideIn(delay: Double(index) * 0.1)
                        }
                    }
                    .padding(.horizontal)
                } else if viewModel.isEmpty {
                    // Enhanced empty state
                    EmptyStateView.emptyFeed {
                        HapticFeedbackService.shared.buttonTap()
                        showCreatePost = true
                    }
                    .fadeIn()
                    .announceScreenChange("Feed is empty. Create your first post to get started.")
                } else {
                    // Posts list with animations
                    postsListView
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticFeedbackService.shared.buttonTap()
                        showCreatePost = true
                    } label: {
                        AccessibleImage(
                            systemName: "plus",
                            accessibilityLabel: "Create new post"
                        )
                        .font(.title2)
                    }
                    .accessibilityButton(
                        label: "Create new post",
                        hint: "Opens the post creation screen"
                    )
                    .buttonStyle(.hapticLight)
                    .highContrastBorder()
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView { newPost in
                    viewModel.addPost(newPost)
                }
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
            .alert("Feed Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
                
                Button("Retry") {
                    Task {
                        await viewModel.loadPosts()
                    }
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            await viewModel.loadPostsIfNeeded()
        }
        .keyboardNavigable(
            onUpArrow: {
                // Navigate to previous post or scroll up
            },
            onDownArrow: {
                // Navigate to next post or scroll down
            },
            onEnter: {
                // Open first post or create new post
                showCreatePost = true
            }
        )
        .announceScreenChange("Feed loaded with \(viewModel.posts.count) posts")
        .validateAccessibility()
        .accessibilityTestingOverlay()
    }
    
    // MARK: - Posts List
    
    private var postsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Stale data indicator
                if let lastUpdate = viewModel.lastUpdateDate {
                    StaleDataIndicator(lastUpdated: lastUpdate)
                        .padding(.horizontal)
                }
                
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                    PostCard(
                        post: post,
                        onLike: {
                            HapticFeedbackService.shared.likeAction()
                            Task {
                                await viewModel.toggleLike(for: post.id)
                            }
                        },
                        onComment: {
                            HapticFeedbackService.shared.buttonTap()
                            selectedPost = post
                        },
                        onShare: {
                            HapticFeedbackService.shared.buttonTap()
                            // Share post
                        },
                        onDelete: viewModel.post(at: index)?.authorId == getCurrentUserId() ? {
                            HapticFeedbackService.shared.destructiveAction()
                            Task {
                                await viewModel.deletePost(post.id)
                            }
                        } : nil
                    )
                    .slideIn(delay: Double(index) * 0.05)
                    .onAppear {
                        viewModel.checkForLoadMore(at: index)
                    }
                }
                
                // Load more indicator with animation
                if viewModel.isLoadingMore {
                    HStack(spacing: 12) {
                        LoadingDots()
                        AccessibleText(
                            "Loading more posts...",
                            font: .caption,
                            color: .secondary
                        )
                    }
                    .padding()
                    .fadeIn()
                    .accessibilityLabel("Loading more posts")
                    .announceContentChange("Loading more posts")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .refreshable {
            HapticFeedbackService.shared.pullToRefresh()
            refreshTrigger.toggle()
            await viewModel.refreshPosts()
            
            // Announce refresh completion
            UIAccessibility.post(
                notification: .announcement,
                argument: "Feed refreshed with \(viewModel.posts.count) posts"
            )
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: NetworkError) {
        HapticFeedbackService.shared.operationFailed()
        // Error handling is now done through the enhanced ErrorView
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String? {
        // TODO: Get current user ID from auth service
        return "current-user-id"
    }
}

// MARK: - Post Card

struct PostCard: View {
    let post: Post
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with author info
            headerView
            
            // Post content
            contentView
            
            // Action buttons
            actionButtonsView
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
        )
        .alert("Delete Post", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Author avatar with caching
            CachedImageView.avatar(
                url: URL(string: post.author?.avatarUrl ?? ""),
                size: 40
            )
            .accessibilityLabel("Author profile picture")
            
            // Author info
            VStack(alignment: .leading, spacing: 2) {
                AccessibleText(
                    post.author?.name ?? "Unknown User",
                    font: .subheadline,
                    color: .primary
                )
                .fontWeight(.semibold)
                
                AccessibleText(
                    relativeTime(for: post.createdAt),
                    font: .caption,
                    color: .secondary
                )
            }
            
            Spacer()
            
            // More options menu
            if onDelete != nil {
                Menu {
                    Button("Delete", role: .destructive) {
                        showDeleteAlert = true
                    }
                } label: {
                    AccessibleImage(
                        systemName: "ellipsis",
                        accessibilityLabel: "Post options"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                }
                .accessibilityButton(
                    label: "Post options",
                    hint: "Opens menu with post actions"
                )
                .highContrastBorder()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Post by \(post.author?.name ?? "Unknown User"), \(relativeTime(for: post.createdAt))")
    }
    
    // MARK: - Content
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            AccessibleText(
                post.title,
                font: .headline,
                color: .primary,
                isHeader: true
            )
            .fontWeight(.semibold)
            .multilineTextAlignment(.leading)
            
            // Content
            if let content = post.content, !content.isEmpty {
                AccessibleText(
                    content,
                    font: .body,
                    color: .secondary
                )
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Post: \(post.title). \(post.content ?? "")")
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        HStack(spacing: 24) {
            // Like button with animation
            LikeButton(
                postId: post.id,
                likeCount: post.likeCount,
                isLiked: post.isLiked
            ) { isLiked, likeCount in
                onLike()
            }
            .bounce(trigger: post.isLiked)
            
            // Comment button
            CommentButton(
                postId: post.id,
                commentCount: post.commentCount
            ) {
                onComment()
            }
            .buttonStyle(.hapticLight)
            
            // Share button with haptic feedback
            Button(action: onShare) {
                AccessibleImage(
                    systemName: "square.and.arrow.up",
                    accessibilityLabel: "Share post"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .buttonStyle(.hapticLight)
            .accessibilityButton(
                label: "Share post",
                hint: "Opens sharing options for this post"
            )
            .highContrastBorder()
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    // MARK: - Helper Methods
    
    private func relativeTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Loading View Extension

extension LoadingView {
    static func feed() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        // Header placeholder
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 12)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 10)
                            }
                            
                            Spacer()
                        }
                        
                        // Content placeholder
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 16)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 14)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 14)
                        }
                        
                        // Actions placeholder
                        HStack(spacing: 24) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 30, height: 12)
                            }
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .redacted(reason: .placeholder)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .accessibilityLabel("Loading posts")
    }
}

// MARK: - Preview Provider

#Preview("Feed with Posts") {
    FeedView()
        .environmentObject(FeedViewModel.mock())
}

#Preview("Loading Feed") {
    FeedView()
        .environmentObject(FeedViewModel.mockLoading())
}

#Preview("Empty Feed") {
    FeedView()
        .environmentObject(FeedViewModel.mockEmpty())
}

#Preview("Post Card") {
    PostCard(
        post: Post(
            id: "1",
            title: "Great workout today! 💪",
            content: "Just finished an amazing session at the gym. Feeling energized and ready for the rest of the day!",
            authorId: "user1",
            author: User.mock,
            createdAt: Date().addingTimeInterval(-3600),
            likeCount: 12,
            commentCount: 3,
            isLiked: true
        ),
        onLike: {},
        onComment: {},
        onShare: {},
        onDelete: {}
    )
    .padding()
}

#Preview("Dark Mode") {
    FeedView()
        .environmentObject(FeedViewModel.mock())
        .preferredColorScheme(.dark)
}