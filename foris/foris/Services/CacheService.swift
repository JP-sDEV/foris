import Foundation
import CoreData
import Combine

/// Service for managing local data caching and synchronization
/// Provides offline-first data access with automatic sync capabilities
@MainActor
final class CacheService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = CacheService()
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStack
    private let graphqlService: GraphQLServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    // MARK: - Configuration
    
    private let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24 hours
    private let syncInterval: TimeInterval = 5 * 60 // 5 minutes
    
    // MARK: - Initialization
    
    init(
        coreDataStack: CoreDataStack = CoreDataStack.shared,
        graphqlService: GraphQLServiceProtocol = GraphQLService.shared
    ) {
        self.coreDataStack = coreDataStack
        self.graphqlService = graphqlService
        
        setupPeriodicSync()
    }
    
    // MARK: - Setup
    
    private func setupPeriodicSync() {
        // Sync every 5 minutes when app is active
        Timer.publish(every: syncInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.syncIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - User Operations
    
    /// Caches user data locally
    /// - Parameter user: User to cache
    /// - Throws: Storage error
    func cacheUser(_ user: User) throws {
        try coreDataStack.performSave {
            let cachedUser = self.findOrCreateCachedUser(id: user.id)
            cachedUser.updateFromUser(user)
        }
    }
    
    /// Retrieves cached user by ID
    /// - Parameter id: User ID
    /// - Returns: Cached user if found
    /// - Throws: Storage error
    func getCachedUser(id: String) throws -> User? {
        let request: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        let cachedUsers = try coreDataStack.fetch(request)
        return cachedUsers.first?.toUser()
    }
    
    /// Retrieves all cached users
    /// - Returns: Array of cached users
    /// - Throws: Storage error
    func getAllCachedUsers() throws -> [User] {
        let request: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedUser.name, ascending: true)]
        
        let cachedUsers = try coreDataStack.fetch(request)
        return cachedUsers.compactMap { $0.toUser() }
    }
    
    // MARK: - Post Operations
    
    /// Caches post data locally
    /// - Parameter post: Post to cache
    /// - Throws: Storage error
    func cachePost(_ post: Post) throws {
        try coreDataStack.performSave {
            let cachedPost = self.findOrCreateCachedPost(id: post.id)
            cachedPost.updateFromPost(post)
            
            // Cache the author if not already cached
            if let author = post.author {
                let cachedAuthor = self.findOrCreateCachedUser(id: author.id)
                cachedAuthor.updateFromUser(author)
                cachedPost.author = cachedAuthor
            }
        }
    }
    
    /// Retrieves cached posts with pagination
    /// - Parameters:
    ///   - limit: Maximum number of posts to return
    ///   - offset: Number of posts to skip
    /// - Returns: Array of cached posts
    /// - Throws: Storage error
    func getCachedPosts(limit: Int = 20, offset: Int = 0) throws -> [Post] {
        let request: NSFetchRequest<CachedPost> = CachedPost.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedPost.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        
        let cachedPosts = try coreDataStack.fetch(request)
        return cachedPosts.compactMap { $0.toPost() }
    }
    
    /// Retrieves cached posts by user
    /// - Parameter userId: User ID
    /// - Returns: Array of user's cached posts
    /// - Throws: Storage error
    func getCachedPosts(byUserId userId: String) throws -> [Post] {
        let request: NSFetchRequest<CachedPost> = CachedPost.fetchRequest()
        request.predicate = NSPredicate(format: "authorId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedPost.createdAt, ascending: false)]
        
        let cachedPosts = try coreDataStack.fetch(request)
        return cachedPosts.compactMap { $0.toPost() }
    }
    
    // MARK: - Like Operations
    
    /// Caches like data locally
    /// - Parameter like: Like to cache
    /// - Throws: Storage error
    func cacheLike(_ like: Like) throws {
        try coreDataStack.performSave {
            let cachedLike = self.findOrCreateCachedLike(userId: like.userId, postId: like.postId)
            cachedLike.updateFromLike(like)
            
            // Link to cached user and post if they exist
            if let cachedUser = try? self.getCachedUser(id: like.userId) {
                let cachedUserEntity = self.findOrCreateCachedUser(id: like.userId)
                cachedLike.user = cachedUserEntity
            }
            
            let cachedPost = self.findOrCreateCachedPost(id: like.postId)
            cachedLike.post = cachedPost
        }
    }
    
    /// Removes a like from cache
    /// - Parameters:
    ///   - userId: User ID
    ///   - postId: Post ID
    /// - Throws: Storage error
    func removeLike(userId: String, postId: String) throws {
        let request: NSFetchRequest<CachedLike> = CachedLike.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND postId == %@", userId, postId)
        
        try coreDataStack.deleteObjects(request)
        try coreDataStack.saveMainContext()
    }
    
    /// Checks if a post is liked by a user
    /// - Parameters:
    ///   - postId: Post ID
    ///   - userId: User ID
    /// - Returns: True if post is liked by user
    /// - Throws: Storage error
    func isPostLiked(postId: String, userId: String) throws -> Bool {
        let request: NSFetchRequest<CachedLike> = CachedLike.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND postId == %@", userId, postId)
        request.fetchLimit = 1
        
        let count = try coreDataStack.count(request)
        return count > 0
    }
    
    /// Retrieves cached likes for a post
    /// - Parameter postId: Post ID
    /// - Returns: Array of likes for the post
    /// - Throws: Storage error
    func getCachedLikes(for postId: String) throws -> [Like] {
        let request: NSFetchRequest<CachedLike> = CachedLike.fetchRequest()
        request.predicate = NSPredicate(format: "postId == %@", postId)
        
        let cachedLikes = try coreDataStack.fetch(request)
        return cachedLikes.compactMap { $0.toLike() }
    }
    
    /// Retrieves cached posts liked by a user
    /// - Parameter userId: User ID
    /// - Returns: Array of posts liked by the user
    /// - Throws: Storage error
    func getCachedLikedPosts(for userId: String) throws -> [Post] {
        let request: NSFetchRequest<CachedLike> = CachedLike.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        
        let cachedLikes = try coreDataStack.fetch(request)
        return cachedLikes.compactMap { $0.post?.toPost() }
    }
    
    // MARK: - Comment Operations
    
    /// Caches comment data locally
    /// - Parameter comment: Comment to cache
    /// - Throws: Storage error
    func cacheComment(_ comment: Comment) throws {
        try coreDataStack.performSave {
            let cachedComment = self.findOrCreateCachedComment(id: comment.id)
            cachedComment.updateFromComment(comment)
            
            // Link to cached user and post
            let cachedUser = self.findOrCreateCachedUser(id: comment.user.id)
            cachedUser.updateFromUser(comment.user)
            cachedComment.user = cachedUser
            
            let cachedPost = self.findOrCreateCachedPost(id: comment.post.id)
            cachedComment.post = cachedPost
        }
    }
    
    /// Removes a comment from cache
    /// - Parameter id: Comment ID
    /// - Throws: Storage error
    func removeComment(id: String) throws {
        let request: NSFetchRequest<CachedComment> = CachedComment.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        try coreDataStack.deleteObjects(request)
        try coreDataStack.saveMainContext()
    }
    
    /// Retrieves cached comment by ID
    /// - Parameter id: Comment ID
    /// - Returns: Cached comment if found
    /// - Throws: Storage error
    func getCachedComment(id: String) throws -> Comment? {
        let request: NSFetchRequest<CachedComment> = CachedComment.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        let cachedComments = try coreDataStack.fetch(request)
        return cachedComments.first?.toComment()
    }
    
    /// Retrieves cached comments for a post with pagination
    /// - Parameters:
    ///   - postId: Post ID
    ///   - limit: Maximum number of comments to return
    ///   - offset: Number of comments to skip
    /// - Returns: Array of comments for the post
    /// - Throws: Storage error
    func getCachedComments(for postId: String, limit: Int = 20, offset: Int = 0) throws -> [Comment] {
        let request: NSFetchRequest<CachedComment> = CachedComment.fetchRequest()
        request.predicate = NSPredicate(format: "postId == %@", postId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedComment.createdAt, ascending: true)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        
        let cachedComments = try coreDataStack.fetch(request)
        return cachedComments.compactMap { $0.toComment() }
    }
    
    /// Retrieves cached comments by user
    /// - Parameter userId: User ID
    /// - Returns: Array of user's cached comments
    /// - Throws: Storage error
    func getCachedComments(byUserId userId: String) throws -> [Comment] {
        let request: NSFetchRequest<CachedComment> = CachedComment.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedComment.createdAt, ascending: false)]
        
        let cachedComments = try coreDataStack.fetch(request)
        return cachedComments.compactMap { $0.toComment() }
    }
    
    // MARK: - User Follow Operations
    
    /// Caches user follow relationship locally
    /// - Parameter userFollow: UserFollow to cache
    /// - Throws: Storage error
    func cacheUserFollow(_ userFollow: UserFollow) throws {
        try coreDataStack.performSave {
            let cachedUserFollow = self.findOrCreateCachedUserFollow(followerId: userFollow.followerId, followingId: userFollow.followingId)
            cachedUserFollow.updateFromUserFollow(userFollow)
            
            // Link to cached users if they exist
            if let follower = userFollow.follower {
                let cachedFollower = self.findOrCreateCachedUser(id: follower.id)
                cachedFollower.updateFromUser(follower)
                cachedUserFollow.follower = cachedFollower
            }
            
            if let following = userFollow.following {
                let cachedFollowing = self.findOrCreateCachedUser(id: following.id)
                cachedFollowing.updateFromUser(following)
                cachedUserFollow.following = cachedFollowing
            }
        }
    }
    
    /// Removes a user follow relationship from cache
    /// - Parameters:
    ///   - followerId: Follower user ID
    ///   - followingId: Following user ID
    /// - Throws: Storage error
    func removeUserFollow(followerId: String, followingId: String) throws {
        let request: NSFetchRequest<CachedUserFollow> = CachedUserFollow.fetchRequest()
        request.predicate = NSPredicate(format: "followerId == %@ AND followingId == %@", followerId, followingId)
        
        try coreDataStack.deleteObjects(request)
        try coreDataStack.saveMainContext()
    }
    
    /// Checks if a user is following another user
    /// - Parameters:
    ///   - followerId: Follower user ID
    ///   - followingId: Following user ID
    /// - Returns: True if following relationship exists
    /// - Throws: Storage error
    func isUserFollowing(followerId: String, followingId: String) throws -> Bool {
        let request: NSFetchRequest<CachedUserFollow> = CachedUserFollow.fetchRequest()
        request.predicate = NSPredicate(format: "followerId == %@ AND followingId == %@", followerId, followingId)
        request.fetchLimit = 1
        
        let count = try coreDataStack.count(request)
        return count > 0
    }
    
    /// Retrieves cached users that a user is following
    /// - Parameters:
    ///   - userId: User ID to get following for
    ///   - limit: Maximum number of users to return
    ///   - offset: Number of users to skip
    /// - Returns: Array of users being followed
    /// - Throws: Storage error
    func getCachedFollowing(for userId: String, limit: Int = 20, offset: Int = 0) throws -> [User] {
        let request: NSFetchRequest<CachedUserFollow> = CachedUserFollow.fetchRequest()
        request.predicate = NSPredicate(format: "followerId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedUserFollow.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        
        let cachedFollows = try coreDataStack.fetch(request)
        return cachedFollows.compactMap { $0.following?.toUser() }
    }
    
    /// Retrieves cached followers for a user
    /// - Parameters:
    ///   - userId: User ID to get followers for
    ///   - limit: Maximum number of users to return
    ///   - offset: Number of users to skip
    /// - Returns: Array of followers
    /// - Throws: Storage error
    func getCachedFollowers(for userId: String, limit: Int = 20, offset: Int = 0) throws -> [User] {
        let request: NSFetchRequest<CachedUserFollow> = CachedUserFollow.fetchRequest()
        request.predicate = NSPredicate(format: "followingId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedUserFollow.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        
        let cachedFollows = try coreDataStack.fetch(request)
        return cachedFollows.compactMap { $0.follower?.toUser() }
    }
    
    /// Gets follower count for a user
    /// - Parameter userId: User ID to get count for
    /// - Returns: Number of followers
    /// - Throws: Storage error
    func getFollowersCount(for userId: String) throws -> Int {
        let request: NSFetchRequest<CachedUserFollow> = CachedUserFollow.fetchRequest()
        request.predicate = NSPredicate(format: "followingId == %@", userId)
        
        return try coreDataStack.count(request)
    }
    
    /// Gets following count for a user
    /// - Parameter userId: User ID to get count for
    /// - Returns: Number of users being followed
    /// - Throws: Storage error
    func getFollowingCount(for userId: String) throws -> Int {
        let request: NSFetchRequest<CachedUserFollow> = CachedUserFollow.fetchRequest()
        request.predicate = NSPredicate(format: "followerId == %@", userId)
        
        return try coreDataStack.count(request)
    }
    
    // MARK: - Challenge Operations
    
    /// Caches challenge data locally
    /// - Parameter challenge: Challenge to cache
    /// - Throws: Storage error
    func cacheChallenge(_ challenge: Challenge) throws {
        try coreDataStack.performSave {
            let cachedChallenge = self.findOrCreateCachedChallenge(id: challenge.id)
            cachedChallenge.updateFromChallenge(challenge)
        }
    }
    
    /// Retrieves all cached challenges
    /// - Returns: Array of cached challenges
    /// - Throws: Storage error
    func getAllCachedChallenges() throws -> [Challenge] {
        let request: NSFetchRequest<CachedChallenge> = CachedChallenge.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedChallenge.name, ascending: true)]
        
        let cachedChallenges = try coreDataStack.fetch(request)
        return cachedChallenges.compactMap { $0.toChallenge() }
    }
    
    /// Retrieves cached challenge by ID
    /// - Parameter id: Challenge ID
    /// - Returns: Cached challenge if found
    /// - Throws: Storage error
    func getCachedChallenge(id: String) throws -> Challenge? {
        let request: NSFetchRequest<CachedChallenge> = CachedChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        let cachedChallenges = try coreDataStack.fetch(request)
        return cachedChallenges.first?.toChallenge()
    }
    
    // MARK: - User Challenge Operations
    
    /// Caches user challenge data locally
    /// - Parameter userChallenge: UserChallenge to cache
    /// - Throws: Storage error
    func cacheUserChallenge(_ userChallenge: UserChallenge) throws {
        try coreDataStack.performSave {
            let cachedUserChallenge = self.findOrCreateCachedUserChallenge(
                userId: userChallenge.userId,
                challengeId: userChallenge.challengeId
            )
            cachedUserChallenge.updateFromUserChallenge(userChallenge)
            
            // Link to cached user and challenge if they exist
            let cachedUser = self.findOrCreateCachedUser(id: userChallenge.userId)
            cachedUserChallenge.user = cachedUser
            
            let cachedChallenge = self.findOrCreateCachedChallenge(id: userChallenge.challengeId)
            cachedUserChallenge.challenge = cachedChallenge
        }
    }
    
    /// Removes a user challenge from cache
    /// - Parameters:
    ///   - userId: User ID
    ///   - challengeId: Challenge ID
    /// - Throws: Storage error
    func removeUserChallenge(userId: String, challengeId: String) throws {
        let request: NSFetchRequest<CachedUserChallenge> = CachedUserChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND challengeId == %@", userId, challengeId)
        
        try coreDataStack.deleteObjects(request)
        try coreDataStack.saveMainContext()
    }
    
    /// Retrieves cached user challenge
    /// - Parameters:
    ///   - userId: User ID
    ///   - challengeId: Challenge ID
    /// - Returns: Cached user challenge if found
    /// - Throws: Storage error
    func getCachedUserChallenge(userId: String, challengeId: String) throws -> UserChallenge? {
        let request: NSFetchRequest<CachedUserChallenge> = CachedUserChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND challengeId == %@", userId, challengeId)
        request.fetchLimit = 1
        
        let cachedUserChallenges = try coreDataStack.fetch(request)
        return cachedUserChallenges.first?.toUserChallenge()
    }
    
    /// Retrieves cached user challenges for a user
    /// - Parameter userId: User ID
    /// - Returns: Array of user's cached challenges
    /// - Throws: Storage error
    func getCachedUserChallenges(for userId: String) throws -> [UserChallenge] {
        let request: NSFetchRequest<CachedUserChallenge> = CachedUserChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedUserChallenge.startedAt, ascending: false)]
        
        let cachedUserChallenges = try coreDataStack.fetch(request)
        return cachedUserChallenges.compactMap { $0.toUserChallenge() }
    }
    
    /// Retrieves cached user challenges for a challenge
    /// - Parameter challengeId: Challenge ID
    /// - Returns: Array of user challenges for the challenge
    /// - Throws: Storage error
    func getCachedUserChallenges(for challengeId: String) throws -> [UserChallenge] {
        let request: NSFetchRequest<CachedUserChallenge> = CachedUserChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "challengeId == %@", challengeId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedUserChallenge.startedAt, ascending: false)]
        
        let cachedUserChallenges = try coreDataStack.fetch(request)
        return cachedUserChallenges.compactMap { $0.toUserChallenge() }
    }
    
    // MARK: - League Operations
    
    /// Caches league data locally
    /// - Parameter league: League to cache
    /// - Throws: Storage error
    func cacheLeague(_ league: League) throws {
        try coreDataStack.performSave {
            let cachedLeague = self.findOrCreateCachedLeague(id: league.id)
            cachedLeague.updateFromLeague(league)
        }
    }
    
    /// Retrieves all cached leagues
    /// - Returns: Array of cached leagues
    /// - Throws: Storage error
    func getAllCachedLeagues() throws -> [League] {
        let request: NSFetchRequest<CachedLeague> = CachedLeague.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedLeague.name, ascending: true)]
        
        let cachedLeagues = try coreDataStack.fetch(request)
        return cachedLeagues.compactMap { $0.toLeague() }
    }
    
    /// Retrieves cached league by ID
    /// - Parameter id: League ID
    /// - Returns: Cached league if found
    /// - Throws: Storage error
    func getCachedLeague(id: String) throws -> League? {
        let request: NSFetchRequest<CachedLeague> = CachedLeague.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        let cachedLeagues = try coreDataStack.fetch(request)
        return cachedLeagues.first?.toLeague()
    }
    
    // MARK: - League User Operations
    
    /// Caches league user data locally
    /// - Parameter leagueUser: LeagueUser to cache
    /// - Throws: Storage error
    func cacheLeagueUser(_ leagueUser: LeagueUser) throws {
        try coreDataStack.performSave {
            let cachedLeagueUser = self.findOrCreateCachedLeagueUser(
                userId: leagueUser.userId,
                leagueId: leagueUser.leagueId
            )
            cachedLeagueUser.updateFromLeagueUser(leagueUser)
            
            // Link to cached user and league
            let cachedUser = self.findOrCreateCachedUser(id: leagueUser.userId)
            if let user = leagueUser.user {
                cachedUser.updateFromUser(user)
            }
            cachedLeagueUser.user = cachedUser
            
            if let league = leagueUser.league {
                let cachedLeague = self.findOrCreateCachedLeague(id: league.id)
                cachedLeague.updateFromLeague(league)
                cachedLeagueUser.league = cachedLeague
            }
        }
    }
    
    /// Removes a league user from cache
    /// - Parameters:
    ///   - userId: User ID
    ///   - leagueId: League ID
    /// - Throws: Storage error
    func removeLeagueUser(userId: String, leagueId: String) throws {
        let request: NSFetchRequest<CachedLeagueUser> = CachedLeagueUser.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND leagueId == %@", userId, leagueId)
        
        try coreDataStack.deleteObjects(request)
        try coreDataStack.saveMainContext()
    }
    
    /// Retrieves cached league user
    /// - Parameters:
    ///   - userId: User ID
    ///   - leagueId: League ID
    /// - Returns: Cached league user if found
    /// - Throws: Storage error
    func getCachedLeagueUser(userId: String, leagueId: String) throws -> LeagueUser? {
        let request: NSFetchRequest<CachedLeagueUser> = CachedLeagueUser.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND leagueId == %@", userId, leagueId)
        request.fetchLimit = 1
        
        let cachedLeagueUsers = try coreDataStack.fetch(request)
        return cachedLeagueUsers.first?.toLeagueUser()
    }
    
    /// Retrieves cached league users for a user
    /// - Parameter userId: User ID
    /// - Returns: Array of user's league memberships
    /// - Throws: Storage error
    func getCachedLeagueUsers(for userId: String) throws -> [LeagueUser] {
        let request: NSFetchRequest<CachedLeagueUser> = CachedLeagueUser.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedLeagueUser.createdAt, ascending: false)]
        
        let cachedLeagueUsers = try coreDataStack.fetch(request)
        return cachedLeagueUsers.compactMap { $0.toLeagueUser() }
    }
    
    /// Retrieves cached league users for a specific league
    /// - Parameter leagueId: League ID
    /// - Returns: Array of league members
    /// - Throws: Storage error
    func getCachedLeagueUsers(for leagueId: String) throws -> [LeagueUser] {
        let request: NSFetchRequest<CachedLeagueUser> = CachedLeagueUser.fetchRequest()
        request.predicate = NSPredicate(format: "leagueId == %@", leagueId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedLeagueUser.createdAt, ascending: false)]
        
        let cachedLeagueUsers = try coreDataStack.fetch(request)
        return cachedLeagueUsers.compactMap { $0.toLeagueUser() }
    }
    
    // MARK: - League Challenge Operations
    
    /// Caches league challenge data locally
    /// - Parameter leagueChallenge: LeagueChallenge to cache
    /// - Throws: Storage error
    func cacheLeagueChallenge(_ leagueChallenge: LeagueChallenge) throws {
        try coreDataStack.performSave {
            let cachedLeagueChallenge = self.findOrCreateCachedLeagueChallenge(id: leagueChallenge.id)
            cachedLeagueChallenge.updateFromLeagueChallenge(leagueChallenge)
            
            // Link to cached league and challenge if they exist
            if let league = leagueChallenge.league {
                let cachedLeague = self.findOrCreateCachedLeague(id: league.id)
                cachedLeague.updateFromLeague(league)
                cachedLeagueChallenge.league = cachedLeague
            }
            
            if let challenge = leagueChallenge.challenge {
                let cachedChallenge = self.findOrCreateCachedChallenge(id: challenge.id)
                cachedChallenge.updateFromChallenge(challenge)
                cachedLeagueChallenge.challenge = cachedChallenge
            }
        }
    }
    
    /// Retrieves cached league challenges for a league
    /// - Parameter leagueId: League ID
    /// - Returns: Array of league challenges
    /// - Throws: Storage error
    func getCachedLeagueChallenges(for leagueId: String) throws -> [LeagueChallenge] {
        let request: NSFetchRequest<CachedLeagueChallenge> = CachedLeagueChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "leagueId == %@", leagueId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedLeagueChallenge.createdAt, ascending: false)]
        
        let cachedLeagueChallenges = try coreDataStack.fetch(request)
        return cachedLeagueChallenges.compactMap { $0.toLeagueChallenge() }
    }
    
    // MARK: - Sync Operations
    
    /// Performs full data synchronization
    /// - Throws: Sync error
    func performFullSync() async throws {
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // Sync users, posts, challenges, etc.
            try await syncUsers()
            try await syncPosts()
            try await syncChallenges()
            
            lastSyncDate = Date()
            syncError = nil
            
        } catch {
            syncError = error
            throw error
        }
    }
    
    /// Syncs data if needed (based on last sync time)
    func syncIfNeeded() async {
        guard shouldSync else { return }
        
        do {
            try await performFullSync()
        } catch {
            print("Sync failed: \(error)")
        }
    }
    
    private var shouldSync: Bool {
        guard let lastSync = lastSyncDate else { return true }
        return Date().timeIntervalSince(lastSync) > syncInterval
    }
    
    // MARK: - Sync Methods for OfflineQueueService
    
    /// Caches multiple posts
    /// - Parameter posts: Array of posts to cache
    func cachePosts(_ posts: [Post]) async {
        for post in posts {
            try? cachePost(post)
        }
    }
    
    /// Caches multiple challenges
    /// - Parameter challenges: Array of challenges to cache
    func cacheChallenges(_ challenges: [Challenge]) async {
        for challenge in challenges {
            try? cacheChallenge(challenge)
        }
    }
    
    /// Caches multiple user challenges
    /// - Parameter userChallenges: Array of user challenges to cache
    func cacheUserChallenges(_ userChallenges: [UserChallenge]) async {
        for userChallenge in userChallenges {
            try? cacheUserChallenge(userChallenge)
        }
    }
    
    /// Caches multiple leagues
    /// - Parameter leagues: Array of leagues to cache
    func cacheLeagues(_ leagues: [League]) async {
        for league in leagues {
            try? cacheLeague(league)
        }
    }
    
    /// Caches multiple league users
    /// - Parameter leagueUsers: Array of league users to cache
    func cacheUserLeagues(_ leagueUsers: [LeagueUser]) async {
        for leagueUser in leagueUsers {
            try? cacheLeagueUser(leagueUser)
        }
    }
    
    /// Caches user follow relationships
    /// - Parameters:
    ///   - followers: Array of followers
    ///   - following: Array of users being followed
    func cacheUserFollows(followers: [UserFollow], following: [UserFollow]) async {
        for follower in followers {
            try? cacheUserFollow(follower)
        }
        for follow in following {
            try? cacheUserFollow(follow)
        }
    }
    
    /// Removes stale data older than the specified date
    /// - Parameter date: Cutoff date for stale data
    func removeStaleData(olderThan date: Date) async {
        do {
            // Remove stale posts
            let postRequest: NSFetchRequest<CachedPost> = CachedPost.fetchRequest()
            postRequest.predicate = NSPredicate(format: "lastUpdated < %@", date as NSDate)
            try coreDataStack.deleteObjects(postRequest)
            
            // Remove stale users (except current user)
            if let currentUserId = AuthService.shared.currentUser?.id {
                let userRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
                userRequest.predicate = NSPredicate(format: "lastUpdated < %@ AND id != %@", date as NSDate, currentUserId)
                try coreDataStack.deleteObjects(userRequest)
            }
            
            // Remove stale challenges
            let challengeRequest: NSFetchRequest<CachedChallenge> = CachedChallenge.fetchRequest()
            challengeRequest.predicate = NSPredicate(format: "lastUpdated < %@", date as NSDate)
            try coreDataStack.deleteObjects(challengeRequest)
            
            // Remove stale leagues
            let leagueRequest: NSFetchRequest<CachedLeague> = CachedLeague.fetchRequest()
            leagueRequest.predicate = NSPredicate(format: "lastUpdated < %@", date as NSDate)
            try coreDataStack.deleteObjects(leagueRequest)
            
            try coreDataStack.saveMainContext()
        } catch {
            print("Failed to remove stale data: \(error)")
        }
    }
    
    // MARK: - Private Sync Methods
    
    private func syncUsers() async throws {
        // TODO: Implement user sync with GraphQL
        // This would fetch users from the backend and update cache
    }
    
    private func syncPosts() async throws {
        // TODO: Implement post sync with GraphQL
        // This would fetch posts from the backend and update cache
    }
    
    private func syncChallenges() async throws {
        // TODO: Implement challenge sync with GraphQL
        // This would fetch challenges from the backend and update cache
    }
    
    // MARK: - Cache Management
    
    /// Clears all cached data
    /// - Throws: Storage error
    func clearCache() throws {
        try coreDataStack.clearAllData()
        lastSyncDate = nil
    }
    
    /// Clears old cached data
    /// - Throws: Storage error
    func clearOldCache() throws {
        let cutoffDate = Date().addingTimeInterval(-maxCacheAge)
        
        // Clear old posts
        let postRequest: NSFetchRequest<CachedPost> = CachedPost.fetchRequest()
        postRequest.predicate = NSPredicate(format: "lastUpdated < %@", cutoffDate as NSDate)
        try coreDataStack.deleteObjects(postRequest)
        
        // Clear old users (except current user)
        let userRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "lastUpdated < %@", cutoffDate as NSDate)
        try coreDataStack.deleteObjects(userRequest)
        
        try coreDataStack.saveMainContext()
    }
    
    /// Gets cache statistics
    /// - Returns: Cache statistics
    func getCacheStats() -> CacheStats {
        do {
            let userCount = try coreDataStack.count(CachedUser.fetchRequest())
            let postCount = try coreDataStack.count(CachedPost.fetchRequest())
            let challengeCount = try coreDataStack.count(CachedChallenge.fetchRequest())
            let likeCount = try coreDataStack.count(CachedLike.fetchRequest())
            let commentCount = try coreDataStack.count(CachedComment.fetchRequest())
            let followCount = try coreDataStack.count(CachedUserFollow.fetchRequest())
            let userChallengeCount = try coreDataStack.count(CachedUserChallenge.fetchRequest())
            let storeSize = coreDataStack.getStoreSize()
            
            return CacheStats(
                userCount: userCount,
                postCount: postCount,
                challengeCount: challengeCount,
                likeCount: likeCount,
                commentCount: commentCount,
                followCount: followCount,
                userChallengeCount: userChallengeCount,
                storeSizeBytes: storeSize,
                lastSyncDate: lastSyncDate
            )
        } catch {
            return CacheStats(
                userCount: 0,
                postCount: 0,
                challengeCount: 0,
                likeCount: 0,
                commentCount: 0,
                followCount: 0,
                userChallengeCount: 0,
                storeSizeBytes: 0,
                lastSyncDate: lastSyncDate
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func findOrCreateCachedUser(id: String) -> CachedUser {
        let request: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        if let existingUser = try? coreDataStack.fetch(request).first {
            return existingUser
        } else {
            return coreDataStack.create(CachedUser.self)
        }
    }
    
    private func findOrCreateCachedPost(id: String) -> CachedPost {
        let request: NSFetchRequest<CachedPost> = CachedPost.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        if let existingPost = try? coreDataStack.fetch(request).first {
            return existingPost
        } else {
            return coreDataStack.create(CachedPost.self)
        }
    }
    
    private func findOrCreateCachedChallenge(id: String) -> CachedChallenge {
        let request: NSFetchRequest<CachedChallenge> = CachedChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        if let existingChallenge = try? coreDataStack.fetch(request).first {
            return existingChallenge
        } else {
            return coreDataStack.create(CachedChallenge.self)
        }
    }
    
    private func findOrCreateCachedLike(userId: String, postId: String) -> CachedLike {
        let request: NSFetchRequest<CachedLike> = CachedLike.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND postId == %@", userId, postId)
        request.fetchLimit = 1
        
        if let existingLike = try? coreDataStack.fetch(request).first {
            return existingLike
        } else {
            return coreDataStack.create(CachedLike.self)
        }
    }
    
    private func findOrCreateCachedComment(id: String) -> CachedComment {
        let request: NSFetchRequest<CachedComment> = CachedComment.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        if let existingComment = try? coreDataStack.fetch(request).first {
            return existingComment
        } else {
            return coreDataStack.create(CachedComment.self)
        }
    }
    
    private func findOrCreateCachedUserFollow(followerId: String, followingId: String) -> CachedUserFollow {
        let request: NSFetchRequest<CachedUserFollow> = CachedUserFollow.fetchRequest()
        request.predicate = NSPredicate(format: "followerId == %@ AND followingId == %@", followerId, followingId)
        request.fetchLimit = 1
        
        if let existingFollow = try? coreDataStack.fetch(request).first {
            return existingFollow
        } else {
            return coreDataStack.create(CachedUserFollow.self)
        }
    }
    
    private func findOrCreateCachedUserChallenge(userId: String, challengeId: String) -> CachedUserChallenge {
        let request: NSFetchRequest<CachedUserChallenge> = CachedUserChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND challengeId == %@", userId, challengeId)
        request.fetchLimit = 1
        
        if let existingUserChallenge = try? coreDataStack.fetch(request).first {
            return existingUserChallenge
        } else {
            return coreDataStack.create(CachedUserChallenge.self)
        }
    }
    
    private func findOrCreateCachedLeague(id: String) -> CachedLeague {
        let request: NSFetchRequest<CachedLeague> = CachedLeague.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        if let existingLeague = try? coreDataStack.fetch(request).first {
            return existingLeague
        } else {
            return coreDataStack.create(CachedLeague.self)
        }
    }
    
    private func findOrCreateCachedLeagueUser(userId: String, leagueId: String) -> CachedLeagueUser {
        let request: NSFetchRequest<CachedLeagueUser> = CachedLeagueUser.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND leagueId == %@", userId, leagueId)
        request.fetchLimit = 1
        
        if let existingLeagueUser = try? coreDataStack.fetch(request).first {
            return existingLeagueUser
        } else {
            return coreDataStack.create(CachedLeagueUser.self)
        }
    }
    
    private func findOrCreateCachedLeagueChallenge(id: String) -> CachedLeagueChallenge {
        let request: NSFetchRequest<CachedLeagueChallenge> = CachedLeagueChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        if let existingLeagueChallenge = try? coreDataStack.fetch(request).first {
            return existingLeagueChallenge
        } else {
            return coreDataStack.create(CachedLeagueChallenge.self)
        }
    }
}

// MARK: - Cache Statistics

struct CacheStats {
    let userCount: Int
    let postCount: Int
    let challengeCount: Int
    let likeCount: Int
    let commentCount: Int
    let followCount: Int
    let userChallengeCount: Int
    let leagueCount: Int
    let leagueMemberCount: Int
    let leagueChallengeCount: Int
    let storeSizeBytes: Int64
    let lastSyncDate: Date?
    
    var storeSizeMB: Double {
        return Double(storeSizeBytes) / (1024 * 1024)
    }
    
    var formattedStoreSize: String {
        if storeSizeMB < 1 {
            return String(format: "%.1f KB", Double(storeSizeBytes) / 1024)
        } else {
            return String(format: "%.1f MB", storeSizeMB)
        }
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockCacheService: CacheService {
    override init() {
        super.init(
            coreDataStack: MockCoreDataStack(),
            graphqlService: MockGraphQLService()
        )
    }
    
    var shouldFailSync = false
    var syncDelay: TimeInterval = 0.5
    
    override func performFullSync() async throws {
        isSyncing = true
        
        try await Task.sleep(nanoseconds: UInt64(syncDelay * 1_000_000_000))
        
        if shouldFailSync {
            syncError = AppError.network(.serverError(500))
            isSyncing = false
            throw syncError!
        }
        
        lastSyncDate = Date()
        syncError = nil
        isSyncing = false
    }
}
#endif