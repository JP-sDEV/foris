import SwiftUI

/// Detailed view of a post with comments
struct PostDetailView: View {
    
    // MARK: - Properties
    
    let post: Post
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var comments: [Comment] = []
    @State private var isLoadingComments = false
    @State private var showDeleteAlert = false
    
    // MARK: - Services
    
    @StateObject private var commentService = CommentService.shared
    @StateObject private var authService = AuthService.shared
    
    // MARK: - Computed Properties
    
    private var canDeletePost: Bool {
        guard let currentUser = authService.currentUser else { return false }
        return currentUser.id == post.authorId
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Post content
                ScrollView {
                    VStack(spacing: 0) {
                        // Post card
                        PostCard(
                            post: post,
                            onLike: {
                                // Handle like
                            },
                            onComment: {
                                // Scroll to comments or focus input
                            },
                            onShare: {
                                // Handle share
                            },
                            onDelete: canDeletePost ? {
                                showDeleteAlert = true
                            } : nil
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Comments section
                        commentsSection
                    }
                }
                
                // Comment input
                CommentInputView(
                    postId: post.id
                ) { newComment in
                    comments.insert(newComment, at: 0)
                }
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if canDeletePost {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Delete Post", role: .destructive) {
                                showDeleteAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
            .alert("Delete Post", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Handle post deletion
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this post? This action cannot be undone.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            await loadComments()
        }
    }
    
    // MARK: - Comments Section
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Comments header
            HStack {
                Text("Comments")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if comments.count > 0 {
                    Text("(\(comments.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            if isLoadingComments {
                // Loading state
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        commentPlaceholder
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
            } else if comments.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No comments yet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Be the first to share your thoughts!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                
            } else {
                // Comments list
                LazyVStack(spacing: 0) {
                    ForEach(comments) { comment in
                        CommentView(
                            comment: comment,
                            onUserTapped: { user in
                                // Navigate to user profile
                            },
                            onDeleteTapped: {
                                deleteComment(comment)
                            }
                        )
                        .padding(.horizontal, 16)
                        
                        if comment.id != comments.last?.id {
                            Divider()
                                .padding(.leading, 60) // Align with comment content
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Comment Placeholder
    
    private var commentPlaceholder: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 10)
                    
                    Spacer()
                }
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 14)
            }
        }
        .redacted(reason: .placeholder)
    }
    
    // MARK: - Actions
    
    private func loadComments() async {
        isLoadingComments = true
        
        do {
            let loadedComments = try await commentService.getComments(for: post.id)
            await MainActor.run {
                comments = loadedComments
            }
        } catch {
            print("Failed to load comments: \(error)")
        }
        
        isLoadingComments = false
    }
    
    private func deleteComment(_ comment: Comment) {
        Task {
            do {
                try await commentService.deleteComment(id: comment.id)
                await MainActor.run {
                    comments.removeAll { $0.id == comment.id }
                }
            } catch {
                print("Failed to delete comment: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PostDetailView(
        post: Post(
            id: "1",
            title: "Great workout today! 💪",
            content: "Just finished an amazing session at the gym. Feeling energized and ready for the rest of the day! The new routine is really paying off and I can see improvements in my strength and endurance.",
            authorId: "user1",
            author: User.mock,
            createdAt: Date().addingTimeInterval(-3600),
            likeCount: 12,
            commentCount: 3,
            isLiked: true
        )
    )
}