import SwiftUI

struct TeamAnalytics: Codable {
    let teamId: String
    var completionRate: Double
    var averageTaskDuration: TimeInterval
    var memberPerformance: [String: Double]
    var taskDistribution: [TaskStatus: Int]
    // Add more analytics fields as needed
} 
