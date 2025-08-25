import Foundation
import Combine

/// Service for managing leagues and league membership
/// Handles league creation, joining, management, and league challenges
@MainActor
final class LeagueService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LeagueService()
    
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
    
    // MARK: - League Operations
    
    /// Gets all available public leagues
    /// - Parameters:
    ///   - limit: Maximum number of leagues to return
    ///   - offset: Number of leagues to skip
    /// - Returns: Array of leagues
    /// - Throws: AppError if operation fails
    func getPublicLeagues(limit: Int = 20, offset: Int = 0) async throws -> [League] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let cachedLeagues = try cacheService.getAllCachedLeagues()
            let publicLeagues = cachedLeagues.filter { $0.isPublic }
            
            if !publicLeagues.isEmpty {
                return Array(publicLeagues.dropFirst(offset).prefix(limit))
            }
            
            // TODO: Implement GraphQL leagues query
            // For now, return mock leagues
            let mockLeagues = generateMockLeagues().filter { $0.isPublic }
            
            // Cache the leagues
            for league in mockLeagues {
                try cacheService.cacheLeague(league)
            }
            
            return Array(mockLeagues.dropFirst(offset).prefix(limit))
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets leagues that the current user has joined
    /// - Returns: Array of joined leagues
    /// - Throws: AppError if operation fails
    func getJoinedLeagues() async throws -> [League] {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let leagueUsers = try cacheService.getCachedLeagueUsers(for: currentUser.id)
            
            var joinedLeagues: [League] = []
            for leagueUser in leagueUsers {
                if let league = try? cacheService.getCachedLeague(id: leagueUser.leagueId) {
                    joinedLeagues.append(league)
                }
            }
            
            if !joinedLeagues.isEmpty {
                return joinedLeagues
            }
            
            // TODO: Implement GraphQL userLeagues query
            // For now, return mock joined leagues
            return generateMockJoinedLeagues()
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets a specific league by ID
    /// - Parameter leagueId: League ID
    /// - Returns: League if found
    /// - Throws: AppError if operation fails
    func getLeague(id leagueId: String) async throws -> League {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            if let cachedLeague = try cacheService.getCachedLeague(id: leagueId) {
                return cachedLeague
            }
            
            // TODO: Implement GraphQL league query
            // For now, return mock league
            let mockLeagues = generateMockLeagues()
            if let league = mockLeagues.first(where: { $0.id == leagueId }) {
                try cacheService.cacheLeague(league)
                return league
            }
            
            throw AppError.notFound("League not found")
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Creates a new league
    /// - Parameter leagueData: League creation data
    /// - Returns: Created league
    /// - Throws: AppError if operation fails
    func createLeague(_ leagueData: LeagueCreationData) async throws -> League {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate input
            try validateLeagueData(leagueData)
            
            // TODO: Implement GraphQL createLeague mutation
            // For now, create mock league
            let league = League(
                id: UUID().uuidString,
                name: leagueData.name,
                description: leagueData.description,
                createdBy: currentUser.id,
                creator: currentUser,
                memberCount: 1,
                maxMembers: leagueData.maxMembers,
                isPublic: leagueData.isPublic,
                joinCode: leagueData.isPublic ? nil : generateJoinCode(),
                isActive: true,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Cache the league
            try cacheService.cacheLeague(league)
            
            // Auto-join the creator as admin
            let leagueUser = LeagueUser(
                id: UUID().uuidString,
                leagueId: league.id,
                userId: currentUser.id,
                role: .admin,
                joinedAt: Date(),
                isActive: true,
                user: currentUser,
                league: league
            )
            
            try cacheService.cacheLeagueUser(leagueUser)
            
            return league
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Joins a league
    /// - Parameter joinData: League join data (ID or join code)
    /// - Returns: LeagueUser representing the membership
    /// - Throws: AppError if operation fails
    func joinLeague(_ joinData: LeagueJoinData) async throws -> LeagueUser {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Validate input
            guard joinData.isValid else {
                throw AppError.validation(.invalid("Invalid join data"))
            }
            
            // Find the league
            var league: League?
            
            if let leagueId = joinData.leagueId {
                league = try await getLeague(id: leagueId)
            } else if let joinCode = joinData.joinCode {
                league = try findLeagueByJoinCode(joinCode)
            }
            
            guard let targetLeague = league else {
                throw AppError.notFound("League not found")
            }
            
            // Check if league can be joined
            guard targetLeague.canJoin else {
                if targetLeague.isFull {
                    throw AppError.validation(.invalid("League is full"))
                } else {
                    throw AppError.validation(.invalid("League is not accepting new members"))
                }
            }
            
            // Check if already joined
            let isAlreadyJoined = try await isUserInLeague(leagueId: targetLeague.id)
            if isAlreadyJoined {
                throw AppError.validation(.invalid("Already joined this league"))
            }
            
            // TODO: Implement GraphQL joinLeague mutation
            // For now, simulate the operation
            try await Task.sleep(nanoseconds: 300_000_000)
            
            let leagueUser = LeagueUser(
                id: UUID().uuidString,
                leagueId: targetLeague.id,
                userId: currentUser.id,
                role: .member,
                joinedAt: Date(),
                isActive: true,
                user: currentUser,
                league: targetLeague
            )
            
            // Cache the league user
            try cacheService.cacheLeagueUser(leagueUser)
            
            return leagueUser
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Leaves a league
    /// - Parameter leagueId: League ID to leave
    /// - Throws: AppError if operation fails
    func leaveLeague(leagueId: String) async throws {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check if user is in the league
            guard let leagueUser = try cacheService.getCachedLeagueUser(userId: currentUser.id, leagueId: leagueId) else {
                throw AppError.validation(.invalid("Not a member of this league"))
            }
            
            // Check if user is the only admin
            if leagueUser.role == .admin {
                let allMembers = try cacheService.getCachedLeagueUsers(for: leagueId)
                let adminCount = allMembers.filter { $0.role == .admin }.count
                
                if adminCount <= 1 && allMembers.count > 1 {
                    throw AppError.validation(.invalid("Cannot leave league as the only admin. Transfer admin role first."))
                }
            }
            
            // TODO: Implement GraphQL leaveLeague mutation
            // For now, simulate the operation
            try await Task.sleep(nanoseconds: 300_000_000)
            
            // Remove from cache
            try cacheService.removeLeagueUser(userId: currentUser.id, leagueId: leagueId)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets members of a league
    /// - Parameter leagueId: League ID
    /// - Returns: Array of league members
    /// - Throws: AppError if operation fails
    func getLeagueMembers(leagueId: String) async throws -> [LeagueUser] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let members = try cacheService.getCachedLeagueUsers(for: leagueId)
            
            if !members.isEmpty {
                return members.sorted { $0.role.priority > $1.role.priority }
            }
            
            // TODO: Implement GraphQL leagueMembers query
            // For now, return mock members
            return generateMockLeagueMembers(leagueId: leagueId)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets league challenges
    /// - Parameter leagueId: League ID
    /// - Returns: Array of league challenges
    /// - Throws: AppError if operation fails
    func getLeagueChallenges(leagueId: String) async throws -> [LeagueChallenge] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try cache first
            let challenges = try cacheService.getCachedLeagueChallenges(for: leagueId)
            
            if !challenges.isEmpty {
                return challenges.sorted { $0.createdAt > $1.createdAt }
            }
            
            // TODO: Implement GraphQL leagueChallenges query
            // For now, return mock challenges
            return generateMockLeagueChallenges(leagueId: leagueId)
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Creates a league-specific challenge
    /// - Parameters:
    ///   - leagueId: League ID
    ///   - challengeId: Challenge ID to add to the league
    /// - Returns: Created league challenge
    /// - Throws: AppError if operation fails
    func createLeagueChallenge(leagueId: String, challengeId: String) async throws -> LeagueChallenge {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check if user can create challenges in this league
            guard let leagueUser = try cacheService.getCachedLeagueUser(userId: currentUser.id, leagueId: leagueId) else {
                throw AppError.validation(.invalid("Not a member of this league"))
            }
            
            guard leagueUser.canModerate else {
                throw AppError.validation(.invalid("Only admins and moderators can create league challenges"))
            }
            
            // TODO: Implement GraphQL createLeagueChallenge mutation
            // For now, create mock league challenge
            let leagueChallenge = LeagueChallenge(
                id: UUID().uuidString,
                leagueId: leagueId,
                challengeId: challengeId,
                createdBy: currentUser.id,
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
                isActive: true,
                participantCount: 0,
                createdAt: Date(),
                updatedAt: Date(),
                league: nil,
                challenge: nil
            )
            
            // Cache the league challenge
            try cacheService.cacheLeagueChallenge(leagueChallenge)
            
            return leagueChallenge
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    /// Gets league leaderboard
    /// - Parameter leagueId: League ID
    /// - Returns: Array of leaderboard entries
    /// - Throws: AppError if operation fails
    func getLeagueLeaderboard(leagueId: String) async throws -> [LeagueLeaderboardEntry] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement GraphQL leagueLeaderboard query
            // For now, return mock leaderboard
            return LeagueLeaderboardEntry.mockEntries
            
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            throw self.error!
        }
    }
    
    // MARK: - Helper Methods
    
    /// Checks if user is in a league
    /// - Parameter leagueId: League ID
    /// - Returns: True if user is in the league
    /// - Throws: AppError if operation fails
    private func isUserInLeague(leagueId: String) async throws -> Bool {
        guard let currentUser = authService.currentUser else {
            return false
        }
        
        do {
            let leagueUser = try cacheService.getCachedLeagueUser(userId: currentUser.id, leagueId: leagueId)
            return leagueUser != nil && leagueUser!.isActive
        } catch {
            return false
        }
    }
    
    /// Finds a league by join code
    /// - Parameter joinCode: Join code to search for
    /// - Returns: League if found
    /// - Throws: AppError if not found
    private func findLeagueByJoinCode(_ joinCode: String) throws -> League {
        let allLeagues = try cacheService.getAllCachedLeagues()
        
        if let league = allLeagues.first(where: { $0.joinCode == joinCode }) {
            return league
        }
        
        // If not in cache, check mock data
        let mockLeagues = generateMockLeagues()
        if let league = mockLeagues.first(where: { $0.joinCode == joinCode }) {
            return league
        }
        
        throw AppError.notFound("Invalid join code")
    }
    
    /// Generates a random join code
    /// - Returns: Random join code string
    private func generateJoinCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    // MARK: - Validation
    
    private func validateLeagueData(_ data: LeagueCreationData) throws {
        guard data.isValid else {
            if data.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw AppError.validation(.required("League name"))
            } else if data.name.count < 3 {
                throw AppError.validation(.tooShort("League name", 3))
            } else if data.name.count > 50 {
                throw AppError.validation(.tooLong("League name", 50))
            } else if data.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw AppError.validation(.required("League description"))
            } else if data.description.count > 200 {
                throw AppError.validation(.tooLong("League description", 200))
            } else if let maxMembers = data.maxMembers, maxMembers < 2 {
                throw AppError.validation(.invalid("Maximum members must be at least 2"))
            }
            
            throw AppError.validation(.invalid("Invalid league data"))
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockLeagues() -> [League] {
        return League.mockLeagues
    }
    
    private func generateMockJoinedLeagues() -> [League] {
        return [League.mock, League.mockPrivate]
    }
    
    private func generateMockLeagueMembers(leagueId: String) -> [LeagueUser] {
        return [
            LeagueUser.mockAdmin,
            LeagueUser.mock,
            LeagueUser(
                id: "mock-league-user-3",
                leagueId: leagueId,
                userId: "user-3",
                role: .moderator,
                joinedAt: Date().addingTimeInterval(-86400 * 20),
                isActive: true,
                user: User(id: "user-3", name: "Alex Johnson", email: "alex@example.com", bio: "Fitness enthusiast", avatarUrl: nil),
                league: nil
            )
        ]
    }
    
    private func generateMockLeagueChallenges(leagueId: String) -> [LeagueChallenge] {
        return [LeagueChallenge.mock]
    }
    
    // MARK: - Sync Methods
    
    /// Gets all leagues (for sync service)
    /// - Returns: Array of all leagues
    /// - Throws: AppError if operation fails
    func getAllLeagues() async throws -> [League] {
        // TODO: Implement GraphQL query to get all leagues
        return try await getLeagues(limit: 1000, offset: 0)
    }
    
    /// Gets user leagues (for sync service)
    /// - Returns: Array of user league memberships
    /// - Throws: AppError if operation fails
    func getUserLeagues() async throws -> [LeagueUser] {
        guard let currentUser = authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        // TODO: Implement GraphQL query to get user leagues
        return try cacheService.getCachedLeagueUsers(for: currentUser.id)
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        error = nil
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockLeagueService: LeagueService {
    var shouldFailOperations = false
    var operationDelay: TimeInterval = 0.5
    var mockLeagues: [League] = []
    var mockLeagueUsers: [String: [LeagueUser]] = [:] // leagueId -> [LeagueUser]
    
    override init() {
        super.init()
        generateMockData()
    }
    
    private func generateMockData() {
        mockLeagues = League.mockLeagues
        
        // Add some mock league users
        mockLeagueUsers["mock-league-1"] = [
            LeagueUser.mockAdmin,
            LeagueUser.mock
        ]
    }
    
    override func getPublicLeagues(limit: Int = 20, offset: Int = 0) async throws -> [League] {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        let publicLeagues = mockLeagues.filter { $0.isPublic }
        return Array(publicLeagues.dropFirst(offset).prefix(limit))
    }
    
    override func getJoinedLeagues() async throws -> [League] {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        // Return leagues that the user has joined
        return mockLeagues.filter { league in
            mockLeagueUsers[league.id]?.contains { $0.userId == "current-user" } ?? false
        }
    }
    
    override func joinLeague(_ joinData: LeagueJoinData) async throws -> LeagueUser {
        isLoading = true
        defer { isLoading = false }
        
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if shouldFailOperations {
            throw AppError.network(.serverError(500))
        }
        
        guard let leagueId = joinData.leagueId else {
            throw AppError.validation(.invalid("League ID required"))
        }
        
        let leagueUser = LeagueUser(
            id: UUID().uuidString,
            leagueId: leagueId,
            userId: "current-user",
            role: .member,
            joinedAt: Date(),
            isActive: true,
            user: User.mock,
            league: nil
        )
        
        // Add to mock data
        if mockLeagueUsers[leagueId] == nil {
            mockLeagueUsers[leagueId] = []
        }
        mockLeagueUsers[leagueId]?.append(leagueUser)
        
        return leagueUser
    }
}
#endif