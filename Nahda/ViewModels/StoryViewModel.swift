import Foundation
import Firebase
import FirebaseStorage

class StoryViewModel: ObservableObject {
    @Published var stories: [Story] = []
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    func uploadStory(image: UIImage, teamId: String, userId: String, completion: @escaping (Bool) -> Void) {
        print("📸 Starting story upload process...")
        print("Team ID: \(teamId)")
        print("User ID: \(userId)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to convert image to data")
            completion(false)
            return
        }
        
        print("📦 Image converted to data: \(imageData.count) bytes")
        let storageRef = storage.reference().child("stories/\(UUID().uuidString).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ Storage error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            print("✅ Image uploaded to Storage successfully")
            print("📝 Getting download URL...")
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Download URL error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let downloadURL = url else {
                    print("❌ Download URL is nil")
                    completion(false)
                    return
                }
                
                print("✅ Got download URL: \(downloadURL.absoluteString)")
                
                let story = Story(
                    teamId: teamId,
                    userId: userId,
                    imageUrl: downloadURL.absoluteString,
                    timestamp: Date(),
                    expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
                )
                
                print("📝 Saving story to Firestore...")
                
                do {
                    try self.db.collection("stories").document().setData(from: story)
                    print("✅ Story saved to Firestore successfully")
                    completion(true)
                } catch {
                    print("❌ Firestore error: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
} 