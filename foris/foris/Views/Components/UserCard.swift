import SwiftUI

/// Reusable user card component with follow button
struct UserCard: View {
    
    // MARK: - Properties
    
    let user: User
    let showFollowButton: Bool
    let onUserTapped: ((User) -> Void)?
    
    // MARK: - State
    
    @State private var showUserProfile = false
    let onFollowTapped: ((User) -> Void)?
    
    // MARK: - State
    
    @State private var isFollowing = false
    @State private var isLoading = false
    @State private var followersCount = 0
    @State private var followingCount = 0
    
    // MARK: - Services
    
    @StateObject private var followService = FollowService.shared
    @StateObject private var authService = AuthService.shared
    
    // MARK: - Computed Properties
    
    private var isCurrentUser: Bool {
        guard let currentUser = authService.currentUser else { return false }
        return currentUser.id == user.id
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            Button(action: {
                onUserTapped?(user)
                showUserProfile = true
            }) {
                AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            AccessibleText(
                                user.initials,
                                font: .subheadline,
                                color: .secondary
                            )
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityButton(
                label: "View \(user.name)'s profile",
                hint: "Opens user profile"
            )
            .highContrastBorder()
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Button(action: {
                    onUserTapped?(user)
                    showUserProfile = true
                }) {
                    VStack(alignment: .leading, spacing: 2) {
                        AccessibleText(
                            user.name,
                            font: .subheadline,
                            color: .primary
                        )
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        
                        if let bio = user.bio, !bio.isEmpty {
                            AccessibleText(
                                bio,
                                font: .caption,
                                color: .secondary
                            )
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityButton(
                    label: "View \(user.name)'s profile",
                    hint: user.bio != nil ? "Bio: \(user.bio!)" : "No bio available"
                )
                
                // Follow counts
                if followersCount > 0 || followingCount > 0 {
                    HStack(spacing: 12) {
                        if followersCount > 0 {
                            AccessibleText(
                                "\(followersCount) followers",
                                font: .caption2,
                                color: .secondary
                            )
                        }
                        
                        if followingCount > 0 {
                            AccessibleText(
                                "\(followingCount) following",
                                font: .caption2,
                                color: .secondary
                            )
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(followersCount) followers, \(followingCount) following")
                }
            }
            
            Spacer()
            
            // Follow Button
            if showFollowButton && !isCurrentUser {
                Button(action: {
                    onFollowTapped?(user)
                    toggleFollow()
                }) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 80, height: 32)
                            .accessibilityLabel("Processing follow request")
                    } else {
                        AccessibleText(
                            isFollowing ? "Following" : "Follow",
                            font: .caption,
                            color: isFollowing ? .secondary : .white
                        )
                        .fontWeight(.semibold)
                        .frame(width: 80, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isFollowing ? Color.gray.opacity(0.2) : Color.accentColor)
                        )
                    }
                }
                .disabled(isLoading)
                .accessibilityButton(
                    label: isFollowing ? "Unfollow \(user.name)" : "Follow \(user.name)",
                    hint: isLoading ? "Please wait" : (isFollowing ? "Tap to unfollow this user" : "Tap to follow this user"),
                    isEnabled: !isLoading
                )
                .highContrastBorder()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .task {
            await loadFollowStatus()
            await loadFollowCounts()
        }
        .sheet(isPresented: $showUserProfile) {
            UserProfileView(user: user)
        }
    }
    
    // MARK: - Actions
    
    private func toggleFollow() {
        Task {
            isLoading = true
            
            do {
                let newFollowStatus = try await followService.toggleFollow(for: user.id)
                await MainActor.run {
                    isFollowing = newFollowStatus
                    // Update follower count optimistically
                    followersCount += newFollowStatus ? 1 : -1
                }
            } catch {
                print("Failed to toggle follow: \(error)")
            }
            
            isLoading = false
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
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        UserCard(
            user: User.mock,
            showFollowButton: true,
            onUserTapped: { user in
                print("User tapped: \(user.name)")
            },
            onFollowTapped: { user in
                print("Follow tapped: \(user.name)")
            }
        )
        
        UserCard(
            user: User.mockWithAvatar,
            showFollowButton: true,
            onUserTapped: { user in
                print("User tapped: \(user.name)")
            },
            onFollowTapped: { user in
                print("Follow tapped: \(user.name)")
            }
        )
        
        UserCard(
            user: User(
                id: "user3",
                name: "Long Name That Should Wrap Properly",
                email: "long@example.com",
                bio: "This is a longer bio that should demonstrate how the text wraps in the user card component when there's more content to display.",
                avatarUrl: nil
            ),
            showFollowButton: false,
            onUserTapped: { user in
                print("User tapped: \(user.name)")
            },
            onFollowTapped: nil
        )
    }
    .padding()
}