import Foundation

// MARK: - Challenge Model

/// Represents a challenge that users can participate in
struct Challenge: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let type: ChallengeType
    let difficulty: ChallengeDifficulty
    let duration: Int // Duration in days
    let targetValue: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    let createdBy: String
    let creator: User?
    let participantCount: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// Returns true if the challenge is currently active
    var isCurrentlyActive: Bool {
        let now = Date()
        return isActive && startDate <= now && endDate > now
    }
    
    /// Returns the number of days remaining in the challenge
    var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        
        if endDate < now {
            return 0
        }
        
        return calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
    }
    
    /// Returns true if the challenge has ended
    var hasEnded: Bool {
        return endDate < Date()
    }
    
    /// Returns true if the challenge hasn't started yet
    var hasNotStarted: Bool {
        return startDate > Date()
    }
}

// MARK: - Challenge Type

/// Types of challenges available
enum ChallengeType: String, CaseIterable, Codable {
    case fitness = "fitness"
    case nutrition = "nutrition"
    case wellness = "wellness"
    case social = "social"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .fitness:
            return "Fitness"
        case .nutrition:
            return "Nutrition"
        case .wellness:
            return "Wellness"
        case .social:
            return "Social"
        case .custom:
            return "Custom"
        }
    }
    
    var iconName: String {
        switch self {
        case .fitness:
            return "figure.run"
        case .nutrition:
            return "leaf.fill"
        case .wellness:
            return "heart.fill"
        case .social:
            return "person.2.fill"
        case .custom:
            return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .fitness:
            return "blue"
        case .nutrition:
            return "green"
        case .wellness:
            return "purple"
        case .social:
            return "orange"
        case .custom:
            return "gray"
        }
    }
}

// MARK: - Challenge Difficulty

/// Difficulty levels for challenges
enum ChallengeDifficulty: String, CaseIterable, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy:
            return "Easy"
        case .medium:
            return "Medium"
        case .hard:
            return "Hard"
        }
    }
    
    var color: String {
        switch self {
        case .easy:
            return "green"
        case .medium:
            return "orange"
        case .hard:
            return "red"
        }
    }
}

// MARK: - User Challenge Model

/// Represents a user's participation in a challenge
struct UserChallenge: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let challengeId: String
    let status: UserChallengeStatus
    let progress: Double // Progress percentage (0-100)
    let completedAt: Date?
    let joinedAt: Date
    let user: User
    let challenge: Challenge?
    
    // MARK: - Computed Properties
    
    /// Returns true if the challenge is completed
    var isCompleted: Bool {
        return status == .completed
    }
    
    /// Returns true if the challenge is active
    var isActive: Bool {
        return status == .active
    }
    
    /// Returns the progress as a percentage string
    var progressPercentage: String {
        return String(format: "%.0f%%", progress)
    }
}

// MARK: - User Challenge Status

/// Status of a user's participation in a challenge
enum UserChallengeStatus: String, CaseIterable, Codable {
    case active = "active"
    case completed = "completed"
    case paused = "paused"
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        case .paused:
            return "Paused"
        }
    }
    
    var color: String {
        switch self {
        case .active:
            return "blue"
        case .completed:
            return "green"
        case .paused:
            return "orange"
        }
    }
}

// MARK: - Challenge User Status (for simplified Challenge model)

/// User's status for a challenge (used in simplified Challenge model)
enum ChallengeUserStatus: String, CaseIterable, Codable {
    case inProgress = "inProgress"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        }
    }
}

// MARK: - Challenge Creation Data

/// Data structure for creating new challenges
struct ChallengeCreationData: Codable {
    let name: String
    let description: String
    let type: ChallengeType
    let difficulty: ChallengeDifficulty
    let duration: Int
    let targetValue: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    
    /// Returns true if the data is valid for creation
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedName.isEmpty &&
               trimmedName.count >= 3 &&
               trimmedName.count <= 100 &&
               !trimmedDescription.isEmpty &&
               trimmedDescription.count <= 500 &&
               targetValue > 0 &&
               duration > 0 &&
               endDate > startDate &&
               startDate >= Calendar.current.startOfDay(for: Date())
    }
}

// MARK: - Challenge Statistics

/// Statistics for a challenge
struct ChallengeStats: Codable {
    let challengeId: String
    let totalParticipants: Int
    let activeParticipants: Int
    let completedParticipants: Int
    let averageProgress: Double
    let completionRate: Double
    
    // MARK: - Computed Properties
    
    /// Returns the completion rate as a percentage string
    var completionRatePercentage: String {
        return String(format: "%.1f%%", completionRate * 100)
    }
    
    /// Returns the average progress as a percentage string
    var averageProgressPercentage: String {
        return String(format: "%.1f%%", averageProgress)
    }
}

// MARK: - Challenge Progress Update

/// Data structure for updating challenge progress
struct ChallengeProgressUpdate: Codable {
    let challengeId: String
    let progress: Double
    let notes: String?
    let timestamp: Date
    
    init(challengeId: String, progress: Double, notes: String? = nil) {
        self.challengeId = challengeId
        self.progress = progress
        self.notes = notes
        self.timestamp = Date()
    }
}

// MARK: - Mock Data Extensions

#if DEBUG
extension Challenge {
    /// Mock challenge for testing and previews
    static let mock = Challenge(
        id: "mock-challenge-1",
        name: "30-Day Fitness Challenge",
        description: "Complete 30 days of consistent exercise to build a healthy habit and improve your overall fitness.",
        type: .fitness,
        difficulty: .medium,
        duration: 30,
        targetValue: 30,
        unit: "days",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
        createdBy: "admin",
        creator: User.mock,
        participantCount: 156,
        isActive: true,
        createdAt: Date().addingTimeInterval(-86400 * 7),
        updatedAt: Date().addingTimeInterval(-86400 * 7)
    )
    
    /// Mock challenge with different properties
    static let mockCompleted = Challenge(
        id: "mock-challenge-2",
        name: "Meditation Streak",
        description: "Practice mindfulness meditation for 10 minutes daily.",
        type: .wellness,
        difficulty: .easy,
        duration: 14,
        targetValue: 14,
        unit: "sessions",
        startDate: Date().addingTimeInterval(-86400 * 14),
        endDate: Date(),
        createdBy: "admin",
        creator: User.mock,
        participantCount: 234,
        isActive: true,
        createdAt: Date().addingTimeInterval(-86400 * 20),
        updatedAt: Date().addingTimeInterval(-86400 * 20)
    )
    
    /// Mock challenges array
    static let mockChallenges = [
        mock,
        mockCompleted,
        Challenge(
            id: "mock-challenge-3",
            name: "10K Steps Daily",
            description: "Walk 10,000 steps every day for better health.",
            type: .fitness,
            difficulty: .easy,
            duration: 21,
            targetValue: 10000,
            unit: "steps",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 21, to: Date())!,
            createdBy: "admin",
            creator: User.mock,
            participantCount: 89,
            isActive: true,
            createdAt: Date().addingTimeInterval(-86400 * 3),
            updatedAt: Date().addingTimeInterval(-86400 * 3)
        )
    ]
}

extension UserChallenge {
    /// Mock user challenge for testing and previews
    static let mock = UserChallenge(
        id: "mock-user-challenge-1",
        userId: "current-user",
        challengeId: "mock-challenge-1",
        status: .active,
        progress: 65.0,
        completedAt: nil,
        joinedAt: Date().addingTimeInterval(-86400 * 5),
        user: User.mock,
        challenge: Challenge.mock
    )
    
    /// Mock completed user challenge
    static let mockCompleted = UserChallenge(
        id: "mock-user-challenge-2",
        userId: "current-user",
        challengeId: "mock-challenge-2",
        status: .completed,
        progress: 100.0,
        completedAt: Date().addingTimeInterval(-86400 * 2),
        joinedAt: Date().addingTimeInterval(-86400 * 16),
        user: User.mock,
        challenge: Challenge.mockCompleted
    )
}

extension ChallengeCreationData {
    /// Mock challenge creation data for testing
    static let mock = ChallengeCreationData(
        name: "Test Challenge",
        description: "A test challenge for development",
        type: .fitness,
        difficulty: .medium,
        duration: 30,
        targetValue: 30,
        unit: "days",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!
    )
}
#endif