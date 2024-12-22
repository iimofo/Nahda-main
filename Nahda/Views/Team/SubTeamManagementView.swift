import SwiftUI

struct SubTeamManagementView: View {
    let team: Team
    @StateObject private var teamViewModel = TeamViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showCreateSubTeam = false
    @State private var isLoading = true
    @State private var selectedSubTeam: Team?
    @State private var showSubTeamOptions = false
    @State private var showDeleteConfirmation = false
    
    var isTeamLeader: Bool {
        authViewModel.currentUser?.id == team.leaderId
    }
    
    var body: some View {
        List {
            Section {
                if isLoading {
                    ProgressView()
                } else if teamViewModel.subTeams.isEmpty {
                    EmptySubTeamsView(showCreate: $showCreateSubTeam)
                } else {
                    ForEach(teamViewModel.subTeams) { subTeam in
                        SubTeamRow(team: subTeam, parentTeam: team)
                            .contextMenu {
                                if isTeamLeader {
                                    Button(role: .destructive) {
                                        selectedSubTeam = subTeam
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete Subteam", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
            } header: {
                HStack {
                    Text("Subteams")
                    Spacer()
                    if isTeamLeader {
                        Button {
                            showCreateSubTeam = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            if !teamViewModel.subTeams.isEmpty {
                Section("Permissions") {
                    NavigationLink {
                        SubTeamPermissionsView(team: team)
                    } label: {
                        Label("Manage Permissions", systemImage: "lock.shield")
                    }
                }
            }
        }
        .navigationTitle("Subteam Management")
        .sheet(isPresented: $showCreateSubTeam) {
            CreateSubTeamView(parentTeam: team)
        }
        .alert("Delete Subteam", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let subTeam = selectedSubTeam {
                    deleteSubTeam(subTeam)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this subteam? This action cannot be undone.")
        }
        .onAppear {
            loadSubTeams()
        }
    }
    
    private func loadSubTeams() {
        isLoading = true
        teamViewModel.fetchSubTeams(for: team.id ?? "") { _ in
            isLoading = false
        }
    }
    
    private func deleteSubTeam(_ subTeam: Team) {
        teamViewModel.deleteSubTeam(subTeam, from: team) { success in
            if success {
                loadSubTeams()
            }
        }
    }
}

struct SubTeamRow: View {
    let team: Team
    let parentTeam: Team
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(team.name)
                        .font(.headline)
                    Text("Led by \(userViewModel.userName(for: team.leaderId))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(team.memberIds.count)")
                    .font(.caption)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Progress indicators
            HStack(spacing: 12) {
                ProgressIndicator(
                    value: Double(team.memberIds.count) / Double(parentTeam.memberIds.count),
                    label: "Team Size",
                    color: .blue
                )
                
                ProgressIndicator(
                    value: 0.7, // Replace with actual task completion rate
                    label: "Tasks",
                    color: .green
                )
            }
        }
        .padding(.vertical, 8)
        .task {
            userViewModel.fetchUser(userId: team.leaderId)
        }
    }
}

struct ProgressIndicator: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * value)
                }
            }
            .frame(height: 4)
            .clipShape(Capsule())
        }
    }
}

struct EmptySubTeamsView: View {
    @Binding var showCreate: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("No Subteams Yet")
                .font(.headline)
            
            Text("Create subteams to better organize your team structure")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showCreate = true
            } label: {
                Text("Create Subteam")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
} 
