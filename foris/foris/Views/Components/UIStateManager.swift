import SwiftUI

/// Centralized UI state management for consistent loading, error, and empty states
/// Provides a unified approach to handling different UI states across the app
struct UIStateManager<Content: View, LoadingContent: View, ErrorContent: View, EmptyContent: View>: View {
    
    // MARK: - Properties
    
    let state: UIState
    let content: () -> Content
    let loadingContent: () -> LoadingContent
    let errorContent: (Error) -> ErrorContent
    let emptyContent: () -> EmptyContent
    
    // MARK: - Initialization
    
    /// Initialize with all state content builders
    init(
        state: UIState,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder loadingContent: @escaping () -> LoadingContent,
        @ViewBuilder errorContent: @escaping (Error) -> ErrorContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.state = state
        self.content = content
        self.loadingContent = loadingContent
        self.errorContent = errorContent
        self.emptyContent = emptyContent
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            switch state {
            case .loading:
                loadingContent()
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                
            case .loaded:
                content()
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
                
            case .empty:
                emptyContent()
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                
            case .error(let error):
                errorContent(error)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
}

// MARK: - UI State Enum

enum UIState: Equatable {
    case loading
    case loaded
    case empty
    case error(Error)
    
    static func == (lhs: UIState, rhs: UIState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.loaded, .loaded), (.empty, .empty):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

// MARK: - Convenience Initializers

extension UIStateManager where LoadingContent == AnyView, ErrorContent == AnyView, EmptyContent == AnyView {
    
    /// Initialize with default loading, error, and empty states
    init(
        state: UIState,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            state: state,
            content: content,
            loadingContent: {
                AnyView(
                    LoadingView(message: "Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            },
            errorContent: { error in
                AnyView(
                    ErrorView(
                        error: error as? NetworkError ?? .unknown,
                        retryAction: { }
                    )
                )
            },
            emptyContent: {
                AnyView(
                    EmptyStateView.noContent()
                )
            }
        )
    }
}

// MARK: - Specialized UI State Managers

/// UI State Manager for list views
struct ListUIStateManager<Content: View>: View {
    let state: UIState
    let content: () -> Content
    let emptyStateConfig: EmptyStateConfig
    let onRetry: () -> Void
    let onEmptyAction: (() -> Void)?
    
    init(
        state: UIState,
        emptyStateConfig: EmptyStateConfig,
        onRetry: @escaping () -> Void,
        onEmptyAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.state = state
        self.content = content
        self.emptyStateConfig = emptyStateConfig
        self.onRetry = onRetry
        self.onEmptyAction = onEmptyAction
    }
    
    var body: some View {
        UIStateManager(
            state: state,
            content: content,
            loadingContent: {
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { index in
                        SkeletonView.card()
                            .slideIn(delay: Double(index) * 0.1)
                    }
                }
                .padding()
            },
            errorContent: { error in
                if let networkError = error as? NetworkError {
                    ErrorView(error: networkError, retryAction: onRetry)
                        .fadeIn()
                } else {
                    ErrorView.noRetry(error: .unknown)
                        .fadeIn()
                }
            },
            emptyContent: {
                EmptyStateView(config: emptyStateConfig, action: onEmptyAction)
                    .fadeIn()
            }
        )
    }
}

/// UI State Manager for feed views
struct FeedUIStateManager<Content: View>: View {
    let state: UIState
    let content: () -> Content
    let onCreatePost: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        ListUIStateManager(
            state: state,
            emptyStateConfig: EmptyStateConfig(
                icon: "doc.text",
                title: "No Posts Yet",
                message: "Be the first to share something with the community! Create your first post to get started.",
                actionTitle: "Create Post",
                actionIcon: "plus",
                iconColor: .blue
            ),
            onRetry: onRetry,
            onEmptyAction: onCreatePost,
            content: content
        )
    }
}

/// UI State Manager for challenges views
struct ChallengesUIStateManager<Content: View>: View {
    let state: UIState
    let content: () -> Content
    let isAvailableTab: Bool
    let onCreateChallenge: () -> Void
    let onBrowseChallenges: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        ListUIStateManager(
            state: state,
            emptyStateConfig: isAvailableTab ? 
                EmptyStateConfig(
                    icon: "target",
                    title: "No Challenges Available",
                    message: "There are no challenges to join right now. Create a new challenge to get started!",
                    actionTitle: "Create Challenge",
                    actionIcon: "plus",
                    iconColor: .orange
                ) :
                EmptyStateConfig(
                    icon: "flag",
                    title: "No Active Challenges",
                    message: "You haven't joined any challenges yet. Browse available challenges and start your fitness journey!",
                    actionTitle: "Browse Challenges",
                    actionIcon: "magnifyingglass",
                    iconColor: .purple
                ),
            onRetry: onRetry,
            onEmptyAction: isAvailableTab ? onCreateChallenge : onBrowseChallenges,
            content: content
        )
    }
}

/// UI State Manager for leagues views
struct LeaguesUIStateManager<Content: View>: View {
    let state: UIState
    let content: () -> Content
    let hasJoinedLeagues: Bool
    let onCreateLeague: () -> Void
    let onBrowseLeagues: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        ListUIStateManager(
            state: state,
            emptyStateConfig: hasJoinedLeagues ?
                EmptyStateConfig(
                    icon: "shield",
                    title: "No Leagues Available",
                    message: "There are no leagues to join yet. Create the first league and invite others to compete!",
                    actionTitle: "Create League",
                    actionIcon: "plus",
                    iconColor: .red
                ) :
                EmptyStateConfig(
                    icon: "person.3",
                    title: "No Leagues Joined",
                    message: "You haven't joined any leagues yet. Join a league to compete with others and participate in group challenges!",
                    actionTitle: "Browse Leagues",
                    actionIcon: "magnifyingglass",
                    iconColor: .indigo
                ),
            onRetry: onRetry,
            onEmptyAction: hasJoinedLeagues ? onCreateLeague : onBrowseLeagues,
            content: content
        )
    }
}

/// UI State Manager for social/users views
struct SocialUIStateManager<Content: View>: View {
    let state: UIState
    let content: () -> Content
    let searchTerm: String?
    let onClearSearch: (() -> Void)?
    let onRetry: () -> Void
    
    var body: some View {
        ListUIStateManager(
            state: state,
            emptyStateConfig: searchTerm != nil ?
                EmptyStateConfig(
                    icon: "magnifyingglass",
                    title: "No Results",
                    message: "No results found for \"\(searchTerm!)\". Try different keywords or check your spelling.",
                    actionTitle: "Clear Search",
                    actionIcon: "xmark.circle",
                    iconColor: .gray
                ) :
                EmptyStateConfig(
                    icon: "person.crop.circle.badge.questionmark",
                    title: "No Users Found",
                    message: "We couldn't find any users. Try refreshing or check your connection.",
                    iconColor: .gray
                ),
            onRetry: onRetry,
            onEmptyAction: onClearSearch,
            content: content
        )
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies UI state management with default configurations
    func uiState<LoadingContent: View, ErrorContent: View, EmptyContent: View>(
        _ state: UIState,
        @ViewBuilder loadingContent: @escaping () -> LoadingContent,
        @ViewBuilder errorContent: @escaping (Error) -> ErrorContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) -> some View {
        UIStateManager(
            state: state,
            content: { self },
            loadingContent: loadingContent,
            errorContent: errorContent,
            emptyContent: emptyContent
        )
    }
    
    /// Applies UI state management with default loading, error, and empty states
    func uiState(_ state: UIState) -> some View {
        UIStateManager(state: state) { self }
    }
    
    /// Applies feed-specific UI state management
    func feedUIState(
        _ state: UIState,
        onCreatePost: @escaping () -> Void,
        onRetry: @escaping () -> Void
    ) -> some View {
        FeedUIStateManager(
            state: state,
            content: { self },
            onCreatePost: onCreatePost,
            onRetry: onRetry
        )
    }
    
    /// Applies challenges-specific UI state management
    func challengesUIState(
        _ state: UIState,
        isAvailableTab: Bool,
        onCreateChallenge: @escaping () -> Void,
        onBrowseChallenges: @escaping () -> Void,
        onRetry: @escaping () -> Void
    ) -> some View {
        ChallengesUIStateManager(
            state: state,
            content: { self },
            isAvailableTab: isAvailableTab,
            onCreateChallenge: onCreateChallenge,
            onBrowseChallenges: onBrowseChallenges,
            onRetry: onRetry
        )
    }
    
    /// Applies leagues-specific UI state management
    func leaguesUIState(
        _ state: UIState,
        hasJoinedLeagues: Bool,
        onCreateLeague: @escaping () -> Void,
        onBrowseLeagues: @escaping () -> Void,
        onRetry: @escaping () -> Void
    ) -> some View {
        LeaguesUIStateManager(
            state: state,
            content: { self },
            hasJoinedLeagues: hasJoinedLeagues,
            onCreateLeague: onCreateLeague,
            onBrowseLeagues: onBrowseLeagues,
            onRetry: onRetry
        )
    }
    
    /// Applies social-specific UI state management
    func socialUIState(
        _ state: UIState,
        searchTerm: String? = nil,
        onClearSearch: (() -> Void)? = nil,
        onRetry: @escaping () -> Void
    ) -> some View {
        SocialUIStateManager(
            state: state,
            content: { self },
            searchTerm: searchTerm,
            onClearSearch: onClearSearch,
            onRetry: onRetry
        )
    }
}

// MARK: - Preview Provider

#Preview("UI State Examples") {
    struct UIStateDemo: View {
        @State private var currentState: UIState = .loading
        
        var body: some View {
            VStack(spacing: 20) {
                // State controls
                HStack {
                    Button("Loading") { currentState = .loading }
                    Button("Loaded") { currentState = .loaded }
                    Button("Empty") { currentState = .empty }
                    Button("Error") { currentState = .error(NetworkError.networkUnavailable) }
                }
                .buttonStyle(.bordered)
                
                // UI State Manager demo
                UIStateManager(
                    state: currentState,
                    content: {
                        VStack {
                            Text("Content Loaded!")
                                .font(.title)
                            Text("This is the main content area")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    },
                    loadingContent: {
                        LoadingView(message: "Loading demo content...")
                    },
                    errorContent: { error in
                        ErrorView(
                            error: error as? NetworkError ?? .unknown,
                            retryAction: {
                                currentState = .loading
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    currentState = .loaded
                                }
                            }
                        )
                    },
                    emptyContent: {
                        EmptyStateView.noContent(
                            title: "Demo Empty State",
                            message: "This is what an empty state looks like",
                            actionTitle: "Load Content"
                        ) {
                            currentState = .loading
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                currentState = .loaded
                            }
                        }
                    }
                )
                .frame(height: 300)
                .border(Color.gray.opacity(0.3))
            }
            .padding()
        }
    }
    
    return UIStateDemo()
}