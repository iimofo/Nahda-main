import Foundation
import FirebaseFirestore

struct Story: Identifiable, Codable {
    @DocumentID var id: String?
    let teamId: String
    let userId: String
    let imageUrl: String
    let timestamp: Date
    let expiresAt: Date // 24 hours from creation
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId
        case userId
        case imageUrl
        case timestamp
        case expiresAt
    }
} 
