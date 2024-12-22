//
//  Team.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// Team.swift

import Foundation
import FirebaseFirestore

struct Team: Identifiable, Codable, Hashable {
    @DocumentID private(set) var id: String?
    var name: String
    var leaderId: String
    var memberIds: [String]
    var departmentType: DepartmentType
    var parentTeamId: String?
    var subTeamIds: [String]?
    
    enum DepartmentType: String, Codable {
        case mainTeam
        case subTeam
    }
    
    // Add Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Team, rhs: Team) -> Bool {
        lhs.id == rhs.id
    }
}

// Add extension for dictionary conversion
extension Team {
    var dictionary: [String: Any] {
        [
            "name": name,
            "leaderId": leaderId,
            "memberIds": memberIds,
            "departmentType": departmentType.rawValue,
            "parentTeamId": parentTeamId as Any,
            "subTeamIds": subTeamIds as Any
        ]
    }
}
