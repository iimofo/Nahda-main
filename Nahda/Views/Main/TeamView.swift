//
//  TeamView.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// TeamView.swift
import SwiftUI
import Firebase
import FirebaseAuth


struct TeamView: View {
    let team: Team
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject var teamViewModel = TeamViewModel()
    @State private var showCreateTask = false
    @State private var showInviteMember = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var teamMembers: [User] = []
    @State private var teamAnalytics: TeamAnalytics?
    @State private var recentActivity: [TeamActivity] = []
    @State private var isLoading = true
    @Environment(\.colorScheme) var colorScheme
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var listeners: [ListenerRegistration] = []
    @State private var isRefreshing = false
    @State private var selectedTab: TeamViewTab = .tasks
    @State private var showAnalytics = false
    @State private var showCreateSubTeam = false
    @StateObject private var userViewModel = UserViewModel()
    private let db = Firestore.firestore()
    @State private var showTeamMembers = false
    @State private var showExpandingButtons = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @StateObject private var storyViewModel = StoryViewModel()
    @State private var showImageSourceSheet = false
    @State private var showLeaveTeamAlert = false
    @Environment(\.dismiss) private var dismiss

    init(team: Team) {
        self.team = team
        // Initialize ViewModels
        _taskViewModel = StateObject(wrappedValue: TaskViewModel())
        _teamViewModel = StateObject(wrappedValue: TeamViewModel())
    }

    var isTeamLeader: Bool {
        authViewModel.currentUser?.id == team.leaderId
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isLoading {
                ZStack {
                    Color(.systemBackground)
                        .opacity(0.8)
                        .ignoresSafeArea()
                    
                    VStack {
                        TriangleLoader(circleColor: .blue)
                        Text("Loading...")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                }
            }
            
            VStack(spacing: 0) {
                StoriesSection(team: team)
                    .padding(.vertical, 8)
                
                // Custom segmented control
                TeamViewTabBar(selection: $selectedTab)
                
                // Main content
                Group {
                    switch selectedTab {
                    case .tasks:
                        TasksView(
                            tasks: taskViewModel.tasks, 
                            team: team,
                            taskViewModel: taskViewModel
                        )
                        
                    case .activity:
                        ActivityFeedView(team: team)
                        
                    case .analytics:
                        TeamAnalyticsView(team: team, tasks: taskViewModel.tasks)
                    }
                }
                .animation(.default, value: selectedTab)
            }
            
            // Add floating action button with animated position
            if isTeamLeader {
                expandingAddButton
                    .padding(.trailing, showExpandingButtons ? 70 : 16)
                    .padding(.bottom, showExpandingButtons ? 50 : 16)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showExpandingButtons)
            }
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: HStack(spacing: 16) {
                // Leave team button (only for non-leaders)
                if !isTeamLeader {
                    Button(action: { showLeaveTeamAlert = true }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                            .imageScale(.large)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
                
                // Team members button
                Button(action: { showTeamMembers.toggle() }) {
                    Image(systemName: "person.2")
                        .imageScale(.large)
                        .frame(minWidth: 44, minHeight: 44)
                }
                
                // Story button (only for team leader)
                if isTeamLeader {
                    Button(action: { showImageSourceSheet.toggle() }) {
                        Image(systemName: "plus.circle")
                            .imageScale(.large)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
        )
        .task {
            await fetchInitialData()
        }
        .onDisappear {
            cleanupListeners()
        }
        .sheet(isPresented: $showCreateTask) {
            CreateTaskView(team: team)
        }
        .sheet(isPresented: $showInviteMember) {
            InviteMemberView(team: team)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showCreateSubTeam) {
            CreateSubTeamView(parentTeam: team)
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .refreshable {
            await fetchInitialData()
        }
        .sheet(isPresented: $showTeamMembers) {
            TeamMembersView(
                team: team,
                members: sortedTeamMembers,
                isTeamLeader: isTeamLeader,
                onRemoveMember: removeMember,
                onAppear: { fetchMembers() }
            )
        }
        .confirmationDialog(
            "Select Image Source",
            isPresented: $showImageSourceSheet,
            titleVisibility: .visible
        ) {
            Button("Camera") {
                imageSource = .camera
                showImagePicker = true
            }
            
            Button("Photo Library") {
                imageSource = .photoLibrary
                showImagePicker = true
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(
                imageSource: $imageSource,
                selectedImage: $selectedImage
            )
        }
        .onChange(of: selectedImage) { newImage in
            if newImage != nil {
                print("🖼️ New image selected, starting upload...")
                addStory()
            }
        }
        .alert("Leave Team?", isPresented: $showLeaveTeamAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                _Concurrency.Task {
                    await leaveTeam()
                }
            }
        } message: {
            Text("Are you sure you want to leave this team? This action cannot be undone.")
        }
    }

    @ViewBuilder
    private func addTaskButton() -> some View {
        Button(action: {
            showCreateTask.toggle()
        }) {
            Image(systemName: "plus")
        }
    }

    @ViewBuilder
    private func inviteMemberButton() -> some View {
        Button(action: {
            showInviteMember.toggle()
        }) {
            Image(systemName: "person.badge.plus")
        }
    }

    private func fetchInitialData() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await fetchTasks()
            }
            
            group.addTask {
                await fetchTeamMembersAsync()
            }
        }
        
        isLoading = false
    }
    
    private func fetchTasks() async {
        do {
            try await taskViewModel.fetchTasksAsync(for: team.id ?? "")
        } catch {
            print("❌ Error fetching tasks: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    private func fetchTeamMembersAsync() async {
        guard !team.memberIds.isEmpty else { return }
        
        do {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: team.memberIds)
                .getDocuments()
            
            let members = snapshot.documents.compactMap { document in
                try? document.data(as: User.self)
            }
            
            await MainActor.run {
                print("📋 Fetched \(members.count) team members") // Add debug log
                self.teamMembers = members.sorted { $0.name < $1.name } // Sort by name
            }
        } catch {
            await MainActor.run {
                print("❌ Error fetching team members: \(error.localizedDescription)") // Add debug log
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    private func cleanupListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        taskViewModel.cleanupListeners()  // Use the new public method
    }

    private func removeMember(_ member: User) {
        guard let memberId = member.id else { return }
        
        teamViewModel.removeMember(userId: memberId, from: team) { success, error in
            DispatchQueue.main.async {
                if success {
                    withAnimation {
                        // Remove from local array
                        self.teamMembers.removeAll { $0.id == memberId }
                        
                        // Update the user's teamIds
                        if memberId == self.authViewModel.currentUser?.id {
                            // If the removed member is the current user, update their teamIds
                            var updatedUser = self.authViewModel.currentUser
                            updatedUser?.teamIds?.removeAll { $0 == self.team.id }
                            self.authViewModel.currentUser = updatedUser
                            
                            // Fetch teams again for the current user
                            if let teamIds = updatedUser?.teamIds {
                                self.teamViewModel.fetchTeams(teamIds: teamIds) { _ in }
                            }
                        }
                    }
                } else {
                    self.errorMessage = error ?? "Failed to remove member"
                    self.showError = true
                }
            }
        }
    }

    private func refreshData() async {
        await withCheckedContinuation { continuation in
            let db = Firestore.firestore()
            let userIds = team.memberIds
            
            // Clear existing data
            cleanupListeners()
            teamMembers.removeAll()
            
            // Set up listeners for team members
            for userId in userIds {
                let listener = db.collection("users").document(userId)
                    .addSnapshotListener { snapshot, error in
                        if let user = try? snapshot?.data(as: User.self) {
                            DispatchQueue.main.async {
                                var updatedMembers = self.teamMembers
                                updatedMembers.removeAll { $0.id == user.id }
                                updatedMembers.append(user)
                                updatedMembers.sort { $0.name < $1.name }
                                self.teamMembers = updatedMembers
                            }
                        }
                    }
                listeners.append(listener)
            }
            
            // Only resume continuation after initial tasks fetch
            var hasResumed = false
            taskViewModel.fetchTasks(for: team.id ?? "") {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume()
                }
            }
        }
    }

    private var sortedTeamMembers: [User] {
        // Put leader first, then sort others by name
        let leader = teamMembers.first { $0.id == team.leaderId }
        let otherMembers = teamMembers
            .filter { $0.id != team.leaderId }
            .sorted { $0.name < $1.name }
        
        return (leader.map { [$0] } ?? []) + otherMembers
    }

    private func fetchMembers() {
        guard !team.memberIds.isEmpty else { return }
        
        let db = Firestore.firestore()
        team.memberIds.forEach { userId in
            db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    print("❌ Error fetching member: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                if let user = try? snapshot?.data(as: User.self) {
                    DispatchQueue.main.async {
                        var updatedMembers = self.teamMembers
                        updatedMembers.removeAll { $0.id == user.id }
                        updatedMembers.append(user)
                        updatedMembers.sort { $0.name < $1.name }
                        self.teamMembers = updatedMembers
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var expandingAddButton: some View {
        ZStack {
            if isTeamLeader {
                // Invite member button
                ExpandingView(
                    expand: $showExpandingButtons,
                    direction: .left,
                    symbolName: "person.badge.plus",
                    action: { 
                        showExpandingButtons = false
                        showInviteMember.toggle() 
                    }
                )
                
                // View team members button
                ExpandingView(
                    expand: $showExpandingButtons,
                    direction: .top,
                    symbolName: "person.2",
                    action: { 
                        showExpandingButtons = false
                        showTeamMembers.toggle() 
                    }
                )
                
                // Create task button
                ExpandingView(
                    expand: $showExpandingButtons,
                    direction: .bottom,
                    symbolName: "checklist",
                    action: { 
                        showExpandingButtons = false
                        showCreateTask.toggle() 
                    }
                )
                
                // Main plus button
                Circle()
                    .fill(Color.white)
                    .frame(width: 82, height: 82)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                            .rotationEffect(showExpandingButtons ? .degrees(45) : .degrees(0))
                    )
                    .shadow(radius: 8)
                    .animation(.easeOut(duration: 0.25), value: showExpandingButtons)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showExpandingButtons.toggle()
                        }
                    }
            }
        }
    }

    private func addStory() {
        if let image = selectedImage {
            guard let userId = authViewModel.currentUser?.id else {
                print("❌ No current user ID found")
                errorMessage = "User not authenticated"
                showError = true
                return
            }
            
            guard let teamId = team.id else {
                print("❌ No team ID found")
                errorMessage = "Invalid team"
                showError = true
                return
            }
            
            print("🚀 Starting story upload...")
            print("Image size: \(image.size)")
            
            storyViewModel.uploadStory(image: image, teamId: teamId, userId: userId) { success in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Story upload completed successfully")
                        self.selectedImage = nil
                        self.showImagePicker = false
                    } else {
                        print("❌ Story upload failed")
                        self.errorMessage = "Failed to upload story"
                        self.showError = true
                    }
                }
            }
        } else {
            showImageSourceSheet.toggle()
        }
    }

    private func leaveTeam() async {
        guard let userId = Auth.auth().currentUser?.uid,
              let teamId = team.id else { return }
        
        do {
            let batch = db.batch()
            
            // 1. Remove user from team members
            let teamRef = db.collection("teams").document(teamId)
            batch.updateData([
                "memberIds": FieldValue.arrayRemove([userId])
            ], forDocument: teamRef)
            
            // 2. Remove team from user's teams
            let userRef = db.collection("users").document(userId)
            batch.updateData([
                "teamIds": FieldValue.arrayRemove([teamId])
            ], forDocument: userRef)
            
            // 3. Execute batch
            try await batch.commit()
            print("✅ Successfully left team")
            
            // 4. Navigate back to dashboard
            dismiss()
            
        } catch {
            print("❌ Error leaving team: \(error.localizedDescription)")
            errorMessage = "Failed to leave team"
            showError = true
        }
    }
}

// MARK: - Supporting Views
struct TeamOverviewCard: View {
    let team: Team
    let tasks: [Task]
    
    var body: some View {
        VStack(spacing: 15) {
            // Team Stats
            HStack(spacing: 20) {
                StatItem(title: "Members", value: "\(team.memberIds.count)", icon: "person.2.fill", color: .blue)
                Divider()
                    .frame(height: 40)
                StatItem(title: "Tasks", value: "\(tasks.count)", icon: "checklist", color: .green)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
}


struct MemberCard: View {
    let member: User
    let isLeader: Bool
    let isCurrentUserLeader: Bool
    let onRemove: () -> Void
    @State private var showRemoveAlert = false
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(member.name.prefix(1).uppercased())
                            .font(.title3)
                            .bold()
                    )
                
                if isCurrentUserLeader && !isLeader {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showRemoveAlert = true
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .background(
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 20, height: 20)
                                    )
                            }
                            .padding(5)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 60, height: 60)
            
            Text(member.name)
                .font(.subheadline)
                .lineLimit(1)
            
            if isLeader {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .frame(width: 80)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .alert("Remove Member", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onRemove()
            }
        } message: {
            Text("Are you sure you want to remove \(member.name) from the team?")
        }
    }
}


struct TasksList: View {
    let tasks: [Task]
    let team: Team
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(tasks) { task in
                NavigationLink(destination: TaskDetailView(task: task, team: team)) {
                    TaskCard(task: task)
                }
            }
        }
    }
}

struct EmptyTasksView: View {
    let isLeader: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "checklist")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Tasks Yet")
                .font(.headline)
            
            Text(isLeader ? "Create tasks for your team" : "No tasks have been assigned yet")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
    }
}

enum TeamViewTab {
    case tasks
    case activity
    case analytics
}

struct TeamViewTabBar: View {
    @Binding var selection: TeamViewTab
    
    var body: some View {
        HStack(spacing: 20) {
            
            TabButton(title: "Tasks", icon: "checklist", isSelected: selection == .tasks) {
                selection = .tasks
            }

            Divider()
            TabButton(title: "Activity", icon: "clock", isSelected: selection == .activity) {
                selection = .activity
            }

            Divider()
            TabButton(title: "Analytics", icon: "chart.bar", isSelected: selection == .analytics) {
                selection = .analytics
            }
        }
        .frame(width: 350, height: 70)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.bottom, 7)
    }
}

struct TeamAnalyticsView: View {
    let team: Team
    let tasks: [Task]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Completion Rate Card
                AnalyticsCard(title: "Task Completion Rate") {
                    CompletionRateChart(tasks: tasks)
                }
                
                // Burndown Chart
                AnalyticsCard(title: "Sprint Progress") {
                    BurndownChart(
                        tasks: tasks,
                        startDate: Date().addingTimeInterval(-14 * 24 * 3600), // 2 weeks ago
                        endDate: Date()
                    )
                }
                
                // Workload Distribution
                AnalyticsCard(title: "Team Workload") {
                    WorkloadDistributionChart(tasks: tasks, team: team)
                }
                
                // Priority Distribution
                AnalyticsCard(title: "Task Priorities") {
                    PriorityDistributionChart(tasks: tasks)
                }
                
                // Time Tracking
                AnalyticsCard(title: "Time Spent") {
                    TimeTrackingChart(tasks: tasks)
                }
            }
            .padding()
        }
    }
}

struct SubteamsSection: View {
    let team: Team
    @StateObject private var teamViewModel = TeamViewModel()
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subteams")
                .font(.headline)
                .padding(.horizontal)
            
            if isLoading {
                ProgressView()
            } else if teamViewModel.subTeams.isEmpty {
                Text("No subteams yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(teamViewModel.subTeams) { subTeam in
                            NavigationLink(destination: TeamView(team: subTeam)) {
                                SubTeamCard(team: subTeam)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
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
}

struct SubTeamCard: View {
    let team: Team
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(team.name)
                .font(.headline)
            
            HStack {
                Image(systemName: "person.2")
                Text("\(team.memberIds.count) members")
                    .font(.caption)
            }
            .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(isHovered ? 0.1 : 0.05),
                    radius: isHovered ? 8 : 5,
                    y: isHovered ? 4 : 2
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    TeamView(
        team: Team(
            id: "preview-team",
            name: "Preview Team",
            leaderId: "leader-id",
            memberIds: ["member1", "member2"],
            departmentType: .mainTeam,
            parentTeamId: nil,
            subTeamIds: []
        )
    )
    .environmentObject(AuthViewModel())
}
