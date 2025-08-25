import SwiftUI

/// Card component for displaying league information
/// Shows league details with join/leave functionality
struct LeagueCard: View {
    let league: League
    let isJoined: Bool
    let userRole: LeagueMemberRole?
    let onJoin: () -> Void
    let onLeave: () -> Void
    
    @State private var showingJoinAlert = false
    @State private var showingLeaveAlert = false
    @State private var isProcessing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with league name and type
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(league.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Label(league.type.displayName, systemImage: league.type.iconName)
                            .font(.caption)
                            .foregroundColor(Color(league.type.color))
                        
                        Label(league.privacy.displayName, systemImage: league.privacy.iconName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Join/Leave button
                actionButton
            }
            
            // Description
            if !league.description.isEmpty {
                Text(league.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Stats row
            HStack(spacing: 16) {
                StatView(
                    value: "\(league.memberCount)",
                    label: "Members",
                    systemImage: "person.2.fill"
                )
                
                StatView(
                    value: "\(league.challengeCount)",
                    label: "Challenges",
                    systemImage: "trophy.fill"
                )
                
                if let maxMembers = league.maxMembers {
                    StatView(
                        value: "\(maxMembers)",
                        label: "Max",
                        systemImage: "person.crop.circle.badge.plus"
                    )
                }
                
                Spacer()
                
                // Status indicators
                HStack(spacing: 8) {
                    if league.isAtCapacity {
                        Label("Full", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    if isJoined, let role = userRole {
                        Label(role.displayName, systemImage: role.iconName)
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Footer with creation info
            HStack {
                if let creator = league.creator {
                    Text("Created by \(creator.name)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Created \(league.createdAt.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if league.isActive {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Label("Inactive", systemImage: "pause.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isJoined ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .alert("Join League", isPresented: $showingJoinAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Join") {
                handleJoin()
            }
        } message: {
            Text(joinAlertMessage)
        }
        .alert("Leave League", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                handleLeave()
            }
        } message: {
            Text("Are you sure you want to leave \(league.name)? You'll need to be invited again to rejoin if it's private.")
        }
    }
    
    // MARK: - Action Button
    @ViewBuilder
    private var actionButton: some View {
        if isProcessing {
            ProgressView()
                .scaleEffect(0.8)
        } else if isJoined {
            Button("Leave") {
                showingLeaveAlert = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
        } else {
            Button("Join") {
                if league.privacy == .public {
                    handleJoin()
                } else {
                    showingJoinAlert = true
                }
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(league.isAtCapacity ? Color.gray : Color.blue)
            .cornerRadius(8)
            .disabled(league.isAtCapacity)
        }
    }
    
    // MARK: - Alert Messages
    private var joinAlertMessage: String {
        switch league.privacy {
        case .public:
            return "Join \(league.name) to participate in challenges and connect with other members."
        case .private:
            return "This is a private league. You'll need to request access to join \(league.name)."
        case .inviteOnly:
            return "This league is invite-only. You'll need an invitation to join \(league.name)."
        }
    }
    
    // MARK: - Actions
    private func handleJoin() {
        isProcessing = true
        onJoin()
        // Note: isProcessing should be reset by the parent view when the operation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
        }
    }
    
    private func handleLeave() {
        isProcessing = true
        onLeave()
        // Note: isProcessing should be reset by the parent view when the operation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
        }
    }
}

// MARK: - Stat View Component
struct StatView: View {
    let value: String
    let label: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - League Card Variants
struct CompactLeagueCard: View {
    let league: League
    let isJoined: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // League type icon
                Image(systemName: league.type.iconName)
                    .font(.title2)
                    .foregroundColor(Color(league.type.color))
                    .frame(width: 32, height: 32)
                    .background(Color(league.type.color).opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(league.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(league.memberCount) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isJoined {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeaturedLeagueCard: View {
    let league: League
    let isJoined: Bool
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Featured badge
            HStack {
                Label("Featured", systemImage: "star.fill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(6)
                
                Spacer()
            }
            
            // League info
            VStack(alignment: .leading, spacing: 8) {
                Text(league.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(league.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(league.type.displayName, systemImage: league.type.iconName)
                        .font(.caption)
                        .foregroundColor(Color(league.type.color))
                    
                    Spacer()
                    
                    Label("\(league.memberCount) members", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action button
            if !isJoined {
                Button(action: onJoin) {
                    Text("Join League")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(league.type.color).opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(league.type.color).opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#if DEBUG
struct LeagueCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                LeagueCard(
                    league: League.mock,
                    isJoined: false,
                    userRole: nil,
                    onJoin: { },
                    onLeave: { }
                )
                
                LeagueCard(
                    league: League.mockPrivate,
                    isJoined: true,
                    userRole: .member,
                    onJoin: { },
                    onLeave: { }
                )
                
                CompactLeagueCard(
                    league: League.mock,
                    isJoined: true,
                    onTap: { }
                )
                
                FeaturedLeagueCard(
                    league: League.mock,
                    isJoined: false,
                    onJoin: { }
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif