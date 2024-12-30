import SwiftUI
import FirebaseFirestore

class DashboardViewModel: ObservableObject {
    @Published var teamAnalytics: [String: TeamAnalytics] = [:]
    @Published var teamActivities: [String: [TeamActivity]] = [:]
    @Published var isLoading = true
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showRemoveTeamAlert = false
    @Published var teamToRemove: Team?
    
    private let db = Firestore.firestore()
    
    func removeTeam(_ team: Team) async {
        guard let teamId = team.id else {
            errorMessage = "Invalid team ID"
            showError = true
            return
        }
        
        do {
            let batch = db.batch()
            
            // Delete team document
            let teamRef = db.collection("teams").document(teamId)
            batch.deleteDocument(teamRef)
            
            // Remove team from all members' teamIds
            for memberId in team.memberIds {
                let userRef = db.collection("users").document(memberId)
                batch.updateData([
                    "teamIds": FieldValue.arrayRemove([teamId])
                ], forDocument: userRef)
            }
            
            // Delete all team tasks
            let tasksSnapshot = try await db.collection("tasks")
                .whereField("teamId", isEqualTo: teamId)
                .getDocuments()
            
            for doc in tasksSnapshot.documents {
                batch.deleteDocument(doc.reference)
            }
            
            // Commit the batch
            try await batch.commit()
            
        } catch {
            errorMessage = "Failed to remove team: \(error.localizedDescription)"
            showError = true
        }
    }
} 