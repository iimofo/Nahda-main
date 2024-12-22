import SwiftUI
import FirebaseFirestore
import FirebaseDatabase

class UserViewModel: ObservableObject {
    @Published private(set) var users: [String: User] = [:]
    @Published private(set) var userActivities: [String: [UserActivity]] = [:]
    private var listeners: [String: ListenerRegistration] = [:]
    
    func userName(for userId: String) -> String {
        return users[userId]?.name ?? "Loading..."
    }
    
    func fetchUser(userId: String) {
        // Check if we already have this user
        if users[userId] != nil { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error fetching user: \(error.localizedDescription)")
                return
            }
            
            if let user = try? snapshot?.data(as: User.self) {
                DispatchQueue.main.async {
                    self?.users[userId] = user
                }
            }
        }
    }
    
    func fetchUsers(userIds: [String]) {
        for userId in userIds {
            fetchUser(userId: userId)
        }
    }
    
    func getActivities(for userId: String) -> [UserActivity] {
        return userActivities[userId] ?? []
    }
    
    func startListeningToActivity(for userId: String) {
        // Remove existing listener if any
        listeners[userId]?.remove()
        
        let db = Firestore.firestore()
        let listener = db.collection("users")
            .document(userId)
            .collection("activities")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error listening to activities: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No activities found")
                    return
                }
                
                let activities = documents.compactMap { document -> UserActivity? in
                    try? document.data(as: UserActivity.self)
                }
                
                DispatchQueue.main.async {
                    self?.userActivities[userId] = activities
                }
            }
        
        listeners[userId] = listener
    }
    
    func stopListeningToActivity(for userId: String) {
        listeners[userId]?.remove()
        listeners[userId] = nil
    }
    
    deinit {
        // Clean up all listeners
        listeners.values.forEach { $0.remove() }
    }
} 
