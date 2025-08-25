import Foundation
import CoreData
import Combine

@MainActor
class OfflineQueueService: ObservableObject {
    static let shared = OfflineQueueService()
    
    @Published var queuedActions: [OfflineAction] = []
    @Published var isSyncing = false
    
    private let coreDataStack = CoreDataStack.shared
    private let maxRetryCount = 3
    private let retryDelays: [TimeInterval] = [1, 5, 15] // seconds
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadQueuedActions()
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        NetworkMonitor.shared.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.processPendingActions()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Queue Management
    
    func queueAction(_ action: OfflineAction) {
        queuedActions.append(action)
        saveQueuedActions()
        
        // Try to process immediately if online
        if NetworkMonitor.shared.isConnected {
            Task {
                await processAction(action)
            }
        }
    }
    
    func removeAction(_ actionId: String) {
        queuedActions.removeAll { $0.id == actionId }
        saveQueuedActions()
    }
    
    private func updateAction(_ action: OfflineAction) {
        if let index = queuedActions.firstIndex(where: { $0.id == action.id }) {
            queuedActions[index] = action
            saveQueuedActions()
        }
    }
    
    // MARK: - Processing
    
    func processPendingActions() async {
        guard !isSyncing && NetworkMonitor.shared.isConnected else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let actionsToProcess = queuedActions.filter { !$0.isProcessing }
        
        for action in actionsToProcess {
            await processAction(action)
        }
    }
    
    private func processAction(_ action: OfflineAction) async {
        var updatedAction = action
        updatedAction.isProcessing = true
        updateAction(updatedAction)
        
        do {
            try await executeAction(action)
            removeAction(action.id)
        } catch {
            await handleActionFailure(action, error: error)
        }
    }
    
    private func executeAction(_ action: OfflineAction) async throws {
        switch action.type {
        case .createPost:
            let data = try JSONDecoder().decode(CreatePostActionData.self, from: action.data)
            try await PostService.shared.createPost(title: data.title, content: data.content)
            
        case .likePost:
            let data = try JSONDecoder().decode(LikePostActionData.self, from: action.data)
            if data.isLiked {
                try await LikeService.shared.likePost(data.postId)
            } else {
                try await LikeService.shared.unlikePost(data.postId)
            }
            
        case .createComment:
            let data = try JSONDecoder().decode(CreateCommentActionData.self, from: action.data)
            try await CommentService.shared.createComment(postId: data.postId, content: data.content)
            
        case .followUser:
            let data = try JSONDecoder().decode(FollowUserActionData.self, from: action.data)
            if data.isFollowing {
                try await FollowService.shared.followUser(data.userId)
            } else {
                try await FollowService.shared.unfollowUser(data.userId)
            }
            
        case .joinChallenge:
            let data = try JSONDecoder().decode(JoinChallengeActionData.self, from: action.data)
            if data.isJoining {
                try await ChallengeService.shared.joinChallenge(data.challengeId)
            } else {
                try await ChallengeService.shared.leaveChallenge(data.challengeId)
            }
            
        case .updateProfile:
            let data = try JSONDecoder().decode(UpdateProfileActionData.self, from: action.data)
            try await UserService.shared.updateProfile(name: data.name, bio: data.bio, avatarData: data.avatarData)
            
        default:
            throw AppError.validation(.unsupportedAction)
        }
    }
    
    private func handleActionFailure(_ action: OfflineAction, error: Error) async {
        var updatedAction = action
        updatedAction.isProcessing = false
        updatedAction.retryCount += 1
        updatedAction.lastRetryDate = Date()
        
        if updatedAction.retryCount >= maxRetryCount {
            // Remove action after max retries
            removeAction(action.id)
            print("Action \(action.type) failed after \(maxRetryCount) retries: \(error)")
        } else {
            updateAction(updatedAction)
            
            // Schedule retry
            let delay = retryDelays[min(updatedAction.retryCount - 1, retryDelays.count - 1)]
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            if NetworkMonitor.shared.isConnected {
                await processAction(updatedAction)
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveQueuedActions() {
        let context = coreDataStack.context
        
        // Clear existing actions
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CachedOfflineAction")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)
        
        // Save current actions
        for action in queuedActions {
            let cachedAction = CachedOfflineAction(context: context)
            cachedAction.id = action.id
            cachedAction.type = action.type.rawValue
            cachedAction.data = action.data
            cachedAction.timestamp = action.timestamp
            cachedAction.retryCount = Int32(action.retryCount)
            cachedAction.lastRetryDate = action.lastRetryDate
            cachedAction.isProcessing = action.isProcessing
        }
        
        coreDataStack.save()
    }
    
    private func loadQueuedActions() {
        let context = coreDataStack.context
        let fetchRequest: NSFetchRequest<CachedOfflineAction> = CachedOfflineAction.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CachedOfflineAction.timestamp, ascending: true)]
        
        do {
            let cachedActions = try context.fetch(fetchRequest)
            queuedActions = cachedActions.compactMap { cached in
                guard let id = cached.id,
                      let typeString = cached.type,
                      let type = OfflineActionType(rawValue: typeString),
                      let data = cached.data,
                      let timestamp = cached.timestamp else {
                    return nil
                }
                
                return OfflineAction(
                    id: id,
                    type: type,
                    data: data,
                    timestamp: timestamp,
                    retryCount: Int(cached.retryCount),
                    lastRetryDate: cached.lastRetryDate,
                    isProcessing: cached.isProcessing
                )
            }
        } catch {
            print("Failed to load queued actions: \(error)")
        }
    }
}

// Extension for OfflineAction with custom initializer
extension OfflineAction {
    init(id: String, type: OfflineActionType, data: Data, timestamp: Date, retryCount: Int, lastRetryDate: Date?, isProcessing: Bool) {
        self.id = id
        self.type = type
        self.data = data
        self.timestamp = timestamp
        self.retryCount = retryCount
        self.lastRetryDate = lastRetryDate
        self.isProcessing = isProcessing
    }
}