import SwiftUI

struct EnhancedTaskCard: View {
    let task: Task
    @State private var isHovered = false
    @State private var isAppearing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                PriorityBadge(priority: task.priority)
                    .scaleEffect(isHovered ? 1.1 : 1)
            }
            
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            HStack(spacing: 15) {
                if let dueDate = task.dueDate {
                    Label(dueDate.formatted(date: .abbreviated, time: .omitted),
                          systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
//                if task.isCompleted {
//                    Label("Completed", systemImage: "checkmark.circle.fill")
//                        .font(.caption)
//                        .foregroundColor(.blue)
//                }
                
                TaskStatusBadge(status: task.status)
                    .scaleEffect(isHovered ? 1.1 : 1)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(
                    color: .black.opacity(isHovered ? 0.1 : 0.05),
                    radius: isHovered ? 8 : 5,
                    y: isHovered ? 4 : 2
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1)
        .onHover { hovering in
            withAnimation(AppAnimation.spring) {
                isHovered = hovering
            }
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(AppAnimation.Delays.staggered(0))) {
                isAppearing = true
            }
        }
        .animatedVisibility(isVisible: isAppearing)
    }
}

// Preview
#Preview {
    EnhancedTaskCard(
        task: Task(
            id: "test-task-1",
            teamId: "test",
            title: "Sample Task",
            description: "This is a sample task description",
            assignedToId: "user1",
            priority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )
    )
    .padding()
} 
