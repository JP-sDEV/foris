import Foundation
import Combine

@MainActor
class SyncService: ObservableObject {
    static let shared = SyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncProgress: Double = 0.0
    @Published var syncStatus: SyncStatus = .idle
    
    private let offlineQueue = OfflineQueueService.shared
    private let cacheService = CacheService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    private init() {
        setupNetworkMonitoring()
        loadLastSyncDate()
    }
    
    private func setupNetworkMonitoring() {
        NetworkMonitor.shared.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.performFullSync()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func performFullSync() async {
        guard !isSyncing && NetworkMonitor.shared.isConnected else { return }
        
        isSyncing = true
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            // Step 1: Process offline actions (30% of progress)
            await processOfflineActions()
            syncProgress = 0.3
            
            // Step 2: Sync cached data (70% of progress)
            try await syncCachedData()
            syncProgress = 1.0
            
            lastSyncDate = Date()
            saveLastSyncDate()
            syncStatus = .success
            
        } catch {
            syncStatus = .failed(error)
            print("Sync failed: \(error)")
        }
        
        isSyncing = false
    }
    
    func forceSyncData() async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw AppError.network(.networkUnavailable)
        }
        
        try await syncCachedData()
        lastSyncDate = Date()
        saveLastSyncDate()
    }
    
    // MARK: - Private Methods
    
    private func processOfflineActions() async {
        await offlineQueue.processPendingActions()
    }
    
    private func syncCachedData() async throws {
        // Sync posts
        try await syncPosts()
        syncProgress = 0.4
        
        // Sync users
        try await syncUsers()
        syncProgress = 0.5
        
        // Sync challenges
        try await syncChallenges()
        syncProgress = 0.6
        
        // Sync leagues
        try await syncLeagues()
        syncProgress = 0.7
        
        // Sync user relationships
        try await syncUserRelationships()
        syncProgress = 0.8
        
        // Clean up stale data
        await cleanupStaleData()
        syncProgress = 1.0
    }
    
    private func syncPosts() async throws {
        let posts = try await PostService.shared.getAllPosts()
        await cacheService.cachePosts(posts)
    }
    
    private func syncUsers() async throws {
        // Sync current user profile
        let currentUser = try await UserService.shared.getCurrentUser()
        await cacheService.cacheUser(currentUser)
        
        // Sync followed users
        let followedUsers = try await FollowService.shared.getFollowedUsers()
        for user in followedUsers {
            await cacheService.cacheUser(user)
        }
    }
    
    private func syncChallenges() async throws {
        let challenges = try await ChallengeService.shared.getAllChallenges()
        await cacheService.cacheChallenges(challenges)
        
        let userChallenges = try await ChallengeService.shared.getUserChallenges()
        await cacheService.cacheUserChallenges(userChallenges)
    }
    
    private func syncLeagues() async throws {
        let leagues = try await LeagueService.shared.getAllLeagues()
        await cacheService.cacheLeagues(leagues)
        
        let userLeagues = try await LeagueService.shared.getUserLeagues()
        await cacheService.cacheUserLeagues(userLeagues)
    }
    
    private func syncUserRelationships() async throws {
        let followers = try await FollowService.shared.getFollowers()
        let following = try await FollowService.shared.getFollowing()
        
        await cacheService.cacheUserFollows(followers: followers, following: following)
    }
    
    private func cleanupStaleData() async {
        let staleThreshold = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days
        await cacheService.removeStaleData(olderThan: staleThreshold)
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict<T: Equatable>(local: T, remote: T, lastModified: Date, remoteModified: Date) -> T {
        // Simple last-write-wins strategy
        return remoteModified > lastModified ? remote : local
    }
    
    // MARK: - Persistence
    
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "LastSyncDate")
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "LastSyncDate") as? Date
    }
}