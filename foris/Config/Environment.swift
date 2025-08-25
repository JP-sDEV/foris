import Foundation

/// Environment configuration for different build configurations
struct Environment {
    
    // MARK: - API Configuration
    
    #if DEBUG
    static let graphqlEndpoint = "http://localhost:3000/graphql"
    static let apiBaseURL = "http://localhost:3000"
    static let enableLogging = true
    static let enableMockData = true
    static let logLevel: LogLevel = .debug
    #elseif STAGING
    static let graphqlEndpoint = "https://staging-api.foris.app/graphql"
    static let apiBaseURL = "https://staging-api.foris.app"
    static let enableLogging = true
    static let enableMockData = false
    static let logLevel: LogLevel = .info
    #else // RELEASE
    static let graphqlEndpoint = "https://api.foris.app/graphql"
    static let apiBaseURL = "https://api.foris.app"
    static let enableLogging = false
    static let enableMockData = false
    static let logLevel: LogLevel = .error
    #endif
    
    // MARK: - App Configuration
    
    static let appName = "Foris"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Feature Flags
    
    #if DEBUG
    static let enableAnalytics = false
    static let enableCrashReporting = false
    static let enablePerformanceMonitoring = false
    static let enableBetaFeatures = true
    #else
    static let enableAnalytics = true
    static let enableCrashReporting = true
    static let enablePerformanceMonitoring = true
    static let enableBetaFeatures = false
    #endif
    
    // MARK: - Network Configuration
    
    static let requestTimeout: TimeInterval = 30.0
    static let resourceTimeout: TimeInterval = 60.0
    static let maxRetryAttempts = 3
    static let retryDelay: TimeInterval = 1.0
    
    // MARK: - Cache Configuration
    
    static let imageCacheMaxSize: UInt = 100 * 1024 * 1024 // 100MB
    static let imageCacheMaxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    static let dataCacheMaxAge: TimeInterval = 24 * 60 * 60 // 24 hours
    
    // MARK: - Security Configuration
    
    static let keychainService = "com.yourcompany.foris.keychain"
    static let certificatePinningEnabled = !enableMockData
    
    // MARK: - OAuth Configuration
    
    struct OAuth {
        static let googleClientID = "YOUR_GOOGLE_CLIENT_ID"
        static let appleServiceID = "com.yourcompany.foris.signin"
        
        #if DEBUG
        static let redirectURI = "com.yourcompany.foris.debug://oauth/callback"
        #else
        static let redirectURI = "com.yourcompany.foris://oauth/callback"
        #endif
    }
    
    // MARK: - Analytics Configuration
    
    struct Analytics {
        static let trackingEnabled = enableAnalytics
        static let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
        static let batchSize = 20
        static let flushInterval: TimeInterval = 60 // 1 minute
    }
    
    // MARK: - Push Notifications
    
    struct PushNotifications {
        #if DEBUG
        static let enabled = false
        #else
        static let enabled = true
        #endif
        
        static let categories = [
            "CHALLENGE_REMINDER",
            "POST_LIKE",
            "NEW_FOLLOWER",
            "CHALLENGE_COMPLETED"
        ]
    }
    
    // MARK: - Helper Methods
    
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isRelease: Bool {
        #if RELEASE
        return true
        #else
        return false
        #endif
    }
    
    static var isStaging: Bool {
        #if STAGING
        return true
        #else
        return false
        #endif
    }
    
    static var buildConfiguration: String {
        #if DEBUG
        return "Debug"
        #elseif STAGING
        return "Staging"
        #else
        return "Release"
        #endif
    }
    
    static func printConfiguration() {
        guard enableLogging else { return }
        
        print("🔧 Environment Configuration")
        print("   Build: \(buildConfiguration)")
        print("   Version: \(appVersion) (\(buildNumber))")
        print("   GraphQL: \(graphqlEndpoint)")
        print("   Logging: \(enableLogging)")
        print("   Mock Data: \(enableMockData)")
        print("   Analytics: \(enableAnalytics)")
    }
}

// MARK: - Log Level

enum LogLevel: Int, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case none = 4
    
    var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .none: return "NONE"
        }
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .none: return ""
        }
    }
}

// MARK: - Logger

struct Logger {
    static func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard Environment.enableLogging && level.rawValue >= Environment.logLevel.rawValue else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        
        print("\(level.emoji) [\(timestamp)] [\(level.description)] \(fileName):\(line) \(function) - \(message)")
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}