//
//  TeamViewModel.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// TeamViewModel.swift

import SwiftUI
import FirebaseFirestore

class TeamViewModel: ObservableObject {
    @Published var teams = [Team]()
    @Published var subTeams = [Team]()
    private var db = Firestore.firestore()
    private var listeners = [ListenerRegistration]()
    
    func inviteMember(email: String, team: Team, completion: @escaping (Bool, String?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("email", isEqualTo: email.lowercased())
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(false, "Error fetching user: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(false, "User not found.")
                    return
                }
                
                if let user = try? documents.first?.data(as: User.self), let userId = user.id {
                    self.addUserToTeam(userId: userId, team: team, completion: completion)
                } else {
                    completion(false, "Failed to parse user data.")
                }
            }
    }

    private func addUserToTeam(userId: String, team: Team, completion: @escaping (Bool, String?) -> Void) {
        if team.memberIds.contains(userId) {
            completion(false, "User is already a team member.")
            return
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let teamRef = db.collection("teams").document(team.id!)
        batch.updateData(["memberIds": FieldValue.arrayUnion([userId])], forDocument: teamRef)
        
        let userRef = db.collection("users").document(userId)
        batch.updateData(["teamIds": FieldValue.arrayUnion([team.id!])], forDocument: userRef)
        
        batch.commit { error in
            if let error = error {
                completion(false, "Error adding user to team: \(error.localizedDescription)")
            } else {
                completion(true, nil)
            }
        }
    }

    func fetchTeams(teamIds: [String], completion: @escaping (Bool) -> Void = { _ in }) {
        guard !teamIds.isEmpty else {
            self.teams = []
            completion(true)
            return
        }

        // Remove existing listeners
        listeners.forEach { $0.remove() }
        listeners.removeAll()

        // Firestore allows a maximum of 10 items in an 'in' query
        let chunks = teamIds.chunked(into: 10)
        var allTeams = Set<Team>() // Use Set to avoid duplicates

        for chunk in chunks {
            let listener = db.collection("teams")
                .whereField(FieldPath.documentID(), in: chunk)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error listening to teams: \(error.localizedDescription)")
                        return
                    }
                    
                    if let documents = snapshot?.documents {
                        let teams = documents.compactMap { try? $0.data(as: Team.self) }
                        DispatchQueue.main.async {
                            // Update allTeams with new data
                            teams.forEach { allTeams.insert($0) }
                            // Convert to array and sort if needed
                            self.teams = Array(allTeams).sorted { $0.name < $1.name }
                        }
                    }
                }
            
            listeners.append(listener)
        }
        
        completion(true)
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
    
    func createTeam(name: String, leaderId: String, completion: @escaping (Bool, String?) -> Void) {
        let teamRef = db.collection("teams").document()
        
        let team = Team(
            name: name,
            leaderId: leaderId,
            memberIds: [leaderId],
            departmentType: .mainTeam,
            parentTeamId: nil,
            subTeamIds: []
        )
        
        let batch = db.batch()
        
        do {
            try batch.setData(from: team, forDocument: teamRef)
            
            let userRef = db.collection("users").document(leaderId)
            batch.updateData([
                "teamIds": FieldValue.arrayUnion([teamRef.documentID])
            ], forDocument: userRef)
            
            batch.commit { [weak self] error in
                if let error = error {
                    print("Error creating team: \(error)")
                    completion(false, error.localizedDescription)
                } else {
                    // Fetch the updated teams instead of manually appending
                    self?.fetchTeams(teamIds: [teamRef.documentID]) { _ in
                        completion(true, nil)
                    }
                }
            }
        } catch {
            print("Error encoding team: \(error)")
            completion(false, error.localizedDescription)
        }
    }

    func createSubTeam(name: String, parentTeamId: String, leaderId: String, completion: @escaping (Bool) -> Void) {
        let teamRef = db.collection("teams").document()
        
        let subTeam = Team(
            name: name,
            leaderId: leaderId,
            memberIds: [leaderId],
            departmentType: .subTeam,
            parentTeamId: parentTeamId,
            subTeamIds: []
        )
        
        do {
            try teamRef.setData(from: subTeam) { error in
                if let error = error {
                    print("Error creating subteam: \(error)")
                    completion(false)
                    return
                }
                
                // Update parent team's subTeamIds
                self.db.collection("teams").document(parentTeamId).updateData([
                    "subTeamIds": FieldValue.arrayUnion([teamRef.documentID])
                ]) { error in
                    if let error = error {
                        print("Error updating parent team: \(error)")
                        completion(false)
                        return
                    }
                    self.fetchTeams(teamIds: [parentTeamId]) { _ in
                        completion(true)
                    }
                }
            }
        } catch {
            print("Error encoding subteam: \(error)")
            completion(false)
        }
    }

    func fetchSubTeams(for parentTeamId: String, completion: @escaping (Bool) -> Void) {
        db.collection("teams")
            .whereField("parentTeamId", isEqualTo: parentTeamId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching subteams: \(error)")
                    completion(false)
                    return
                }
                
                if let documents = snapshot?.documents {
                    self.subTeams = documents.compactMap { document in
                        try? document.data(as: Team.self)
                    }
                    completion(true)
                }
            }
    }

    func removeMember(userId: String, from team: Team, completion: @escaping (Bool, String?) -> Void) {
        guard let teamId = team.id else {
            completion(false, "Invalid team ID")
            return
        }
        
        // Don't allow removing the team leader
        if userId == team.leaderId {
            completion(false, "Cannot remove the team leader")
            return
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Remove user from team's memberIds
        let teamRef = db.collection("teams").document(teamId)
        batch.updateData([
            "memberIds": FieldValue.arrayRemove([userId])
        ], forDocument: teamRef)
        
        // Remove team from user's teamIds
        let userRef = db.collection("users").document(userId)
        batch.updateData([
            "teamIds": FieldValue.arrayRemove([teamId])
        ], forDocument: userRef)
        
        batch.commit { [weak self] error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                // Update local teams array
                DispatchQueue.main.async {
                    if let index = self?.teams.firstIndex(where: { $0.id == teamId }) {
                        var updatedTeam = self?.teams[index]
                        updatedTeam?.memberIds.removeAll { $0 == userId }
                        if let updatedTeam = updatedTeam {
                            self?.teams[index] = updatedTeam
                        }
                    }
                }
                completion(true, nil)
            }
        }
    }

    func deleteSubTeam(_ subTeam: Team, from parentTeam: Team, completion: @escaping (Bool) -> Void) {
        guard let subTeamId = subTeam.id, let parentTeamId = parentTeam.id else {
            completion(false)
            return
        }
        
        let batch = db.batch()
        
        // Delete the subteam
        let subTeamRef = db.collection("teams").document(subTeamId)
        batch.deleteDocument(subTeamRef)
        
        // Update parent team's subTeamIds
        let parentRef = db.collection("teams").document(parentTeamId)
        batch.updateData([
            "subTeamIds": FieldValue.arrayRemove([subTeamId])
        ], forDocument: parentRef)
        
        // Remove team from members' teamIds
        let userUpdates = subTeam.memberIds.map { userId in
            let userRef = db.collection("users").document(userId)
            return batch.updateData([
                "teamIds": FieldValue.arrayRemove([subTeamId])
            ], forDocument: userRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error deleting subteam: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func updateSubTeamPermissions(_ permissions: [String: Any], for teamId: String, completion: @escaping (Bool) -> Void) {
        let teamRef = db.collection("teams").document(teamId)
        
        teamRef.updateData([
            "permissions": permissions
        ]) { error in
            if let error = error {
                print("Error updating permissions: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        var chunks: [[Element]] = []
        for i in stride(from: 0, to: self.count, by: size) {
            let chunk = Array(self[i..<Swift.min(i + size, self.count)])
            chunks.append(chunk)
        }
        return chunks
    }
}

