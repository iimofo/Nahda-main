import SwiftUI

enum TimeFrame: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    
    var id: String { rawValue }
    
    var targetHours: Double {
        switch self {
        case .day: return 8
        case .week: return 40
        case .month: return 160
        }
    }
}

struct TimeTrackingChart: View {
    let tasks: [Task]
    private let analytics: TimeAnalytics
    
    private var priorityStats: [TaskPriority: PriorityStatistics] {
        var stats: [TaskPriority: PriorityStatistics] = [:]
        
        for priority in TaskPriority.allCases {
            let priorityTasks = tasks.filter { $0.priority == priority }
            let completedTasks = priorityTasks.filter { $0.isCompleted }
            
            // Calculate total time from finish times
            let totalTime = completedTasks.reduce(0.0) { total, task in
                total + task.totalTimeSpent
            }
            
            // Calculate average time only from completed tasks
            let averageTime = completedTasks.isEmpty ? 0 : 
                totalTime / Double(completedTasks.count)
            
            let activeTasks = priorityTasks.filter { $0.isActive }
            let completionRate = priorityTasks.isEmpty ? 0 : 
                Double(completedTasks.count) / Double(priorityTasks.count)
            
            stats[priority] = PriorityStatistics(
                totalTime: totalTime,
                averageTime: averageTime,
                taskCount: priorityTasks.count,
                completedCount: completedTasks.count,
                activeCount: activeTasks.count,
                completionRate: completionRate
            )
        }
        
        return stats
    }
    
    init(tasks: [Task]) {
        self.tasks = tasks
        self.analytics = TimeAnalytics(tasks: tasks)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Priority Analysis Cards
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    if let stats = priorityStats[priority] {
                        PriorityAnalysisCard(
                            priority: priority,
                            stats: stats
                        )
                    }
                }
                
                // Add new visualization
                TimeVisualizationView(tasks: tasks, analytics: analytics)
                
                // Overall Statistics
                OverallStatsCard(priorityStats: priorityStats)
            }
            .padding()
        }
    }
}

struct PriorityAnalysisCard: View {
    let priority: TaskPriority
    let stats: PriorityStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(priority.color)
                    .frame(width: 12, height: 12)
                Text(priority.rawValue.capitalized)
                    .font(.headline)
                Spacer()
                Text("\(stats.taskCount) tasks")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                StatItem(
                    title: "Average Time",
                    value: formatTime(stats.averageTime),
                    icon: "clock",
                    color: priority.color
                )
                StatItem(
                    title: "Total Time",
                    value: formatTime(stats.totalTime),
                    icon: "hourglass",
                    color: priority.color
                )
                StatItem(
                    title: "Active Tasks",
                    value: "\(stats.activeCount)",
                    icon: "play.circle",
                    color: priority.color
                )
                StatItem(
                    title: "Completed",
                    value: "\(stats.completedCount)/\(stats.taskCount)",
                    icon: "checkmark.circle",
                    color: priority.color
                )
            }
            
            // Progress Bar
            ProgressView(value: stats.completionRate)
                .tint(priority.color)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
    }
}

struct OverallStatsCard: View {
    let priorityStats: [TaskPriority: PriorityStatistics]
    
    private var totalTime: TimeInterval {
        priorityStats.values.reduce(0) { $0 + $1.totalTime }
    }
    
    private var averageTimePerPriority: TimeInterval {
        priorityStats.isEmpty ? 0 : totalTime / Double(priorityStats.count)
    }
    
    private var overallCompletionRate: Double {
        let totalTasks = priorityStats.values.reduce(0) { $0 + $1.taskCount }
        let completedTasks = priorityStats.values.reduce(0) { $0 + $1.completedCount }
        return totalTasks == 0 ? 0 : Double(completedTasks) / Double(totalTasks)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Overall Statistics")
                .font(.headline)
            
            HStack {
                StatBox(
                    title: "Total Time",
                    value: formatTime(totalTime),
                    color: .blue
                )
                StatBox(
                    title: "Avg per Priority",
                    value: formatTime(averageTimePerPriority),
                    color: .green
                )
            }
            
            HStack {
                StatBox(
                    title: "Completion Rate",
                    value: "\(Int(overallCompletionRate * 100))%",
                    color: .purple
                )
                StatBox(
                    title: "Priority Groups",
                    value: "\(priorityStats.count)",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(value)
                .font(.subheadline)
                .bold()
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title3)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct PriorityStatistics {
    let totalTime: TimeInterval
    let averageTime: TimeInterval
    let taskCount: Int
    let completedCount: Int
    let activeCount: Int
    let completionRate: Double
}

private func formatTime(_ interval: TimeInterval) -> String {
    let totalMinutes = Int(interval) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return "\(hours)h \(minutes)m"
} 
