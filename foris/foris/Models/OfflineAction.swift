import Foundation

enum OfflineActionType: String, CaseIterable, Codable {
    case createPost
    case updatePost
    case deletePost
    case likePost
    case unlikePost
    case createComment
    case updateComment
    case deleteComment
    case followUser
    case unfollowUser
    case joinChallenge
    case leaveChallenge
    case updateChallengeStatus
    case joinLeague
    case leaveLeague
    case updateProfile
}

struct OfflineAction: Codable, Identifiable {
    let id: String
    let type: OfflineActionType
    let data: Data
    let timestamp: Date
    var retryCount: Int
    var lastRetryDate: Date?
    var isProcessing: Bool
    
    init(type: OfflineActionType, data: Data) {
        self.id = UUID().uuidString
        self.type = type
        self.data = data
        self.timestamp = Date()
        self.retryCount = 0
        self.lastRetryDate = nil
        self.isProcessing = false
    }
}

// Specific action data structures
struct CreatePostActionData: Codable {
    let title: String
    let content: String?
    let tempId: String // For optimistic updates
}

struct LikePostActionData: Codable {
    let postId: String
    let isLiked: Bool
}

struct CreateCommentActionData: Codable {
    let postId: String
    let content: String
    let tempId: String
}

struct FollowUserActionData: Codable {
    let userId: String
    let isFollowing: Bool
}

struct JoinChallengeActionData: Codable {
    let challengeId: String
    let isJoining: Bool
}

struct UpdateProfileActionData: Codable {
    let name: String?
    let bio: String?
    let avatarData: Data?
}