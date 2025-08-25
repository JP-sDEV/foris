import SwiftUI

/// View for displaying followers or following lists
struct FollowListView: View {
    
    // MARK: - Types
    
    enum ListType {
        case followers
        case following
        
        var title: String {
            switch self {
            case .followers:
                return "Followers"
            case .following:
                return "Following"
            }
        }
        
        var emptyTitle: String {
            switch self {
            case .followers:
                return "No Followers Yet"
            case .following:
                return "Not Following Anyone"
            }
        }
        
        var emptyMessage: String {
            switch self {
            case .followers:
                return "When people follow you, they'll appear here"
            case .following:
                return "Start following people to see them here"
            }
        }
    }
    
    // MARK: - Properties
    
    let userId: String
    let listType: ListType
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var hasMoreUsers = true
    @State private var currentOffset = 0
    
    // MARK: - Services
    
    @StateObject private var followService = FollowService.shared
    
    // MARK: - Constants
    
    private let pageSize = 20
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if isLoading && users.isEmpty {
                    loadingView
                } else if users.isEmpty {
                    emptyStateView
                } else {
                    usersList
                }
            }
            .navigationTitle(listType.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            await loadUsers()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                userPlaceholder
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: listType == .followers ? "person.2" : "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(listType.emptyTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(listType.emptyMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Users List
    
    private var usersList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(users.enumerated()), id: \.element.id) { index, user in
                    UserCard(
                        user: user,
                        showFollowButton: true,
                        onUserTapped: { user in
                            // Navigate to user profile
                        },
                        onFollowTapped: { user in
                            // Handle follow action
                        }
                    )
                    .onAppear {
                        checkForLoadMore(at: index)
                    }
                    
                    if user.id != users.last?.id {
                        Divider()
                            .padding(.leading, 78) // Align with user info
                    }
                }
                
                // Load more indicator
                if isLoadingMore {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading more...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            await refreshUsers()
        }
    }
    
    // MARK: - User Placeholder
    
    private var userPlaceholder: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 10)
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .redacted(reason: .placeholder)
    }
    
    // MARK: - Actions
    
    private func loadUsers() async {
        guard !isLoading else { return }
        
        isLoading = true
        currentOffset = 0
        hasMoreUsers = true
        
        do {
            let newUsers = try await loadUsersForType(limit: pageSize, offset: 0)
            await MainActor.run {
                users = newUsers
                currentOffset = newUsers.count
                hasMoreUsers = newUsers.count == pageSize
            }
        } catch {
            print("Failed to load users: \(error)")
        }
        
        isLoading = false
    }
    
    private func refreshUsers() async {
        await loadUsers()
    }
    
    private func loadMoreUsers() async {
        guard !isLoadingMore && hasMoreUsers else { return }
        
        isLoadingMore = true
        
        do {
            let moreUsers = try await loadUsersForType(limit: pageSize, offset: currentOffset)
            await MainActor.run {
                users.append(contentsOf: moreUsers)
                currentOffset += moreUsers.count
                hasMoreUsers = moreUsers.count == pageSize
            }
        } catch {
            print("Failed to load more users: \(error)")
        }
        
        isLoadingMore = false
    }
    
    private func loadUsersForType(limit: Int, offset: Int) async throws -> [User] {
        switch listType {
        case .followers:
            return try await followService.getFollowers(limit: limit, offset: offset)
        case .following:
            return try await followService.getFollowing(limit: limit, offset: offset)
        }
    }
    
    private func checkForLoadMore(at index: Int) {
        // Load more when we're 5 users from the end
        if index >= users.count - 5 && hasMoreUsers && !isLoadingMore {
            Task {
                await loadMoreUsers()
            }
        }
    }
}

// MARK: - Preview

#Preview("Followers") {
    FollowListView(
        userId: "current-user",
        listType: .followers
    )
}

#Preview("Following") {
    FollowListView(
        userId: "current-user",
        listType: .following
    )
}