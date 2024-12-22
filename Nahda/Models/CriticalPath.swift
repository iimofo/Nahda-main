import SwiftUI

struct TaskDependency: Codable {
    let taskId: String
    let dependsOnTaskId: String
    let type: DependencyType
    
    enum DependencyType: String, Codable {
        case finishToStart = "FS"  // Most common: B can't start until A finishes
        case startToStart = "SS"   // B can't start until A starts
        case finishToFinish = "FF" // B can't finish until A finishes
        case startToFinish = "SF"  // B can't finish until A starts
    }
}

class CriticalPathAnalyzer {
    struct PathNode {
        let task: Task
        var earliestStart: TimeInterval = 0
        var earliestFinish: TimeInterval = 0
        var latestStart: TimeInterval = 0
        var latestFinish: TimeInterval = 0
        var slack: TimeInterval = 0
        var dependencies: [TaskDependency] = []
    }
    
    static func analyzeCriticalPath(tasks: [Task], dependencies: [TaskDependency]) -> [Task] {
        var nodes: [String: PathNode] = [:]
        
        // Initialize nodes
        for task in tasks {
            nodes[task.id ?? ""] = PathNode(
                task: task,
                earliestFinish: task.timeSpent
            )
        }
        
        // Forward pass
        for task in tasks {
            guard let taskId = task.id else { continue }
            let deps = dependencies.filter { $0.taskId == taskId }
            
            for dep in deps {
                if let node = nodes[taskId],
                   let depNode = nodes[dep.dependsOnTaskId] {
                    let newStart = depNode.earliestFinish
                    if newStart > node.earliestStart {
                        nodes[taskId]?.earliestStart = newStart
                        nodes[taskId]?.earliestFinish = newStart + task.timeSpent
                    }
                }
            }
        }
        
        // Backward pass and slack calculation
        let maxFinish = nodes.values.map { $0.earliestFinish }.max() ?? 0
        for node in nodes.values {
            var latestFinish = maxFinish
            let deps = dependencies.filter { $0.dependsOnTaskId == node.task.id }
            
            for dep in deps {
                if let succNode = nodes[dep.taskId] {
                    latestFinish = min(latestFinish, succNode.latestStart)
                }
            }
            
            nodes[node.task.id ?? ""]?.latestFinish = latestFinish
            nodes[node.task.id ?? ""]?.latestStart = latestFinish - node.task.timeSpent
            nodes[node.task.id ?? ""]?.slack = latestFinish - node.earliestFinish
        }
        
        // Find critical path (tasks with zero slack)
        return nodes.values
            .filter { $0.slack == 0 }
            .map { $0.task }
            .sorted { $0.startedAt ?? Date() < $1.startedAt ?? Date() }
    }
} 
