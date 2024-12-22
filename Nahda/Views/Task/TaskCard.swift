import SwiftUI

struct TaskCard: View {
    let task: Task
    var userName: String? = nil
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    
    private var statusColor: Color {
        task.status.color.opacity(colorScheme == .dark ? 0.8 : 0.9)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                // Status Icon
                Image(systemName: task.status.icon)
                    .foregroundColor(statusColor)
                    .font(.system(size: 16, weight: .semibold))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                TaskPriorityBadge(priority: task.priority)
            }
            
            // Metadata
            HStack(spacing: 16) {
                // Due Date
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(formatDate(dueDate))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Assignee
                if !task.assignedToId.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.system(size: 12))
                        Text(userName ?? task.assignedToId)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress Indicator (if applicable)
                if task.status == .inProgress {
                    ProgressView(value: 0.6)
                        .progressViewStyle(.linear)
                        .frame(width: 60)
                        .tint(.blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                .shadow(
                    color: Color.black.opacity(isHovered ? 0.1 : 0.05),
                    radius: isHovered ? 8 : 4,
                    y: isHovered ? 4 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    statusColor.opacity(isHovered ? 0.3 : 0.1),
                    lineWidth: 1
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.01 : 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// Preview
//struct TaskCard_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack(spacing: 16) {
//            TaskCard(
//                task: Task(
//                    teamId: "team1",
//                    title: "Design New Feature",
//                    description: "Create wireframes and mockups for the new dashboard interface",
//                    assignedToId: "user1",
//                    assignedToName: "John Doe",
//                    priority: .high,
//                    status: .inProgress,
//                    dueDate: Date().addingTimeInterval(86400 * 3)
//                ),
//                onTap: {}
//            )
//            
//            TaskCard(
//                task: Task(
//                    teamId: "team1",
//                    title: "Bug Fix",
//                    description: "Fix authentication issue in login screen",
//                    assignedToId: "user2",
//                    assignedToName: "Jane Smith",
//                    priority: .medium,
//                    status: .todo,
//                    dueDate: Date().addingTimeInterval(86400)
//                ),
//                onTap: {}
//            )
//        }
//        .padding()
//    }
//} 
