//
//  User.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//

// User.swift
import SwiftUI
import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var teamIds: [String]?
    var lastActive: Date?
    var isOnline: Bool?
    var status: UserStatus = .offline
    var activityHistory: [UserActivity]?
    
    enum UserStatus: String, Codable {
        case online
        case away
        case offline
        case busy
        
        var color: Color {
            switch self {
            case .online: return .green
            case .away: return .orange
            case .offline: return .gray
            case .busy: return .red
            }
        }
    }
}

struct UserActivity: Codable, Identifiable {
    let id: String
    let type: ActivityType
    let timestamp: Date
    let details: String
    let teamId: String?
    let taskId: String?
    
    enum ActivityType: String, Codable {
        case login
        case logout
        case taskCreated
        case taskCompleted
        case taskAssigned
        case teamJoined
        case teamCreated
        case commentAdded
    }
}
