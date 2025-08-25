import Foundation
import CoreData

/// Core Data stack for the Foris app
/// Provides persistent storage with background context support
final class CoreDataStack {
    
    // MARK: - Singleton
    
    static let shared = CoreDataStack()
    
    // MARK: - Properties
    
    /// Main context for UI operations (main queue)
    lazy var mainContext: NSManagedObjectContext = {
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    /// Background context for data operations
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ForisDataModel")
        
        // Configure persistent store
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.shouldInferMappingModelAutomatically = true
        storeDescription?.shouldMigrateStoreAutomatically = true
        
        // Enable persistent history tracking
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
            
            self?.setupContexts()
        }
        
        return container
    }()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Setup
    
    private func setupContexts() {
        // Configure main context
        mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Configure background context
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Save Operations
    
    /// Saves the main context
    /// - Throws: Core Data save error
    func saveMainContext() throws {
        guard mainContext.hasChanges else { return }
        
        try mainContext.save()
    }
    
    /// Saves the background context
    /// - Throws: Core Data save error
    func saveBackgroundContext() throws {
        guard backgroundContext.hasChanges else { return }
        
        try backgroundContext.save()
    }
    
    /// Performs a save operation on the main context
    /// - Parameter block: Block to execute before saving
    /// - Throws: Core Data save error
    func performSave(on context: NSManagedObjectContext = CoreDataStack.shared.mainContext, _ block: @escaping () throws -> Void) throws {
        var saveError: Error?
        
        context.performAndWait {
            do {
                try block()
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                saveError = error
            }
        }
        
        if let error = saveError {
            throw error
        }
    }
    
    /// Performs a background save operation
    /// - Parameter block: Block to execute on background context
    /// - Returns: Async operation
    func performBackgroundSave(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    try block(self.backgroundContext)
                    if self.backgroundContext.hasChanges {
                        try self.backgroundContext.save()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Fetch Operations
    
    /// Performs a fetch request on the main context
    /// - Parameter request: Fetch request to execute
    /// - Returns: Array of fetched objects
    /// - Throws: Core Data fetch error
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
        return try mainContext.fetch(request)
    }
    
    /// Performs a fetch request on the background context
    /// - Parameter request: Fetch request to execute
    /// - Returns: Array of fetched objects
    /// - Throws: Core Data fetch error
    func fetchInBackground<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let results = try self.backgroundContext.fetch(request)
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Counts objects matching the fetch request
    /// - Parameter request: Fetch request to count
    /// - Returns: Number of matching objects
    /// - Throws: Core Data count error
    func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> Int {
        return try mainContext.count(for: request)
    }
    
    // MARK: - Delete Operations
    
    /// Deletes an object from the main context
    /// - Parameter object: Object to delete
    func delete(_ object: NSManagedObject) {
        mainContext.delete(object)
    }
    
    /// Deletes objects matching the fetch request
    /// - Parameter request: Fetch request for objects to delete
    /// - Throws: Core Data error
    func deleteObjects<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws {
        let objects = try fetch(request)
        objects.forEach { mainContext.delete($0) }
    }
    
    /// Batch delete objects matching the fetch request
    /// - Parameter request: Fetch request for objects to delete
    /// - Throws: Core Data error
    func batchDelete<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try mainContext.execute(deleteRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
        
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [mainContext])
    }
    
    // MARK: - Cache Management
    
    /// Clears all cached data
    /// - Throws: Core Data error
    func clearAllData() throws {
        let entityNames = [
            "CachedUser", "CachedPost", "CachedComment", "CachedLike",
            "CachedChallenge", "CachedUserChallenge", "CachedLeague",
            "CachedLeagueUser", "CachedUserFollow"
        ]
        
        for entityName in entityNames {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            try batchDelete(request as! NSFetchRequest<NSManagedObject>)
        }
        
        try saveMainContext()
    }
    
    /// Gets the size of the persistent store in bytes
    /// - Returns: Store size in bytes
    func getStoreSize() -> Int64 {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            return 0
        }
        
        do {
            let resources = try storeURL.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resources.fileSize ?? 0)
        } catch {
            return 0
        }
    }
    
    /// Checks if the store is getting full (over 100MB)
    /// - Returns: True if store is large
    var isStoreLarge: Bool {
        return getStoreSize() > 100 * 1024 * 1024 // 100MB
    }
}

// MARK: - Convenience Extensions

extension CoreDataStack {
    /// Creates a new managed object of the specified type
    /// - Parameter type: Type of object to create
    /// - Returns: New managed object
    func create<T: NSManagedObject>(_ type: T.Type) -> T {
        return T(context: mainContext)
    }
    
    /// Creates a new managed object in background context
    /// - Parameter type: Type of object to create
    /// - Returns: New managed object
    func createInBackground<T: NSManagedObject>(_ type: T.Type) -> T {
        return T(context: backgroundContext)
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
/// Mock Core Data stack for testing
class MockCoreDataStack: CoreDataStack {
    override init() {
        super.init()
        setupInMemoryStore()
    }
    
    private func setupInMemoryStore() {
        let container = NSPersistentContainer(name: "ForisDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Mock Core Data error: \(error)")
            }
        }
        
        // Replace the persistent container
        self.persistentContainer = container
    }
    
    /// Populates the mock store with test data
    func populateWithMockData() {
        // Create mock users
        let user1 = create(CachedUser.self)
        user1.id = "user1"
        user1.name = "John Doe"
        user1.email = "john@example.com"
        user1.lastUpdated = Date()
        
        let user2 = create(CachedUser.self)
        user2.id = "user2"
        user2.name = "Jane Smith"
        user2.email = "jane@example.com"
        user2.lastUpdated = Date()
        
        // Create mock posts
        let post1 = create(CachedPost.self)
        post1.id = "post1"
        post1.title = "My First Workout"
        post1.content = "Had a great workout today!"
        post1.authorId = "user1"
        post1.author = user1
        post1.createdAt = Date()
        post1.lastUpdated = Date()
        
        try? saveMainContext()
    }
}
#endif