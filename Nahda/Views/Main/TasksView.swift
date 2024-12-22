import SwiftUI
import Firebase
import FirebaseAuth

struct TasksView: View {
    let tasks: [Task]
    let team: Team
    @ObservedObject var taskViewModel: TaskViewModel
    @State private var isLoading = true
    @State private var selectedTask: Task?
    @State private var showTaskDetail = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading tasks...")
            } else if tasks.isEmpty {
                EmptyTasksView(isLeader: team.leaderId == Auth.auth().currentUser?.uid)
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(tasks) { task in
                            NavigationLink(destination: TaskDetailView(task: task, team: team)) {
                                TaskCard(task: task)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            taskViewModel.fetchTasks(for: team.id ?? "") {
                isLoading = false
            }
        }
        .navigationDestination(isPresented: $showTaskDetail) {
            if let selectedTask = selectedTask {
                TaskDetailView(task: selectedTask, team: team)
            }
        }
    }
}

//struct EnhancedTaskCard: View {
//    let task: Task
//    
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 8) {
//                HStack {
//                    Text(task.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    Spacer()
//                    
//                    PriorityBadge(priority: task.priority)
//                }
//                
//                Text(task.description)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                    .lineLimit(2)
//                
//                HStack(spacing: 15) {
//                    if let dueDate = task.dueDate {
//                        Label(dueDate.formatted(date: .abbreviated, time: .omitted),
//                              systemImage: "calendar")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                    
//                    if task.isCompleted {
//                        Label("Completed", systemImage: "checkmark.circle.fill")
//                            .font(.caption)
//                            .foregroundColor(.green)
//                    }
//                }
//            }
//        }
//        .padding()
//        .background(Color(.secondarySystemGroupedBackground))
//        .cornerRadius(15)
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
//    }
//}

struct PriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color.opacity(0.2))
            .foregroundColor(priority.color)
            .cornerRadius(8)
    }
}

//struct TabButton: View {
//    let title: String
//    let icon: String
//    let isSelected: Bool
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            VStack(spacing: 8) {
//                Image(systemName: icon)
//                    .font(.system(size: 22))
//                Text(title)
//                    .font(.caption)
//            }
//            .foregroundColor(isSelected ? .blue : .gray)
//        }
//    }
//}

struct AnalyticsCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
            
            content
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

//struct ActivityRow: View {
//    let activity: TaskActivity
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(activity.action.rawValue.capitalized)
//                .font(.headline)
//            
//            if let details = activity.details {
//                Text(details)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//            
//            Text(activity.timestamp.formatted())
//                .font(.caption)
//                .foregroundColor(.gray)
//        }
//        .padding(.vertical, 8)
//    }
//} 
