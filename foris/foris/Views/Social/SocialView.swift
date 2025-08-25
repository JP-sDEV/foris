import SwiftUI

/// Main social view with user discovery and follow management
struct SocialView: View {
    
    // MARK: - State
    
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @State private var followersCount = 0
    @State private var followingCount = 0
    @State private var isLoadingCounts = false
    
    // MARK: - Services
    
    @StateObject private var followService = FollowService.shared
    @StateObject private var authService = AuthService.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Follow Stats Card
                    followStatsCard
                    
                    // User Search Section
                    userSearchSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadFollowCounts()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showFollowersList) {
            if let currentUser = authService.currentUser {
                FollowListView(userId: currentUser.id, listType: .followers)
            }
        }
        .sheet(isPresented: $showFollowingList) {
            if let currentUser = authService.currentUser {
                FollowListView(userId: currentUser.id, listType: .following)
            }
        }
        .task {
            await loadFollowCounts()
        }
    }
    
    // MARK: - Follow Stats Card
    
    private var followStatsCard: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Your Network")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isLoadingCounts {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Stats
            HStack(spacing: 0) {
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
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
    
    // MARK: - User Search Section
    
    private var userSearchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Discover People")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Search Card
            NavigationLink(destination: UserSearchView()) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Search Users")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Find people to connect with")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
            }
            .buttonStyle(PlainButtonStyle())
            
            // Suggested Actions
            VStack(spacing: 12) {
                suggestionCard(
                    icon: "person.2.fill",
                    title: "Invite Friends",
                    subtitle: "Share the app with your friends",
                    action: {
                        // Handle invite friends
                    }
                )
                
                suggestionCard(
                    icon: "person.crop.circle.badge.plus",
                    title: "Find Contacts",
                    subtitle: "Connect with people from your contacts",
                    action: {
                        // Handle find contacts
                    }
                )
            }
        }
    }
    
    // MARK: - Suggestion Card
    
    private func suggestionCard(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions
    
    private func loadFollowCounts() async {
        guard let currentUser = authService.currentUser else { return }
        
        isLoadingCounts = true
        
        do {
            let counts = try await followService.getFollowCounts(for: currentUser.id)
            await MainActor.run {
                followersCount = counts.followers
                followingCount = counts.following
            }
        } catch {
            print("Failed to load follow counts: \(error)")
        }
        
        isLoadingCounts = false
    }
}

// MARK: - Preview

#Preview {
    SocialView()
}