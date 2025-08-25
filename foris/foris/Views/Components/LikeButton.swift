import SwiftUI

/// Reusable like button component with optimistic UI updates
struct LikeButton: View {
    
    // MARK: - Properties
    
    let postId: String
    let initialLikeCount: Int
    let initialIsLiked: Bool
    let onLikeToggled: ((Bool, Int) -> Void)?
    
    // MARK: - State
    
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var isAnimating = false
    @State private var isLoading = false
    
    // MARK: - Services
    
    @StateObject private var likeService = LikeService.shared
    
    // MARK: - Initialization
    
    init(
        postId: String,
        likeCount: Int,
        isLiked: Bool,
        onLikeToggled: ((Bool, Int) -> Void)? = nil
    ) {
        self.postId = postId
        self.initialLikeCount = likeCount
        self.initialIsLiked = isLiked
        self.onLikeToggled = onLikeToggled
        
        // Initialize state
        self._isLiked = State(initialValue: isLiked)
        self._likeCount = State(initialValue: likeCount)
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: toggleLike) {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : .secondary)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .respectReduceMotion(
                        animation: .easeInOut(duration: 0.1),
                        value: isAnimating,
                        fallbackAnimation: nil
                    )
                
                if likeCount > 0 {
                    Text("\(likeCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .dynamicTypeSupport()
                }
            }
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
        .accessibilityButton(
            label: isLiked ? "Unlike post" : "Like post",
            hint: isLoading ? "Please wait" : (likeCount > 0 ? "\(likeCount) likes" : "No likes yet"),
            isEnabled: !isLoading
        )
        .accessibilityValue(likeCount > 0 ? "\(likeCount) likes" : "")
        .highContrastBorder()
        .onAppear {
            // Sync state with initial values
            isLiked = initialIsLiked
            likeCount = initialLikeCount
        }
        .onChange(of: initialIsLiked) { newValue in
            isLiked = newValue
        }
        .onChange(of: initialLikeCount) { newValue in
            likeCount = newValue
        }
    }
    
    // MARK: - Actions
    
    private func toggleLike() {
        // Optimistic UI update
        let previousIsLiked = isLiked
        let previousLikeCount = likeCount
        
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1
        
        // Trigger animation
        withAnimation(.easeInOut(duration: 0.1)) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAnimating = false
        }
        
        // Notify parent of change
        onLikeToggled?(isLiked, likeCount)
        
        // Perform actual like operation
        Task {
            isLoading = true
            
            do {
                let actualIsLiked = try await likeService.toggleLike(for: postId)
                
                // Update UI with actual result
                await MainActor.run {
                    isLiked = actualIsLiked
                    likeCount = previousLikeCount + (actualIsLiked ? 1 : -1)
                    onLikeToggled?(isLiked, likeCount)
                }
                
            } catch {
                // Revert optimistic update on error
                await MainActor.run {
                    isLiked = previousIsLiked
                    likeCount = previousLikeCount
                    onLikeToggled?(isLiked, likeCount)
                }
                
                print("Failed to toggle like: \(error)")
            }
            
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        LikeButton(
            postId: "1",
            likeCount: 0,
            isLiked: false
        )
        
        LikeButton(
            postId: "2",
            likeCount: 5,
            isLiked: false
        )
        
        LikeButton(
            postId: "3",
            likeCount: 12,
            isLiked: true
        )
    }
    .padding()
}