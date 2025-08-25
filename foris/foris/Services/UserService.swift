import Foundation
import Combine

/// Service for managing user profile operations
/// Handles user data, profile updates, and social features
@MainActor
final class UserService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = UserService()
    
    // MARK: - Properties
    
    private let graphqlService: GraphQLServiceProtocol
    private let cacheService: CacheService
    private let authService: AuthServiceProtocol
    private let followService: FollowService
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var error: AppError?
    
    // MARK: - Initialization
    
    init(
        graphqlService: GraphQLServiceProtocol = GraphQLService.shared,
        cacheService: CacheService = CacheService.shared,
        authService: AuthServiceProtocol = AuthService.shared,
        followService: FollowService = FollowService.shared
    ) {
        self.graphqlService = graphqlService
        self.cacheService = cacheService
        self.authService = authService
        self.followService = followService
    }
    
    // MARK: - Profile Operations
    
    /// Gets the current user's profile
    /// - Returns: Current user profile
    /// - Throws: AppError if operation fails
    func getCurrentUserProfile() async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try to get from cache first
            if let currentUser = authService.currentUser {
                return currentUser
            }
            
            // TODO: Implement GraphQL 'me' query
            // For now, return cached user or throw error
            throw AppError.authentication(.notAuthenticated)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets a user profile by ID
    /// - Parameter userId: User ID to fetch
    /// - Returns: User profile
    /// - Throws: AppError if operation fails
    func getUserProfile(userId: String) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            if let cachedUser = try cacheService.getCachedUser(id: userId) {
                return cachedUser
            }
            
            // TODO: Implement GraphQL user query
            // For now, throw not found error
            throw AppError.network(.notFound)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Updates the current user's profile
    /// - Parameter updateData: Profile update data
    /// - Returns: Updated user profile
    /// - Throws: AppError if operation fails
    func updateProfile(_ updateData: ProfileUpdateData) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate input
            try validateProfileUpdate(updateData)
            
            guard let currentUser = authService.currentUser else {
                throw AppError.authentication(.notAuthenticated)
            }
            
            // Create updated user for optimistic update
            let updatedUser = User(
                id: currentUser.id,
                name: updateData.name ?? currentUser.name,
                email: currentUser.email, // Email typically can't be changed
                bio: updateData.bio ?? currentUser.bio,
                avatarUrl: updateData.avatarUrl ?? currentUser.avatarUrl
            )
            
            // Cache the updated user
            try cacheService.cacheUser(updatedUser)
            
            // Check if online
            if NetworkMonitor.shared.isConnected {
                // TODO: Implement GraphQL updateUser mutation
                // For now, just return the updated user
                return updatedUser
            } else {
                // Queue for offline processing
                let actionData = UpdateProfileActionData(
                    name: updateData.name,
                    bio: updateData.bio,
                    avatarData: updateData.avatarData
                )
                let data = try JSONEncoder().encode(actionData)
                let action = OfflineAction(type: .updateProfile, data: data)
                
                await OfflineQueueService.shared.queueAction(action)
                
                return updatedUser
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Uploads a new avatar image
    /// - Parameter imageData: Image data to upload
    /// - Returns: Avatar URL
    /// - Throws: AppError if operation fails
    func uploadAvatar(_ imageData: Data) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement image upload to backend
            // For now, return mock URL
            let mockAvatarUrl = "https://example.com/avatars/\(UUID().uuidString).jpg"
            
            // Simulate upload delay
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            return mockAvatarUrl
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    // MARK: - Social Features
    
    /// Follows a user
    /// - Parameter userId: User ID to follow
    /// - Throws: AppError if operation fails
    func followUser(_ userId: String) async throws {
        _ = try await followService.followUser(userId: userId)
    }
    
    /// Unfollows a user
    /// - Parameter userId: User ID to unfollow
    /// - Throws: AppError if operation fails
    func unfollowUser(_ userId: String) async throws {
        _ = try await followService.unfollowUser(userId: userId)
    }
    
    /// Gets a user's followers
    /// - Parameter userId: User ID
    /// - Returns: Array of followers
    /// - Throws: AppError if operation fails
    func getFollowers(userId: String) async throws -> [User] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement GraphQL getFollowers query
            // For now, return empty array
            return []
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets users that a user is following
    /// - Parameter userId: User ID
    /// - Returns: Array of users being followed
    /// - Throws: AppError if operation fails
    func getFollowing(userId: String) async throws -> [User] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement GraphQL getFollowing query
            // For now, return empty array
            return []
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Checks if current user is following another user
    /// - Parameter userId: User ID to check
    /// - Returns: True if following
    /// - Throws: AppError if operation fails
    func isFollowing(userId: String) async throws -> Bool {
        do {
            // TODO: Implement GraphQL isFollowing query
            // For now, return false
            return false
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets follower count for a user
    /// - Parameter userId: User ID
    /// - Returns: Follower count
    /// - Throws: AppError if operation fails
    func getFollowerCount(userId: String) async throws -> Int {
        do {
            // TODO: Implement GraphQL getFollowerCount query
            // For now, return 0
            return 0
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets following count for a user
    /// - Parameter userId: User ID
    /// - Returns: Following count
    /// - Throws: AppError if operation fails
    func getFollowingCount(userId: String) async throws -> Int {
        do {
            // TODO: Implement GraphQL getFollowingCount query
            // For now, return 0
            return 0
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Searches for users
    /// - Parameter query: Search query
    /// - Returns: Array of matching users
    /// - Throws: AppError if operation fails
    func searchUsers(query: String) async throws -> [User] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedUsers = try cacheService.getAllCachedUsers()
            let filteredUsers = cachedUsers.filter { user in
                user.name.localizedCaseInsensitiveContains(query) ||
                user.email.localizedCaseInsensitiveContains(query)
            }
            
            // TODO: Implement GraphQL user search
            // For now, return filtered cached users
            return filteredUsers
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    // MARK: - Validation
    
    private func validateProfileUpdate(_ updateData: ProfileUpdateData) throws {
        if let name = updateData.name {
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AppError.validation(.required("Name"))
            }
            
            guard name.count >= 2 else {
                throw AppError.validation(.tooShort("Name", 2))
            }
            
            guard name.count <= 50 else {
                throw AppError.validation(.tooLong("Name", 50))
            }
        }
        
        if let bio = updateData.bio {
            guard bio.count <= 500 else {
                throw AppError.validation(.tooLong("Bio", 500))
            }
        }
        
        if let avatarUrl = updateData.avatarUrl {
            guard URL(string: avatarUrl) != nil else {
                throw AppError.validation(.invalidURL)
            }
        }
    }
    
    // MARK: - Offline Queue Methods
    
    /// Updates profile with individual parameters (for offline queue service)
    /// - Parameters:
    ///   - name: New name
    ///   - bio: New bio
    ///   - avatarData: New avatar image data
    /// - Returns: Updated user profile
    /// - Throws: AppError if operation fails
    func updateProfile(name: String?, bio: String?, avatarData: Data?) async throws -> User {
        let updateData = ProfileUpdateData(
            name: name,
            bio: bio,
            avatarData: avatarData
        )
        return try await updateProfile(updateData)
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        error = nil
    }
}

// MARK: - Profile Update Data

/// Data structure for profile updates
struct ProfileUpdateData {
    let name: String?
    let bio: String?
    let avatarUrl: String?
    
    init(name: String? = nil, bio: String? = nil, avatarUrl: String? = nil) {
        self.name = name
        self.bio = bio
        self.avatarUrl = avatarUrl
    }
    
    /// Returns true if any field has been updated
    var hasChanges: Bool {
        return name != nil || bio != nil || avatarUrl != nil
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockUserService: UserService {
    var shouldFailOperations = false
    var operationDelay: TimeInterval = 0.5
    
    override func getCurrentUserProfile() async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        return User.mock
    }
    
    override func getUserProfile(userId: String) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.notFound)
        }
        
        return User.mockWithAvatar
    }
    
    override func updateProfile(_ updateData: ProfileUpdateData) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.validation(.required("Name"))
        }
        
        return User(
            id: "mock-user-id",
            name: updateData.name ?? "Updated Name",
            email: "user@example.com",
            bio: updateData.bio ?? "Updated bio",
            avatarUrl: updateData.avatarUrl
        )
    }
    
    override func searchUsers(query: String) async throws -> [User] {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        return [User.mock, User.mockWithAvatar]
    }
}
#endif