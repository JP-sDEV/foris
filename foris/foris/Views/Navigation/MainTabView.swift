import SwiftUI

/// Main tab navigation for the Foris app
/// Provides access to all major app sections
struct MainTabView: View {
    
    // MARK: - Properties
    
    @State private var selectedTab: Tab = .feed
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Offline indicator at the top
            OfflineIndicator()
            
            TabView(selection: $selectedTab) {
            // Feed Tab
            FeedView()
                .tabItem {
                    AccessibleImage(
                        systemName: selectedTab == .feed ? "house.fill" : "house",
                        accessibilityLabel: "Feed tab"
                    )
                    AccessibleText("Feed")
                }
                .tag(Tab.feed)
                .accessibilityLabel("Feed tab")
                .accessibilityHint("View posts and updates from users you follow")
            
            // Challenges Tab
            ChallengesListView()
                .tabItem {
                    AccessibleImage(
                        systemName: selectedTab == .challenges ? "target.fill" : "target",
                        accessibilityLabel: "Challenges tab"
                    )
                    AccessibleText("Challenges")
                }
                .tag(Tab.challenges)
                .accessibilityLabel("Challenges tab")
                .accessibilityHint("Browse and join fitness challenges")
            
            // Leagues Tab
            LeaguesListView()
                .tabItem {
                    AccessibleImage(
                        systemName: selectedTab == .leagues ? "person.3.fill" : "person.3",
                        accessibilityLabel: "Leagues tab"
                    )
                    AccessibleText("Leagues")
                }
                .tag(Tab.leagues)
                .accessibilityLabel("Leagues tab")
                .accessibilityHint("Join leagues and compete with groups")
            
            // Social Tab
            SocialView()
                .tabItem {
                    AccessibleImage(
                        systemName: selectedTab == .social ? "person.2.fill" : "person.2",
                        accessibilityLabel: "Social tab"
                    )
                    AccessibleText("Social")
                }
                .tag(Tab.social)
                .accessibilityLabel("Social tab")
                .accessibilityHint("Find and connect with other users")
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    AccessibleImage(
                        systemName: selectedTab == .profile ? "person.crop.circle.fill" : "person.crop.circle",
                        accessibilityLabel: "Profile tab"
                    )
                    AccessibleText("Profile")
                }
                .tag(Tab.profile)
                .accessibilityLabel("Profile tab")
                .accessibilityHint("View and edit your profile")
            }
            .accentColor(.accentColor)
            .onChange(of: selectedTab) { newTab in
                HapticFeedbackService.shared.tabSelection()
                
                // Announce tab change to VoiceOver users
                let announcement = "Switched to \(newTab.title) tab"
                UIAccessibility.post(notification: .screenChanged, argument: announcement)
            }
            .keyboardNavigable(
                onLeftArrow: {
                    // Navigate to previous tab
                    if let currentIndex = Tab.allCases.firstIndex(of: selectedTab),
                       currentIndex > 0 {
                        selectedTab = Tab.allCases[currentIndex - 1]
                    }
                },
                onRightArrow: {
                    // Navigate to next tab
                    if let currentIndex = Tab.allCases.firstIndex(of: selectedTab),
                       currentIndex < Tab.allCases.count - 1 {
                        selectedTab = Tab.allCases[currentIndex + 1]
                    }
                }
            )
            .validateAccessibility()
            .accessibilityTestingOverlay()
        }
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case feed = "feed"
    case challenges = "challenges"
    case leagues = "leagues"
    case social = "social"
    case profile = "profile"
    
    var title: String {
        switch self {
        case .feed:
            return "Feed"
        case .challenges:
            return "Challenges"
        case .leagues:
            return "Leagues"
        case .social:
            return "Social"
        case .profile:
            return "Profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .feed:
            return "house"
        case .challenges:
            return "target"
        case .leagues:
            return "person.3"
        case .social:
            return "person.2"
        case .profile:
            return "person.crop.circle"
        }
    }
    
    var selectedIconName: String {
        switch self {
        case .feed:
            return "house.fill"
        case .challenges:
            return "target.fill"
        case .leagues:
            return "person.3.fill"
        case .social:
            return "person.2.fill"
        case .profile:
            return "person.crop.circle.fill"
        }
    }
}

// MARK: - Placeholder Views

struct ChallengesPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Challenges")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Challenge yourself and track your progress")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Coming Soon!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
            .navigationTitle("Challenges")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LeaguesPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.3")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Leagues")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Join leagues and compete with others")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Coming Soon!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
            .navigationTitle("Leagues")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SocialPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.2")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Social")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Connect with other fitness enthusiasts")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Coming Soon!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
            .navigationTitle("Social")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Preview Provider

#Preview("Main Tab View") {
    MainTabView()
}

#Preview("Dark Mode") {
    MainTabView()
        .preferredColorScheme(.dark)
}

#Preview("iPad") {
    MainTabView()
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}