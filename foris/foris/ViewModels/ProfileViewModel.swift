import Foundation
import Combine
import SwiftUI

/// ViewModel for user profile management
/// Handles profile display, editing, and social interactions
@MainActor
final class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var user: User?
    @Published var isLoading = false
    @Published var isEditing = false
    @Published var error: AppError?
    @Published var showError = false
    
    // Profile editing
    @Published var editingName = ""
    @Published var editingBio = ""
    @Published var editingAvatarUrl = ""
    @Published var selectedAvatarImage: UIImage?
    @Published var isUploadingAvatar = false
    
    // Social features
    @Published var isFollowing = false
    @Published var followerCount = 0
    @Published var followingCount = 0
    @Published var followers: [User] = []
    @Published var following: [User] = []
    
    // MARK: - Private Properties
    
    private let userService: UserService
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isCurrentUser: Bool {
        guard let user = user, let currentUser = authService.currentUser else {
            return false
        }
        return user.id == currentUser.id
    }
    
    var canEdit: Bool {
        return isCurrentUser && !isLoading
    }
    
    var hasUnsavedChanges: Bool {
        guard let user = user else { return false }
        
        return editingName != user.name ||
               editingBio != (user.bio ?? "") ||
               editingAvatarUrl != (user.avatarUrl ?? "") ||
               selectedAvatarImage != nil
    }
    
    var displayName: String {
        return user?.displayName ?? "Unknown User"
    }
    
    var displayBio: String {
        return user?.bio ?? "No bio available"
    }
    
    var avatarUrl: String? {
        return user?.avatarUrl
    }
    
    var initials: String {
        return user?.initials ?? "?"
    }
    
    // MARK: - Initialization
    
    init(
        user: User? = nil,
        userService: UserService = UserService.shared,
        authService: AuthServiceProtocol = AuthService.shared
    ) {
        self.user = user
        self.userService = userService
        self.authService = authService
        
        setupBindings()
        
        if let user = user {
            loadUserData(user)
        }
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind user service errors
        userService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
        
        // Bind loading state
        userService.$isLoading
            .assign(to: &$isLoading)
    }
    
    private func loadUserData(_ user: User) {
        self.user = user
        self.editingName = user.name
        self.editingBio = user.bio ?? ""
        self.editingAvatarUrl = user.avatarUrl ?? ""
        
        // Load social data
        Task {
            await loadSocialData()
        }
    }
    
    // MARK: - Profile Loading
    
    /// Loads the current user's profile
    func loadCurrentUserProfile() async {
        do {
            let user = try await userService.getCurrentUserProfile()
            loadUserData(user)
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    /// Loads a specific user's profile
    /// - Parameter userId: User ID to load
    func loadUserProfile(userId: String) async {
        do {
            let user = try await userService.getUserProfile(userId: userId)
            loadUserData(user)
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    /// Refreshes the current profile data
    func refreshProfile() async {
        guard let user = user else { return }
        
        if isCurrentUser {
            await loadCurrentUserProfile()
        } else {
            await loadUserProfile(userId: user.id)
        }
    }
    
    // MARK: - Profile Editing
    
    /// Starts editing the profile
    func startEditing() {
        guard canEdit else { return }
        
        isEditing = true
        
        // Reset editing fields to current values
        if let user = user {
            editingName = user.name
            editingBio = user.bio ?? ""
            editingAvatarUrl = user.avatarUrl ?? ""
        }
        
        selectedAvatarImage = nil
    }
    
    /// Cancels profile editing
    func cancelEditing() {
        isEditing = false
        selectedAvatarImage = nil
        
        // Reset editing fields
        if let user = user {
            editingName = user.name
            editingBio = user.bio ?? ""
            editingAvatarUrl = user.avatarUrl ?? ""
        }
    }
    
    /// Saves profile changes
    func saveProfile() async {
        guard hasUnsavedChanges else {
            isEditing = false
            return
        }
        
        do {
            var avatarUrl = editingAvatarUrl
            
            // Upload new avatar if selected
            if let avatarImage = selectedAvatarImage,
               let imageData = avatarImage.jpegData(compressionQuality: 0.8) {
                isUploadingAvatar = true
                avatarUrl = try await userService.uploadAvatar(imageData)
                isUploadingAvatar = false
            }
            
            // Create update data
            let updateData = ProfileUpdateData(
                name: editingName.isEmpty ? nil : editingName,
                bio: editingBio.isEmpty ? nil : editingBio,
                avatarUrl: avatarUrl.isEmpty ? nil : avatarUrl
            )
            
            // Update profile
            let updatedUser = try await userService.updateProfile(updateData)
            
            // Update local state
            self.user = updatedUser
            isEditing = false
            selectedAvatarImage = nil
            
        } catch {
            isUploadingAvatar = false
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    /// Selects a new avatar image
    /// - Parameter image: Selected image
    func selectAvatarImage(_ image: UIImage) {
        selectedAvatarImage = image
    }
    
    // MARK: - Social Features
    
    /// Loads social data (followers, following, counts)
    private func loadSocialData() async {
        guard let user = user else { return }
        
        do {
            async let followerCount = userService.getFollowerCount(userId: user.id)
            async let followingCount = userService.getFollowingCount(userId: user.id)
            async let isFollowing = isCurrentUser ? false : userService.isFollowing(userId: user.id)
            
            self.followerCount = try await followerCount
            self.followingCount = try await followingCount
            self.isFollowing = try await isFollowing
            
        } catch {
            // Don't show error for social data loading failures
            print("Failed to load social data: \(error)")
        }
    }
    
    /// Loads followers list
    func loadFollowers() async {
        guard let user = user else { return }
        
        do {
            followers = try await userService.getFollowers(userId: user.id)
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    /// Loads following list
    func loadFollowing() async {
        guard let user = user else { return }
        
        do {
            following = try await userService.getFollowing(userId: user.id)
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    /// Toggles follow status for the user
    func toggleFollow() async {
        guard let user = user, !isCurrentUser else { return }
        
        do {
            if isFollowing {
                try await userService.unfollowUser(user.id)
                isFollowing = false
                followerCount = max(0, followerCount - 1)
            } else {
                try await userService.followUser(user.id)
                isFollowing = true
                followerCount += 1
            }
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(_ error: AppError) {
        self.error = error
        showError = true
    }
    
    /// Dismisses the current error
    func dismissError() {
        showError = false
        error = nil
        userService.clearError()
    }
    
    // MARK: - Validation
    
    /// Validates the current editing data
    /// - Returns: Validation error if any
    func validateEditingData() -> AppError? {
        if editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return AppError.validation(.required("Name"))
        }
        
        if editingName.count < 2 {
            return AppError.validation(.tooShort("Name", 2))
        }
        
        if editingName.count > 50 {
            return AppError.validation(.tooLong("Name", 50))
        }
        
        if editingBio.count > 500 {
            return AppError.validation(.tooLong("Bio", 500))
        }
        
        if !editingAvatarUrl.isEmpty, URL(string: editingAvatarUrl) == nil {
            return AppError.validation(.invalidURL)
        }
        
        return nil
    }
    
    /// Returns true if the editing data is valid
    var isEditingDataValid: Bool {
        return validateEditingData() == nil
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
extension ProfileViewModel {
    /// Creates a mock ProfileViewModel for testing and previews
    /// - Parameters:
    ///   - user: User to display
    ///   - isLoading: Whether to show loading state
    ///   - isEditing: Whether to show editing state
    /// - Returns: Configured mock ProfileViewModel
    static func mock(
        user: User = .mock,
        isLoading: Bool = false,
        isEditing: Bool = false
    ) -> ProfileViewModel {
        let mockUserService = MockUserService()
        let mockAuthService = MockAuthService()
        mockAuthService.setAuthenticated(user)
        
        let viewModel = ProfileViewModel(
            user: user,
            userService: mockUserService,
            authService: mockAuthService
        )
        
        viewModel.isLoading = isLoading
        viewModel.isEditing = isEditing
        viewModel.followerCount = 42
        viewModel.followingCount = 24
        
        if isEditing {
            viewModel.editingName = user.name
            viewModel.editingBio = user.bio ?? ""
        }
        
        return viewModel
    }
    
    /// Creates a mock ProfileViewModel for another user (not current user)
    /// - Parameter user: User to display
    /// - Returns: Configured mock ProfileViewModel
    static func mockOtherUser(user: User = .mockWithAvatar) -> ProfileViewModel {
        let mockUserService = MockUserService()
        let mockAuthService = MockAuthService()
        mockAuthService.setAuthenticated(.mock) // Different user is authenticated
        
        let viewModel = ProfileViewModel(
            user: user,
            userService: mockUserService,
            authService: mockAuthService
        )
        
        viewModel.followerCount = 128
        viewModel.followingCount = 67
        viewModel.isFollowing = false
        
        return viewModel
    }
    
    /// Creates a mock ProfileViewModel in loading state
    /// - Returns: Configured mock ProfileViewModel
    static func mockLoading() -> ProfileViewModel {
        return mock(isLoading: true)
    }
    
    /// Creates a mock ProfileViewModel in editing state
    /// - Returns: Configured mock ProfileViewModel
    static func mockEditing() -> ProfileViewModel {
        return mock(isEditing: true)
    }
}
#endif