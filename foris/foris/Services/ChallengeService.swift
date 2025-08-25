import Foundation
import Combine

/// Service for managing challenges and user participation
/// Handles challenge creation, joining, completion, and progress tracking
@MainActor
final class ChallengeService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ChallengeService()
    
    // MARK: - Properties
    
    private let graphqlService: GraphQLServiceProtocol
    private let cacheService: CacheService
    private let authService: AuthServiceProtocol
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var error: AppError?
    
    // MARK: - Initialization
    
    init(
        graphqlService: GraphQLServiceProtocol = GraphQLService.shared,
        cacheService: CacheService = CacheService.shared,
        authService: AuthServiceProtocol = AuthService.shared
    ) {
        self.graphqlService = graphqlService
        self.cacheService = cacheService
        self.authService = authService
    }
    
    // MARK: - Challenge Operations
    
    /// Gets all available challenges
    /// - Parameters:
    ///   - limit: Maximum number of challenges to return
    ///   - offset: Number of challenges to skip
    /// - Returns: Array of challenges
    /// - Throws: AppError if operation fails
    func getChallenges(limit: Int = 20, offset: Int = 0) async throws -> [Challenge] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedChallenges = try cacheService.getAllCachedChallenges()
            
            if !cachedChallenges.isEmpty {
                return Array(cachedChallenges.prefix(limit))
            }
            
            // TODO: Implement GraphQL challenges query
            // For now, return mock challenges
            return generateMockChallenges(limit: limit)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets a specific challenge by ID
    /// - Parameter challengeId: Challenge ID
    /// - Returns: Challenge if found
    /// - Throws: AppError if operation fails
    func getChallenge(id challengeId: String) async throws -> Challenge {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            if let cachedChallenge = try cacheService.getCachedChallenge(id: challengeId) {
                return cachedChallenge
            }
            
            // TODO: Implement GraphQL challenge query
            // For now, return mock challenge
            return generateMockChallenges(limit: 1).first!
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets challenges that the current user has joined
    /// - Returns: Array of joined challenges
    /// - Throws: AppError if operation fails
    func getJoinedChallenges() async throws -> [Challenge] {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let userChallenges = try cacheService.getCachedUserChallenges(for: currentUser.id)
            let challengeIds = userChallenges.map { $0.challengeId }
            
            var joinedChallenges: [Challenge] = []
            for challengeId in challengeIds {
                if let challenge = try? cacheService.getCachedChallenge(id: challengeId) {
                    joinedChallenges.append(challenge)
                }
            }
            
            if !joinedChallenges.isEmpty {
                return joinedChallenges
            }
            
            // TODO: Implement GraphQL userChallenges query
            // For now, return mock joined challenges
            return generateMockJoinedChallenges()
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Creates a new challenge
    /// - Parameter challengeData: Challenge creation data
    /// - Returns: Created challenge
    /// - Throws: AppError if operation fails
    func createChallenge(_ challengeData: ChallengeCreationData) async throws -> Challenge {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate input
            try validateChallengeCreation(challengeData)
            
            // TODO: Implement GraphQL createChallenge mutation
            // For now, create mock challenge
            let challenge = Challenge(
                id: UUID().uuidString,
                name: challengeData.name,
                description: challengeData.description,
                createdBy: currentUser.id,
                endDate: challengeData.endDate,
                userStatus: nil
            )
            
            // Cache the challenge
            try cacheService.cacheChallenge(challenge)
            
            return challenge
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Joins a challenge
    /// - Parameter challengeId: Challenge ID to join
    /// - Returns: UserChallenge representing the participation
    /// - Throws: AppError if operation fails
    func joinChallenge(_ challengeId: String) async throws -> UserChallenge {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check if already joined
            let existingUserChallenge = try? cacheService.getCachedUserChallenge(
                userId: currentUser.id,
                challengeId: challengeId
            )
            
            if existingUserChallenge != nil {
                throw AppError.validation(.invalid("Already joined this challenge"))
            }
            
            // Create user challenge for optimistic update
            let userChallenge = UserChallenge(
                userId: currentUser.id,
                challengeId: challengeId,
                status: .inProgress,
                startedAt: Date(),
                completedAt: nil
            )
            
            // Cache the user challenge
            try cacheService.cacheUserChallenge(userChallenge)
            
            // Check if online
            if NetworkMonitor.shared.isConnected {
                // TODO: Implement GraphQL joinChallenge mutation
                // For now, just return the cached challenge
                return userChallenge
            } else {
                // Queue for offline processing
                let actionData = JoinChallengeActionData(challengeId: challengeId, isJoining: true)
                let data = try JSONEncoder().encode(actionData)
                let action = OfflineAction(type: .joinChallenge, data: data)
                
                await OfflineQueueService.shared.queueAction(action)
                
                return userChallenge
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Leaves a challenge
    /// - Parameter challengeId: Challenge ID to leave
    /// - Throws: AppError if operation fails
    func leaveChallenge(_ challengeId: String) async throws {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Optimistically remove from cache
            try cacheService.removeUserChallenge(userId: currentUser.id, challengeId: challengeId)
            
            // Check if online
            if NetworkMonitor.shared.isConnected {
                // TODO: Implement GraphQL leaveChallenge mutation
                // For now, just complete the operation
            } else {
                // Queue for offline processing
                let actionData = JoinChallengeActionData(challengeId: challengeId, isJoining: false)
                let data = try JSONEncoder().encode(actionData)
                let action = OfflineAction(type: .leaveChallenge, data: data)
                
                await OfflineQueueService.shared.queueAction(action)
            }
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Completes a challenge
    /// - Parameter challengeId: Challenge ID to complete
    /// - Returns: Updated UserChallenge
    /// - Throws: AppError if operation fails
    func completeChallenge(_ challengeId: String) async throws -> UserChallenge {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get existing user challenge
            guard var userChallenge = try? cacheService.getCachedUserChallenge(
                userId: currentUser.id,
                challengeId: challengeId
            ) else {
                throw AppError.validation(.invalid("Not participating in this challenge"))
            }
            
            // Update status
            userChallenge = UserChallenge(
                userId: userChallenge.userId,
                challengeId: userChallenge.challengeId,
                status: .completed,
                startedAt: userChallenge.startedAt,
                completedAt: Date()
            )
            
            // TODO: Implement GraphQL completeChallenge mutation
            // For now, just update cache
            try cacheService.cacheUserChallenge(userChallenge)
            
            return userChallenge
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets challenges the user has joined
    /// - Returns: Array of challenges the user has joined
    /// - Throws: AppError if operation fails
    func getJoinedChallenges() async throws -> [Challenge] {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let userChallenges = try cacheService.getCachedUserChallenges(for: currentUser.id)
            
            if !userChallenges.isEmpty {
                // Convert UserChallenges to Challenges with user status
                var joinedChallenges: [Challenge] = []
                
                for userChallenge in userChallenges {
                    if let cachedChallenge = try? cacheService.getCachedChallenge(id: userChallenge.challengeId) {
                        // Create challenge with user status based on UserChallenge status
                        let userStatus: ChallengeUserStatus? = {
                            switch userChallenge.status {
                            case .inProgress:
                                return .inProgress
                            case .completed:
                                return .completed
                            case .paused:
                                return .inProgress // Map paused to inProgress for now
                            }
                        }()
                        
                        let challengeWithStatus = Challenge(
                            id: cachedChallenge.id,
                            name: cachedChallenge.name,
                            description: cachedChallenge.description,
                            createdBy: cachedChallenge.createdBy,
                            endDate: cachedChallenge.endDate,
                            userStatus: userStatus
                        )
                        
                        joinedChallenges.append(challengeWithStatus)
                    }
                }
                
                return joinedChallenges
            }
            
            // TODO: Implement GraphQL getJoinedChallenges query
            // For now, return mock joined challenges
            return generateMockJoinedChallenges()
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets challenge participants
    /// - Parameter challengeId: Challenge ID
    /// - Returns: Array of users participating in the challenge
    /// - Throws: AppError if operation fails
    func getChallengeParticipants(_ challengeId: String) async throws -> [User] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let userChallenges = try cacheService.getCachedUserChallenges(for: challengeId)
            let userIds = userChallenges.map { $0.userId }
            
            var participants: [User] = []
            for userId in userIds {
                if let user = try? cacheService.getCachedUser(id: userId) {
                    participants.append(user)
                }
            }
            
            if !participants.isEmpty {
                return participants
            }
            
            // TODO: Implement GraphQL challengeParticipants query
            // For now, return mock participants
            return generateMockParticipants()
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets user's challenge status for a specific challenge
    /// - Parameter challengeId: Challenge ID
    /// - Returns: Challenge status or nil if not participating
    /// - Throws: AppError if operation fails
    func getUserChallengeStatus(_ challengeId: String) async throws -> UserChallengeStatus? {
        guard let currentUser = authService.currentUser else {
            return nil
        }
        
        do {
            let userChallenge = try? cacheService.getCachedUserChallenge(
                userId: currentUser.id,
                challengeId: challengeId
            )
            
            return userChallenge?.status
            
        } catch {
            return nil
        }
    }
    
    // MARK: - Validation
    
    private func validateChallengeCreation(_ challengeData: ChallengeCreationData) throws {
        guard !challengeData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.validation(.required("Challenge name"))
        }
        
        guard challengeData.name.count >= 3 else {
            throw AppError.validation(.tooShort("Challenge name", 3))
        }
        
        guard challengeData.name.count <= 100 else {
            throw AppError.validation(.tooLong("Challenge name", 100))
        }
        
        if let description = challengeData.description {
            guard description.count <= 500 else {
                throw AppError.validation(.tooLong("Challenge description", 500))
            }
        }
        
        if let endDate = challengeData.endDate {
            guard endDate > Date() else {
                throw AppError.validation(.invalid("End date must be in the future"))
            }
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockChallenges(limit: Int) -> [Challenge] {
        let mockChallenges = [
            Challenge(
                id: "challenge-1",
                name: "30-Day Fitness Challenge",
                description: "Complete 30 days of consistent workouts to build a healthy habit",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                userStatus: nil
            ),
            Challenge(
                id: "challenge-2",
                name: "10K Steps Daily",
                description: "Walk at least 10,000 steps every day for a week",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                userStatus: nil
            ),
            Challenge(
                id: "challenge-3",
                name: "Hydration Hero",
                description: "Drink 8 glasses of water daily for 2 weeks",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                userStatus: nil
            ),
            Challenge(
                id: "challenge-4",
                name: "Morning Yoga",
                description: "Start each day with 15 minutes of yoga for a month",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                userStatus: nil
            ),
            Challenge(
                id: "challenge-5",
                name: "Strength Training",
                description: "Complete 3 strength training sessions per week for 4 weeks",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 28, to: Date()),
                userStatus: nil
            )
        ]
        
        return Array(mockChallenges.prefix(limit))
    }
    
    private func generateMockJoinedChallenges() -> [Challenge] {
        return [
            Challenge(
                id: "challenge-1",
                name: "30-Day Fitness Challenge",
                description: "Complete 30 days of consistent workouts to build a healthy habit",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                userStatus: .inProgress
            ),
            Challenge(
                id: "challenge-2",
                name: "10K Steps Daily",
                description: "Walk at least 10,000 steps every day for a week",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                userStatus: .inProgress
            )
        ]
    }
    
    private func generateMockParticipants() -> [User] {
        return [
            User.mock,
            User.mockWithAvatar,
            User(id: "user3", name: "Alex Johnson", email: "alex@example.com", bio: "Fitness enthusiast", avatarUrl: nil),
            User(id: "user4", name: "Sarah Wilson", email: "sarah@example.com", bio: "Yoga instructor", avatarUrl: "https://example.com/sarah.jpg")
        ]
    }
    
    // MARK: - Sync Methods
    
    /// Gets all challenges (for sync service)
    /// - Returns: Array of all challenges
    /// - Throws: AppError if operation fails
    func getAllChallenges() async throws -> [Challenge] {
        // TODO: Implement GraphQL query to get all challenges
        return try await getChallenges(limit: 1000, offset: 0)
    }
    
    /// Gets user challenges (for sync service)
    /// - Returns: Array of user challenges
    /// - Throws: AppError if operation fails
    func getUserChallenges() async throws -> [UserChallenge] {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        // TODO: Implement GraphQL query to get user challenges
        return try cacheService.getCachedUserChallenges(for: currentUser.id)
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        error = nil
    }
}

// MARK: - Challenge Data Structures

/// Data structure for creating challenges
struct ChallengeCreationData {
    let name: String
    let description: String?
    let endDate: Date?
    
    init(name: String, description: String? = nil, endDate: Date? = nil) {
        self.name = name
        self.description = description
        self.endDate = endDate
    }
    
    /// Returns true if the data is valid for creation
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty &&
               trimmedName.count >= 3 &&
               trimmedName.count <= 100 &&
               (description?.count ?? 0) <= 500 &&
               (endDate == nil || endDate! > Date())
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockChallengeService: ChallengeService {
    var shouldFailOperations = false
    var operationDelay: TimeInterval = 0.5
    var mockChallenges: [Challenge] = []
    var mockUserChallenges: [String: UserChallenge] = [:] // challengeId -> UserChallenge
    
    override init() {
        super.init()
        generateMockData()
    }
    
    private func generateMockData() {
        mockChallenges = [
            Challenge(
                id: "mock-challenge-1",
                name: "Mock 30-Day Challenge",
                description: "A mock challenge for testing",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                userStatus: nil
            ),
            Challenge(
                id: "mock-challenge-2",
                name: "Mock Weekly Challenge",
                description: "A shorter mock challenge",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                userStatus: .inProgress
            )
        ]
        
        // Add some mock user challenges
        mockUserChallenges["mock-challenge-2"] = UserChallenge(
            id: "mock-user-challenge-1",
            userId: "current-user",
            challengeId: "mock-challenge-2",
            status: .active,
            progress: 50.0,
            completedAt: nil,
            joinedAt: Date().addingTimeInterval(-86400), // 1 day ago
            user: User.mock,
            challenge: nil
        )
    }
    
    override func getChallenges(limit: Int = 20, offset: Int = 0) async throws -> [Challenge] {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        let endIndex = min(offset + limit, mockChallenges.count)
        let startIndex = min(offset, mockChallenges.count)
        
        return Array(mockChallenges[startIndex..<endIndex])
    }
    
    override func joinChallenge(_ challengeId: String) async throws -> UserChallenge {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        let userChallenge = UserChallenge(
            id: UUID().uuidString,
            userId: "current-user",
            challengeId: challengeId,
            status: .active,
            progress: 0.0,
            completedAt: nil,
            joinedAt: Date(),
            user: User.mock,
            challenge: nil
        )
        
        mockUserChallenges[challengeId] = userChallenge
        
        return userChallenge
    }
    
    override func getUserChallengeStatus(_ challengeId: String) async throws -> UserChallengeStatus? {
        return mockUserChallenges[challengeId]?.status
    }
    
    override func getJoinedChallenges() async throws -> [Challenge] {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        // Return challenges that the user has joined
        return mockChallenges.compactMap { challenge in
            if mockUserChallenges[challenge.id] != nil {
                // Create challenge with user status
                return Challenge(
                    id: challenge.id,
                    name: challenge.name,
                    description: challenge.description,
                    type: challenge.type,
                    difficulty: challenge.difficulty,
                    duration: challenge.duration,
                    targetValue: challenge.targetValue,
                    unit: challenge.unit,
                    startDate: challenge.startDate,
                    endDate: challenge.endDate,
                    createdBy: challenge.createdBy,
                    creator: challenge.creator,
                    participantCount: challenge.participantCount,
                    isActive: challenge.isActive,
                    createdAt: challenge.createdAt,
                    updatedAt: challenge.updatedAt
                )
            }
            return nil
        }
    }
}
#endif