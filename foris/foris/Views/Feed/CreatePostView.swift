import SwiftUI

/// View for creating new posts
/// Provides form-based post creation with validation
struct CreatePostView: View {
    
    // MARK: - Properties
    
    let onPostCreated: (Post) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var postService = PostService.shared
    
    @State private var title = ""
    @State private var content = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               title.count >= 3 &&
               title.count <= 200 &&
               content.count <= 2000
    }
    
    private var canSave: Bool {
        return isValid && !isLoading
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Title section
                titleSection
                
                // Content section
                contentSection
                
                // Character counts
                characterCountsSection
                
                // Create button
                createButtonSection
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            await createPost()
                        }
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .alert("Create Post Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        Section {
            TextField("What's on your mind?", text: $title, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.headline)
                .lineLimit(3...5)
                .autocorrectionDisabled(false)
                .textInputAutocapitalization(.sentences)
        } header: {
            Text("Title")
        } footer: {
            if !title.isEmpty {
                HStack {
                    if title.count < 3 {
                        Text("Title must be at least 3 characters")
                            .foregroundColor(.red)
                    } else if title.count > 200 {
                        Text("Title is too long")
                            .foregroundColor(.red)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        Section {
            TextField(
                "Share more details about your fitness journey...",
                text: $content,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(.body)
            .lineLimit(5...15)
            .autocorrectionDisabled(false)
            .textInputAutocapitalization(.sentences)
        } header: {
            Text("Content (Optional)")
        } footer: {
            if content.count > 2000 {
                Text("Content is too long")
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Character Counts
    
    private var characterCountsSection: some View {
        Section {
            VStack(spacing: 8) {
                HStack {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(title.count)/200")
                        .font(.caption)
                        .foregroundColor(title.count > 200 ? .red : .secondary)
                }
                
                HStack {
                    Text("Content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(content.count)/2000")
                        .font(.caption)
                        .foregroundColor(content.count > 2000 ? .red : .secondary)
                }
            }
        }
    }
    
    // MARK: - Create Button Section
    
    private var createButtonSection: some View {
        Section {
            VStack(spacing: 12) {
                Button("Create Post") {
                    Task {
                        await createPost()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSave)
                .frame(maxWidth: .infinity)
                
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Creating post...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Actions
    
    private func createPost() async {
        guard canSave else { return }
        
        isLoading = true
        
        do {
            let postData = PostCreationData(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : content.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            let newPost = try await postService.createPost(postData)
            
            // Notify parent view
            onPostCreated(newPost)
            
            // Dismiss view
            dismiss()
            
        } catch {
            errorMessage = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Validation Helpers
    
    private func validateInput() -> String? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTitle.isEmpty {
            return "Title is required"
        }
        
        if trimmedTitle.count < 3 {
            return "Title must be at least 3 characters"
        }
        
        if trimmedTitle.count > 200 {
            return "Title must be less than 200 characters"
        }
        
        if content.count > 2000 {
            return "Content must be less than 2000 characters"
        }
        
        return nil
    }
}

// MARK: - Preview Provider

#Preview("Create Post") {
    CreatePostView { _ in
        // Handle post creation
    }
}

#Preview("Create Post - Dark Mode") {
    CreatePostView { _ in
        // Handle post creation
    }
    .preferredColorScheme(.dark)
}

#Preview("Create Post - iPad") {
    CreatePostView { _ in
        // Handle post creation
    }
    .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}