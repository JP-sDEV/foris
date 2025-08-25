import SwiftUI

/// View for searching and discovering users
struct UserSearchView: View {
    
    // MARK: - State
    
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    
    // MARK: - Services
    
    @StateObject private var followService = FollowService.shared
    
    // MARK: - Constants
    
    private let searchDebounceDelay: TimeInterval = 0.5
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Content
                if isSearching {
                    loadingView
                } else if searchText.isEmpty {
                    emptySearchView
                } else if searchResults.isEmpty {
                    noResultsView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Discover People")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search users...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchText) { newValue in
                        performSearch(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                        searchTask?.cancel()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty Search View
    
    private var emptySearchView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Discover People")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Search for users by name or email to connect with them")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - No Results View
    
    private var noResultsView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Users Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Try searching with different keywords")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Search Results List
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults) { user in
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
                    
                    if user.id != searchResults.last?.id {
                        Divider()
                            .padding(.leading, 78) // Align with user info
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Actions
    
    private func performSearch(query: String) {
        // Cancel previous search task
        searchTask?.cancel()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            searchResults = []
            return
        }
        
        // Create new search task with debounce
        searchTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(searchDebounceDelay * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                isSearching = true
            }
            
            do {
                let results = try await followService.searchUsers(query: trimmedQuery)
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
                
            } catch {
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
                
                print("Search failed: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    UserSearchView()
}