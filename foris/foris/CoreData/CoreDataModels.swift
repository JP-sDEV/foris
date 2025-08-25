import Foundation
import CoreData

// MARK: - CachedUser Extensions

@objc(CachedUser)
public class CachedUser: NSManagedObject {
    
    /// Updates the cached user with data from a User model
    /// - Parameter user: User model to update from
    func updateFromUser(_ user: User) {
        self.id = user.id
        self.name = user.name
        self.email = user.email
        self.bio = user.bio
        self.avatarUrl = user.avatarUrl
        self.lastUpdated = Date()
    }
    
    /// Converts the cached user to a User model
    /// - Returns: User model
    func toUser() -> User? {
        guard let id = id, let name = name, let email = email else {
            return nil
        }
        
        return User(
            id: id,
            name: name,
            email: email,
            bio: bio,
            avatarUrl: avatarUrl
        )
    }
}

extension CachedUser {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedUser> {
        return NSFetchRequest<CachedUser>(entityName: "CachedUser")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var email: String?
    @NSManaged public var bio: String?
    @NSManaged public var avatarUrl: String?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var posts: NSSet?
    @NSManaged public var comments: NSSet?
    @NSManaged public var likes: NSSet?
    @NSManaged public var followers: NSSet?
    @NSManaged public var following: NSSet?
    @NSManaged public var userChallenges: NSSet?
    @NSManaged public var leagueMemberships: NSSet?
    @NSManaged public var leagueChallengeParticipations: NSSet?
}

// MARK: - CachedPost Extensions

@objc(CachedPost)
public class CachedPost: NSManagedObject {
    
    /// Updates the cached post with data from a Post model
    /// - Parameter post: Post model to update from
    func updateFromPost(_ post: Post) {
        self.id = post.id
        self.title = post.title
        self.content = post.content
        self.authorId = post.authorId
        self.createdAt = post.createdAt
        self.lastUpdated = Date()
    }
    
    /// Converts the cached post to a Post model
    /// - Returns: Post model
    func toPost() -> Post? {
        guard let id = id,
              let title = title,
              let authorId = authorId,
              let createdAt = createdAt else {
            return nil
        }
        
        let authorUser = author?.toUser()
        
        return Post(
            id: id,
            title: title,
            content: content,
            authorId: authorId,
            author: authorUser,
            createdAt: createdAt,
            likeCount: Int(likes?.count ?? 0),
            commentCount: Int(comments?.count ?? 0),
            isLiked: false // This would need to be calculated based on current user
        )
    }
}

extension CachedPost {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedPost> {
        return NSFetchRequest<CachedPost>(entityName: "CachedPost")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var authorId: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var author: CachedUser?
    @NSManaged public var comments: NSSet?
    @NSManaged public var likes: NSSet?
}

// MARK: - CachedComment Extensions

@objc(CachedComment)
public class CachedComment: NSManagedObject {
    
    /// Updates the cached comment with data from a Comment model
    /// - Parameter comment: Comment model to update from
    func updateFromComment(_ comment: Comment) {
        self.id = comment.id
        self.content = comment.content
        self.userId = comment.user.id
        self.postId = comment.post.id
        self.createdAt = comment.createdAt
        self.updatedAt = comment.updatedAt
        self.lastUpdated = Date()
    }
    
    /// Converts the cached comment to a Comment model
    /// - Returns: Comment model
    func toComment() -> Comment? {
        guard let id = id,
              let content = content,
              let createdAt = createdAt,
              let updatedAt = updatedAt,
              let user = user?.toUser(),
              let post = post?.toPost() else {
            return nil
        }
        
        return Comment(
            id: id,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            user: user,
            post: post
        )
    }
}

extension CachedComment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedComment> {
        return NSFetchRequest<CachedComment>(entityName: "CachedComment")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var content: String?
    @NSManaged public var userId: String?
    @NSManaged public var postId: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var user: CachedUser?
    @NSManaged public var post: CachedPost?
}

// MARK: - CachedChallenge Extensions

@objc(CachedChallenge)
public class CachedChallenge: NSManagedObject {
    
    /// Updates the cached challenge with data from a Challenge model
    /// - Parameter challenge: Challenge model to update from
    func updateFromChallenge(_ challenge: Challenge) {
        self.id = challenge.id
        self.name = challenge.name
        self.challengeDescription = challenge.description
        self.type = challenge.type.rawValue
        self.difficulty = challenge.difficulty.rawValue
        self.duration = Int32(challenge.duration)
        self.targetValue = challenge.targetValue
        self.unit = challenge.unit
        self.startDate = challenge.startDate
        self.endDate = challenge.endDate
        self.createdBy = challenge.createdBy
        self.participantCount = Int32(challenge.participantCount)
        self.isActive = challenge.isActive
        self.createdAt = challenge.createdAt
        self.updatedAt = challenge.updatedAt
        self.lastUpdated = Date()
    }
    
    /// Converts the cached challenge to a Challenge model
    /// - Returns: Challenge model
    func toChallenge() -> Challenge? {
        guard let id = id,
              let name = name,
              let challengeDescription = challengeDescription,
              let typeString = type,
              let type = ChallengeType(rawValue: typeString),
              let difficultyString = difficulty,
              let difficulty = ChallengeDifficulty(rawValue: difficultyString),
              let unit = unit,
              let startDate = startDate,
              let endDate = endDate,
              let createdBy = createdBy,
              let createdAt = createdAt,
              let updatedAt = updatedAt else {
            return nil
        }
        
        return Challenge(
            id: id,
            name: name,
            description: challengeDescription,
            type: type,
            difficulty: difficulty,
            duration: Int(duration),
            targetValue: targetValue,
            unit: unit,
            startDate: startDate,
            endDate: endDate,
            createdBy: createdBy,
            creator: nil, // Would need to be populated separately
            participantCount: Int(participantCount),
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension CachedChallenge {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedChallenge> {
        return NSFetchRequest<CachedChallenge>(entityName: "CachedChallenge")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var challengeDescription: String?
    @NSManaged public var type: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var duration: Int32
    @NSManaged public var targetValue: Double
    @NSManaged public var unit: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var createdBy: String?
    @NSManaged public var participantCount: Int32
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var userChallenges: NSSet?
}

// MARK: - CachedUserChallenge Extensions

@objc(CachedUserChallenge)
public class CachedUserChallenge: NSManagedObject {
    
    /// Updates the cached user challenge with data from a UserChallenge model
    /// - Parameter userChallenge: UserChallenge model to update from
    func updateFromUserChallenge(_ userChallenge: UserChallenge) {
        self.id = userChallenge.id
        self.userId = userChallenge.userId
        self.challengeId = userChallenge.challengeId
        self.status = userChallenge.status.rawValue
        self.progress = userChallenge.progress
        self.completedAt = userChallenge.completedAt
        self.joinedAt = userChallenge.joinedAt
        self.lastUpdated = Date()
    }
    
    /// Converts the cached user challenge to a UserChallenge model
    /// - Returns: UserChallenge model
    func toUserChallenge() -> UserChallenge? {
        guard let id = id,
              let userId = userId,
              let challengeId = challengeId,
              let statusString = status,
              let status = UserChallengeStatus(rawValue: statusString),
              let joinedAt = joinedAt else {
            return nil
        }
        
        let userModel = user?.toUser() ?? User.mock // Fallback to mock user if not available
        let challengeModel = challenge?.toChallenge()
        
        return UserChallenge(
            id: id,
            userId: userId,
            challengeId: challengeId,
            status: status,
            progress: progress,
            completedAt: completedAt,
            joinedAt: joinedAt,
            user: userModel,
            challenge: challengeModel
        )
    }
}

extension CachedUserChallenge {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedUserChallenge> {
        return NSFetchRequest<CachedUserChallenge>(entityName: "CachedUserChallenge")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var userId: String?
    @NSManaged public var challengeId: String?
    @NSManaged public var status: String?
    @NSManaged public var progress: Double
    @NSManaged public var completedAt: Date?
    @NSManaged public var joinedAt: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var user: CachedUser?
    @NSManaged public var challenge: CachedChallenge?
}

// MARK: - CachedLike Extensions

@objc(CachedLike)
public class CachedLike: NSManagedObject {
    
    /// Updates the cached like with data from a Like model
    /// - Parameter like: Like model to update from
    func updateFromLike(_ like: Like) {
        self.userId = like.userId
        self.postId = like.postId
        self.lastUpdated = Date()
    }
    
    /// Converts the cached like to a Like model
    /// - Returns: Like model
    func toLike() -> Like? {
        guard let userId = userId,
              let postId = postId,
              let user = user?.toUser(),
              let post = post?.toPost() else {
            return nil
        }
        
        return Like(
            userId: userId,
            postId: postId,
            user: user,
            post: post
        )
    }
}

extension CachedLike {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedLike> {
        return NSFetchRequest<CachedLike>(entityName: "CachedLike")
    }
    
    @NSManaged public var userId: String?
    @NSManaged public var postId: String?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var user: CachedUser?
    @NSManaged public var post: CachedPost?
}

// MARK: - CachedLeague Extensions

@objc(CachedLeague)
public class CachedLeague: NSManagedObject {
    
    /// Updates the cached league with data from a League model
    /// - Parameter league: League model to update from
    func updateFromLeague(_ league: League) {
        self.id = league.id
        self.name = league.name
        self.leagueDescription = league.description
        self.type = league.type.rawValue
        self.privacy = league.privacy.rawValue
        self.maxMembers = league.maxMembers != nil ? Int32(league.maxMembers!) : -1
        self.createdBy = league.createdBy
        self.memberCount = Int32(league.memberCount)
        self.challengeCount = Int32(league.challengeCount)
        self.isActive = league.isActive
        self.createdAt = league.createdAt
        self.updatedAt = league.updatedAt
        self.lastUpdated = Date()
    }
    
    /// Converts the cached league to a League model
    /// - Returns: League model
    func toLeague() -> League? {
        guard let id = id,
              let name = name,
              let leagueDescription = leagueDescription,
              let typeString = type,
              let type = LeagueType(rawValue: typeString),
              let privacyString = privacy,
              let privacy = LeaguePrivacy(rawValue: privacyString),
              let createdBy = createdBy,
              let createdAt = createdAt,
              let updatedAt = updatedAt else {
            return nil
        }
        
        return League(
            id: id,
            name: name,
            description: leagueDescription,
            type: type,
            privacy: privacy,
            maxMembers: maxMembers >= 0 ? Int(maxMembers) : nil,
            createdBy: createdBy,
            creator: creator?.toUser(),
            memberCount: Int(memberCount),
            challengeCount: Int(challengeCount),
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension CachedLeague {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedLeague> {
        return NSFetchRequest<CachedLeague>(entityName: "CachedLeague")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var leagueDescription: String?
    @NSManaged public var type: String?
    @NSManaged public var privacy: String?
    @NSManaged public var maxMembers: Int32
    @NSManaged public var createdBy: String?
    @NSManaged public var memberCount: Int32
    @NSManaged public var challengeCount: Int32
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var creator: CachedUser?
    @NSManaged public var members: NSSet?
    @NSManaged public var challenges: NSSet?
}

// MARK: - CachedLeagueMember Extensions

@objc(CachedLeagueMember)
public class CachedLeagueMember: NSManagedObject {
    
    /// Updates the cached league member with data from a LeagueMember model
    /// - Parameter leagueMember: LeagueMember model to update from
    func updateFromLeagueMember(_ leagueMember: LeagueMember) {
        self.id = leagueMember.id
        self.userId = leagueMember.userId
        self.leagueId = leagueMember.leagueId
        self.role = leagueMember.role.rawValue
        self.joinedAt = leagueMember.joinedAt
        self.lastUpdated = Date()
    }
    
    /// Converts the cached league member to a LeagueMember model
    /// - Returns: LeagueMember model
    func toLeagueMember() -> LeagueMember? {
        guard let id = id,
              let userId = userId,
              let leagueId = leagueId,
              let roleString = role,
              let role = LeagueMemberRole(rawValue: roleString),
              let joinedAt = joinedAt,
              let user = user?.toUser() else {
            return nil
        }
        
        return LeagueMember(
            id: id,
            userId: userId,
            leagueId: leagueId,
            role: role,
            joinedAt: joinedAt,
            user: user,
            league: league?.toLeague()
        )
    }
}

extension CachedLeagueMember {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedLeagueMember> {
        return NSFetchRequest<CachedLeagueMember>(entityName: "CachedLeagueMember")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var userId: String?
    @NSManaged public var leagueId: String?
    @NSManaged public var role: String?
    @NSManaged public var joinedAt: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var user: CachedUser?
    @NSManaged public var league: CachedLeague?
}

// MARK: - CachedUserFollow Extensions

@objc(CachedUserFollow)
public class CachedUserFollow: NSManagedObject {
    
    /// Updates the cached user follow with data from a UserFollow model
    /// - Parameter userFollow: UserFollow model to update from
    func updateFromUserFollow(_ userFollow: UserFollow) {
        self.followerId = userFollow.followerId
        self.followingId = userFollow.followingId
        self.createdAt = userFollow.createdAt
        self.lastUpdated = Date()
    }
    
    /// Converts the cached user follow to a UserFollow model
    /// - Returns: UserFollow model
    func toUserFollow() -> UserFollow? {
        guard let followerId = followerId,
              let followingId = followingId,
              let createdAt = createdAt else {
            return nil
        }
        
        return UserFollow(
            followerId: followerId,
            followingId: followingId,
            createdAt: createdAt,
            follower: follower?.toUser(),
            following: following?.toUser()
        )
    }
}

extension CachedUserFollow {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedUserFollow> {
        return NSFetchRequest<CachedUserFollow>(entityName: "CachedUserFollow")
    }
    
    @NSManaged public var followerId: String?
    @NSManaged public var followingId: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var follower: CachedUser?
    @NSManaged public var following: CachedUser?
}

// MARK: - CachedLeagueChallenge Extensions

@objc(CachedLeagueChallenge)
public class CachedLeagueChallenge: NSManagedObject {
    
    /// Updates the cached league challenge with data from a LeagueChallenge model
    /// - Parameter leagueChallenge: LeagueChallenge model to update from
    func updateFromLeagueChallenge(_ leagueChallenge: LeagueChallenge) {
        self.id = leagueChallenge.id
        self.leagueId = leagueChallenge.leagueId
        self.challengeId = leagueChallenge.challengeId
        self.name = leagueChallenge.name
        self.challengeDescription = leagueChallenge.description
        self.type = leagueChallenge.type.rawValue
        self.difficulty = leagueChallenge.difficulty.rawValue
        self.duration = Int32(leagueChallenge.duration)
        self.targetValue = leagueChallenge.targetValue
        self.unit = leagueChallenge.unit
        self.startDate = leagueChallenge.startDate
        self.endDate = leagueChallenge.endDate
        self.createdBy = leagueChallenge.createdBy
        self.participantCount = Int32(leagueChallenge.participantCount)
        self.isActive = leagueChallenge.isActive
        self.createdAt = leagueChallenge.createdAt
        self.updatedAt = leagueChallenge.updatedAt
        self.lastUpdated = Date()
    }
    
    /// Converts the cached league challenge to a LeagueChallenge model
    /// - Returns: LeagueChallenge model
    func toLeagueChallenge() -> LeagueChallenge? {
        guard let id = id,
              let leagueId = leagueId,
              let challengeId = challengeId,
              let name = name,
              let challengeDescription = challengeDescription,
              let typeString = type,
              let type = ChallengeType(rawValue: typeString),
              let difficultyString = difficulty,
              let difficulty = ChallengeDifficulty(rawValue: difficultyString),
              let unit = unit,
              let startDate = startDate,
              let endDate = endDate,
              let createdBy = createdBy,
              let createdAt = createdAt,
              let updatedAt = updatedAt else {
            return nil
        }
        
        return LeagueChallenge(
            id: id,
            leagueId: leagueId,
            challengeId: challengeId,
            name: name,
            description: challengeDescription,
            type: type,
            difficulty: difficulty,
            duration: Int(duration),
            targetValue: targetValue,
            unit: unit,
            startDate: startDate,
            endDate: endDate,
            createdBy: createdBy,
            creator: creator?.toUser(),
            participantCount: Int(participantCount),
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            league: league?.toLeague()
        )
    }
}

extension CachedLeagueChallenge {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedLeagueChallenge> {
        return NSFetchRequest<CachedLeagueChallenge>(entityName: "CachedLeagueChallenge")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var leagueId: String?
    @NSManaged public var challengeId: String?
    @NSManaged public var name: String?
    @NSManaged public var challengeDescription: String?
    @NSManaged public var type: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var duration: Int32
    @NSManaged public var targetValue: Double
    @NSManaged public var unit: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var createdBy: String?
    @NSManaged public var participantCount: Int32
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var creator: CachedUser?
    @NSManaged public var league: CachedLeague?
}

// MARK: - CachedLeagueChallengeParticipation Extensions

@objc(CachedLeagueChallengeParticipation)
public class CachedLeagueChallengeParticipation: NSManagedObject {
    
    /// Updates the cached league challenge participation with data from a LeagueChallengeParticipation model
    /// - Parameter participation: LeagueChallengeParticipation model to update from
    func updateFromLeagueChallengeParticipation(_ participation: LeagueChallengeParticipation) {
        self.id = participation.id
        self.userId = participation.userId
        self.leagueChallengeId = participation.leagueChallengeId
        self.status = participation.status.rawValue
        self.progress = participation.progress
        self.completedAt = participation.completedAt
        self.joinedAt = participation.joinedAt
        self.lastUpdated = Date()
    }
    
    /// Converts the cached league challenge participation to a LeagueChallengeParticipation model
    /// - Returns: LeagueChallengeParticipation model
    func toLeagueChallengeParticipation() -> LeagueChallengeParticipation? {
        guard let id = id,
              let userId = userId,
              let leagueChallengeId = leagueChallengeId,
              let statusString = status,
              let status = UserChallengeStatus(rawValue: statusString),
              let joinedAt = joinedAt,
              let user = user?.toUser() else {
            return nil
        }
        
        return LeagueChallengeParticipation(
            id: id,
            userId: userId,
            leagueChallengeId: leagueChallengeId,
            status: status,
            progress: progress,
            completedAt: completedAt,
            joinedAt: joinedAt,
            user: user,
            leagueChallenge: leagueChallenge?.toLeagueChallenge()
        )
    }
}

extension CachedLeagueChallengeParticipation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedLeagueChallengeParticipation> {
        return NSFetchRequest<CachedLeagueChallengeParticipation>(entityName: "CachedLeagueChallengeParticipation")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var userId: String?
    @NSManaged public var leagueChallengeId: String?
    @NSManaged public var status: String?
    @NSManaged public var progress: Double
    @NSManaged public var completedAt: Date?
    @NSManaged public var joinedAt: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var user: CachedUser?
    @NSManaged public var leagueChallenge: CachedLeagueChallenge?
}

// MARK: - Additional Model Types

/// Challenge status enum matching GraphQL schema
enum ChallengeStatus: String, CaseIterable, Codable {
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case notInProgress = "NOT_IN_PROGRESS"
}

/// Post model for the app
struct Post: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let content: String?
    let authorId: String
    let author: User?
    let createdAt: Date
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
}

/// Comment model for the app
struct Comment: Codable, Identifiable, Equatable {
    let id: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let user: User
    let post: Post
}

/// Challenge model for the app
struct Challenge: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let createdBy: String
    let endDate: Date?
    let userStatus: ChallengeStatus?
}

/// UserChallenge model for the app
struct UserChallenge: Codable, Identifiable, Equatable {
    let userId: String
    let challengeId: String
    let status: ChallengeStatus
    let startedAt: Date
    let completedAt: Date?
    
    var id: String {
        return "\(userId)-\(challengeId)"
    }
}

/// Like model for the app
struct Like: Codable, Identifiable, Equatable {
    let userId: String
    let postId: String
    let user: User
    let post: Post
    
    var id: String {
        return "\(userId)-\(postId)"
    }
}

/// League model for the app
struct League: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let createdBy: String
}

/// LeagueUser model for the app
struct LeagueUser: Codable, Identifiable, Equatable {
    let id: String
    let leagueId: String
    let userId: String
    let createdAt: Date
    let updatedAt: Date
    let user: User?
    let league: League?
}

/// UserFollow model for the app
struct UserFollow: Codable, Identifiable, Equatable {
    let followerId: String
    let followingId: String
    let createdAt: Date
    let follower: User?
    let following: User?
    
    var id: String {
        return "\(followerId)-\(followingId)"
    }
}