import SwiftUI

/// Reusable challenge card component
struct ChallengeCard: View {
    
    // MARK: - Properties
    
    let challenge: Challenge
    let onJoinTapped: ((Challenge) -> Void)?
    let onLeaveTapped: ((Challenge) -> Void)?
    let onCompleteTapped: ((Challenge) -> Void)?
    let onChallengeTapped: ((Challenge) -> Void)?
    
    // MARK: - State
    
    @State private var userStatus: ChallengeStatus?
    @State private var isLoading = false
    
    // MARK: - Services
    
    @StateObject private var challengeService = ChallengeService.shared
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        switch userStatus {
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .notInProgress, .none:
            return "Not Joined"
        }
    }
    
    private var statusColor: Color {
        switch userStatus {
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .notInProgress, .none:
            return .secondary
        }
    }
    
    private var timeRemaining: String? {
        guard let endDate = challenge.endDate else { return nil }
        
        let now = Date()
        if endDate <= now {
            return "Ended"
        }
        
        let timeInterval = endDate.timeIntervalSince(now)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") left"
        } else {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") left"
        }
    }
    
    private var canJoin: Bool {
        return userStatus == nil || userStatus == .notInProgress
    }
    
    private var canLeave: Bool {
        return userStatus == .inProgress
    }
    
    private var canComplete: Bool {
        return userStatus == .inProgress
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            onChallengeTapped?(challenge)
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        AccessibleText(
                            challenge.name,
                            font: .headline,
                            color: .primary,
                            isHeader: true
                        )
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        
                        if let timeRemaining = timeRemaining {
                            AccessibleText(
                                timeRemaining,
                                font: .caption,
                                color: .secondary
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    AccessibleText(
                        statusText,
                        font: .caption,
                        color: .white
                    )
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor)
                    )
                    .accessibilityLabel("Challenge status: \(statusText)")
                    .highContrastBorder(color: .white, width: 1)
                }
                
                // Description
                if let description = challenge.description, !description.isEmpty {
                    AccessibleText(
                        description,
                        font: .body,
                        color: .secondary
                    )
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                }
                
                // Action Buttons
                HStack(spacing: 8) {
                    if canJoin {
                        Button(action: {
                            joinChallenge()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(height: 32)
                                    .accessibilityLabel("Joining challenge")
                            } else {
                                AccessibleText(
                                    "Join Challenge",
                                    font: .caption,
                                    color: .white
                                )
                                .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(isLoading)
                        .accessibilityButton(
                            label: "Join \(challenge.name)",
                            hint: isLoading ? "Please wait" : "Tap to join this challenge",
                            isEnabled: !isLoading
                        )
                        .highContrastBorder()
                    }
                    
                    if canComplete {
                        Button(action: {
                            completeChallenge()
                        }) {
                            AccessibleText(
                                "Mark Complete",
                                font: .caption
                            )
                            .fontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isLoading)
                        .accessibilityButton(
                            label: "Mark \(challenge.name) as complete",
                            hint: "Tap to mark this challenge as completed",
                            isEnabled: !isLoading
                        )
                        .highContrastBorder()
                    }
                    
                    if canLeave {
                        Button(action: {
                            leaveChallenge()
                        }) {
                            AccessibleText(
                                "Leave",
                                font: .caption
                            )
                            .fontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isLoading)
                        .accessibilityButton(
                            label: "Leave \(challenge.name)",
                            hint: "Tap to leave this challenge",
                            isEnabled: !isLoading
                        )
                        .highContrastBorder()
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .contain)
        .accessibilityButton(
            label: "Challenge: \(challenge.name)",
            hint: "Status: \(statusText). \(timeRemaining ?? "No time limit"). Tap to view details"
        )
        .highContrastBorder()
        .task {
            await loadUserStatus()
        }
    }
    
    // MARK: - Actions
    
    private func loadUserStatus() async {
        do {
            let status = try await challengeService.getUserChallengeStatus(challenge.id)
            await MainActor.run {
                userStatus = status
            }
        } catch {
            print("Failed to load user challenge status: \(error)")
        }
    }
    
    private func joinChallenge() {
        Task {
            isLoading = true
            
            do {
                _ = try await challengeService.joinChallenge(challenge.id)
                await MainActor.run {
                    userStatus = .inProgress
                    onJoinTapped?(challenge)
                }
            } catch {
                print("Failed to join challenge: \(error)")
            }
            
            isLoading = false
        }
    }
    
    private func leaveChallenge() {
        Task {
            isLoading = true
            
            do {
                try await challengeService.leaveChallenge(challenge.id)
                await MainActor.run {
                    userStatus = nil
                    onLeaveTapped?(challenge)
                }
            } catch {
                print("Failed to leave challenge: \(error)")
            }
            
            isLoading = false
        }
    }
    
    private func completeChallenge() {
        Task {
            isLoading = true
            
            do {
                _ = try await challengeService.completeChallenge(challenge.id)
                await MainActor.run {
                    userStatus = .completed
                    onCompleteTapped?(challenge)
                }
            } catch {
                print("Failed to complete challenge: \(error)")
            }
            
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ChallengeCard(
            challenge: Challenge(
                id: "1",
                name: "30-Day Fitness Challenge",
                description: "Complete 30 days of consistent workouts to build a healthy habit and improve your overall fitness level.",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 25, to: Date()),
                userStatus: nil
            ),
            onJoinTapped: { challenge in
                print("Joined: \(challenge.name)")
            },
            onLeaveTapped: { challenge in
                print("Left: \(challenge.name)")
            },
            onCompleteTapped: { challenge in
                print("Completed: \(challenge.name)")
            },
            onChallengeTapped: { challenge in
                print("Tapped: \(challenge.name)")
            }
        )
        
        ChallengeCard(
            challenge: Challenge(
                id: "2",
                name: "10K Steps Daily",
                description: "Walk at least 10,000 steps every day for a week",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                userStatus: .inProgress
            ),
            onJoinTapped: nil,
            onLeaveTapped: nil,
            onCompleteTapped: nil,
            onChallengeTapped: nil
        )
        
        ChallengeCard(
            challenge: Challenge(
                id: "3",
                name: "Completed Challenge",
                description: "This challenge has been completed successfully",
                createdBy: "admin",
                endDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
                userStatus: .completed
            ),
            onJoinTapped: nil,
            onLeaveTapped: nil,
            onCompleteTapped: nil,
            onChallengeTapped: nil
        )
    }
    .padding()
}