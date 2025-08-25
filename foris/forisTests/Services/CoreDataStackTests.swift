import XCTest
import CoreData
@testable import foris

/// Comprehensive unit tests for CoreDataStack
/// Tests Core Data setup, persistence, and data operations
final class CoreDataStackTests: XCTestCase {
    
    // MARK: - Properties
    
    var coreDataStack: CoreDataStack!
    var testContext: NSManagedObjectContext!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        // Create in-memory Core Data stack for testing
        coreDataStack = CoreDataStack(inMemory: true)
        testContext = coreDataStack.viewContext
    }
    
    override func tearDownWithError() throws {
        testContext = nil
        coreDataStack = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given/When - Stack is initialized in setup
        
        // Then
        XCTAssertNotNil(coreDataStack)
        XCTAssertNotNil(coreDataStack.persistentContainer)
        XCTAssertNotNil(coreDataStack.viewContext)
        XCTAssertNotNil(coreDataStack.backgroundContext)
    }
    
    func testInMemoryInitialization() {
        // Given
        let inMemoryStack = CoreDataStack(inMemory: true)
        
        // When
        let container = inMemoryStack.persistentContainer
        
        // Then
        XCTAssertEqual(container.persistentStoreDescriptions.first?.type, NSInMemoryStoreType)
    }
    
    func testPersistentInitialization() {
        // Given
        let persistentStack = CoreDataStack(inMemory: false)
        
        // When
        let container = persistentStack.persistentContainer
        
        // Then
        XCTAssertEqual(container.persistentStoreDescriptions.first?.type, NSSQLiteStoreType)
    }
    
    // MARK: - Context Tests
    
    func testViewContextConfiguration() {
        // Given
        let context = coreDataStack.viewContext
        
        // Then
        XCTAssertEqual(context.concurrencyType, .mainQueueConcurrencyType)
        XCTAssertTrue(context.automaticallyMergesChangesFromParent)
    }
    
    func testBackgroundContextConfiguration() {
        // Given
        let context = coreDataStack.backgroundContext
        
        // Then
        XCTAssertEqual(context.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertEqual(context.parent, coreDataStack.viewContext)
    }
    
    func testNewBackgroundContext() {
        // When
        let context1 = coreDataStack.newBackgroundContext()
        let context2 = coreDataStack.newBackgroundContext()
        
        // Then
        XCTAssertNotEqual(context1, context2)
        XCTAssertEqual(context1.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertEqual(context2.concurrencyType, .privateQueueConcurrencyType)
    }
    
    // MARK: - Save Operations Tests
    
    func testSaveViewContext() throws {
        // Given
        let user = createTestUser(in: testContext)
        
        // When
        try coreDataStack.save()
        
        // Then
        XCTAssertFalse(testContext.hasChanges)
        
        // Verify the user was saved
        let fetchRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        let users = try testContext.fetch(fetchRequest)
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.name, user.name)
    }
    
    func testSaveBackgroundContext() throws {
        // Given
        let backgroundContext = coreDataStack.backgroundContext
        var testUser: CachedUser!
        
        backgroundContext.performAndWait {
            testUser = createTestUser(in: backgroundContext)
        }
        
        // When
        try coreDataStack.save(context: backgroundContext)
        
        // Then
        backgroundContext.performAndWait {
            XCTAssertFalse(backgroundContext.hasChanges)
        }
        
        // Verify the user was saved to the view context
        let fetchRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        let users = try testContext.fetch(fetchRequest)
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.name, testUser.name)
    }
    
    func testSaveWithNoChanges() throws {
        // Given - No changes made
        
        // When/Then - Should not throw
        XCTAssertNoThrow(try coreDataStack.save())
    }
    
    func testSaveFailure() {
        // Given - Create invalid data that will fail validation
        let user = CachedUser(context: testContext)
        // Don't set required fields to trigger validation error
        
        // When/Then
        XCTAssertThrowsError(try coreDataStack.save()) { error in
            XCTAssertTrue(error is NSError)
        }
    }
    
    // MARK: - Batch Operations Tests
    
    func testBatchInsert() throws {
        // Given
        let userDictionaries = [
            ["id": "1", "name": "User 1", "email": "user1@test.com"],
            ["id": "2", "name": "User 2", "email": "user2@test.com"],
            ["id": "3", "name": "User 3", "email": "user3@test.com"]
        ]
        
        // When
        try coreDataStack.batchInsert(entityName: "CachedUser", objects: userDictionaries)
        
        // Then
        let fetchRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        let users = try testContext.fetch(fetchRequest)
        XCTAssertEqual(users.count, 3)
        
        let names = users.map { $0.name }.sorted()
        XCTAssertEqual(names, ["User 1", "User 2", "User 3"])
    }
    
    func testBatchUpdate() throws {
        // Given - Create test users
        for i in 1...3 {
            let user = createTestUser(in: testContext, id: "user\(i)", name: "User \(i)")
        }
        try coreDataStack.save()
        
        // When - Update all users' bio
        let updateRequest = NSBatchUpdateRequest(entityName: "CachedUser")
        updateRequest.propertiesToUpdate = ["bio": "Updated bio"]
        updateRequest.resultType = .updatedObjectsCountResultType
        
        let result = try testContext.execute(updateRequest) as! NSBatchUpdateResult
        
        // Then
        XCTAssertEqual(result.result as! Int, 3)
        
        // Refresh context to see changes
        testContext.refreshAllObjects()
        
        let fetchRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        let users = try testContext.fetch(fetchRequest)
        XCTAssertTrue(users.allSatisfy { $0.bio == "Updated bio" })
    }
    
    func testBatchDelete() throws {
        // Given - Create test users
        for i in 1...5 {
            createTestUser(in: testContext, id: "user\(i)", name: "User \(i)")
        }
        try coreDataStack.save()
        
        // When - Delete users with specific criteria
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: CachedUser.fetchRequest())
        deleteRequest.resultType = .resultTypeCount
        
        let result = try testContext.execute(deleteRequest) as! NSBatchDeleteResult
        
        // Then
        XCTAssertEqual(result.result as! Int, 5)
        
        // Verify deletion
        let fetchRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        let users = try testContext.fetch(fetchRequest)
        XCTAssertEqual(users.count, 0)
    }
    
    // MARK: - Data Migration Tests
    
    func testDataModelVersioning() {
        // Given
        let container = coreDataStack.persistentContainer
        
        // When
        let model = container.managedObjectModel
        
        // Then
        XCTAssertNotNil(model)
        XCTAssertGreaterThan(model.entities.count, 0)
        
        // Verify expected entities exist
        let entityNames = model.entities.map { $0.name! }.sorted()
        let expectedEntities = ["CachedUser", "CachedPost", "CachedChallenge", "CachedLeague"]
        
        for expectedEntity in expectedEntities {
            XCTAssertTrue(entityNames.contains(expectedEntity), "Missing entity: \(expectedEntity)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testBulkInsertPerformance() throws {
        // Given
        let userCount = 1000
        let userDictionaries = (0..<userCount).map { index in
            [
                "id": "user\(index)",
                "name": "User \(index)",
                "email": "user\(index)@test.com",
                "bio": "Bio for user \(index)"
            ]
        }
        
        // When/Then
        measure {
            do {
                try coreDataStack.batchInsert(entityName: "CachedUser", objects: userDictionaries)
            } catch {
                XCTFail("Batch insert failed: \(error)")
            }
        }
        
        // Verify all users were inserted
        let fetchRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        let users = try testContext.fetch(fetchRequest)
        XCTAssertEqual(users.count, userCount)
    }
    
    func testFetchPerformance() throws {
        // Given - Insert test data
        let userCount = 1000
        for i in 0..<userCount {
            createTestUser(in: testContext, id: "user\(i)", name: "User \(i)")
        }
        try coreDataStack.save()
        
        // When/Then
        measure {
            let fetchRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
            fetchRequest.fetchLimit = 100
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            do {
                let users = try testContext.fetch(fetchRequest)
                XCTAssertEqual(users.count, 100)
            } catch {
                XCTFail("Fetch failed: \(error)")
            }
        }
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentSaves() async throws {
        // Given
        let context1 = coreDataStack.newBackgroundContext()
        let context2 = coreDataStack.newBackgroundContext()
        
        // When - Perform concurrent saves
        async let save1: Void = performBackgroundSave(context: context1, userPrefix: "Context1")
        async let save2: Void = performBackgroundSave(context: context2, userPrefix: "Context2")
        
        // Then
        try await save1
        try await save2
        
        // Verify all users were saved
        let fetchRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        let users = try testContext.fetch(fetchRequest)
        XCTAssertEqual(users.count, 20) // 10 from each context
        
        let context1Users = users.filter { $0.name?.hasPrefix("Context1") == true }
        let context2Users = users.filter { $0.name?.hasPrefix("Context2") == true }
        
        XCTAssertEqual(context1Users.count, 10)
        XCTAssertEqual(context2Users.count, 10)
    }
    
    private func performBackgroundSave(context: NSManagedObjectContext, userPrefix: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Create test users
                    for i in 0..<10 {
                        let user = CachedUser(context: context)
                        user.id = "\(userPrefix)_user\(i)"
                        user.name = "\(userPrefix) User \(i)"
                        user.email = "\(userPrefix.lowercased())user\(i)@test.com"
                        user.lastUpdated = Date()
                    }
                    
                    // Save context
                    try self.coreDataStack.save(context: context)
                    continuation.resume()
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        // Given
        weak var weakStack: CoreDataStack?
        weak var weakContext: NSManagedObjectContext?
        
        autoreleasepool {
            let testStack = CoreDataStack(inMemory: true)
            let testContext = testStack.viewContext
            
            weakStack = testStack
            weakContext = testContext
            
            // Use the stack
            let user = CachedUser(context: testContext)
            user.id = "test"
            user.name = "Test User"
            user.email = "test@example.com"
            user.lastUpdated = Date()
            
            try? testStack.save()
        }
        
        // When/Then - Objects should be deallocated
        XCTAssertNil(weakStack)
        XCTAssertNil(weakContext)
    }
    
    // MARK: - Error Handling Tests
    
    func testSaveErrorHandling() {
        // Given - Create invalid entity
        let user = CachedUser(context: testContext)
        // Missing required fields will cause validation error
        
        // When/Then
        XCTAssertThrowsError(try coreDataStack.save()) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, NSCocoaErrorDomain)
        }
    }
    
    func testFetchErrorHandling() {
        // Given - Invalid fetch request
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "NonExistentEntity")
        
        // When/Then
        XCTAssertThrowsError(try testContext.fetch(fetchRequest)) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, NSCocoaErrorDomain)
        }
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistencyAcrossContexts() throws {
        // Given - Create user in background context
        let backgroundContext = coreDataStack.backgroundContext
        var userId: String!
        
        backgroundContext.performAndWait {
            let user = createTestUser(in: backgroundContext)
            userId = user.id
        }
        
        try coreDataStack.save(context: backgroundContext)
        
        // When - Fetch from view context
        let fetchRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", userId)
        
        let users = try testContext.fetch(fetchRequest)
        
        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.id, userId)
    }
    
    func testRelationshipConsistency() throws {
        // Given - Create user and posts
        let user = createTestUser(in: testContext)
        let post1 = createTestPost(in: testContext, authorId: user.id!)
        let post2 = createTestPost(in: testContext, authorId: user.id!)
        
        try coreDataStack.save()
        
        // When - Fetch user with posts
        let fetchRequest: NSFetchRequest<CachedUser> = CachedUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", user.id!)
        fetchRequest.relationshipKeyPathsForPrefetching = ["posts"]
        
        let users = try testContext.fetch(fetchRequest)
        
        // Then
        XCTAssertEqual(users.count, 1)
        let fetchedUser = users.first!
        XCTAssertEqual(fetchedUser.posts?.count, 2)
    }
    
    // MARK: - Helper Methods
    
    @discardableResult
    private func createTestUser(
        in context: NSManagedObjectContext,
        id: String = UUID().uuidString,
        name: String = "Test User"
    ) -> CachedUser {
        let user = CachedUser(context: context)
        user.id = id
        user.name = name
        user.email = "\(name.lowercased().replacingOccurrences(of: " ", with: ""))@test.com"
        user.bio = "Test bio for \(name)"
        user.lastUpdated = Date()
        return user
    }
    
    @discardableResult
    private func createTestPost(
        in context: NSManagedObjectContext,
        id: String = UUID().uuidString,
        authorId: String
    ) -> CachedPost {
        let post = CachedPost(context: context)
        post.id = id
        post.title = "Test Post"
        post.content = "Test content"
        post.authorId = authorId
        post.createdAt = Date()
        post.likeCount = 0
        post.isLiked = false
        post.lastUpdated = Date()
        return post
    }
}

// MARK: - Core Data Stack Extensions for Testing

extension CoreDataStack {
    /// Batch insert operation for testing
    func batchInsert(entityName: String, objects: [[String: Any]]) throws {
        let batchInsert = NSBatchInsertRequest(entityName: entityName, objects: objects)
        batchInsert.resultType = .count
        
        let result = try viewContext.execute(batchInsert) as! NSBatchInsertResult
        
        // Merge changes into view context
        let changes = [NSInsertedObjectsKey: result.result as! NSSet]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
    }
}