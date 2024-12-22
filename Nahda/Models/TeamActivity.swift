import SwiftUI

struct TeamActivity: Codable, Identifiable {
    let id: String
    let teamId: String
    let userId: String
    let activityType: TeamActivityType
    let timestamp: Date
    let details: String
    
    enum TeamActivityType: String, Codable {
        case memberJoined
        case memberLeft
        case taskCreated
        case taskCompleted
        case subteamCreated
        // Add more activity types as needed
    }
} 
