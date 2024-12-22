import Foundation
import Firebase
import FirebaseStorage

class StoryViewModel: ObservableObject {
    @Published private(set) var stories: [Story] = []
    @Published private(set) var storiesByUser: [String: [Story]] = [:]
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private let cache = NSCache<NSString, UIImage>()
    
    // Constants for optimization
    private let maxImageSize: CGFloat = 1080 // Max dimension for images
    private let compressionQuality: CGFloat = 0.6 // Balance between quality and size
    private let cacheLimit = 50 // Maximum number of stories to cache
    
    init() {
        cache.countLimit = cacheLimit
    }
    
    func uploadStory(image: UIImage, teamId: String, userId: String, completion: @escaping (Bool) -> Void) {
        print("📸 Starting story upload process...")
        
        // Optimize image before upload
        guard let optimizedImage = optimizeImage(image),
              let imageData = optimizedImage.jpegData(compressionQuality: compressionQuality) else {
            print("❌ Failed to optimize image")
            completion(false)
            return
        }
        
        print("📦 Optimized image size: \(imageData.count / 1024)KB")
        let storageRef = storage.reference().child("stories/\(UUID().uuidString).jpg")
        
        // Add metadata for caching
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public, max-age=31536000" // Cache for 1 year
        
        storageRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
            if let error = error {
                print("❌ Storage error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("❌ Download URL is nil")
                    completion(false)
                    return
                }
                
                let story = Story(
                    teamId: teamId,
                    userId: userId,
                    imageUrl: downloadURL.absoluteString,
                    timestamp: Date(),
                    expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
                )
                
                // Cache the optimized image
                self?.cache.setObject(optimizedImage, forKey: downloadURL.absoluteString as NSString)
                
                do {
                    try self?.db.collection("stories").document().setData(from: story)
                    print("✅ Story saved successfully")
                    completion(true)
                } catch {
                    print("❌ Firestore error: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    func fetchStories(for teamId: String, completion: @escaping (Bool) -> Void) {
        print("📱 Fetching stories for team: \(teamId)")
        
        let now = Date()
        // Create a query that listens for real-time updates
        let query = db.collection("stories")
            .whereField("teamId", isEqualTo: teamId)
            .whereField("expiresAt", isGreaterThan: now)
            .order(by: "expiresAt", descending: false)
            .limit(to: 100) // Limit for performance
        
        // Use a snapshot listener for real-time updates
        query.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error fetching stories: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("❌ No documents found")
                completion(false)
                return
            }
            
            let stories = documents.compactMap { document -> Story? in
                try? document.data(as: Story.self)
            }
            
            DispatchQueue.main.async {
                self?.stories = stories
                self?.groupStoriesByUser()
                completion(true)
            }
        }
    }
    
    // Helper method to optimize images
    private func optimizeImage(_ image: UIImage) -> UIImage? {
        let size = image.size
        let scale: CGFloat
        
        if size.width > size.height {
            scale = maxImageSize / size.width
        } else {
            scale = maxImageSize / size.height
        }
        
        // Only resize if image is larger than maxImageSize
        if scale < 1 {
            let newSize = CGSize(
                width: size.width * scale,
                height: size.height * scale
            )
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let optimizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return optimizedImage
        }
        
        return image
    }
    
    // Get cached image if available
    func getCachedImage(for url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
    
    private func groupStoriesByUser() {
        let grouped = Dictionary(grouping: stories) { $0.userId }
        DispatchQueue.main.async {
            self.storiesByUser = grouped
        }
    }
} 