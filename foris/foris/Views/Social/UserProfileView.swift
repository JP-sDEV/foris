import SwiftUI

/// Detailed user profile view with posts and follow information
struct UserProfileView: View {
    
    // MARK: - Properties
    
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var posts: [Post] = []
    @State private var isLoadingPosts = false
    @State private var followersCount = 0
    @State private var followingCount = 0
    @State private var isFollowing = false
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    
    // MARK: - Services
    
    @StateObject private var postService = PostService.shared
    @StateObject private var followService = FollowService.shared
    @StateObject private var authService = AuthService.shared
    
    // MARK: - Computed Properties
    
    private var isCurrentUser: Bool {
        guard let currentUser = authService.currentUser else { return false }
        return currentUser.id == user.id
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    profileHeader
                    
                    // Posts Section
                    postsSection
                }
            }
            .navigationTitle(user.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showFollowersList) {
            FollowListView(userId: user.id, listType: .followers)
        }
        .sheet(isPresented: $showFollowingList) {
            FollowListView(userId: user.id, listType: .following)
        }
        .task {
            await loadProfileData()
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 20) {
            // Avatar and Basic Info
            VStack(spacing: 12) {
                AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(user.initials)
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                
                VStack(spacing: 4) {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // Follow Stats
            HStack(spacing: 0) {
                // Posts
                VStack(spacing: 4) {
                    Text("\(posts.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Posts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // Followers
                Button(action: {
                    showFollowersList = true
                }) {
                    VStack(spacing: 4) {
                        Text("\(followersCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Followers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .frame(height: 40)
                
                // Following
                Button(action: {
                    showFollowingList = true
                }) {
                    VStack(spacing: 4) {
                        Text("\(followingCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Following")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 40)
            
            // Follow Button
            if !isCurrentUser {
                FollowButton(
                    userId: user.id,
                    isFollowing: isFollowing
                ) { newFollowStatus in
                    isFollowing = newFollowStatus
                    followersCount += newFollowStatus ? 1 : -1
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Posts Section
    
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            HStack {
                Text("Posts")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            if isLoadingPosts {
                // Loading state
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        postPlaceholder
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
            } else if posts.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text(isCurrentUser ? "You haven't posted anything yet" : "\(user.name) hasn't posted anything yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                
            } else {
                // Posts list
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        PostCard(
                            post: post,
                            onLike: {
                                // Handle like
                            },
                            onComment: {
                                // Handle comment
                            },
                            onShare: {
                                // Handle share
                            },
                            onDelete: isCurrentUser ? {
                                deletePost(post)
                            } : nil
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Post Placeholder
    
    private var postPlaceholder: some View {
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
    
    // MARK: - Actions
    
    private func loadProfileData() async {
        await withTaskGroup(of: Void.self) { group in
            // Load follow status
            if !isCurrentUser {
                group.addTask {
                    await self.loadFollowStatus()
                }
            }
            
            // Load follow counts
            group.addTask {
                await self.loadFollowCounts()
            }
            
            // Load user posts
            group.addTask {
                await self.loadUserPosts()
            }
        }
    }
    
    private func loadFollowStatus() async {
        do {
            let followStatus = try await followService.isFollowing(userId: user.id)
            await MainActor.run {
                isFollowing = followStatus
            }
        } catch {
            print("Failed to load follow status: \(error)")
        }
    }
    
    private func loadFollowCounts() async {
        do {
            let counts = try await followService.getFollowCounts(for: user.id)
            await MainActor.run {
                followersCount = counts.followers
                followingCount = counts.following
            }
        } catch {
            print("Failed to load follow counts: \(error)")
        }
    }
    
    private func loadUserPosts() async {
        isLoadingPosts = true
        
        do {
            let userPosts = try await postService.getUserPosts(userId: user.id)
            await MainActor.run {
                posts = userPosts
            }
        } catch {
            print("Failed to load user posts: \(error)")
        }
        
        isLoadingPosts = false
    }
    
    private func deletePost(_ post: Post) {
        Task {
            do {
                try await postService.deletePost(id: post.id)
                await MainActor.run {
                    posts.removeAll { $0.id == post.id }
                }
            } catch {
                print("Failed to delete post: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    UserProfileView(user: User.mock)
}