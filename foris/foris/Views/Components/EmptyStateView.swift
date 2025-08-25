import SwiftUI

/// Reusable empty state view component for when lists or content areas are empty
/// Provides consistent messaging and actions across the app
struct EmptyStateView: View {
    
    // MARK: - Properties
    
    /// The empty state configuration
    let config: EmptyStateConfig
    
    /// Optional action to perform
    let action: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Initialize with configuration
    /// - Parameters:
    ///   - config: Empty state configuration
    ///   - action: Optional action closure
    init(config: EmptyStateConfig, action: (() -> Void)? = nil) {
        self.config = config
        self.action = action
    }
    
    /// Initialize with individual parameters
    /// - Parameters:
    ///   - icon: SF Symbol icon name
    ///   - title: Main title text
    ///   - message: Descriptive message
    ///   - actionTitle: Optional action button title
    ///   - action: Optional action closure
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.config = EmptyStateConfig(
            icon: icon,
            title: title,
            message: message,
            actionTitle: actionTitle
        )
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: config.icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(config.iconColor)
                .accessibilityLabel("\(config.title) icon")
            
            // Content
            VStack(spacing: 12) {
                // Title
                Text(config.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                // Message
                Text(config.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
            }
            
            // Action Button
            if let actionTitle = config.actionTitle, let action = action {
                Button(action: {
                    handleActionTap(action)
                }) {
                    HStack(spacing: 8) {
                        if let actionIcon = config.actionIcon {
                            Image(systemName: actionIcon)
                        }
                        Text(actionTitle)
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor)
                    )
                }
                .accessibilityLabel(actionTitle)
                .accessibilityHint(config.actionHint ?? "Tap to \(actionTitle.lowercased())")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Actions
    
    private func handleActionTap(_ action: @escaping () -> Void) {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Perform action
        action()
    }
}

// MARK: - Empty State Configuration

struct EmptyStateConfig {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let actionIcon: String?
    let iconColor: Color
    let actionHint: String?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        iconColor: Color = .secondary,
        actionHint: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.iconColor = iconColor
        self.actionHint = actionHint
    }
}

// MARK: - Predefined Empty States

extension EmptyStateView {
    
    // MARK: - Feed Empty States
    
    /// Empty feed state
    static func emptyFeed(onCreatePost: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "doc.text",
                title: "No Posts Yet",
                message: "Be the first to share something with the community! Create your first post to get started.",
                actionTitle: "Create Post",
                actionIcon: "plus",
                iconColor: .blue,
                actionHint: "Tap to create your first post"
            ),
            action: onCreatePost
        )
    }
    
    /// No following posts state
    static func noFollowingPosts(onDiscoverUsers: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "person.2",
                title: "No Posts from Following",
                message: "You're not following anyone yet. Discover and follow other users to see their posts in your feed.",
                actionTitle: "Discover Users",
                actionIcon: "magnifyingglass",
                iconColor: .green,
                actionHint: "Tap to find users to follow"
            ),
            action: onDiscoverUsers
        )
    }
    
    // MARK: - Challenge Empty States
    
    /// No challenges available
    static func noChallenges(onCreateChallenge: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "target",
                title: "No Challenges Available",
                message: "There are no challenges to join right now. Create a new challenge to get started!",
                actionTitle: "Create Challenge",
                actionIcon: "plus",
                iconColor: .orange,
                actionHint: "Tap to create a new challenge"
            ),
            action: onCreateChallenge
        )
    }
    
    /// No active challenges
    static func noActiveChallenges(onBrowseChallenges: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "flag",
                title: "No Active Challenges",
                message: "You haven't joined any challenges yet. Browse available challenges and start your fitness journey!",
                actionTitle: "Browse Challenges",
                actionIcon: "magnifyingglass",
                iconColor: .purple,
                actionHint: "Tap to browse available challenges"
            ),
            action: onBrowseChallenges
        )
    }
    
    // MARK: - League Empty States
    
    /// No leagues available
    static func noLeagues(onCreateLeague: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "shield",
                title: "No Leagues Available",
                message: "There are no leagues to join yet. Create the first league and invite others to compete!",
                actionTitle: "Create League",
                actionIcon: "plus",
                iconColor: .red,
                actionHint: "Tap to create a new league"
            ),
            action: onCreateLeague
        )
    }
    
    /// No joined leagues
    static func noJoinedLeagues(onBrowseLeagues: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "person.3",
                title: "No Leagues Joined",
                message: "You haven't joined any leagues yet. Join a league to compete with others and participate in group challenges!",
                actionTitle: "Browse Leagues",
                actionIcon: "magnifyingglass",
                iconColor: .indigo,
                actionHint: "Tap to browse available leagues"
            ),
            action: onBrowseLeagues
        )
    }
    
    // MARK: - Social Empty States
    
    /// No users found in search
    static func noUsersFound(onClearSearch: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "person.crop.circle.badge.questionmark",
                title: "No Users Found",
                message: "We couldn't find any users matching your search. Try different keywords or browse all users.",
                actionTitle: onClearSearch != nil ? "Clear Search" : nil,
                actionIcon: "xmark.circle",
                iconColor: .gray,
                actionHint: "Tap to clear search and see all users"
            ),
            action: onClearSearch
        )
    }
    
    /// No followers
    static func noFollowers() -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "person.badge.plus",
                title: "No Followers Yet",
                message: "You don't have any followers yet. Share interesting content and engage with the community to gain followers!",
                iconColor: .blue
            )
        )
    }
    
    /// Not following anyone
    static func notFollowingAnyone(onDiscoverUsers: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "person.2.badge.plus",
                title: "Not Following Anyone",
                message: "You're not following anyone yet. Discover interesting users and follow them to see their content!",
                actionTitle: "Discover Users",
                actionIcon: "magnifyingglass",
                iconColor: .green,
                actionHint: "Tap to discover users to follow"
            ),
            action: onDiscoverUsers
        )
    }
    
    // MARK: - Comment Empty States
    
    /// No comments on post
    static func noComments() -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "bubble.left",
                title: "No Comments Yet",
                message: "Be the first to comment on this post! Share your thoughts and start a conversation.",
                iconColor: .secondary
            )
        )
    }
    
    // MARK: - Generic Empty States
    
    /// Generic no content state
    static func noContent(
        title: String = "No Content",
        message: String = "There's nothing to show here right now.",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "tray",
                title: title,
                message: message,
                actionTitle: actionTitle,
                iconColor: .secondary
            ),
            action: action
        )
    }
    
    /// Network error empty state
    static func networkError(onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "wifi.slash",
                title: "Connection Error",
                message: "Unable to load content. Please check your internet connection and try again.",
                actionTitle: "Try Again",
                actionIcon: "arrow.clockwise",
                iconColor: .red,
                actionHint: "Tap to retry loading content"
            ),
            action: onRetry
        )
    }
    
    /// Search empty state
    static func searchEmpty(searchTerm: String) -> EmptyStateView {
        EmptyStateView(
            config: EmptyStateConfig(
                icon: "magnifyingglass",
                title: "No Results",
                message: "No results found for \"\(searchTerm)\". Try different keywords or check your spelling.",
                iconColor: .secondary
            )
        )
    }
}

// MARK: - View Modifiers

extension View {
    /// Shows empty state when condition is met
    func emptyState<EmptyContent: View>(
        _ isEmpty: Bool,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) -> some View {
        ZStack {
            if isEmpty {
                emptyContent()
            } else {
                self
            }
        }
    }
    
    /// Shows empty state with fade transition
    func emptyStateWithTransition<EmptyContent: View>(
        _ isEmpty: Bool,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) -> some View {
        ZStack {
            self
                .opacity(isEmpty ? 0 : 1)
            
            if isEmpty {
                emptyContent()
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isEmpty)
    }
}

// MARK: - Accessibility Enhancements

extension EmptyStateView {
    /// Adds enhanced accessibility support
    func accessibilityEnhanced() -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(config.title). \(config.message)")
            .onAppear {
                // Announce empty state to accessibility users
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIAccessibility.post(
                        notification: .screenChanged,
                        argument: "\(config.title). \(config.message)"
                    )
                }
            }
    }
}

// MARK: - Animation Enhancements

extension EmptyStateView {
    /// Adds gentle bounce animation on appear
    func withBounceAnimation() -> some View {
        self
            .scaleEffect(0.8)
            .opacity(0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                    // Animation handled by modifiers
                }
            }
    }
    
    /// Adds fade-in animation
    func withFadeInAnimation() -> some View {
        self
            .opacity(0)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    // Animation handled by opacity modifier
                }
            }
    }
}

// MARK: - Preview Provider

#Preview("Feed Empty States") {
    VStack(spacing: 40) {
        EmptyStateView.emptyFeed { }
        EmptyStateView.noFollowingPosts { }
    }
}

#Preview("Challenge Empty States") {
    VStack(spacing: 40) {
        EmptyStateView.noChallenges { }
        EmptyStateView.noActiveChallenges { }
    }
}

#Preview("League Empty States") {
    VStack(spacing: 40) {
        EmptyStateView.noLeagues { }
        EmptyStateView.noJoinedLeagues { }
    }
}

#Preview("Social Empty States") {
    VStack(spacing: 40) {
        EmptyStateView.noUsersFound()
        EmptyStateView.noFollowers()
        EmptyStateView.notFollowingAnyone { }
    }
}

#Preview("Generic Empty States") {
    VStack(spacing: 40) {
        EmptyStateView.noContent()
        EmptyStateView.networkError { }
        EmptyStateView.searchEmpty(searchTerm: "fitness")
    }
}

#Preview("Dark Mode") {
    EmptyStateView.emptyFeed { }
        .preferredColorScheme(.dark)
}