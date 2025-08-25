import SwiftUI

/// Primary app screen that serves as the main interface for authenticated users
/// Displays the main tab navigation with all app features
struct MainView: View {
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            Text("Feed")
                .tabItem {
                    Image(systemName: "house")
                    Text("Feed")
                }
            
            Text("Challenges")
                .tabItem {
                    Image(systemName: "trophy")
                    Text("Challenges")
                }
            
            Text("Leagues")
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Leagues")
                }
            
            Text("Social")
                .tabItem {
                    Image(systemName: "heart")
                    Text("Social")
                }
            
            Text("Profile")
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

// MARK: - Preview Provider

#Preview("Main View") {
    MainView()
}

#Preview("Dark Mode") {
    MainView()
        .preferredColorScheme(.dark)
}

#Preview("iPad") {
    MainView()
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}