import Foundation
import SwiftUI

struct TimeAnalytics {
    let tasks: [Task]
    
    // Performance Metrics
    var averageCompletionTime: TimeInterval {
        let completedTasks = tasks.filter { $0.isCompleted && $0.finishTime != nil }
        guard !completedTasks.isEmpty else { return 0 }
        return completedTasks.reduce(0.0) { $0 + ($1.finishTime ?? 0) } / Double(completedTasks.count)
    }
    
    var completionTimesByPriority: [TaskPriority: TimeInterval] {
        var times: [TaskPriority: [TimeInterval]] = [:]
        
        for task in tasks where task.isCompleted && task.finishTime != nil {
            times[task.priority, default: []].append(task.finishTime!)
        }
        
        return times.mapValues { times in
            times.reduce(0, +) / Double(times.count)
        }
    }
    
    // Prediction Model
    func estimateCompletionTime(for task: Task) -> TimeInterval {
        let similarTasks = tasks.filter {
            $0.isCompleted &&
            $0.finishTime != nil &&
            $0.priority == task.priority
        }
        
        guard !similarTasks.isEmpty else {
            return averageCompletionTime
        }
        
        // Calculate weighted average based on multiple factors
        var totalWeight = 0.0
        var weightedTime = 0.0
        
        for similarTask in similarTasks {
            let weight = calculateTaskSimilarity(task, similarTask)
            weightedTime += (similarTask.finishTime ?? 0) * weight
            totalWeight += weight
        }
        
        return totalWeight > 0 ? weightedTime / totalWeight : averageCompletionTime
    }
    
    private func calculateTaskSimilarity(_ task1: Task, _ task2: Task) -> Double {
        var similarity = 1.0
        
        // Priority match
        if task1.priority == task2.priority {
            similarity *= 1.5
        }
        
        // Description length similarity
        let lengthDiff = abs(Double(task1.description.count - task2.description.count))
        similarity *= 1.0 / (1.0 + lengthDiff / 100.0)
        
        return similarity
    }
    
    // Performance Trends
    func getCompletionTrend() -> CompletionTrend {
        let completedTasks = tasks.filter { $0.isCompleted && $0.finishTime != nil }
            .sorted { ($0.completedAt ?? Date()) < ($1.completedAt ?? Date()) }
        
        guard completedTasks.count >= 2 else { return .stable }
        
        let recentTasks = Array(completedTasks.suffix(5))
        let times = recentTasks.map { $0.finishTime ?? 0 }
        
        let trend = calculateTrend(times)
        return trend < -0.1 ? .improving : (trend > 0.1 ? .slowing : .stable)
    }
    
    private func calculateTrend(_ values: [TimeInterval]) -> Double {
        // Simple linear regression
        let n = Double(values.count)
        let indices = Array(0..<values.count).map(Double.init)
        
        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map(*).reduce(0, +)
        let sumXX = indices.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        return slope
    }
}

enum CompletionTrend {
    case improving
    case stable
    case slowing
    
    var description: String {
        switch self {
        case .improving: return "Getting Faster"
        case .stable: return "Consistent"
        case .slowing: return "Taking Longer"
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.down.right"
        case .stable: return "equal"
        case .slowing: return "arrow.up.right"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .slowing: return .orange
        }
    }
} 
