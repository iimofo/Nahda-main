//
//  TaskDetailView.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// TaskDetailView.swift

import SwiftUI
import Firebase
import FirebaseAuth


struct TaskDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var taskViewModel = TaskViewModel()
    let task: Task
    let team: Team
    @State private var taskState: TaskState
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showRejectDialog = false
    @State private var rejectionReason = ""
    @State private var showCompletionAnimation = false
    @State private var taskListener: ListenerRegistration?
    
    // Add computed property for safe taskId
    private var taskId: String {
        let id = task.id ?? ""
        if id.isEmpty {
            print("⚠️ Task ID is empty in TaskDetailView")
        }
        return id
    }
    
    @State private var showImagePicker = false
    @State private var showImageSourceDialog = false
    @State private var selectedImage: UIImage?
    @State private var commentText = ""
    @State private var comments = [Comment]()
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private var isTeamLeader: Bool {
        authViewModel.currentUser?.id == team.leaderId
    }
    
    private var isAssignedUser: Bool {
        authViewModel.currentUser?.id == task.assignedToId
    }
    
    @State private var showReassignSheet = false
    @State private var selectedMemberId: String?
    @State private var teamMembers: [User] = []
    
    @State private var showDinoGame = false
    @State private var gameScore: Int = 0
    
    init(task: Task, team: Team) {
        print("📝 Initializing TaskDetailView with task ID: \(task.id ?? "nil")")
        self.task = task
        self.team = team
        _taskState = State(initialValue: TaskState(
            isCompleted: task.isCompleted,
            imageUrl: task.imageUrl,
            status: task.status
        ))
    }

    private func setupTaskListener() {
        guard !taskId.isEmpty else { return }
        
        let db = Firestore.firestore()
        taskListener = db.collection("tasks").document(taskId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("🔴 Error listening to task: \(error.localizedDescription)")
                    return
                }
                
                if let updatedTask = try? snapshot?.data(as: Task.self) {
                    print("✅ Task update received: Status = \(updatedTask.status.rawValue)")
                    DispatchQueue.main.async {
                        // Store previous status
                        let previousStatus = self.taskState.status
                        
                        // Update task state
                        self.taskState = TaskState(
                            isCompleted: updatedTask.isCompleted,
                            imageUrl: updatedTask.imageUrl,
                            status: updatedTask.status
                        )
                        
                        // Only dismiss if the status just changed to completed
                        if updatedTask.status == .completed && previousStatus != .completed {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.dismiss()
                            }
                        }
                        
                        // Refresh comments if needed
                        if updatedTask.status != previousStatus {
                            self.fetchComments()
                        }
                    }
                }
            }
    }

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(task.title)
                    .font(.title)
                    .bold()

                Text(task.description)

                TaskStatusBadge(status: task.status)

                AssignedUserBadge(
                    isCurrentUser: isAssignedUser,
                    assignedToId: task.assignedToId
                )

//                if task.status == .inProgress && isAssignedUser {
//                    WorkSessionView(task: task, taskViewModel: taskViewModel)
//                        .padding()
//                        .background(Color(.secondarySystemGroupedBackground))
//                        .cornerRadius(15)
//                }

                if let imageUrl = taskState.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .scaledToFit()
                    .cornerRadius(10)
                }

                if task.status == .inProgress && isAssignedUser {
                    SubmitCompletionButton(
                        showImageSourceDialog: $showImageSourceDialog,
                        showImagePicker: $showImagePicker,
                        imageSource: $imageSource,
                        isCameraAvailable: isCameraAvailable
                    )
                } else if task.status == .inProgress && !isAssignedUser {
                    NotAssignedWarning()
                }

                if task.status == .pendingApproval && isTeamLeader {
                    VStack(spacing: 16) {
                        DragToApproveButton {
                            approveTask()
                        }
                        
                        Button(action: {
                            showRejectDialog = true
                        }) {
                            Text("Reject Task")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }

                if task.status == .rejected, let reason = task.rejectionReason {
                    RejectionNote(reason: reason)
                }

                if isTeamLeader {
                    ReassignButton(
                        showReassignSheet: $showReassignSheet
                    )
                }

                if !task.isCompleted && isAssignedUser {
                    Section {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                    .foregroundColor(.blue)
                                Text("Need a Break?")
                                    .font(.headline)
                                Spacer()
                                if gameScore > 0 {
                                    Text("High Score: \(gameScore)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Button(action: {
                                showDinoGame = true
                            }) {
                                HStack {
                                    Image(systemName: "figure.run")
                                        .font(.title2)
                                    Text("Play Dino Runner")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                            }
                            
                            Text("Take a quick break to refresh your mind")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(12)
                    }
                }

                Text("Comments")
                    .font(.headline)

                ForEach(comments) { comment in
                    VStack(alignment: .leading) {
                        Text(comment.content)
                        Text(comment.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                }

                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Send") {
                        addComment()
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .onAppear {
            print("🔍 TaskDetailView appeared with task ID: \(taskId)")
            guard !taskId.isEmpty else {
                print("⚠️ Warning: Task has no ID")
                showError = true
                errorMessage = "Invalid task: Missing ID"
                return
            }
            fetchComments()
            fetchTeamMembers()
            setupTaskListener()
        }
        .onDisappear {
            taskListener?.remove()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imageSource) {
                if selectedImage != nil {
                    uploadImage()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .alert("Reject Task", isPresented: $showRejectDialog) {
            TextField("Reason for rejection", text: $rejectionReason)
            Button("Cancel", role: .cancel) {
                rejectionReason = ""
            }
            Button("Reject", role: .destructive) {
                rejectTask(reason: rejectionReason)
                rejectionReason = ""
            }
        } message: {
            Text("Please provide a reason for rejecting this task")
        }
        .confirmationDialog("Choose Image Source", isPresented: $showImageSourceDialog) {
            if isCameraAvailable {
                Button("Take Photo") {
                    imageSource = .camera
                    showImagePicker = true
                }
            }
            Button("Choose from Library") {
                imageSource = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showReassignSheet) {
            ReassignmentSheet(
                task: task,
                teamMembers: teamMembers,
                selectedMemberId: $selectedMemberId,
                onReassign: reassignTask
            )
        }
        .overlay {
            if showCompletionAnimation {
                TaskCompletionAnimation(isShowing: $showCompletionAnimation) {
                    // Just dismiss the animation
                    showCompletionAnimation = false
                }
            }
        }
        .fullScreenCover(isPresented: $showDinoGame) {
            DinoGameView()
                .edgesIgnoringSafeArea(.all)
        }
    }

    private func fetchComments() {
        guard !taskId.isEmpty else { return }
        
        taskViewModel.fetchComments(for: taskId) { fetchedComments in
            DispatchQueue.main.async {
                self.comments = fetchedComments
            }
        }
    }

    private func addComment() {
        print("💬 Attempting to add comment for task ID: \(taskId)")
        guard !taskId.isEmpty else {
            showError = true
            errorMessage = "Cannot add comment: Invalid task ID"
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let comment = Comment(userId: userId, content: commentText, timestamp: Date())
        
        taskViewModel.addComment(taskId: taskId, comment: comment) { success, error in
            DispatchQueue.main.async {
                if success {
                    commentText = ""
                    fetchComments()
                } else {
                    showError = true
                    errorMessage = error ?? "Failed to add comment"
                }
            }
        }
    }

    private func uploadImage() {
        guard let image = selectedImage else { return }
        
        ImageUploader.uploadImage(image) { result in
            switch result {
            case .success(let url):
                taskViewModel.submitForCompletion(taskId: taskId, imageUrl: url) { success, error in
                    if success {
                        taskState.imageUrl = url
                    } else {
                        showError = true
                        errorMessage = error ?? "Failed to submit task"
                    }
                }
            case .failure(let error):
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }

    private func approveTask() {
        // First show the animation
        showCompletionAnimation = true
        
        // Directly approve the task
        taskViewModel.reviewCompletion(taskId: taskId, approved: true, team: team) { success, error in
            if !success {
                DispatchQueue.main.async {
                    showError = true
                    errorMessage = error ?? "Failed to approve task"
                }
            }
        }
    }

    private func rejectTask(reason: String) {
        taskViewModel.reviewCompletion(taskId: taskId, approved: false, team: team, rejectionReason: reason) { success, error in
            if !success {
                showError = true
                errorMessage = error ?? "Failed to reject task"
            }
        }
    }

    private func fetchTeamMembers() {
        let db = Firestore.firestore()
        team.memberIds.forEach { userId in
            db.collection("users").document(userId).getDocument { snapshot, error in
                if let user = try? snapshot?.data(as: User.self) {
                    DispatchQueue.main.async {
                        teamMembers.append(user)
                    }
                }
            }
        }
    }

    private func reassignTask(to userId: String) {
        taskViewModel.reassignTask(taskId: taskId, newAssigneeId: userId, team: team) { success, error in
            if !success {
                showError = true
                errorMessage = error ?? "Failed to reassign task"
            }
            showReassignSheet = false
        }
    }
}

// Add this struct to hold task state
struct TaskState: Equatable {
    var isCompleted: Bool
    var imageUrl: String?
    var status: TaskStatus
    
    static func == (lhs: TaskState, rhs: TaskState) -> Bool {
        lhs.isCompleted == rhs.isCompleted &&
        lhs.imageUrl == rhs.imageUrl &&
        lhs.status == rhs.status
    }
}

// Supporting Views
struct TaskStatusBadge: View {
    let status: TaskStatus
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
            Text(status.rawValue.capitalized)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ApprovalButtons: View {
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onApprove) {
                Label("Approve", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            
            Button(action: onReject) {
                Label("Reject", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
}

struct RejectionNote: View {
    let reason: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Rejection Reason", systemImage: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(reason)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Add SubmitCompletionButton
struct SubmitCompletionButton: View {
    @Binding var showImageSourceDialog: Bool
    @Binding var showImagePicker: Bool
    @Binding var imageSource: UIImagePickerController.SourceType
    let isCameraAvailable: Bool
    
    var body: some View {
        Button(action: {
            showImageSourceDialog = true
        }) {
            HStack {
                Image(systemName: "camera.fill")
                Text("Submit for Completion")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

// Add these new supporting views
struct AssignedUserBadge: View {
    let isCurrentUser: Bool
    let assignedToId: String
    
    var body: some View {
        HStack {
            Image(systemName: "person.fill")
            Text(isCurrentUser ? "Assigned to you" : "Assigned to \(assignedToId)")
                .font(.subheadline)
        }
        .foregroundColor(isCurrentUser ? .blue : .gray)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct NotAssignedWarning: View {
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
            Text("Only the assigned user can complete this task")
        }
        .foregroundColor(.orange)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ReassignButton: View {
    @Binding var showReassignSheet: Bool
    
    var body: some View {
        Button(action: { showReassignSheet = true }) {
            HStack {
                Image(systemName: "person.2.arrow.trianglehead.counterclockwise")
                Text("Reassign Task")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
    }
}

struct ReassignmentSheet: View {
    let task: Task
    let teamMembers: [User]
    @Binding var selectedMemberId: String?
    let onReassign: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    private var filteredMembers: [User] {
        if searchText.isEmpty {
            return teamMembers
        }
        return teamMembers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Current assignee section
                if let currentAssignee = teamMembers.first(where: { $0.id == task.assignedToId }) {
                    CurrentAssigneeSection(member: currentAssignee)
                }
                
                // Members list
                List {
                    ForEach(filteredMembers) { member in
                        if member.id != task.assignedToId {
                            MemberSelectionRow(
                                member: member,
                                isSelected: selectedMemberId == member.id,
                                isCurrentAssignee: false
                            )
                            .onTapGesture {
                                selectedMemberId = member.id
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Reassign Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Reassign") {
                    if let memberId = selectedMemberId {
                        onReassign(memberId)
                    }
                }
                .disabled(selectedMemberId == nil)
                .foregroundColor(selectedMemberId == nil ? .gray : .blue)
            )
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search members", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct CurrentAssigneeSection: View {
    let member: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Currently Assigned To")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(member.name.prefix(1).uppercased())
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading) {
                    Text(member.name)
                        .font(.headline)
                    Text("Current Assignee")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "person.fill.checkmark")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct MemberSelectionRow: View {
    let member: User
    let isSelected: Bool
    let isCurrentAssignee: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(member.name)
                if isCurrentAssignee {
                    Text("Current Assignee")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
    }
}

//#Preview {
//    TaskDetailView()
//}
