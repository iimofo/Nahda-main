//
//  DashboardView.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// DashboardView.swift

import SwiftUI
import Firebase
import FirebaseFirestore

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var teamViewModel = TeamViewModel()
    @StateObject var taskViewModel = TaskViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var viewModel = DashboardViewModel()
    
    @State private var showCreateTeam = false
    @State private var selectedTab = 0
    
    var leadingTeams: [Team] {
        teamViewModel.teams.filter { $0.leaderId == authViewModel.currentUser?.id }
    }
    
    var memberTeams: [Team] {
        teamViewModel.teams.filter { $0.leaderId != authViewModel.currentUser?.id }
    }
    
    private func handleTeamRemoval(_ team: Team) async {
        await viewModel.removeTeam(team)
        await refreshData()
    }
    
    var body: some View {
        NavigationView {
            DashboardContent(
                viewModel: viewModel,
                teamViewModel: teamViewModel,
                authViewModel: authViewModel,
                selectedTab: $selectedTab,
                showCreateTeam: $showCreateTeam,
                leadingTeams: leadingTeams,
                memberTeams: memberTeams,
                onRefresh: refreshData
            )
            .navigationTitle("Dashboard")
            .navigationBarItems(
                leading: SignOutButton(),
                trailing: CreateTeamButton(showCreateTeam: $showCreateTeam)
            )
            .alert(
                "Remove Team",
                isPresented: $viewModel.showRemoveTeamAlert,
                actions: {
                    Button("Cancel", role: .cancel) { }
                    Button("Remove", role: .destructive) {
                        if let team = viewModel.teamToRemove {
                            _Concurrency.Task {
                                await handleTeamRemoval(team)
                            }
                        }
                    }
                },
                message: {
                    Text("Are you sure you want to remove this team? This action cannot be undone and will remove all team data including tasks and member associations.")
                }
            )
        }
        .onAppear {
            fetchInitialData()
        }
        .onChange(of: authViewModel.currentUser?.teamIds) { _ in
            fetchInitialData()
        }
        .onChange(of: teamViewModel.teams) { _ in
            fetchInitialData()
        }
    }
    
    // MARK: - Data Management
    private func fetchInitialData() {
        viewModel.isLoading = true
        
        guard let currentUser = authViewModel.currentUser else {
            viewModel.isLoading = false
            teamViewModel.teams = []
            return
        }
        
        // If user has no teams, don't try to fetch
        guard let teamIds = currentUser.teamIds, !teamIds.isEmpty else {
            viewModel.isLoading = false
            teamViewModel.teams = []
            return
        }
        
        // Create a dispatch group to coordinate multiple fetches
        let group = DispatchGroup()
        var fetchErrors: [String] = []
        
        // 1. Fetch teams first
        group.enter()
        teamViewModel.fetchTeams(teamIds: teamIds) { success in
            if !success {
                fetchErrors.append("Failed to fetch teams")
            }
            group.leave()
        }
        
        // 2. Handle completion
        group.notify(queue: .main) {
            // After teams are fetched, fetch tasks
            if let firstTeam = self.leadingTeams.first ?? self.memberTeams.first {
                self.taskViewModel.fetchTasks(for: firstTeam.id ?? "") {
                    self.viewModel.isLoading = false
                }
            } else {
                self.viewModel.isLoading = false
            }
            
            if !fetchErrors.isEmpty {
                self.viewModel.errorMessage = fetchErrors.joined(separator: "\n")
                self.viewModel.showError = true
            }
        }
    }
    
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            guard let currentUser = authViewModel.currentUser,
                  let teamIds = currentUser.teamIds else {
                continuation.resume()
                return
            }
            
            teamViewModel.fetchTeams(teamIds: teamIds) { success in
                if success {
                    if let firstTeam = leadingTeams.first ?? memberTeams.first {
                        taskViewModel.fetchTasks(for: firstTeam.id ?? "") {
                            continuation.resume()
                        }
                    } else {
                        continuation.resume()
                    }
                } else {
                    viewModel.showError = true
                    viewModel.errorMessage = "Failed to refresh data"
                    continuation.resume()
                }
            }
        }
    }
}

// Break out the content into a separate view
struct DashboardContent: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var teamViewModel: TeamViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var selectedTab: Int
    @Binding var showCreateTeam: Bool
    let leadingTeams: [Team]
    let memberTeams: [Team]
    let onRefresh: () async -> Void
    
    private func handleTeamRemoval(_ team: Team) async {
        await viewModel.removeTeam(team)
        await onRefresh()
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                LoadingView("Loading teams...")
            } else {
                VStack(spacing: 24) {
                    WelcomeSection(userName: authViewModel.currentUser?.name ?? "User")
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground).opacity(0.8))
                                .blur(radius: 0.5)
                        )
                        .padding(.horizontal)
                    
                    StatsSection(leadingTeams: leadingTeams, memberTeams: memberTeams)
                        .padding(.horizontal)
                    
                    TeamsSection(
                        selectedTab: $selectedTab,
                        leadingTeams: leadingTeams,
                        memberTeams: memberTeams,
                        viewModel: viewModel,
                        authViewModel: authViewModel
                    )
                }
                .padding(.vertical)
            }
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            _Concurrency.Task {
                await onRefresh()
            }
        }
        .sheet(isPresented: $showCreateTeam) {
            CreateTeamView()
                .environmentObject(authViewModel)
                .environmentObject(teamViewModel)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert(
            "Remove Team",
            isPresented: $viewModel.showRemoveTeamAlert,
            actions: {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    if let team = viewModel.teamToRemove {
                        _Concurrency.Task {
                            await handleTeamRemoval(team)
                        }
                    }
                }
            },
            message: {
                Text("Are you sure you want to remove this team? This action cannot be undone and will remove all team data including tasks and member associations.")
            }
        )
    }
}

// Break out the stats section into a separate view
struct StatsSection: View {
    let leadingTeams: [Team]
    let memberTeams: [Team]
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Teams Led",
                value: "\(leadingTeams.count)",
                trend: "+\(leadingTeams.count) active",
                icon: "crown.fill",
                color: .orange
            )
            
            StatCard(
                title: "Member Of",
                value: "\(memberTeams.count)",
                trend: "\(memberTeams.count) collaborations",
                icon: "person.2.fill",
                color: .green
            )
        }
    }
}

// Break out the teams section into a separate view
struct TeamsSection: View {
    @Binding var selectedTab: Int
    let leadingTeams: [Team]
    let memberTeams: [Team]
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            CustomTabBar(selectedTab: $selectedTab)
            
            TeamsGrid(
                teams: selectedTab == 0 ? leadingTeams : memberTeams,
                isLeadingTeams: selectedTab == 0,
                viewModel: viewModel,
                authViewModel: authViewModel
            )
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Teams I Lead",
                icon: "crown.fill",
                isSelected: selectedTab == 0
            ) {
                withAnimation { selectedTab = 0 }
            }
            Spacer()
            Divider()
            Spacer()
            TabButton(
                title: "Member Teams",
                icon: "person.2.fill",
                isSelected: selectedTab == 1
            ) {
                withAnimation { selectedTab = 1 }
            }
        }
        .padding(.horizontal)
    }
}

struct TeamsGrid: View {
    let teams: [Team]
    let isLeadingTeams: Bool
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 16
        ) {
            ForEach(teams) { team in
                NavigationLink(destination: TeamView(team: team)) {
                    EnhancedTeamCard(team: team)
                        .environmentObject(viewModel)
                        .environmentObject(authViewModel)
                }
            }
        }
        .padding(.horizontal)
        
        if teams.isEmpty {
            EnhancedEmptyStateView(isLeadingTeams: isLeadingTeams)
        }
    }
}

struct EnhancedTeamCard: View {
    let team: Team
    @State private var isHovered = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var isTeamLeader: Bool {
        authViewModel.currentUser?.id == team.leaderId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Team Icon
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(team.name.prefix(1).uppercased())
                            .font(.title2.bold())
                            .foregroundColor(.blue)
                    )
                
                Spacer()
                
                // Remove team button (only for team leader)
                if isTeamLeader {
                    Button {
                        viewModel.teamToRemove = team
                        viewModel.showRemoveTeamAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44) // Apple's minimum touch target size
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(team.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "person.2")
                    Text("\(team.memberIds.count) members")
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(isHovered ? 0.1 : 0.05),
                    radius: isHovered ? 10 : 5,
                    y: isHovered ? 5 : 2
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
            .foregroundColor(isSelected ? .white : .gray)
        }
    }
}

struct EnhancedEmptyStateView: View {
    let isLeadingTeams: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isLeadingTeams ? "crown.fill" : "person.2.fill")
                .font(.system(size: 50))
                .foregroundColor(isLeadingTeams ? .orange : .blue)
                .padding()
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .shadow(radius: 5)
                )
            
            Text(isLeadingTeams ? "No Teams Led" : "Not a Member Yet")
                .font(.title2.bold())
            
            Text(isLeadingTeams ? "Create a team to get started" : "Join teams to collaborate")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding()
    }
}

// Add these supporting views back
struct WelcomeSection: View {
    let userName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome")
                .font(.title2)
                .foregroundColor(.gray)
            Text(userName)
                .font(.title)
                .bold()
                .foregroundStyle(.brown)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let trend: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(trend)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SignOutButton: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Button(action: {
            authViewModel.signOut()
        }) {
            Text("Sign Out")
                .foregroundColor(.red)
        }
    }
}

struct CreateTeamButton: View {
    @Binding var showCreateTeam: Bool
    
    var body: some View {
        Button(action: {
            showCreateTeam.toggle()
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
        }
    }
}


#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
}
