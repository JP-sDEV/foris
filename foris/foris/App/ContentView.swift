import SwiftUI

/// Root content view that serves as the entry point for the app
/// Integrates authentication and main app content with proper state management
struct ContentView: View {
    
    // MARK: - Properties
    
    @StateObject private var networkManager = NetworkManager.shared
    @StateObject private var apiService = APIService.shared
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Text("Foris iOS App")
                .font(.largeTitle)
                .padding()
            
            Text("Welcome to Foris!")
                .font(.title2)
                .foregroundColor(.secondary)
            
            // Main app content will be shown here when authenticated
            MainView()
                .environmentObject(networkManager)
                .environmentObject(apiService)
        }
        .onAppear {
            setupAppearance()
        }
    }
    
    // MARK: - Setup
    
    private func setupAppearance() {
        // Basic appearance setup
        print("Setting up app appearance")
    }
}

// MARK: - Preview Provider

#Preview {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("iPad") {
    ContentView()
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}