import SwiftUI

struct OfflineIndicator: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var syncService = SyncService.shared
    
    var body: some View {
        VStack(spacing: 4) {
            if !networkMonitor.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text("Offline")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            } else if syncService.isSyncing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    
                    Text("Syncing...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        .animation(.easeInOut(duration: 0.3), value: syncService.isSyncing)
    }
}

struct SyncStatusView: View {
    @StateObject private var syncService = SyncService.shared
    @StateObject private var offlineQueue = OfflineQueueService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sync Status")
                    .font(.headline)
                
                Spacer()
                
                if syncService.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Last sync info
            if let lastSync = syncService.lastSyncDate {
                Text("Last synced: \(lastSync, formatter: relativeDateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Pending actions
            if !offlineQueue.queuedActions.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                    
                    Text("\(offlineQueue.queuedActions.count) pending actions")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Sync progress
            if syncService.isSyncing {
                ProgressView(value: syncService.syncProgress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            
            // Sync status
            switch syncService.syncStatus {
            case .idle:
                EmptyView()
            case .syncing:
                Text("Syncing data...")
                    .font(.caption)
                    .foregroundColor(.blue)
            case .success:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Sync completed")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            case .failed(let error):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Sync failed: \(error.localizedDescription)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StaleDataIndicator: View {
    let lastUpdated: Date
    let threshold: TimeInterval = 5 * 60 // 5 minutes
    
    private var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > threshold
    }
    
    var body: some View {
        if isStale {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.orange)
                
                Text("Data may be outdated")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
}()

#Preview {
    VStack(spacing: 20) {
        OfflineIndicator()
        SyncStatusView()
        StaleDataIndicator(lastUpdated: Date().addingTimeInterval(-10 * 60))
    }
    .padding()
}