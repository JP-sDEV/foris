import SwiftUI

/// View for inputting new comments
struct CommentInputView: View {
    
    // MARK: - Properties
    
    let postId: String
    let onCommentCreated: ((Comment) -> Void)?
    
    // MARK: - State
    
    @State private var commentText = ""
    @State private var isSubmitting = false
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Services
    
    @StateObject private var commentService = CommentService.shared
    @StateObject private var authService = AuthService.shared
    
    // MARK: - Constants
    
    private let maxCharacters = 500
    
    // MARK: - Computed Properties
    
    private var canSubmit: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        commentText.count <= maxCharacters &&
        !isSubmitting &&
        authService.currentUser != nil
    }
    
    private var remainingCharacters: Int {
        maxCharacters - commentText.count
    }
    
    private var characterCountColor: Color {
        if remainingCharacters < 0 {
            return .red
        } else if remainingCharacters < 50 {
            return .orange
        } else {
            return .secondary
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // User Avatar
                if let currentUser = authService.currentUser {
                    AsyncImage(url: URL(string: currentUser.avatarUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text(currentUser.name.prefix(1).uppercased())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            )
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                }
                
                VStack(spacing: 8) {
                    // Text Input
                    TextField("Add a comment...", text: $commentText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .lineLimit(1...4)
                        .disabled(isSubmitting)
                    
                    // Actions Row
                    HStack {
                        // Character Count
                        if !commentText.isEmpty {
                            Text("\(remainingCharacters)")
                                .font(.caption2)
                                .foregroundColor(characterCountColor)
                        }
                        
                        Spacer()
                        
                        // Submit Button
                        Button(action: submitComment) {
                            if isSubmitting {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Posting...")
                                        .font(.caption)
                                }
                            } else {
                                Text("Post")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(!canSubmit)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
            
            // Error Display
            if let error = commentService.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Button("Dismiss") {
                        commentService.clearError()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
    
    // MARK: - Actions
    
    private func submitComment() {
        guard canSubmit else { return }
        
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        Task {
            isSubmitting = true
            
            do {
                let newComment = try await commentService.createComment(
                    postId: postId,
                    content: trimmedText
                )
                
                await MainActor.run {
                    commentText = ""
                    isTextFieldFocused = false
                    onCommentCreated?(newComment)
                }
                
            } catch {
                print("Failed to create comment: \(error)")
            }
            
            isSubmitting = false
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        
        CommentInputView(
            postId: "sample-post",
            onCommentCreated: { comment in
                print("Comment created: \(comment.content)")
            }
        )
    }
    .background(Color(.systemGroupedBackground))
}