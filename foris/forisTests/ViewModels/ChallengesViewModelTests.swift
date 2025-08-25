import XCTest
import Combine
@testable import foris

/// Comprehensive unit tests for ChallengesViewModel
/// Tests challenge loading, joining, completion, and error handling
final class ChallengesViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    var viewModel: ChallengesViewModel!
    var mockChallengeService: MockChallengeService!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        mockChallengeService = MockChallengeService()
        viewModel = ChallengesViewModel(challengeService: mockChallengeService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        viewModel = nil
        mockChallengeService = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given/When - ViewModel is initialized in setup
        
        // Then
        XCTAssertTrue(viewModel.availableChallenges.isEmpty)
        XCTAssertTrue(viewModel.myChallenges.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showError)
        XCTAssertTrue(viewModel.isEmpty)
    }
    
    // MARK: - Challenge Loading Tests
    
    func testLoadChallengesSuccess() async {
        // Given
        let mockChallenges = Challenge.mockArray(count: 5)
        mockChallengeService.mockChallenges = mockChallenges
        
        let expectation = XCTestExpectation(description: "Challenges loaded")
        
        viewModel.$availableChallenges
            .dropFirst()
            .sink { challenges in
                if !challenges.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.loadChallenges()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.availableChallenges.count, 5)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertNotNil(viewModel.lastUpdateDate)
    }
    
    func testLoadChallengesFailure() async {
        // Given
        mockChallengeService.shouldFail = true
        
        let expectation = XCTestExpectation(description: "Error shown")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.loadChallenges()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.availableChallenges.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.error)
    }
    
    func testRefreshChallengesSuccess() async {
        // Given
        let initialChallenges = Challenge.mockArray(count: 3)
        let refreshedChallenges = Challenge.mockArray(count: 5)
        
        mockChallengeService.mockChallenges = initialChallenges
        await viewModel.loadChallenges()
        
        mockChallengeService.mockChallenges = refreshedChallenges
        
        let expectation = XCTestExpectation(description: "Challenges refreshed")
        
        viewModel.$availableChallenges
            .dropFirst()
            .sink { challenges in
                if challenges.count == 5 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.refreshChallenges()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.availableChallenges.count, 5)
        XCTAssertFalse(viewModel.isRefreshing)
    }
    
    // MARK: - Challenge Actions Tests
    
    func testJoinChallengeSuccess() async {
        // Given
        let challenge = Challenge.mock
        viewModel.availableChallenges = [challenge]
        mockChallengeService.shouldSucceedJoin = true
        
        let expectation = XCTestExpectation(description: "Challenge joined")
        
        viewModel.$myChallenges
            .dropFirst()
            .sink { myChallenges in
                if !myChallenges.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.joinChallenge(challenge.id)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.myChallenges.count, 1)
        XCTAssertEqual(viewModel.myChallenges.first?.id, challenge.id)
        XCTAssertEqual(viewModel.myChallenges.first?.userStatus, .inProgress)
    }
    
    func testJoinChallengeFailure() async {
        // Given
        let challenge = Challenge.mock
        viewModel.availableChallenges = [challenge]
        mockChallengeService.shouldFailJoin = true
        
        let expectation = XCTestExpectation(description: "Join error shown")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.joinChallenge(challenge.id)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.myChallenges.isEmpty)
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.error)
    }
    
    func testLeaveChallengeSuccess() async {
        // Given
        let challenge = Challenge(
            id: "challenge1",
            name: "Test Challenge",
            description: "Test",
            createdBy: "admin",
            endDate: Date().addingTimeInterval(86400),
            userStatus: .inProgress
        )
        viewModel.myChallenges = [challenge]
        mockChallengeService.shouldSucceedLeave = true
        
        let expectation = XCTestExpectation(description: "Challenge left")
        
        viewModel.$myChallenges
            .dropFirst()
            .sink { myChallenges in
                if myChallenges.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.leaveChallenge(challenge.id)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.myChallenges.isEmpty)
    }
    
    func testCompleteChallengeSuccess() async {
        // Given
        let challenge = Challenge(
            id: "challenge1",
            name: "Test Challenge",
            description: "Test",
            createdBy: "admin",
            endDate: Date().addingTimeInterval(86400),
            userStatus: .inProgress
        )
        viewModel.myChallenges = [challenge]
        mockChallengeService.shouldSucceedComplete = true
        
        let expectation = XCTestExpectation(description: "Challenge completed")
        
        viewModel.$myChallenges
            .dropFirst()
            .sink { myChallenges in
                if let updatedChallenge = myChallenges.first,
                   updatedChallenge.userStatus == .completed {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.completeChallenge(challenge.id)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.myChallenges.count, 1)
        XCTAssertEqual(viewModel.myChallenges.first?.userStatus, .completed)
    }
    
    // MARK: - Challenge Creation Tests
    
    func testCreateChallengeSuccess() async {
        // Given
        let newChallenge = Challenge(
            id: "new-challenge",
            name: "New Challenge",
            description: "New challenge description",
            createdBy: "user1",
            endDate: Date().addingTimeInterval(86400),
            userStatus: nil
        )
        mockChallengeService.mockCreatedChallenge = newChallenge
        
        let expectation = XCTestExpectation(description: "Challenge created")
        
        viewModel.$availableChallenges
            .dropFirst()
            .sink { challenges in
                if challenges.contains(where: { $0.id == newChallenge.id }) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.createChallenge(
            name: newChallenge.name,
            description: newChallenge.description,
            endDate: newChallenge.endDate
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.availableChallenges.contains(where: { $0.id == newChallenge.id }))
    }
    
    func testCreateChallengeValidationError() async {
        // Given
        mockChallengeService.shouldFailCreate = true
        
        let expectation = XCTestExpectation(description: "Validation error shown")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.createChallenge(
            name: "",
            description: "Description",
            endDate: Date().addingTimeInterval(86400)
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Filtering and Sorting Tests
    
    func testFilterChallengesByStatus() {
        // Given
        let challenges = [
            Challenge(id: "1", name: "Challenge 1", description: "Desc", createdBy: "admin", endDate: Date().addingTimeInterval(86400), userStatus: .inProgress),
            Challenge(id: "2", name: "Challenge 2", description: "Desc", createdBy: "admin", endDate: Date().addingTimeInterval(86400), userStatus: .completed),
            Challenge(id: "3", name: "Challenge 3", description: "Desc", createdBy: "admin", endDate: Date().addingTimeInterval(86400), userStatus: .failed),
            Challenge(id: "4", name: "Challenge 4", description: "Desc", createdBy: "admin", endDate: Date().addingTimeInterval(86400), userStatus: nil)
        ]
        viewModel.myChallenges = challenges
        
        // When/Then
        let inProgressChallenges = viewModel.challengesByStatus(.inProgress)
        XCTAssertEqual(inProgressChallenges.count, 1)
        XCTAssertEqual(inProgressChallenges.first?.id, "1")
        
        let completedChallenges = viewModel.challengesByStatus(.completed)
        XCTAssertEqual(completedChallenges.count, 1)
        XCTAssertEqual(completedChallenges.first?.id, "2")
        
        let failedChallenges = viewModel.challengesByStatus(.failed)
        XCTAssertEqual(failedChallenges.count, 1)
        XCTAssertEqual(failedChallenges.first?.id, "3")
    }
    
    func testSortChallengesByEndDate() {
        // Given
        let now = Date()
        let challenges = [
            Challenge(id: "1", name: "Challenge 1", description: "Desc", createdBy: "admin", endDate: now.addingTimeInterval(86400 * 3), userStatus: nil),
            Challenge(id: "2", name: "Challenge 2", description: "Desc", createdBy: "admin", endDate: now.addingTimeInterval(86400), userStatus: nil),
            Challenge(id: "3", name: "Challenge 3", description: "Desc", createdBy: "admin", endDate: now.addingTimeInterval(86400 * 2), userStatus: nil)
        ]
        viewModel.availableChallenges = challenges
        
        // When
        let sortedChallenges = viewModel.sortedChallengesByEndDate()
        
        // Then
        XCTAssertEqual(sortedChallenges.count, 3)
        XCTAssertEqual(sortedChallenges[0].id, "2") // Ends soonest
        XCTAssertEqual(sortedChallenges[1].id, "3")
        XCTAssertEqual(sortedChallenges[2].id, "1") // Ends latest
    }
    
    // MARK: - Challenge Status Tests
    
    func testChallengeStatusHelpers() {
        // Given
        let challenge = Challenge.mock
        
        // When/Then
        XCTAssertTrue(viewModel.canJoinChallenge(challenge))
        XCTAssertFalse(viewModel.isUserInChallenge(challenge.id))
        XCTAssertEqual(viewModel.challengeStatusText(for: challenge), "Available")
        
        // Add to my challenges
        let joinedChallenge = Challenge(
            id: challenge.id,
            name: challenge.name,
            description: challenge.description,
            createdBy: challenge.createdBy,
            endDate: challenge.endDate,
            userStatus: .inProgress
        )
        viewModel.myChallenges = [joinedChallenge]
        
        XCTAssertFalse(viewModel.canJoinChallenge(joinedChallenge))
        XCTAssertTrue(viewModel.isUserInChallenge(challenge.id))
        XCTAssertEqual(viewModel.challengeStatusText(for: joinedChallenge), "In Progress")
    }
    
    func testExpiredChallenges() {
        // Given
        let expiredChallenge = Challenge(
            id: "expired",
            name: "Expired Challenge",
            description: "This challenge has ended",
            createdBy: "admin",
            endDate: Date().addingTimeInterval(-86400), // Yesterday
            userStatus: nil
        )
        
        // When/Then
        XCTAssertFalse(viewModel.canJoinChallenge(expiredChallenge))
        XCTAssertTrue(viewModel.isChallengeExpired(expiredChallenge))
        XCTAssertEqual(viewModel.challengeStatusText(for: expiredChallenge), "Expired")
    }
    
    // MARK: - Error Handling Tests
    
    func testDismissError() {
        // Given
        viewModel.error = AppError.network(.serverError(500))
        viewModel.showError = true
        
        // When
        viewModel.dismissError()
        
        // Then
        XCTAssertFalse(viewModel.showError)
        XCTAssertNil(viewModel.error)
    }
    
    func testErrorBindingFromService() {
        // Given
        let expectation = XCTestExpectation(description: "Error bound from service")
        
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockChallengeService.error = AppError.network(.serverError(500))
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.showError)
    }
    
    // MARK: - State Consistency Tests
    
    func testIsEmptyConsistency() {
        // Given - No challenges, not loading
        viewModel.availableChallenges = []
        viewModel.myChallenges = []
        viewModel.isLoading = false
        
        // Then
        XCTAssertTrue(viewModel.isEmpty)
        
        // When - Has available challenges
        viewModel.availableChallenges = Challenge.mockArray(count: 1)
        
        // Then
        XCTAssertFalse(viewModel.isEmpty)
        
        // When - No available but has my challenges
        viewModel.availableChallenges = []
        viewModel.myChallenges = Challenge.mockArray(count: 1)
        
        // Then
        XCTAssertFalse(viewModel.isEmpty)
        
        // When - Empty but loading
        viewModel.myChallenges = []
        viewModel.isLoading = true
        
        // Then
        XCTAssertFalse(viewModel.isEmpty)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        // Given
        weak var weakViewModel: ChallengesViewModel?
        weak var weakService: MockChallengeService?
        
        autoreleasepool {
            let service = MockChallengeService()
            let testViewModel = ChallengesViewModel(challengeService: service)
            
            weakViewModel = testViewModel
            weakService = service
            
            // Use the view model
            Task {
                await testViewModel.loadChallenges()
            }
        }
        
        // When/Then - Objects should be deallocated
        XCTAssertNil(weakViewModel)
        XCTAssertNil(weakService)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentOperations() async {
        // Given
        let challenges = Challenge.mockArray(count: 5)
        mockChallengeService.mockChallenges = challenges
        
        // When - Multiple concurrent operations
        async let loadTask: Void = viewModel.loadChallenges()
        async let refreshTask: Void = viewModel.refreshChallenges()
        async let joinTask: Void = viewModel.joinChallenge("challenge1")
        
        // Then - Should handle gracefully without crashes
        await loadTask
        await refreshTask
        await joinTask
        
        // Should have some challenges loaded
        XCTAssertGreaterThan(viewModel.availableChallenges.count, 0)
    }
}

// MARK: - Mock Challenge Service

class MockChallengeService: ChallengeService {
    @Published var error: AppError?
    
    var mockChallenges: [Challenge] = []
    var mockCreatedChallenge: Challenge?
    var shouldFail = false
    var shouldFailJoin = false
    var shouldFailLeave = false
    var shouldFailComplete = false
    var shouldFailCreate = false
    var shouldSucceedJoin = true
    var shouldSucceedLeave = true
    var shouldSucceedComplete = true
    var mockDelay: TimeInterval = 0.1
    
    override func getChallenges() async throws -> [Challenge] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFail {
            throw AppError.network(.serverError(500))
        }
        
        return mockChallenges
    }
    
    override func joinChallenge(id: String) async throws -> Challenge {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFailJoin {
            throw AppError.network(.serverError(500))
        }
        
        guard let challenge = mockChallenges.first(where: { $0.id == id }) else {
            throw AppError.validation(.invalidInput("Challenge not found"))
        }
        
        return Challenge(
            id: challenge.id,
            name: challenge.name,
            description: challenge.description,
            createdBy: challenge.createdBy,
            endDate: challenge.endDate,
            userStatus: .inProgress
        )
    }
    
    override func leaveChallenge(id: String) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFailLeave {
            throw AppError.network(.serverError(500))
        }
        
        // Mock successful leave
    }
    
    override func completeChallenge(id: String) async throws -> Challenge {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFailComplete {
            throw AppError.network(.serverError(500))
        }
        
        guard let challenge = mockChallenges.first(where: { $0.id == id }) else {
            throw AppError.validation(.invalidInput("Challenge not found"))
        }
        
        return Challenge(
            id: challenge.id,
            name: challenge.name,
            description: challenge.description,
            createdBy: challenge.createdBy,
            endDate: challenge.endDate,
            userStatus: .completed
        )
    }
    
    override func createChallenge(name: String, description: String?, endDate: Date?) async throws -> Challenge {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldFailCreate {
            throw AppError.validation(.invalidInput("Name is required"))
        }
        
        return mockCreatedChallenge ?? Challenge(
            id: UUID().uuidString,
            name: name,
            description: description,
            createdBy: "user1",
            endDate: endDate,
            userStatus: nil
        )
    }
    
    func clearError() {
        error = nil
    }
}

// MARK: - Challenge Extensions

extension Challenge {
    static var mock: Challenge {
        Challenge(
            id: "mock-challenge",
            name: "Mock Challenge",
            description: "This is a mock challenge for testing",
            createdBy: "admin",
            endDate: Date().addingTimeInterval(86400),
            userStatus: nil
        )
    }
    
    static func mockArray(count: Int) -> [Challenge] {
        return (0..<count).map { index in
            Challenge(
                id: "challenge\(index)",
                name: "Challenge \(index + 1)",
                description: "Description for challenge \(index + 1)",
                createdBy: "admin",
                endDate: Date().addingTimeInterval(Double(index + 1) * 86400),
                userStatus: nil
            )
        }
    }
}