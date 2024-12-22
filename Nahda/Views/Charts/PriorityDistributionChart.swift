import SwiftUI

struct PriorityDistributionChart: View {
    let tasks: [Task]
    
    private var priorityCounts: [TaskPriority: Int] {
        Dictionary(grouping: tasks, by: { $0.priority })
            .mapValues { $0.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(TaskPriority.allCases, id: \.self) { priority in
                HStack {
                    Text(priority.rawValue.capitalized)
                    Spacer()
                    Text("\(priorityCounts[priority, default: 0])")
                        .foregroundColor(priority.color)
                }
            }
        }
    }
} 
