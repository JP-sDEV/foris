import SwiftUI

/// View for displaying and managing leagues
/// Shows both available leagues and user's joined leagues
struct LeaguesListView: View {
    @StateObject private var viewModel = LeaguesViewModel()
    @State private var selectedTab = 0
    @State private var showingCreateLeague = false
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("League View", selection: $selectedTab) {
                    Text("Discover").tag(0)
                    Text("My Leagues").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Discover Leagues Tab
                    discoverLeaguesView
                        .tag(0)
                    
                    // My Leagues Tab
                    myLeaguesView
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Leagues")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if selectedTab == 0 {
                            Button(action: { showingFilters = true }) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                            }
                        }
                        
                        Button(action: { showingCreateLeague = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateLeague) {
                CreateLeagueView { league in
                    Task {
                        await viewModel.refreshAll()
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                LeagueFiltersView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadLeagues()
                await viewModel.loadUserLeagues()
            }
            .refreshable {
                await viewModel.refreshAll()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
    
    // MARK: - Discover Leagues View
    private var discoverLeaguesView: some View {
        VStack {
            // Search Bar
            SearchBar(text: $viewModel.searchText, placeholder: "Search leagues...")
                .padding(.horizontal)
            
            if viewModel.isLoading && viewModel.filteredLeagues.isEmpty {
                LoadingView(message: "Loading leagues...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredLeagues.isEmpty {
                EmptyStateView(
                    title: "No Leagues Found",
                    message: viewModel.searchText.isEmpty ? 
                        "No leagues are available right now." : 
                        "No leagues match your search criteria.",
                    systemImage: "person.3.fill"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredLeagues) { league in
                            LeagueCard(
                                league: league,
                                isJoined: viewModel.isUserMember(of: league.id),
                                userRole: viewModel.getUserRole(in: league.id),
                                onJoin: {
                                    Task {
                                        await viewModel.joinLeague(leagueId: league.id)
                                    }
                                },
                                onLeave: {
                                    Task {
                                        await viewModel.leaveLeague(leagueId: league.id)
                                    }
                                }
                            )
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - My Leagues View
    private var myLeaguesView: some View {
        VStack {
            if viewModel.isLoading && viewModel.userLeagues.isEmpty {
                LoadingView(message: "Loading your leagues...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.userLeagues.isEmpty {
                EmptyStateView(
                    title: "No Leagues Joined",
                    message: "You haven't joined any leagues yet. Discover and join leagues to connect with others!",
                    systemImage: "person.3.fill",
                    actionTitle: "Discover Leagues",
                    action: {
                        selectedTab = 0
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.userLeagues) { leagueMember in
                            if let league = leagueMember.league {
                                MyLeagueCard(
                                    league: league,
                                    leagueMember: leagueMember,
                                    onLeave: {
                                        Task {
                                            await viewModel.leaveLeague(leagueId: league.id)
                                        }
                                    }
                                )
                            }
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - League Filters View
struct LeagueFiltersView: View {
    @ObservedObject var viewModel: LeaguesViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("League Type") {
                    Picker("Type", selection: $viewModel.selectedLeagueType) {
                        Text("All Types").tag(LeagueType?.none)
                        ForEach(LeagueType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(LeagueType?.some(type))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Privacy") {
                    Picker("Privacy", selection: $viewModel.selectedPrivacy) {
                        Text("All Privacy Levels").tag(LeaguePrivacy?.none)
                        ForEach(LeaguePrivacy.allCases, id: \.self) { privacy in
                            Label(privacy.displayName, systemImage: privacy.iconName)
                                .tag(LeaguePrivacy?.some(privacy))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    Button("Clear All Filters") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
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

// MARK: - Create League View
struct CreateLeagueView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LeaguesViewModel()
    
    let onLeagueCreated: (League) -> Void
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedType = LeagueType.fitness
    @State private var selectedPrivacy = LeaguePrivacy.public
    @State private var maxMembers: String = ""
    @State private var hasMaxMembers = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("League Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section("League Settings") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(LeagueType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Privacy", selection: $selectedPrivacy) {
                        ForEach(LeaguePrivacy.allCases, id: \.self) { privacy in
                            Label(privacy.displayName, systemImage: privacy.iconName)
                                .tag(privacy)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Member Limit") {
                    Toggle("Set Maximum Members", isOn: $hasMaxMembers)
                    
                    if hasMaxMembers {
                        TextField("Maximum Members", text: $maxMembers)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section {
                    Text(selectedPrivacy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createLeague()
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!hasMaxMembers || !maxMembers.isEmpty)
    }
    
    private func createLeague() {
        let maxMembersInt = hasMaxMembers ? Int(maxMembers) : nil
        
        let leagueData = LeagueCreationData(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            type: selectedType,
            privacy: selectedPrivacy,
            maxMembers: maxMembersInt
        )
        
        Task {
            if let league = await viewModel.createLeague(leagueData) {
                onLeagueCreated(league)
                dismiss()
            }
        }
    }
}

// MARK: - My League Card
struct MyLeagueCard: View {
    let league: League
    let leagueMember: LeagueMember
    let onLeave: () -> Void
    
    @State private var showingLeaveAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(league.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(league.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Label(leagueMember.role.displayName, systemImage: leagueMember.role.iconName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Joined \(leagueMember.joinedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Label(league.type.displayName, systemImage: league.type.iconName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(league.memberCount) members", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(league.challengeCount) challenges", systemImage: "trophy.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                NavigationLink(destination: LeagueDetailView(league: league)) {
                    Text("View Details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if leagueMember.role != .admin {
                    Button("Leave", role: .destructive) {
                        showingLeaveAlert = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .alert("Leave League", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                onLeave()
            }
        } message: {
            Text("Are you sure you want to leave \(league.name)? You'll need to be invited again to rejoin.")
        }
    }
}

// MARK: - League Detail View Placeholder
struct LeagueDetailView: View {
    let league: League
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(league.description)
                    .font(.body)
                
                Text("League Details")
                    .font(.headline)
                
                Text("This is a placeholder for the league detail view.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle(league.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview
#if DEBUG
struct LeaguesListView_Previews: PreviewProvider {
    static var previews: some View {
        LeaguesListView()
    }
}
#endif