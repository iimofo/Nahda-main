import SwiftUI
import FirebaseFirestore
import FirebaseDatabase

class UserViewModel: ObservableObject {
    @Published var users: [String: User] = [:]
    private var db = Firestore.firestore()
    private var presenceRef: DatabaseReference?
    private var activityListeners: [String: ListenerRegistration] = [:]
    
    // MARK: - Presence Tracking
    func setupPresenceTracking(for userId: String) {
        let userRef = db.collection("users").document(userId)
        let presenceRef = Database.database().reference().child("presence").child(userId)
        self.presenceRef = presenceRef
        
        // Configure presence monitoring
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value) { [weak self] snapshot, _ in
            guard let self = self,
                  let isConnected = snapshot.value as? Bool,
                  isConnected else {
                self?.updateUserStatus(userId: userId, status: .offline)
                return
            }
            
            // User is connected, update presence
            let presence: [String: Any] = [
                "status": User.UserStatus.online.rawValue,
                "lastActive": ServerValue.timestamp()
            ]
            
            // Set the presence data and handle disconnection
            presenceRef.onDisconnectUpdateChildValues([
                "status": User.UserStatus.offline.rawValue,
                "lastActive": ServerValue.timestamp()
            ])
            
            presenceRef.setValue(presence) { error, _ in
                if let error = error {
                    print("Error updating presence: \(error)")
                }
            }
        }
        
        // Update Firestore user document
        userRef.updateData([
            "status": User.UserStatus.online.rawValue,
            "lastActive": FieldValue.serverTimestamp()
        ])
    }
    
    func updateUserStatus(userId: String, status: User.UserStatus) {
        let userRef = db.collection("users").document(userId)
        let presenceRef = Database.database().reference().child("presence").child(userId)
        
        // Update Realtime Database presence
        let presenceData: [String: Any] = [
            "status": status.rawValue,
            "lastActive": ServerValue.timestamp()
        ]
        presenceRef.updateChildValues(presenceData)
        
        // Update Firestore user document
        userRef.updateData([
            "status": status.rawValue,
            "lastActive": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating status: \(error)")
            }
        }
    }
    
    // MARK: - Activity History
    func logActivity(userId: String, type: UserActivity.ActivityType, details: String, teamId: String? = nil, taskId: String? = nil) {
        let activity = UserActivity(
            id: UUID().uuidString,
            type: type,
            timestamp: Date(),
            details: details,
            teamId: teamId,
            taskId: taskId
        )
        
        let userRef = db.collection("users").document(userId)
        userRef.updateData([
            "activityHistory": FieldValue.arrayUnion([try! Firestore.Encoder().encode(activity)])
        ]) { error in
            if let error = error {
                print("Error logging activity: \(error)")
            }
        }
    }
    
    func startListeningToActivity(for userId: String) {
        guard activityListeners[userId] == nil else { return }
        
        let listener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data(),
                      let user = try? Firestore.Decoder().decode(User.self, from: data)
                else { return }
                
                DispatchQueue.main.async {
                    self.users[userId] = user
                }
            }
        
        activityListeners[userId] = listener
    }
    
    func stopListeningToActivity(for userId: String) {
        activityListeners[userId]?.remove()
        activityListeners[userId] = nil
    }
    
    // MARK: - Cleanup
    func cleanup() {
        // Remove the onDisconnect operations
        presenceRef?.removeValue()
        // Remove all listeners
        activityListeners.values.forEach { $0.remove() }
        activityListeners.removeAll()
        clearCache()
    }
    
    func fetchUsers(userIds: [String]) {
        for userId in userIds {
            // Skip if we already have this user's data
            guard users[userId] == nil else { continue }
            
            db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching user: \(error)")
                    return
                }
                
                if let user = try? snapshot?.data(as: User.self) {
                    DispatchQueue.main.async {
                        self?.users[userId] = user
                    }
                }
            }
        }
    }
    
    func userName(for userId: String) -> String {
        users[userId]?.name ?? "Loading..."
    }
    
    func userEmail(for userId: String) -> String {
        users[userId]?.email ?? "Loading..."
    }
    
    func user(for userId: String) -> User? {
        users[userId]
    }
    
    func clearCache() {
        users.removeAll()
    }
} 
