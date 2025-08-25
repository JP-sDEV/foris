import SwiftUI

/// Reusable follow button component with optimistic UI updates
struct FollowButton: View {
    
    // MARK: - Properties
    
    let userId: String
    let initialIsFollowing: Bool
    let onFollowToggled: ((Bool) -> Void)?
    
    // MARK: - State
    
    @State private var isFollowing: Bool
    @State private var isLoading = false
    
    // MARK: - Services
    
    @StateObject private var followService = FollowService.shared
    @StateObject private var authService = AuthService.shared
    
    // MARK: - Computed Properties
    
    private var isCurrentUser: Bool {
        guard let currentUser = authService.currentUser else { return false }
        return currentUser.id == userId
    }
    
    // MARK: - Initialization
    
    init(
        userId: String,
        isFollowing: Bool,
        onFollowToggled: ((Bool) -> Void)? = nil
    ) {
        self.userId = userId
        self.initialIsFollowing = isFollowing
        self.onFollowToggled = onFollowToggled
        
        // Initialize state
        self._isFollowing = State(initialValue: isFollowing)
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: toggleFollow) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 80, height: 32)
            } else {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isFollowing ? .secondary : .white)
                    .frame(width: 80, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFollowing ? Color.gray.opacity(0.2) : Color.accentColor)
                    )
            }
        }
        .disabled(isLoading || isCurrentUser)
        .opacity(isCurrentUser ? 0 : 1)
        .onAppear {
            // Sync state with initial value
            isFollowing = initialIsFollowing
        }
        .onChange(of: initialIsFollowing) { newValue in
            isFollowing = newValue
        }
    }
    
    // MARK: - Actions
    
    private func toggleFollow() {
        // Optimistic UI update
        let previousIsFollowing = isFollowing
        isFollowing.toggle()
        
        // Notify parent of change
        onFollowToggled?(isFollowing)
        
        // Perform actual follow operation
        Task {
            isLoading = true
            
            do {
                let actualIsFollowing = try await followService.toggleFollow(for: userId)
                
                // Update UI with actual result
                await MainActor.run {
                    isFollowing = actualIsFollowing
                    onFollowToggled?(isFollowing)
                }
                
            } catch {
                // Revert optimistic update on error
                await MainActor.run {
                    isFollowing = previousIsFollowing
                    onFollowToggled?(isFollowing)
                }
                
                print("Failed to toggle follow: \(error)")
            }
            
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        FollowButton(
            userId: "user1",
            isFollowing: false
        )
        
        FollowButton(
            userId: "user2",
            isFollowing: true
        )
        
        HStack {
            Text("In a card:")
            Spacer()
            FollowButton(
                userId: "user3",
                isFollowing: false
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    .padding()
}