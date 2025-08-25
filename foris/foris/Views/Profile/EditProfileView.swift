import SwiftUI
import PhotosUI

/// Edit profile view for updating user information
/// Provides form-based editing with validation and image selection
struct EditProfileView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Avatar section
                avatarSection
                
                // Basic info section
                basicInfoSection
                
                // Bio section
                bioSection
                
                // Save button section
                saveButtonSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveProfile()
                            if !viewModel.isEditing {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isEditingDataValid || viewModel.isLoading)
                }
            }
            .alert("Save Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let newItem = newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectAvatarImage(image)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        Section {
            HStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Avatar display
                    avatarView
                    
                    // Change avatar button
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Change Photo")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                    .disabled(viewModel.isUploadingAvatar)
                    
                    if viewModel.isUploadingAvatar {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Uploading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private var avatarView: some View {
        Group {
            if let selectedImage = viewModel.selectedAvatarImage {
                // Show selected image
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                    )
            } else if let avatarUrl = viewModel.avatarUrl {
                // Show current avatar
                AsyncImage(url: URL(string: avatarUrl)) { image in
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
            } else {
                // Show initials placeholder
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(viewModel.initials)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                    )
            }
        }
        .accessibilityLabel("Profile picture")
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        Section("Basic Information") {
            // Name field
            HStack {
                Text("Name")
                    .foregroundColor(.primary)
                
                Spacer()
                
                TextField("Enter your name", text: $viewModel.editingName)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Name field")
            
            // Email field (read-only)
            HStack {
                Text("Email")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(viewModel.user?.email ?? "")
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Email: \(viewModel.user?.email ?? "")")
        }
    }
    
    // MARK: - Bio Section
    
    private var bioSection: some View {
        Section("About") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                TextField(
                    "Tell us about yourself...",
                    text: $viewModel.editingBio,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .lineLimit(5...10)
                
                HStack {
                    Spacer()
                    Text("\(viewModel.editingBio.count)/500")
                        .font(.caption)
                        .foregroundColor(viewModel.editingBio.count > 500 ? .red : .secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Save Button Section
    
    private var saveButtonSection: some View {
        Section {
            if viewModel.hasUnsavedChanges {
                VStack(spacing: 12) {
                    Button("Save Changes") {
                        Task {
                            await viewModel.saveProfile()
                            if !viewModel.isEditing {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isEditingDataValid || viewModel.isLoading)
                    .frame(maxWidth: .infinity)
                    
                    if viewModel.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Saving...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Validation Helpers

extension EditProfileView {
    private var nameValidationMessage: String? {
        if viewModel.editingName.isEmpty {
            return "Name is required"
        } else if viewModel.editingName.count < 2 {
            return "Name must be at least 2 characters"
        } else if viewModel.editingName.count > 50 {
            return "Name must be less than 50 characters"
        }
        return nil
    }
    
    private var bioValidationMessage: String? {
        if viewModel.editingBio.count > 500 {
            return "Bio must be less than 500 characters"
        }
        return nil
    }
}

// MARK: - Preview Provider

#Preview("Edit Profile") {
    EditProfileView(viewModel: ProfileViewModel.mockEditing())
}

#Preview("Edit Profile - Dark Mode") {
    EditProfileView(viewModel: ProfileViewModel.mockEditing())
        .preferredColorScheme(.dark)
}

#Preview("Edit Profile - iPad") {
    EditProfileView(viewModel: ProfileViewModel.mockEditing())
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}