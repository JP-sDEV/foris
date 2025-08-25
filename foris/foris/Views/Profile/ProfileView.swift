import SwiftUI

/// Main profile view displaying user information and actions
/// Supports both current user and other users with appropriate actions
struct ProfileView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    init(user: User? = nil) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }
    
    init(viewModel: ProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.user == nil {
                    // Loading state
                    LoadingView.profile()
                } else if let user = viewModel.user {
                    // Profile content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile header
                            profileHeaderView(user: user)
                            
                            // Stats section
                            statsView
                            
                            // Action buttons
                            actionButtonsView
                            
                            // Bio section
                            if !viewModel.displayBio.isEmpty {
                                bioView
                            }
                            
                            // Sync status (only for current user)
                            if viewModel.isCurrentUser {
                                SyncStatusView()
                            }
                            
                            // Posts section (placeholder)
                            postsPlaceholderView
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await viewModel.refreshProfile()
                    }
                } else {
                    // Error state
                    ErrorView(
                        error: viewModel.error ?? AppError.unknown("Failed to load profile"),
                        onRetry: {
                            Task {
                                await viewModel.loadCurrentUserProfile()
                            }
                        }
                    )
                }
            }
            .navigationTitle(viewModel.isCurrentUser ? "Profile" : viewModel.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.canEdit {
                        Button("Edit") {
                            viewModel.startEditing()
                        }
                        .disabled(viewModel.isLoading)
                        .accessibilityButton(
                            label: "Edit profile",
                            hint: "Opens profile editing screen",
                            isEnabled: !viewModel.isLoading
                        )
                        .highContrastBorder()
                    }
                }
            }
            .sheet(isPresented: $viewModel.isEditing) {
                EditProfileView(viewModel: viewModel)
            }
            .alert("Profile Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            if viewModel.user == nil {
                await viewModel.loadCurrentUserProfile()
            }
        }
        .keyboardNavigable(
            onEnter: {
                if viewModel.canEdit {
                    viewModel.startEditing()
                }
            }
        )
        .announceScreenChange(viewModel.isCurrentUser ? "Your profile" : "\(viewModel.displayName)'s profile")
        .validateAccessibility()
        .accessibilityTestingOverlay()
    }
    
    // MARK: - Profile Header
    
    private func profileHeaderView(user: User) -> some View {
        VStack(spacing: 16) {
            // Avatar
            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .overlay(
                        Text(viewModel.initials)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
            )
            .accessibilityLabel(user.avatarUrl != nil ? "Profile picture for \(user.name)" : "Default profile picture for \(user.name)")
            .accessibilityAddTraits(.isImage)
            .highContrastBorder()
            
            // Name and email
            VStack(spacing: 4) {
                AccessibleText(
                    user.name,
                    font: .title2,
                    color: .primary,
                    isHeader: true
                )
                .fontWeight(.bold)
                
                AccessibleText(
                    user.email,
                    font: .subheadline,
                    color: .secondary
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("User profile: \(user.name), email: \(user.email)")
        }
    }
    
    // MARK: - Stats View
    
    private var statsView: some View {
        HStack(spacing: 32) {
            StatView(
                title: "Followers",
                count: viewModel.followerCount
            ) {
                // Navigate to followers list
            }
            
            StatView(
                title: "Following",
                count: viewModel.followingCount
            ) {
                // Navigate to following list
            }
            
            StatView(
                title: "Posts",
                count: 0 // TODO: Implement post count
            ) {
                // Navigate to posts list
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            if viewModel.isCurrentUser {
                // Current user actions
                Button("Edit Profile") {
                    viewModel.startEditing()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                
                Button("Settings") {
                    // Navigate to settings
                }
                .buttonStyle(.bordered)
                
            } else {
                // Other user actions
                Button(viewModel.isFollowing ? "Unfollow" : "Follow") {
                    Task {
                        await viewModel.toggleFollow()
                    }
                }
                .buttonStyle(viewModel.isFollowing ? .bordered : .borderedProminent)
                .disabled(viewModel.isLoading)
                
                Button("Message") {
                    // Navigate to messages
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Bio View
    
    private var bioView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Text(viewModel.displayBio)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Posts Placeholder
    
    private var postsPlaceholderView: some View {
        VStack(spacing: 16) {
            Text("Posts")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                
                Text("No posts yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if viewModel.isCurrentUser {
                    Text("Share your fitness journey!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Stat View

struct StatView: View {
    let title: String
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count) \(title)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Loading View Extension

extension LoadingView {
    static func profile() -> some View {
        VStack(spacing: 20) {
            // Avatar placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 100)
                .redacted(reason: .placeholder)
            
            // Name placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 20)
                .redacted(reason: .placeholder)
            
            // Email placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 16)
                .redacted(reason: .placeholder)
            
            // Stats placeholder
            HStack(spacing: 32) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 30, height: 20)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 12)
                    }
                    .redacted(reason: .placeholder)
                }
            }
            .padding(.top, 20)
        }
        .accessibilityLabel("Loading profile")
    }
}

// MARK: - Preview Provider

#Preview("Current User") {
    ProfileView(viewModel: ProfileViewModel.mock())
}

#Preview("Other User") {
    ProfileView(viewModel: ProfileViewModel.mockOtherUser())
}

#Preview("Loading") {
    ProfileView(viewModel: ProfileViewModel.mockLoading())
}

#Preview("Dark Mode") {
    ProfileView(viewModel: ProfileViewModel.mock())
        .preferredColorScheme(.dark)
}

#Preview("iPad") {
    ProfileView(viewModel: ProfileViewModel.mock())
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}