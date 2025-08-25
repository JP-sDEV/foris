import Foundation
import Combine

/// ViewModel for managing leagues and league-related operations
/// Handles league discovery, joining, creation, and management
@MainActor
final class LeaguesViewModel: ObservableObject {
    // MARK: - Properties
    private let leagueService: LeagueService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var allLeagues: [League] = []
    @Published var userLeagues: [LeagueMember] = []
    @Published var selectedLeague: League?
    @Published var leagueMembers: [LeagueMember] = []
    @Published var leagueChallenges: [LeagueChallenge] = []
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var searchText = ""
    @Published var selectedLeagueType: LeagueType?
    @Published var selectedPrivacy: LeaguePrivacy?
    
    // MARK: - Computed Properties
    /// Filtered leagues based on search text and filters
    var filteredLeagues: [League] {
        var leagues = allLeagues
        
        // Apply search filter
        if !searchText.isEmpty {
            leagues = leagues.filter { league in
                league.name.localizedCaseInsensitiveContains(searchText) ||
                league.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply type filter
        if let selectedType = selectedLeagueType {
            leagues = leagues.filter { $0.type == selectedType }
        }
        
        // Apply privacy filter
        if let selectedPrivacy = selectedPrivacy {
            leagues = leagues.filter { $0.privacy == selectedPrivacy }
        }
        
        return leagues
    }
    
    /// Returns true if the user has joined any leagues
    var hasJoinedLeagues: Bool {
        !userLeagues.isEmpty
    }
    
    /// Returns the number of leagues the user has joined
    var joinedLeaguesCount: Int {
        userLeagues.count
    }
    
    // MARK: - Initialization
    init(leagueService: LeagueService = LeagueService.shared) {
        self.leagueService = leagueService
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind to service loading state
        leagueService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        // Bind to service error state
        leagueService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - League Operations
    /// Loads all available leagues
    /// - Parameters:
    ///   - refresh: Whether to force refresh from server
    ///   - limit: Maximum number of leagues to load
    ///   - offset: Number of leagues to skip
    func loadLeagues(refresh: Bool = false, limit: Int = 20, offset: Int = 0) async {
        do {
            let leagues = try await leagueService.getLeagues(limit: limit, offset: offset)
            if offset == 0 {
                allLeagues = leagues
            } else {
                allLeagues.append(contentsOf: leagues)
            }
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
        }
    }
    
    /// Loads leagues the user has joined
    /// - Parameters:
    ///   - refresh: Whether to force refresh from server
    ///   - limit: Maximum number of leagues to load
    ///   - offset: Number of leagues to skip
    func loadUserLeagues(refresh: Bool = false, limit: Int = 20, offset: Int = 0) async {
        do {
            let leagues = try await leagueService.getUserLeagues(limit: limit, offset: offset)
            if offset == 0 {
                userLeagues = leagues
            } else {
                userLeagues.append(contentsOf: leagues)
            }
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
        }
    }
    
    /// Loads a specific league by ID
    /// - Parameter leagueId: League ID to load
    func loadLeague(id leagueId: String) async {
        do {
            let league = try await leagueService.getLeague(id: leagueId)
            selectedLeague = league
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
        }
    }
    
    /// Creates a new league
    /// - Parameter leagueData: League creation data
    /// - Returns: Created league
    func createLeague(_ leagueData: LeagueCreationData) async -> League? {
        do {
            let league = try await leagueService.createLeague(leagueData)
            // Add to user leagues
            if let leagueMember = try? await leagueService.getUserLeagues().first(where: { $0.leagueId == league.id }) {
                userLeagues.insert(leagueMember, at: 0)
            }
            // Add to all leagues
            allLeagues.insert(league, at: 0)
            return league
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            return nil
        }
    }
    
    /// Joins a league
    /// - Parameter leagueId: League ID to join
    /// - Returns: True if successfully joined
    func joinLeague(leagueId: String) async -> Bool {
        do {
            let leagueMember = try await leagueService.joinLeague(leagueId: leagueId)
            userLeagues.insert(leagueMember, at: 0)
            
            // Update the league's member count in allLeagues
            if let index = allLeagues.firstIndex(where: { $0.id == leagueId }) {
                var updatedLeague = allLeagues[index]
                updatedLeague = League(
                    id: updatedLeague.id,
                    name: updatedLeague.name,
                    description: updatedLeague.description,
                    type: updatedLeague.type,
                    privacy: updatedLeague.privacy,
                    maxMembers: updatedLeague.maxMembers,
                    createdBy: updatedLeague.createdBy,
                    creator: updatedLeague.creator,
                    memberCount: updatedLeague.memberCount + 1,
                    challengeCount: updatedLeague.challengeCount,
                    isActive: updatedLeague.isActive,
                    createdAt: updatedLeague.createdAt,
                    updatedAt: updatedLeague.updatedAt
                )
                allLeagues[index] = updatedLeague
            }
            
            return true
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            return false
        }
    }
    
    /// Leaves a league
    /// - Parameter leagueId: League ID to leave
    /// - Returns: True if successfully left
    func leaveLeague(leagueId: String) async -> Bool {
        do {
            try await leagueService.leaveLeague(leagueId: leagueId)
            userLeagues.removeAll { $0.leagueId == leagueId }
            
            // Update the league's member count in allLeagues
            if let index = allLeagues.firstIndex(where: { $0.id == leagueId }) {
                var updatedLeague = allLeagues[index]
                updatedLeague = League(
                    id: updatedLeague.id,
                    name: updatedLeague.name,
                    description: updatedLeague.description,
                    type: updatedLeague.type,
                    privacy: updatedLeague.privacy,
                    maxMembers: updatedLeague.maxMembers,
                    createdBy: updatedLeague.createdBy,
                    creator: updatedLeague.creator,
                    memberCount: max(0, updatedLeague.memberCount - 1),
                    challengeCount: updatedLeague.challengeCount,
                    isActive: updatedLeague.isActive,
                    createdAt: updatedLeague.createdAt,
                    updatedAt: updatedLeague.updatedAt
                )
                allLeagues[index] = updatedLeague
            }
            
            return true
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            return false
        }
    }
    
    /// Checks if the user is a member of a specific league
    /// - Parameter leagueId: League ID to check
    /// - Returns: True if user is a member
    func isUserMember(of leagueId: String) -> Bool {
        userLeagues.contains { $0.leagueId == leagueId }
    }
    
    /// Gets the user's role in a specific league
    /// - Parameter leagueId: League ID
    /// - Returns: User's role in the league, nil if not a member
    func getUserRole(in leagueId: String) -> LeagueMemberRole? {
        userLeagues.first { $0.leagueId == leagueId }?.role
    }
    
    // MARK: - League Member Operations
    /// Loads members for a specific league
    /// - Parameter leagueId: League ID
    func loadLeagueMembers(leagueId: String) async {
        do {
            let members = try await leagueService.getLeagueMembers(leagueId: leagueId)
            leagueMembers = members
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - League Challenge Operations
    /// Loads challenges for a specific league
    /// - Parameter leagueId: League ID
    func loadLeagueChallenges(leagueId: String) async {
        do {
            let challenges = try await leagueService.getLeagueChallenges(leagueId: leagueId)
            leagueChallenges = challenges
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
        }
    }
    
    /// Creates a new league challenge
    /// - Parameter challengeData: League challenge creation data
    /// - Returns: Created league challenge
    func createLeagueChallenge(_ challengeData: LeagueChallengeCreationData) async -> LeagueChallenge? {
        do {
            let leagueChallenge = try await leagueService.createLeagueChallenge(challengeData)
            leagueChallenges.insert(leagueChallenge, at: 0)
            return leagueChallenge
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            return nil
        }
    }
    
    /// Joins a league challenge
    /// - Parameter leagueChallengeId: League challenge ID to join
    /// - Returns: True if successfully joined
    func joinLeagueChallenge(leagueChallengeId: String) async -> Bool {
        do {
            _ = try await leagueService.joinLeagueChallenge(leagueChallengeId: leagueChallengeId)
            
            // Update the challenge's participant count
            if let index = leagueChallenges.firstIndex(where: { $0.id == leagueChallengeId }) {
                var updatedChallenge = leagueChallenges[index]
                updatedChallenge = LeagueChallenge(
                    id: updatedChallenge.id,
                    leagueId: updatedChallenge.leagueId,
                    challengeId: updatedChallenge.challengeId,
                    name: updatedChallenge.name,
                    description: updatedChallenge.description,
                    type: updatedChallenge.type,
                    difficulty: updatedChallenge.difficulty,
                    duration: updatedChallenge.duration,
                    targetValue: updatedChallenge.targetValue,
                    unit: updatedChallenge.unit,
                    startDate: updatedChallenge.startDate,
                    endDate: updatedChallenge.endDate,
                    createdBy: updatedChallenge.createdBy,
                    creator: updatedChallenge.creator,
                    participantCount: updatedChallenge.participantCount + 1,
                    isActive: updatedChallenge.isActive,
                    createdAt: updatedChallenge.createdAt,
                    updatedAt: updatedChallenge.updatedAt,
                    league: updatedChallenge.league
                )
                leagueChallenges[index] = updatedChallenge
            }
            
            return true
        } catch {
            self.error = error as? AppError ?? AppError.unknown(error.localizedDescription)
            return false
        }
    }
    
    // MARK: - Filter Operations
    /// Clears all filters
    func clearFilters() {
        searchText = ""
        selectedLeagueType = nil
        selectedPrivacy = nil
    }
    
    /// Sets the league type filter
    /// - Parameter type: League type to filter by, nil to clear filter
    func setLeagueTypeFilter(_ type: LeagueType?) {
        selectedLeagueType = type
    }
    
    /// Sets the privacy filter
    /// - Parameter privacy: Privacy level to filter by, nil to clear filter
    func setPrivacyFilter(_ privacy: LeaguePrivacy?) {
        selectedPrivacy = privacy
    }
    
    // MARK: - Error Handling
    /// Clears the current error
    func clearError() {
        error = nil
        leagueService.clearError()
    }
    
    // MARK: - Refresh Operations
    /// Refreshes all data
    func refreshAll() async {
        await loadLeagues(refresh: true)
        await loadUserLeagues(refresh: true)
    }
    
    /// Refreshes leagues data
    func refreshLeagues() async {
        await loadLeagues(refresh: true)
    }
    
    /// Refreshes user leagues data
    func refreshUserLeagues() async {
        await loadUserLeagues(refresh: true)
    }
}

// MARK: - Mock Implementation for Testing
#if DEBUG
class MockLeaguesViewModel: LeaguesViewModel {
    override init() {
        super.init(leagueService: MockLeagueService())
        generateMockData()
    }
    
    private func generateMockData() {
        allLeagues = League.mockLeagues
        userLeagues = [LeagueMember.mock, LeagueMember.mockAdmin]
        leagueChallenges = [LeagueChallenge.mock]
    }
    
    override func loadLeagues(refresh: Bool = false, limit: Int = 20, offset: Int = 0) async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        if offset == 0 {
            allLeagues = League.mockLeagues
        }
        isLoading = false
    }
    
    override func loadUserLeagues(refresh: Bool = false, limit: Int = 20, offset: Int = 0) async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        if offset == 0 {
            userLeagues = [LeagueMember.mock, LeagueMember.mockAdmin]
        }
        isLoading = false
    }
    
    override func joinLeague(leagueId: String) async -> Bool {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        if let league = allLeagues.first(where: { $0.id == leagueId }) {
            let newMember = LeagueMember(
                id: UUID().uuidString,
                userId: "current-user",
                leagueId: leagueId,
                role: .member,
                joinedAt: Date(),
                user: User.mock,
                league: league
            )
            userLeagues.insert(newMember, at: 0)
        }
        
        isLoading = false
        return true
    }
    
    override func leaveLeague(leagueId: String) async -> Bool {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        userLeagues.removeAll { $0.leagueId == leagueId }
        isLoading = false
        return true
    }
}
#endif