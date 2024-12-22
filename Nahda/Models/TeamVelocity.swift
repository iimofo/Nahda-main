import SwiftUI

struct TeamVelocity: Codable {
    let teamId: String
    let sprint: Int
    let completedPoints: Int
    let plannedPoints: Int
    let startDate: Date
    let endDate: Date
    
    var completionRate: Double {
        Double(completedPoints) / Double(plannedPoints)
    }
    
    static func calculateCurrentVelocity(team: Team, tasks: [Task], sprintDuration: TimeInterval = 14 * 24 * 3600) -> TeamVelocity {
        let now = Date()
        let sprintStart = now.addingTimeInterval(-sprintDuration)
        
        let sprintTasks = tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= sprintStart && completedAt <= now
        }
        
        let completed = sprintTasks.filter { $0.isCompleted }.count
        let total = sprintTasks.count
        
        return TeamVelocity(
            teamId: team.id ?? "",
            sprint: getCurrentSprint(),
            completedPoints: completed,
            plannedPoints: total,
            startDate: sprintStart,
            endDate: now
        )
    }
    
    private static func getCurrentSprint() -> Int {
        // Calculate current sprint number based on project start date
        let projectStart = Date(timeIntervalSince1970: 0) // Replace with actual project start
        return Int(Date().timeIntervalSince(projectStart) / (14 * 24 * 3600))
    }
} 
