# Implementation Plan

- [x] 1. Set up Apollo iOS and GraphQL infrastructure
  - Install Apollo iOS via Swift Package Manager
  - Configure Apollo client with authentication headers and error handling
  - Generate GraphQL schema and Swift types from the NestJS backend
  - Create GraphQLService protocol and implementation with proper error handling
  - _Requirements: 1.3, 1.4, 3.2, 4.4, 5.2, 6.2_

- [x] 2. Implement authentication system with OAuth providers
  - Add Google Sign-In and Apple Sign-In SDKs to the project
  - Create AuthService protocol and implementation for OAuth flow management
  - Implement secure token storage using Keychain Services
  - Create authentication ViewModels for sign-in/sign-out flows
  - Build authentication UI screens (sign-in options, loading states)
  - Implement automatic token refresh logic with proper error handling
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

- [x] 3. Create Core Data stack for offline caching
  - Design Core Data model matching GraphQL schema entities
  - Implement CacheService for local data persistence and synchronization
  - Create data migration strategies for schema updates
  - Build offline-first data loading with sync capabilities
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.6_

- [x] 4. Build user profile management system
  - Create User data models and GraphQL operations (queries/mutations)
  - Implement UserService for profile operations (get, update, avatar upload)
  - Build ProfileViewModel with state management for profile data
  - Create ProfileView UI with editable fields and avatar picker
  - Implement profile editing functionality with validation and error handling
  - Add logout functionality that clears tokens and cached data
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.7_

- [x] 5. Implement posts system with creation and viewing
  - Create Post data models and GraphQL operations for CRUD operations
  - Implement PostService for post management (create, fetch, update, delete)
  - Build FeedViewModel with pagination and state management
  - Create PostCard reusable component for displaying posts
  - Build CreatePostView with title/content input and validation
  - Implement FeedView with pull-to-refresh and infinite scrolling
  - Add post detail view with full content display
  - _Requirements: 3.1, 3.2, 3.3, 3.7, 3.8_

- [x] 6. Add like and comment functionality to posts
  - Create Like and Comment data models with GraphQL operations
  - Implement LikeService and CommentService for interaction management
  - Add like toggle functionality with optimistic UI updates
  - Build comment creation UI with input validation
  - Implement comment display in post detail view with proper threading
  - Add like and comment count displays with real-time updates
  - _Requirements: 3.4, 3.5, 3.6, 3.7_

- [x] 7. Build user following and social features
  - Create UserFollow data models and GraphQL operations
  - Implement FollowService for managing follow relationships
  - Build user search functionality with debounced input
  - Create UserCard component for displaying users with follow buttons
  - Implement user profile view showing posts and follow counts
  - Build followers/following lists with proper navigation
  - Add follow/unfollow functionality with optimistic updates
  - Integrate following relationships into feed prioritization
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [x] 8. Implement challenges system
  - Create Challenge and UserChallenge data models with GraphQL operations
  - Implement ChallengeService for challenge management and participation
  - Build ChallengesViewModel with state management for challenge lists
  - Create ChallengeCard component showing challenge info and join status
  - Implement ChallengesListView with available and joined challenges
  - Build ChallengeDetailView with participant lists and progress tracking
  - Add challenge creation functionality with validation
  - Implement challenge status updates (join, complete, leave)
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

- [x] 9. Build leagues and league challenges system
  - Create League and LeagueChallenge data models with GraphQL operations
  - Implement LeagueService for league management and membership
  - Build LeaguesViewModel with state management for league data
  - Create LeagueCard component displaying league info and member counts
  - Implement LeaguesListView with available leagues and join functionality
  - Build LeagueDetailView showing challenges and member management
  - Add league creation functionality with admin role assignment
  - Implement league-specific challenge participation and tracking
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

- [x] 10. Implement offline capabilities and synchronization
  - Build offline detection and status indicators throughout the app
  - Implement action queuing for offline operations with retry logic
  - Create sync service for uploading queued actions when online
  - Add offline content indicators and stale data warnings
  - Implement conflict resolution for sync operations
  - Build retry mechanisms for failed network operations
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.7_

- [x] 11. Create main navigation and app structure
  - Implement TabView with Feed, Challenges, Leagues, Social, and Profile tabs
  - Build navigation coordinators for each tab's flow
  - Create consistent navigation patterns and transitions
  - Implement deep linking support for sharing content
  - Add proper navigation state management and restoration
  - _Requirements: 8.1, 8.4_

- [x] 12. Implement UI polish and user experience enhancements
  - Add loading states and skeleton views for all data loading scenarios
  - Implement comprehensive error handling with user-friendly messages and retry options
  - Build dark mode support with proper color schemes
  - Add smooth animations and transitions between screens
  - Implement proper image caching and placeholder handling
  - Create empty state views for all list screens with appropriate actions
  - Add haptic feedback for user interactions
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8_

- [x] 13. Add accessibility support and testing
  - Implement VoiceOver support with proper labels and hints
  - Add accessibility traits and navigation for all UI components
  - Test with Dynamic Type for text scaling support
  - Implement keyboard navigation support where applicable
  - Add accessibility announcements for state changes
  - Create accessibility-focused UI tests
  - _Requirements: 8.7_

- [x] 14. Write comprehensive unit and integration tests
  - Create unit tests for all ViewModels with mock dependencies
  - Write tests for all service classes with proper mocking
  - Implement GraphQL operation tests with mock responses
  - Add Core Data persistence tests with test database
  - Create authentication flow tests with mock OAuth providers
  - Build UI tests for critical user flows and error scenarios
  - _Requirements: All requirements through comprehensive testing coverage_

- [x] 15. Update app branding and configuration for Foris
  - Update app name, bundle identifier, and display name to Foris
  - Replace placeholder icons and branding with Foris design
  - Update app metadata and configuration files
  - Modify navigation titles and app-specific text to reflect Foris branding
  - _Requirements: App branding and identity_