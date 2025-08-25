import Foundation
import Security

/// Service for securely storing and retrieving authentication data using Keychain
/// Provides type-safe methods for storing tokens and user data
final class KeychainService {
    
    // MARK: - Singleton
    
    static let shared = KeychainService()
    
    // MARK: - Properties
    
    private let serviceName = "com.foris.app"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Stores a string value in the Keychain
    /// - Parameters:
    ///   - value: The string value to store
    ///   - key: The key to associate with the value
    /// - Throws: StorageError if the operation fails
    func store(_ value: String, for key: KeychainKey) throws {
        try store(value.data(using: .utf8)!, for: key.key)
    }
    
    /// Stores data in the Keychain
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The key to associate with the data
    /// - Throws: StorageError if the operation fails
    func store(_ data: Data, for key: String) throws {
        // Delete existing item first
        try? delete(key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw StorageError.keychainError("Failed to store item: \(status)")
        }
    }
    
    /// Stores a Codable object in the Keychain
    /// - Parameters:
    ///   - object: The Codable object to store
    ///   - key: The key to associate with the object
    /// - Throws: StorageError if encoding or storage fails
    func store<T: Codable>(_ object: T, for key: KeychainKey) throws {
        do {
            let data = try JSONEncoder().encode(object)
            try store(data, for: key.key)
        } catch {
            throw StorageError.keychainError("Failed to encode object: \(error.localizedDescription)")
        }
    }
    
    /// Retrieves a string value from the Keychain
    /// - Parameter key: The key associated with the value
    /// - Returns: The string value, or nil if not found
    /// - Throws: StorageError if the operation fails
    func retrieve(for key: KeychainKey) throws -> String? {
        guard let data = try retrieveData(for: key.key) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    /// Retrieves data from the Keychain
    /// - Parameter key: The key associated with the data
    /// - Returns: The data, or nil if not found
    /// - Throws: StorageError if the operation fails
    func retrieveData(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw StorageError.keychainError("Failed to retrieve item: \(status)")
        }
    }
    
    /// Retrieves a Codable object from the Keychain
    /// - Parameters:
    ///   - type: The type of object to decode
    ///   - key: The key associated with the object
    /// - Returns: The decoded object, or nil if not found
    /// - Throws: StorageError if retrieval or decoding fails
    func retrieve<T: Codable>(_ type: T.Type, for key: KeychainKey) throws -> T? {
        guard let data = try retrieveData(for: key.key) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw StorageError.keychainError("Failed to decode object: \(error.localizedDescription)")
        }
    }
    
    /// Deletes an item from the Keychain
    /// - Parameter key: The key of the item to delete
    /// - Throws: StorageError if the operation fails
    func delete(_ key: KeychainKey) throws {
        try delete(key.key)
    }
    
    /// Deletes an item from the Keychain
    /// - Parameter key: The key of the item to delete
    /// - Throws: StorageError if the operation fails
    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Success or item not found are both acceptable
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StorageError.keychainError("Failed to delete item: \(status)")
        }
    }
    
    /// Checks if an item exists in the Keychain
    /// - Parameter key: The key to check
    /// - Returns: True if the item exists, false otherwise
    func exists(for key: KeychainKey) -> Bool {
        do {
            return try retrieveData(for: key.key) != nil
        } catch {
            return false
        }
    }
    
    /// Clears all authentication-related data from the Keychain
    /// - Throws: StorageError if any deletion fails
    func clearAuthenticationData() throws {
        try delete(.refreshToken)
        try delete(.accessToken)
        try delete(.userProfile)
    }
    
    // MARK: - Authentication-Specific Methods
    
    /// Stores authentication tokens
    /// - Parameters:
    ///   - refreshToken: The refresh token to store
    ///   - accessToken: The access token to store (optional)
    /// - Throws: StorageError if storage fails
    func storeTokens(refreshToken: String, accessToken: String? = nil) throws {
        try store(refreshToken, for: .refreshToken)
        
        if let accessToken = accessToken {
            try store(accessToken, for: .accessToken)
        }
    }
    
    /// Retrieves stored authentication tokens
    /// - Returns: Tuple containing refresh token and optional access token
    /// - Throws: StorageError if retrieval fails
    func retrieveTokens() throws -> (refreshToken: String?, accessToken: String?) {
        let refreshToken = try retrieve(for: .refreshToken)
        let accessToken = try retrieve(for: .accessToken)
        return (refreshToken, accessToken)
    }
    
    /// Stores user profile data
    /// - Parameter user: The user profile to store
    /// - Throws: StorageError if storage fails
    func storeUserProfile(_ user: User) throws {
        try store(user, for: .userProfile)
    }
    
    /// Retrieves stored user profile data
    /// - Returns: The user profile, or nil if not found
    /// - Throws: StorageError if retrieval fails
    func retrieveUserProfile() throws -> User? {
        return try retrieve(User.self, for: .userProfile)
    }
    
    /// Checks if user is authenticated (has valid tokens)
    /// - Returns: True if refresh token exists, false otherwise
    func hasValidAuthentication() -> Bool {
        return exists(for: .refreshToken)
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
/// Mock Keychain service for testing and previews
class MockKeychainService: KeychainService {
    private var storage: [String: Data] = [:]
    
    override func store(_ data: Data, for key: String) throws {
        storage[key] = data
    }
    
    override func retrieveData(for key: String) throws -> Data? {
        return storage[key]
    }
    
    override func delete(_ key: String) throws {
        storage.removeValue(forKey: key)
    }
    
    override func exists(for key: KeychainKey) -> Bool {
        return storage[key.key] != nil
    }
    
    func clearAll() {
        storage.removeAll()
    }
    
    // Pre-populate with mock data
    func setupMockData() {
        try? store("mock-refresh-token", for: .refreshToken)
        try? store("mock-access-token", for: .accessToken)
        try? store(User.mock, for: .userProfile)
    }
}
#endif