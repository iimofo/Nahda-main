//
//  TaskViewModel.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// TaskViewModel.swift

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class TaskViewModel: ObservableObject {
    @Published var tasks = [Task]()
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var activityListener: ListenerRegistration?

    func fetchTasks(for teamId: String, completion: @escaping () -> Void = {}) {
        // Remove any existing listener before setting up a new one
        listener?.remove()
        
        print("🔵 Starting fetchTasks for teamId: \(teamId)")
        
        listener = db.collection("tasks")
            .whereField("teamId", isEqualTo: teamId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching tasks: \(error.localizedDescription)")
                    completion()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found in fetchTasks")
                    self.tasks = []
                    completion()
                    return
                }
                
                print("📋 Processing \(documents.count) tasks")
                
                // Process the changes
                if let changes = snapshot?.documentChanges {
                    DispatchQueue.main.async {
                        for change in changes {
                            switch change.type {
                            case .added, .modified:
                                if let task = try? change.document.data(as: Task.self) {
                                    // Update or add task
                                    if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                                        self.tasks[index] = task
                                    } else {
                                        self.tasks.append(task)
                                    }
                                    print("✅ Task updated/added: \(task.id ?? "nil")")
                                }
                            case .removed:
                                if let task = try? change.document.data(as: Task.self) {
                                    self.tasks.removeAll { $0.id == task.id }
                                    print("🗑 Task removed: \(task.id ?? "nil")")
                                }
                            }
                        }
                        
                        // Sort tasks if needed
                        self.tasks.sort { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
                        
                        completion()
                    }
                }
            }
    }
    
    deinit {
        listener?.remove()
        activityListener?.remove()
    }

    func createTask(task: Task, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, "User not authenticated")
            return
        }
        
        do {
            // Create a new document reference first to get the ID
            let docRef = db.collection("tasks").document()
            
            // Create the initial activity
            let activity = TaskActivity(
                id: UUID().uuidString,
                userId: userId,
                action: .created,
                timestamp: Date(),
                details: "Task '\(task.title)' was created"
            )
            
            // Create task with activity log and ID
            var newTask = task
            newTask.id = docRef.documentID  // Set the ID explicitly
            newTask.activityLog = [activity]
            
            var taskData = try Firestore.Encoder().encode(newTask)
            taskData["createdAt"] = FieldValue.serverTimestamp()
            
            try docRef.setData(taskData) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }

    func completeTask(taskId: String, imageUrl: String, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, "User not authenticated")
            return
        }
        
        let taskRef = db.collection("tasks").document(taskId)
        
        // First get the task to calculate finish time
        taskRef.getDocument { [weak self] snapshot, error in
            guard let task = try? snapshot?.data(as: Task.self) else {
                completion(false, "Could not find task")
                return
            }
            
            let completionTime = Date()
            let startTime = task.startedAt ?? completionTime
            let finishTime = completionTime.timeIntervalSince(startTime)
            
            // Create completion activity
            let activity = TaskActivity(
                id: UUID().uuidString,
                userId: userId,
                action: .statusChanged,
                timestamp: completionTime,
                details: "Task was marked as completed"
            )
            
            // Update task with completion data
            taskRef.updateData([
                "isCompleted": true,
                "imageUrl": imageUrl,
                "completedAt": completionTime,
                "finishTime": finishTime,
                "activityLog": FieldValue.arrayUnion([try! Firestore.Encoder().encode(activity)])
            ]) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }

    func addComment(taskId: String, comment: Comment, completion: @escaping (Bool, String?) -> Void) {
        guard !taskId.isEmpty else {
            completion(false, "Invalid task ID")
            return
        }
        
        do {
            let commentRef = db.collection("tasks").document(taskId).collection("comments").document()
            try commentRef.setData(from: comment) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }

    func fetchComments(for taskId: String, completion: @escaping ([Comment]) -> Void) {
        // Add guard to prevent empty taskId
        guard !taskId.isEmpty else {
            print("⚠️ Warning: Attempted to fetch comments with empty taskId")
            completion([])
            return
        }
        
        db.collection("tasks").document(taskId).collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error fetching comments: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No comments found")
                    completion([])
                    return
                }
                
                let comments = documents.compactMap { try? $0.data(as: Comment.self) }
                DispatchQueue.main.async {
                    completion(comments)
                }
            }
    }

    func fetchActivities(for teamId: String, completion: @escaping ([TaskActivity]) -> Void) {
        // Remove any existing listener
        activityListener?.remove()
        
        activityListener = db.collection("tasks")
            .whereField("teamId", isEqualTo: teamId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching activities: \(error.localizedDescription)")
                    // Don't complete with empty array on error, keep existing activities
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                var activities: [TaskActivity] = []
                for document in documents {
                    if let task = try? document.data(as: Task.self),
                       let taskActivities = task.activityLog {
                        activities.append(contentsOf: taskActivities)
                    }
                }
                
                // Sort activities by timestamp, newest first
                activities.sort { $0.timestamp > $1.timestamp }
                
                DispatchQueue.main.async {
                    completion(activities)
                }
            }
    }

    func addActivity(to taskId: String, type: TaskActivityType, details: String, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, "User not authenticated")
            return
        }
        
        let activity = TaskActivity(
            id: UUID().uuidString,
            userId: userId,
            action: type,
            timestamp: Date(),
            details: details
        )
        
        do {
            let encodedActivity = try Firestore.Encoder().encode(activity)
            let taskRef = db.collection("tasks").document(taskId)
            
            taskRef.updateData([
                "activityLog": FieldValue.arrayUnion([encodedActivity])
            ]) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }

    func startWorkSession(taskId: String, userId: String) {
        let taskRef = db.collection("tasks").document(taskId)
        let sessionId = UUID().uuidString
        
        let session: [String: Any] = [
            "id": sessionId,
            "startTime": Date(),
            "userId": userId,
            "duration": 0
        ]
        
        taskRef.updateData([
            "startedAt": Date(),
            "workSessions": FieldValue.arrayUnion([session])
        ])
    }
    
    func endWorkSession(taskId: String, sessionId: String) {
        let taskRef = db.collection("tasks").document(taskId)
        
        taskRef.getDocument { snapshot, error in
            guard let task = try? snapshot?.data(as: Task.self) else { return }
            
            let endTime = Date()
            var totalDuration: TimeInterval = task.timeSpent
            
            if let sessions = task.workSessions,
               let currentSession = sessions.first(where: { $0.id == sessionId }) {
                let duration = endTime.timeIntervalSince(currentSession.startTime)
                totalDuration += duration
                
                let updatedSession: [String: Any] = [
                    "id": sessionId,
                    "startTime": currentSession.startTime,
                    "endTime": endTime,
                    "duration": duration,
                    "userId": currentSession.userId
                ]
                
                // Update task with completed session and new total time
                taskRef.updateData([
                    "completedAt": endTime,
                    "timeSpent": totalDuration,
                    "workSessions": FieldValue.arrayUnion([updatedSession])
                ])
            }
        }
    }
    
    func updateTaskProgress(taskId: String, progress: Double) {
        let taskRef = db.collection("tasks").document(taskId)
        taskRef.updateData([
            "progress": progress
        ])
    }

    func submitForCompletion(taskId: String, imageUrl: String, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, "User not authenticated")
            return
        }
        
        let taskRef = db.collection("tasks").document(taskId)
        
        taskRef.getDocument { snapshot, error in
            guard let task = try? snapshot?.data(as: Task.self) else {
                completion(false, "Could not find task")
                return
            }
            
            // Enhanced security checks
            guard task.status == .inProgress else {
                completion(false, "Task is not in progress")
                return
            }
            
            guard task.assignedToId == userId else {
                completion(false, "Only the assigned user can complete this task")
                return
            }
            
            let completionRequest = CompletionRequest(
                submittedAt: Date(),
                submittedBy: userId,
                imageUrl: imageUrl
            )
            
            do {
                let encodedRequest = try Firestore.Encoder().encode(completionRequest)
                
                taskRef.updateData([
                    "status": TaskStatus.pendingApproval.rawValue,
                    "imageUrl": imageUrl,
                    "completionRequest": encodedRequest
                ]) { error in
                    if let error = error {
                        completion(false, error.localizedDescription)
                    } else {
                        completion(true, nil)
                    }
                }
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }

    func reviewCompletion(taskId: String, approved: Bool, team: Team, rejectionReason: String? = nil, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, "User not authenticated")
            return
        }
        
        let taskRef = db.collection("tasks").document(taskId)
        
        taskRef.getDocument(source: .default) { snapshot, error in
            guard let task = try? snapshot?.data(as: Task.self) else {
                completion(false, "Could not find task")
                return
            }
            
            // Enhanced security checks
            guard task.status == .pendingApproval else {
                completion(false, "Task is not pending approval")
                return
            }
            
            guard team.leaderId == userId else {
                completion(false, "Only team leader can review tasks")
                return
            }
            
            if !approved && (rejectionReason?.isEmpty ?? true) {
                completion(false, "Rejection reason is required")
                return
            }
            
            // Create activity log entry
            let activity = TaskActivity(
                id: UUID().uuidString,
                userId: userId,
                action: approved ? .statusChanged : .updated,
                timestamp: Date(),
                details: approved ? "Task was approved and completed" : "Task was rejected: \(rejectionReason ?? "")"
            )
            
            var updateData: [String: Any] = [
                "status": approved ? TaskStatus.completed.rawValue : TaskStatus.rejected.rawValue,
                "isCompleted": approved
            ]
            
            if approved {
                updateData["completedAt"] = Date()
                if let startTime = task.startedAt {
                    updateData["finishTime"] = Date().timeIntervalSince(startTime)
                }
            } else if let reason = rejectionReason {
                updateData["rejectionReason"] = reason
            }
            
            // Update completion request with review details
            if var request = task.completionRequest {
                request.reviewedAt = Date()
                request.reviewedBy = userId
                if let encodedRequest = try? Firestore.Encoder().encode(request) {
                    updateData["completionRequest"] = encodedRequest
                }
            }
            
            // Add the activity to the update data
            if let encodedActivity = try? Firestore.Encoder().encode(activity) {
                updateData["activityLog"] = FieldValue.arrayUnion([encodedActivity])
            }
            
            taskRef.updateData(updateData) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }

    // Add validation rules
    private func validateTaskReassignment(task: Task, newAssigneeId: String) -> (isValid: Bool, error: String?) {
        // Check if task is in a valid state for reassignment
        if task.status == .completed {
            return (false, "Cannot reassign completed tasks")
        }
        
        if task.status == .pendingApproval {
            return (false, "Cannot reassign tasks pending approval")
        }
        
        // Check if new assignee is different from current
        if task.assignedToId == newAssigneeId {
            return (false, "Task is already assigned to this user")
        }
        
        return (true, nil)
    }

    func reassignTask(taskId: String, newAssigneeId: String, team: Team, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, "User not authenticated")
            return
        }
        
        let taskRef = db.collection("tasks").document(taskId)
        
        taskRef.getDocument { snapshot, error in
            guard let task = try? snapshot?.data(as: Task.self) else {
                completion(false, "Could not find task")
                return
            }
            
            // Security and validation checks
            guard task.teamId == team.id && team.leaderId == userId else {
                completion(false, "Only team leader can reassign tasks")
                return
            }
            
            // Validate reassignment
            let validation = self.validateTaskReassignment(task: task, newAssigneeId: newAssigneeId)
            guard validation.isValid else {
                completion(false, validation.error)
                return
            }
            
            // Create activity log entry with more details
            let activity = TaskActivity(
                id: UUID().uuidString,
                userId: userId,
                action: .updated,
                timestamp: Date(),
                details: "Task reassigned from \(task.assignedToId) to \(newAssigneeId)"
            )
            
            do {
                let encodedActivity = try Firestore.Encoder().encode(activity)
                
                let updateData: [String: Any] = [
                    "assignedToId": newAssigneeId,
                    "activityLog": FieldValue.arrayUnion([encodedActivity]),
                    "lastModified": Date(),
                    "lastModifiedBy": userId
                ]
                
                taskRef.updateData(updateData) { error in
                    if let error = error {
                        completion(false, error.localizedDescription)
                    } else {
                        completion(true, nil)
                    }
                }
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }

    // Add this public method to clean up listeners
    func cleanupListeners() {
        listener?.remove()
        activityListener?.remove()
    }

    func fetchTasksAsync(for teamId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            self.fetchTasks(for: teamId) {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: ())
                }
            }
        }
    }
}


//#Preview {
//    TaskViewModel()
//}
