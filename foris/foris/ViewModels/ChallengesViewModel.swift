import Foundation
import Combine

/// ViewModel for managing challenges and user participation
/// Handles challenge loading, filtering, and user interactions
@MainActor
final class ChallengesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var allChallenges: [Challenge] = []
    @Published var joinedChallenges: [Challenge] = []
    @Published var isLoading = false
    @Published var isLoadingJoined = false
    @Published var error: AppError?
    @Published var showError = false
    @Published var selectedTab: ChallengeTab = .available
    
    // MARK: - Private Properties
    
    private let challengeService: ChallengeService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var displayedChallenges: [Challenge] {
        switch selectedTab {
        case .available:
            return allChallenges
        case .joined:
            return joinedChallenges
        }
    }
    
    var isEmpty: Bool {
        return displayedChallenges.isEmpty && !isLoading && !isLoadingJoined
    }
    
    var emptyStateTitle: String {
        switch selectedTab {
        case .available:
            return "No Challenges Available"
        case .joined:
            return "No Joined Challenges"
        }
    }
    
    var emptyStateMessage: String {
        switch selectedTab {
        case .available:
            return "Check back later for new challenges to join"
        case .joined:
            return "Join some challenges to see them here"
        }
    }
    
    // MARK: - Initialization
    
    init(challengeService: ChallengeService = ChallengeService.shared) {
        self.challengeService = challengeService
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind challenge service errors
        challengeService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Challenge Loading
    
    /// Loads all available challenges
    func loadChallenges() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            let challenges = try await challengeService.getChallenges()
            allChallenges = challenges
            
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
        
        isLoading = false
    }
    
    /// Loads challenges that the user has joined
    func loadJoinedChallenges() async {
        guard !isLoadingJoined else { return }
        
        isLoadingJoined = true
        
        do {
            let challenges = try await challengeService.getJoinedChallenges()
            joinedChallenges = challenges
            
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
        
        isLoadingJoined = false
    }
    
    /// Refreshes challenges based on selected tab
    func refreshChallenges() async {
        switch selectedTab {
        case .available:
            await loadChallenges()
        case .joined:
            await loadJoinedChallenges()
        }
    }
    
    /// Loads challenges if needed (called when view appears)
    func loadChallengesIfNeeded() async {
        if allChallenges.isEmpty {
            await loadChallenges()
        }
        
        if joinedChallenges.isEmpty {
            await loadJoinedChallenges()
        }
    }
    
    // MARK: - Challenge Actions
    
    /// Handles joining a challenge
    /// - Parameter challenge: Challenge to join
    func joinChallenge(_ challenge: Challenge) async {
        do {
            _ = try await challengeService.joinChallenge(challenge.id)
            
            // Update local state - just use the existing challenge since userStatus is not part of the Challenge model anymore
            let updatedChallenge = challenge
            
            // Add to joined challenges if not already there
            if !joinedChallenges.contains(where: { $0.id == challenge.id }) {
                joinedChallenges.append(updatedChallenge)
            }
            
            // Update in all challenges
            if let index = allChallenges.firstIndex(where: { $0.id == challenge.id }) {
                allChallenges[index] = updatedChallenge
            }
            
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    /// Handles leaving a challenge
    /// - Parameter challenge: Challenge to leave
    func leaveChallenge(_ challenge: Challenge) async {
        do {
            try await challengeService.leaveChallenge(challenge.id)
            
            // Remove from joined challenges
            joinedChallenges.removeAll { $0.id == challenge.id }
            
            // Update in all challenges - just keep the existing challenge
            // The userStatus concept is now handled through UserChallenge relationships
            
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    /// Handles completing a challenge
    /// - Parameter challenge: Challenge to complete
    func completeChallenge(_ challenge: Challenge) async {
        do {
            _ = try await challengeService.completeChallenge(challenge.id)
            
            // Update local state - just use the existing challenge
            let updatedChallenge = challenge
            
            // Update in joined challenges
            if let index = joinedChallenges.firstIndex(where: { $0.id == challenge.id }) {
                joinedChallenges[index] = updatedChallenge
            }
            
            // Update in all challenges
            if let index = allChallenges.firstIndex(where: { $0.id == challenge.id }) {
                allChallenges[index] = updatedChallenge
            }
            
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    /// Creates a new challenge
    /// - Parameter challengeData: Challenge creation data
    func createChallenge(_ challengeData: ChallengeCreationData) async {
        do {
            let newChallenge = try await challengeService.createChallenge(challengeData)
            
            // Add to all challenges
            allChallenges.insert(newChallenge, at: 0)
            
        } catch {
            showError(error as? AppError ?? AppError.unknown(error.localizedDescription))
        }
    }
    
    // MARK: - Tab Management
    
    /// Changes the selected tab
    /// - Parameter tab: Tab to select
    func selectTab(_ tab: ChallengeTab) {
        selectedTab = tab
        
        // Load data for the selected tab if needed
        Task {
            switch tab {
            case .available:
                if allChallenges.isEmpty {
                    await loadChallenges()
                }
            case .joined:
                if joinedChallenges.isEmpty {
                    await loadJoinedChallenges()
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(_ error: AppError) {
        self.error = error
        showError = true
    }
    
    /// Dismisses the current error
    func dismissError() {
        showError = false
        error = nil
        challengeService.clearError()
    }
    
    // MARK: - Utility Methods
    
    /// Gets a challenge by ID
    /// - Parameter id: Challenge ID
    /// - Returns: Challenge if found
    func getChallenge(id: String) -> Challenge? {
        return allChallenges.first { $0.id == id } ?? joinedChallenges.first { $0.id == id }
    }
    
    /// Checks if a challenge is joined
    /// - Parameter challengeId: Challenge ID
    /// - Returns: True if joined
    func isChallengeJoined(_ challengeId: String) -> Bool {
        return joinedChallenges.contains { $0.id == challengeId }
    }
}

// MARK: - Challenge Tab Enum

enum ChallengeTab: String, CaseIterable {
    case available = "available"
    case joined = "joined"
    
    var title: String {
        switch self {
        case .available:
            return "Available"
        case .joined:
            return "Joined"
        }
    }
    
    var iconName: String {
        switch self {
        case .available:
            return "target"
        case .joined:
            return "checkmark.circle"
        }
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
extension ChallengesViewModel {
    /// Creates a mock ChallengesViewModel for testing and previews
    /// - Parameters:
    ///   - challenges: Challenges to display
    ///   - isLoading: Whether to show loading state
    ///   - isEmpty: Whether to show empty state
    /// - Returns: Configured mock ChallengesViewModel
    static func mock(
        challenges: [Challenge] = [],
        isLoading: Bool = false,
        isEmpty: Bool = false
    ) -> ChallengesViewModel {
        let mockService = MockChallengeService()
        let viewModel = ChallengesViewModel(challengeService: mockService)
        
        if isEmpty {
            viewModel.allChallenges = []
            viewModel.joinedChallenges = []
        } else if challenges.isEmpty {
            // Generate mock challenges using the mock data from the model
            viewModel.allChallenges = Challenge.mockChallenges
            
            // For joined challenges, just use a subset for demo purposes
            viewModel.joinedChallenges = Array(Challenge.mockChallenges.prefix(2))
        } else {
            viewModel.allChallenges = challenges
            viewModel.joinedChallenges = Array(challenges.prefix(challenges.count / 2)) // Just use half for demo
        }
        
        viewModel.isLoading = isLoading
        
        return viewModel
    }
    
    /// Creates a mock ChallengesViewModel in loading state
    /// - Returns: Configured mock ChallengesViewModel
    static func mockLoading() -> ChallengesViewModel {
        return mock(isLoading: true)
    }
    
    /// Creates a mock ChallengesViewModel in empty state
    /// - Returns: Configured mock ChallengesViewModel
    static func mockEmpty() -> ChallengesViewModel {
        return mock(isEmpty: true)
    }
    
    /// Creates a mock ChallengesViewModel with error state
    /// - Parameter error: Error to display
    /// - Returns: Configured mock ChallengesViewModel
    static func mockError(_ error: AppError = AppError.network(.serverError(500))) -> ChallengesViewModel {
        let viewModel = mock()
        viewModel.error = error
        viewModel.showError = true
        return viewModel
    }
}
#endif