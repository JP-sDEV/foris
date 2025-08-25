import Foundation

// MARK: - League Model

/// Represents a league that users can join to compete in challenges together
struct League: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let createdBy: String
    let creator: User?
    let memberCount: Int
    let maxMembers: Int?
    let isPublic: Bool
    let joinCode: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// Returns true if the league is full
    var isFull: Bool {
        guard let maxMembers = maxMembers else { return false }
        return memberCount >= maxMembers
    }
    
    /// Returns true if the league can accept new members
    var canJoin: Bool {
        return isActive && !isFull
    }
    
    /// Returns the membership status as a string
    var membershipStatus: String {
        if isFull {
            return "Full (\(memberCount)/\(maxMembers ?? 0))"
        } else if let maxMembers = maxMembers {
            return "\(memberCount)/\(maxMembers) members"
        } else {
            return "\(memberCount) members"
        }
    }
}

// MARK: - League User Model

/// Represents a user's membership in a league
struct LeagueUser: Identifiable, Codable, Equatable {
    let id: String
    let leagueId: String
    let userId: String
    let role: LeagueRole
    let joinedAt: Date
    let isActive: Bool
    let user: User?
    let league: League?
    
    // MARK: - Computed Properties
    
    /// Returns true if the user is an admin of the league
    var isAdmin: Bool {
        return role == .admin
    }
    
    /// Returns true if the user is a moderator or admin
    var canModerate: Bool {
        return role == .admin || role == .moderator
    }
}

// MARK: - League Role

/// Roles that users can have in a league
enum LeagueRole: String, CaseIterable, Codable {
    case member = "member"
    case moderator = "moderator"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .member:
            return "Member"
        case .moderator:
            return "Moderator"
        case .admin:
            return "Admin"
        }
    }
    
    var priority: Int {
        switch self {
        case .member:
            return 0
        case .moderator:
            return 1
        case .admin:
            return 2
        }
    }
}

// MARK: - League Challenge Model

/// Represents a challenge that is specific to a league
struct LeagueChallenge: Identifiable, Codable, Equatable {
    let id: String
    let leagueId: String
    let challengeId: String
    let createdBy: String
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let participantCount: Int
    let createdAt: Date
    let updatedAt: Date
    let league: League?
    let challenge: Challenge?
    
    // MARK: - Computed Properties
    
    /// Returns true if the league challenge is currently active
    var isCurrentlyActive: Bool {
        let now = Date()
        return isActive && startDate <= now && endDate > now
    }
    
    /// Returns the number of days remaining in the league challenge
    var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        
        if endDate < now {
            return 0
        }
        
        return calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
    }
    
    /// Returns true if the league challenge has ended
    var hasEnded: Bool {
        return endDate < Date()
    }
}

// MARK: - League Creation Data

/// Data structure for creating new leagues
struct LeagueCreationData: Codable {
    let name: String
    let description: String
    let maxMembers: Int?
    let isPublic: Bool
    
    /// Returns true if the data is valid for creation
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedName.isEmpty &&
               trimmedName.count >= 3 &&
               trimmedName.count <= 50 &&
               !trimmedDescription.isEmpty &&
               trimmedDescription.count <= 200 &&
               (maxMembers == nil || maxMembers! >= 2)
    }
}

// MARK: - League Join Data

/// Data structure for joining leagues
struct LeagueJoinData: Codable {
    let leagueId: String?
    let joinCode: String?
    
    /// Returns true if the data is valid for joining
    var isValid: Bool {
        return leagueId != nil || (joinCode != nil && !joinCode!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}

// MARK: - League Statistics

/// Statistics for a league
struct LeagueStats: Codable {
    let leagueId: String
    let totalMembers: Int
    let activeMembers: Int
    let totalChallenges: Int
    let activeChallenges: Int
    let completedChallenges: Int
    let averageParticipation: Double
    
    // MARK: - Computed Properties
    
    /// Returns the participation rate as a percentage string
    var participationRatePercentage: String {
        return String(format: "%.1f%%", averageParticipation * 100)
    }
    
    /// Returns the challenge completion rate
    var challengeCompletionRate: Double {
        guard totalChallenges > 0 else { return 0 }
        return Double(completedChallenges) / Double(totalChallenges)
    }
    
    /// Returns the completion rate as a percentage string
    var completionRatePercentage: String {
        return String(format: "%.1f%%", challengeCompletionRate * 100)
    }
}

// MARK: - League Leaderboard Entry

/// Represents a user's position in a league leaderboard
struct LeagueLeaderboardEntry: Identifiable, Codable, Equatable {
    let id: String
    let leagueId: String
    let userId: String
    let rank: Int
    let score: Double
    let challengesCompleted: Int
    let challengesParticipated: Int
    let user: User?
    
    // MARK: - Computed Properties
    
    /// Returns the completion rate for this user
    var completionRate: Double {
        guard challengesParticipated > 0 else { return 0 }
        return Double(challengesCompleted) / Double(challengesParticipated)
    }
    
    /// Returns the completion rate as a percentage string
    var completionRatePercentage: String {
        return String(format: "%.1f%%", completionRate * 100)
    }
    
    /// Returns a formatted rank string
    var rankString: String {
        switch rank {
        case 1:
            return "1st"
        case 2:
            return "2nd"
        case 3:
            return "3rd"
        default:
            return "\(rank)th"
        }
    }
}

// MARK: - Mock Data Extensions

#if DEBUG
extension League {
    /// Mock league for testing and previews
    static let mock = League(
        id: "mock-league-1",
        name: "Fitness Warriors",
        description: "A league for dedicated fitness enthusiasts who want to push their limits together.",
        createdBy: "admin",
        creator: User.mock,
        memberCount: 24,
        maxMembers: 50,
        isPublic: true,
        joinCode: "FW2024",
        isActive: true,
        createdAt: Date().addingTimeInterval(-86400 * 30),
        updatedAt: Date().addingTimeInterval(-86400 * 7)
    )
    
    /// Mock private league
    static let mockPrivate = League(
        id: "mock-league-2",
        name: "Office Champions",
        description: "Private league for our office team to stay healthy and motivated.",
        createdBy: "admin",
        creator: User.mock,
        memberCount: 8,
        maxMembers: 15,
        isPublic: false,
        joinCode: "OFFICE2024",
        isActive: true,
        createdAt: Date().addingTimeInterval(-86400 * 14),
        updatedAt: Date().addingTimeInterval(-86400 * 2)
    )
    
    /// Mock leagues array
    static let mockLeagues = [
        mock,
        mockPrivate,
        League(
            id: "mock-league-3",
            name: "Wellness Circle",
            description: "Focus on mental and physical wellness through mindful challenges.",
            createdBy: "admin",
            creator: User.mock,
            memberCount: 156,
            maxMembers: nil,
            isPublic: true,
            joinCode: nil,
            isActive: true,
            createdAt: Date().addingTimeInterval(-86400 * 60),
            updatedAt: Date().addingTimeInterval(-86400 * 1)
        )
    ]
}

extension LeagueUser {
    /// Mock league user for testing and previews
    static let mock = LeagueUser(
        id: "mock-league-user-1",
        leagueId: "mock-league-1",
        userId: "current-user",
        role: .member,
        joinedAt: Date().addingTimeInterval(-86400 * 14),
        isActive: true,
        user: User.mock,
        league: League.mock
    )
    
    /// Mock admin league user
    static let mockAdmin = LeagueUser(
        id: "mock-league-user-2",
        leagueId: "mock-league-1",
        userId: "admin-user",
        role: .admin,
        joinedAt: Date().addingTimeInterval(-86400 * 30),
        isActive: true,
        user: User.mock,
        league: League.mock
    )
}

extension LeagueChallenge {
    /// Mock league challenge for testing and previews
    static let mock = LeagueChallenge(
        id: "mock-league-challenge-1",
        leagueId: "mock-league-1",
        challengeId: "mock-challenge-1",
        createdBy: "admin",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
        isActive: true,
        participantCount: 18,
        createdAt: Date().addingTimeInterval(-86400 * 2),
        updatedAt: Date().addingTimeInterval(-86400 * 2),
        league: League.mock,
        challenge: Challenge.mock
    )
}

extension LeagueCreationData {
    /// Mock league creation data for testing
    static let mock = LeagueCreationData(
        name: "Test League",
        description: "A test league for development",
        maxMembers: 25,
        isPublic: true
    )
}

extension LeagueLeaderboardEntry {
    /// Mock leaderboard entries for testing
    static let mockEntries = [
        LeagueLeaderboardEntry(
            id: "mock-entry-1",
            leagueId: "mock-league-1",
            userId: "user-1",
            rank: 1,
            score: 950.0,
            challengesCompleted: 8,
            challengesParticipated: 10,
            user: User.mock
        ),
        LeagueLeaderboardEntry(
            id: "mock-entry-2",
            leagueId: "mock-league-1",
            userId: "user-2",
            rank: 2,
            score: 875.0,
            challengesCompleted: 7,
            challengesParticipated: 9,
            user: User.mockWithAvatar
        ),
        LeagueLeaderboardEntry(
            id: "mock-entry-3",
            leagueId: "mock-league-1",
            userId: "user-3",
            rank: 3,
            score: 820.0,
            challengesCompleted: 6,
            challengesParticipated: 8,
            user: User(id: "user-3", name: "Alex Johnson", email: "alex@example.com", bio: "Fitness enthusiast", avatarUrl: nil)
        )
    ]
}
#endif