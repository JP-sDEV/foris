import Foundation
import SwiftUI

/// Main view model managing app state and API communication
/// Follows MVVM pattern with ObservableObject for SwiftUI binding
@MainActor
final class MainViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current hello response from the API
    @Published var helloResponse: HelloResponse?
    
    /// Loading state indicator
    @Published var isLoading: Bool = false
    
    /// Current error state
    @Published var currentError: NetworkError?
    
    /// Network connectivity status
    @Published var isNetworkAvailable: Bool = true
    
    /// Connection type description
    @Published var connectionType: String?
    
    // MARK: - Private Properties
    
    private let apiService: APIService
    
    // MARK: - Computed Properties
    
    /// Returns true if there's currently an error
    var hasError: Bool {
        return currentError != nil
    }
    
    /// Returns the current error message for display
    var errorMessage: String {
        return currentError?.localizedDescription ?? "Unknown error occurred"
    }
    
    /// Returns true if data has been loaded successfully
    var hasData: Bool {
        return helloResponse != nil && !hasError
    }
    
    /// Returns the display message from the hello response
    var displayMessage: String {
        return helloResponse?.displayMessage ?? "No message available"
    }
    
    /// Returns true if the current message is the default "Hello World!"
    var isDefaultMessage: Bool {
        return helloResponse?.isDefaultMessage ?? false
    }
    
    /// Returns the current app state for UI display
    var currentState: AppState {
        if isLoading {
            return .loading
        } else if hasError {
            return .error(currentError!)
        } else if hasData {
            return .loaded(helloResponse!)
        } else {
            return .idle
        }
    }
    
    // MARK: - Initialization
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
        
        // Observe network status changes
        observeNetworkStatus()
        
        // Load initial data
        Task {
            await loadHelloMessage()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads the hello message from the API
    func loadHelloMessage() async {
        await setLoading(true)
        clearError()
        
        do {
            let response = try await apiService.getHello()
            await setHelloResponse(response)
        } catch {
            print("🚨 MainViewModel Error: \(error)")
            print("🚨 Error Type: \(type(of: error))")
            if let networkError = error as? NetworkError {
                print("🚨 Network Error: \(networkError)")
            }
            await setError(NetworkError.fromError(error))
        }
        
        await setLoading(false)
    }
    
    /// Refreshes the hello message (for pull-to-refresh)
    func refreshHelloMessage() async {
        // Add a small delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        await loadHelloMessage()
    }
    
    /// Retries loading the hello message after an error
    func retryLoadHelloMessage() async {
        await loadHelloMessage()
    }
    
    /// Clears the current error state
    func clearError() {
        currentError = nil
    }
    
    /// Checks API health status
    func checkAPIHealth() async -> Bool {
        return await apiService.checkAPIHealth()
    }
    
    // MARK: - Private Methods
    
    private func setLoading(_ loading: Bool) async {
        isLoading = loading
    }
    
    private func setHelloResponse(_ response: HelloResponse) async {
        helloResponse = response
    }
    
    private func setError(_ error: NetworkError) async {
        currentError = error
    }
    
    private func observeNetworkStatus() {
        // In a real implementation, you would observe NetworkManager's published properties
        // For now, we'll update the status when making requests
        updateNetworkStatus()
    }
    
    private func updateNetworkStatus() {
        isNetworkAvailable = apiService.isNetworkAvailable
        connectionType = apiService.connectionType
    }
}

// MARK: - App State Enum

extension MainViewModel {
    enum AppState: Equatable {
        case idle
        case loading
        case loaded(HelloResponse)
        case error(NetworkError)
        
        static func == (lhs: AppState, rhs: AppState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading):
                return true
            case (.loaded(let lhsResponse), .loaded(let rhsResponse)):
                return lhsResponse == rhsResponse
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
}

// MARK: - Convenience Methods

extension MainViewModel {
    /// Loads hello message with completion handler (for non-async contexts)
    func loadHelloMessage(completion: @escaping () -> Void) {
        Task {
            await loadHelloMessage()
            completion()
        }
    }
    
    /// Refreshes hello message with completion handler
    func refreshHelloMessage(completion: @escaping () -> Void) {
        Task {
            await refreshHelloMessage()
            completion()
        }
    }
    
    /// Gets a user-friendly status description
    var statusDescription: String {
        switch currentState {
        case .idle:
            return "Ready to load"
        case .loading:
            return "Loading..."
        case .loaded:
            return "Data loaded successfully"
        case .error(let error):
            return error.localizedDescription
        }
    }
    
    /// Returns true if the error suggests a retry should be attempted
    var shouldShowRetry: Bool {
        return currentError?.shouldRetry ?? false
    }
    
    /// Returns recovery suggestion for the current error
    var recoverySuggestion: String? {
        return currentError?.recoverySuggestion
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension MainViewModel {
    /// Creates a mock view model for previews and testing
    static func mock(
        response: HelloResponse? = HelloResponse.mock(),
        isLoading: Bool = false,
        error: NetworkError? = nil
    ) -> MainViewModel {
        let viewModel = MainViewModel()
        viewModel.helloResponse = response
        viewModel.isLoading = isLoading
        viewModel.currentError = error
        return viewModel
    }
    
    /// Simulates a loading state for testing
    func simulateLoading() {
        isLoading = true
        currentError = nil
    }
    
    /// Simulates an error state for testing
    func simulateError(_ error: NetworkError) {
        isLoading = false
        currentError = error
        helloResponse = nil
    }
    
    /// Simulates a success state for testing
    func simulateSuccess(_ response: HelloResponse) {
        isLoading = false
        currentError = nil
        helloResponse = response
    }
}
#endif