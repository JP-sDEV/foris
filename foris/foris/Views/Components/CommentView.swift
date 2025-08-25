import SwiftUI

/// View for displaying individual comments
struct CommentView: View {
    
    // MARK: - Properties
    
    let comment: Comment
    let onUserTapped: ((User) -> Void)?
    let onDeleteTapped: (() -> Void)?
    
    // MARK: - Services
    
    @StateObject private var authService = AuthService.shared
    
    // MARK: - State
    
    @State private var showDeleteAlert = false
    
    // MARK: - Computed Properties
    
    private var canDelete: Bool {
        guard let currentUser = authService.currentUser else { return false }
        return currentUser.id == comment.user.id
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: comment.createdAt, relativeTo: Date())
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User Avatar
            Button(action: {
                onUserTapped?(comment.user)
            }) {
                AsyncImage(url: URL(string: comment.user.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(comment.user.name.prefix(1).uppercased())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                // Comment Header
                HStack {
                    Button(action: {
                        onUserTapped?(comment.user)
                    }) {
                        Text(comment.user.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if canDelete {
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Comment Content
                Text(comment.content)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 4)
        .alert("Delete Comment", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDeleteTapped?()
            }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        CommentView(
            comment: Comment(
                id: "1",
                content: "This is a great post! Thanks for sharing your insights.",
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                updatedAt: Date().addingTimeInterval(-3600),
                user: User.mock,
                post: Post(
                    id: "post1",
                    title: "Sample Post",
                    content: nil,
                    authorId: "author1",
                    author: nil,
                    createdAt: Date(),
                    likeCount: 0,
                    commentCount: 0,
                    isLiked: false
                )
            ),
            onUserTapped: { user in
                print("User tapped: \(user.name)")
            },
            onDeleteTapped: {
                print("Delete tapped")
            }
        )
        
        CommentView(
            comment: Comment(
                id: "2",
                content: "I completely agree with this approach. It's been working well for me too.",
                createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
                updatedAt: Date().addingTimeInterval(-7200),
                user: User.mockWithAvatar,
                post: Post(
                    id: "post1",
                    title: "Sample Post",
                    content: nil,
                    authorId: "author1",
                    author: nil,
                    createdAt: Date(),
                    likeCount: 0,
                    commentCount: 0,
                    isLiked: false
                )
            ),
            onUserTapped: { user in
                print("User tapped: \(user.name)")
            },
            onDeleteTapped: {
                print("Delete tapped")
            }
        )
    }
    .padding()
}