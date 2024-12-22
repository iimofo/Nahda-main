import SwiftUI

struct TaskPriorityBadge: View {
    let priority: TaskPriority
    @State private var isHovered = false
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(priority.color.opacity(isHovered ? 0.3 : 0.2))
            )
            .foregroundColor(priority.color)
            .scaleEffect(isHovered ? 1.05 : 1)
            .shadow(
                color: priority.color.opacity(isHovered ? 0.3 : 0),
                radius: isHovered ? 4 : 0,
                y: isHovered ? 2 : 0
            )
            .onHover { hovering in
                withAnimation(AppAnimation.spring) {
                    isHovered = hovering
                }
            }
    }
}

// Preview
#Preview {
    HStack {
        TaskPriorityBadge(priority: .low)
        TaskPriorityBadge(priority: .medium)
        TaskPriorityBadge(priority: .high)
    }
    .padding()
} 