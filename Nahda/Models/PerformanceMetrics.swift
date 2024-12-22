import SwiftUI

struct PerformanceMetrics: Codable {
    let userId: String
    let period: DateInterval
    var tasksCompleted: Int
    var totalTimeSpent: TimeInterval
    var averageTaskDuration: TimeInterval
    var onTimeCompletionRate: Double
    var velocityScore: Double
    
    static func calculate(for user: User, tasks: [Task], in period: DateInterval) -> PerformanceMetrics {
        let userTasks = tasks.filter { $0.assignedToId == user.id }
        let completedTasks = userTasks.filter { $0.isCompleted }
        
        let timeSpent = completedTasks.reduce(0.0) { $0 + ($1.finishTime ?? 0) }
        let avgDuration = completedTasks.isEmpty ? 0 : timeSpent / Double(completedTasks.count)
        
        let onTimeTasks = completedTasks.filter { task in
            guard let dueDate = task.dueDate, let completedAt = task.completedAt else { return false }
            return completedAt <= dueDate
        }
        
        let onTimeRate = completedTasks.isEmpty ? 0 : Double(onTimeTasks.count) / Double(completedTasks.count)
        let velocity = calculateVelocity(tasks: completedTasks, period: period)
        
        return PerformanceMetrics(
            userId: user.id ?? "",
            period: period,
            tasksCompleted: completedTasks.count,
            totalTimeSpent: timeSpent,
            averageTaskDuration: avgDuration,
            onTimeCompletionRate: onTimeRate,
            velocityScore: velocity
        )
    }
    
    private static func calculateVelocity(tasks: [Task], period: DateInterval) -> Double {
        // Calculate points completed per week
        let totalPoints = tasks.count // Could be weighted by priority/complexity
        let weeks = period.duration / (7 * 24 * 3600)
        return Double(totalPoints) / weeks
    }
} 
