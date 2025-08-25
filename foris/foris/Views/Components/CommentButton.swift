import SwiftUI

/// Reusable comment button component
struct CommentButton: View {
    
    // MARK: - Properties
    
    let postId: String
    let commentCount: Int
    let onCommentTapped: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            onCommentTapped?()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "bubble.left")
                    .foregroundColor(.secondary)
                
                if commentCount > 0 {
                    Text("\(commentCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CommentButton(
            postId: "1",
            commentCount: 0,
            onCommentTapped: nil
        )
        
        CommentButton(
            postId: "2",
            commentCount: 5,
            onCommentTapped: nil
        )
        
        CommentButton(
            postId: "3",
            commentCount: 23,
            onCommentTapped: nil
        )
    }
    .padding()
}