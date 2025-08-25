import SwiftUI

/// Main challenges list view with tabs for available and joined challenges
struct ChallengesListView: View {
    
    // MARK: - State
    
    @StateObject private var viewModel = ChallengesViewModel()
    @State private var showingCreateChallenge = false
    @State private var selectedChallenge: Challenge?
    @State private var showingChallengeDetail = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                tabPicker
                
                // Content
                contentView
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedbackService.shared.buttonTap()
                        showingCreateChallenge = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.hapticLight)
                }
            }
            .sheet(isPresented: $showingCreateChallenge) {
                CreateChallengeView { challengeData in
                    Task {
                        await viewModel.createChallenge(challengeData)
                    }
                }
            }
            .sheet(item: $selectedChallenge) { challenge in
                ChallengeDetailView(challenge: challenge)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    HapticFeedbackService.shared.operationFailed()
                    viewModel.dismissError()
                }
                
                if let error = viewModel.error as? NetworkError, error.shouldRetry {
                    Button("Retry") {
                        HapticFeedbackService.shared.buttonTap()
                        Task {
                            await viewModel.loadChallengesIfNeeded()
                        }
                    }
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
            }
        }
        .task {
            await viewModel.loadChallengesIfNeeded()
        }
    }
    
    // MARK: - Tab Picker
    
    private var tabPicker: some View {
        Picker("Challenge Tab", selection: $viewModel.selectedTab) {
            ForEach(ChallengeTab.allCases, id: \.self) { tab in
                Label(tab.title, systemImage: tab.iconName)
                    .tag(tab)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onChange(of: viewModel.selectedTab) { newTab in
            HapticFeedbackService.shared.tabSelection()
            viewModel.selectTab(newTab)
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        Group {
            if viewModel.isLoading || viewModel.isLoadingJoined {
                loadingView
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                challengesList
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { index in
                SkeletonLayouts.challengeCard()
                    .slideIn(delay: Double(index) * 0.1)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        Group {
            if viewModel.selectedTab == .available {
                EmptyStateView.noChallenges {
                    HapticFeedbackService.shared.buttonTap()
                    showingCreateChallenge = true
                }
            } else {
                EmptyStateView.noActiveChallenges {
                    HapticFeedbackService.shared.tabSelection()
                    viewModel.selectedTab = .available
                }
            }
        }
        .fadeIn()
    }
    
    // MARK: - Challenges List
    
    private var challengesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.displayedChallenges, id: \.id) { challenge in
                    ChallengeCard(
                        challenge: challenge,
                        userChallenge: nil, // Will be populated based on challenge relationships
                        onJoinTapped: { challenge in
                            Task {
                                await viewModel.joinChallenge(challenge)
                            }
                        },
                        onLeaveTapped: { challenge in
                            Task {
                                await viewModel.leaveChallenge(challenge)
                            }
                        },
                        onChallengeTapped: { challenge in
                            selectedChallenge = challenge
                            showingChallengeDetail = true
                        }
                    )
                }
            }
            .padding(16)
        }
        .refreshable {
            await viewModel.refreshChallenges()
        }
    }
}

// MARK: - Challenge Detail View

struct ChallengeDetailView: View {
    let challenge: Challenge
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        Text(challenge.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(challenge.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            DetailRow(title: "Created by", value: challenge.createdBy)
                            DetailRow(title: "Type", value: challenge.type.displayName)
                            DetailRow(title: "Difficulty", value: challenge.difficulty.displayName)
                            DetailRow(title: "Duration", value: "\(challenge.duration) days")
                            DetailRow(title: "Target", value: "\(Int(challenge.targetValue)) \(challenge.unit)")
                            DetailRow(title: "Participants", value: "\(challenge.participantCount)")
                            DetailRow(title: "Starts", value: DateFormatter.challengeDate.string(from: challenge.startDate))
                            DetailRow(title: "Ends", value: DateFormatter.challengeDate.string(from: challenge.endDate))
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let challengeDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    ChallengesListView()
}

#Preview("Loading") {
    let viewModel = ChallengesViewModel.mockLoading()
    return ChallengesListView()
}

#Preview("Empty") {
    let viewModel = ChallengesViewModel.mockEmpty()
    return ChallengesListView()
}

#Preview("Error") {
    let viewModel = ChallengesViewModel.mockError()
    return ChallengesListView()
}