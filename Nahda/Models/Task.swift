//
//  Task.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// Task.swift
import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseFirestore

struct Task: Identifiable, Codable {
    @DocumentID var id: String?
    var teamId: String
    var title: String
    var description: String
    var assignedToId: String
    var assignedToName: String?
    var imageUrl: String?
    var isCompleted: Bool = false
    
    // Task properties
    var priority: TaskPriority = .medium
    var status: TaskStatus = .inProgress
    var dueDate: Date?
    var dependsOn: [String]?
    var mentions: [String]?
    var activityLog: [TaskActivity]?
    var completionRequest: CompletionRequest?
    var rejectionReason: String?
    
    // Time tracking fields
    var startedAt: Date?
    var completedAt: Date?
    var timeSpent: TimeInterval = 0
    var workSessions: [WorkSession]?
    var finishTime: TimeInterval?
    
    var totalTimeSpent: TimeInterval {
        finishTime ?? timeSpent
    }
    
    var isActive: Bool {
        startedAt != nil && completedAt == nil
    }
    
    // Coding keys
    enum CodingKeys: String, CodingKey {
        case id
        case teamId
        case title
        case description
        case assignedToId
        case assignedToName
        case imageUrl
        case isCompleted
        case priority
        case status
        case dueDate
        case dependsOn
        case mentions
        case activityLog
        case completionRequest
        case rejectionReason
        case startedAt
        case completedAt
        case timeSpent
        case workSessions
        case finishTime
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct TaskActivity: Codable, Identifiable {
    let id: String
    let userId: String
    let action: TaskActivityType
    let timestamp: Date
    let details: String?
}

enum TaskActivityType: String, Codable {
    case created
    case updated
    case statusChanged
    case commented
    case mentioned
    case dependencyAdded
    case dependencyRemoved
    case priorityChanged
    case dueDateChanged
}

struct WorkSession: Codable, Identifiable {
    let id: String
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
    let userId: String
    
    var calculatedDuration: TimeInterval {
        if let end = endTime {
            return end.timeIntervalSince(startTime)
        }
        return duration
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case startTime
        case endTime
        case duration
        case userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 0
        userId = try container.decode(String.self, forKey: .userId)
    }
}

enum TaskStatus: String, Codable {
    case todo = "todo"
    case inProgress = "inProgress"
    case pendingApproval = "pendingApproval"
    case completed = "completed"
    case rejected = "rejected"
    
    var color: Color {
        switch self {
        case .todo: return .gray
        case .inProgress: return .blue
        case .pendingApproval: return .orange
        case .completed: return .green
        case .rejected: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "clock"
        case .pendingApproval: return "hourglass"
        case .completed: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
}

struct CompletionRequest: Codable {
    let submittedAt: Date
    let submittedBy: String
    let imageUrl: String
    var reviewedAt: Date?
    var reviewedBy: String?
}


