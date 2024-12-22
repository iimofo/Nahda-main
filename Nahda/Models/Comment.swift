//
//  Comment.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// Comment.swift

import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var content: String
    var timestamp: Date
    var mentions: [Mention]?
    
    struct Mention: Codable {
        let userId: String
        let startIndex: Int
        let endIndex: Int
        
        func getRange(in content: String) -> Range<String.Index>? {
            guard let start = content.index(content.startIndex, offsetBy: startIndex, limitedBy: content.endIndex),
                  let end = content.index(content.startIndex, offsetBy: endIndex, limitedBy: content.endIndex) else {
                return nil
            }
            return start..<end
        }
        
        init(userId: String, range: Range<String.Index>, in text: String) {
            self.userId = userId
            self.startIndex = text.distance(from: text.startIndex, to: range.lowerBound)
            self.endIndex = text.distance(from: text.startIndex, to: range.upperBound)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            userId = try container.decode(String.self, forKey: .userId)
            startIndex = try container.decode(Int.self, forKey: .startIndex)
            endIndex = try container.decode(Int.self, forKey: .endIndex)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(userId, forKey: .userId)
            try container.encode(startIndex, forKey: .startIndex)
            try container.encode(endIndex, forKey: .endIndex)
        }
        
        private enum CodingKeys: String, CodingKey {
            case userId
            case startIndex
            case endIndex
        }
    }
    
    func getMentionRanges() -> [(userId: String, range: Range<String.Index>)] {
        return mentions?.compactMap { mention in
            if let range = mention.getRange(in: content) {
                return (userId: mention.userId, range: range)
            }
            return nil
        } ?? []
    }
}

// Add MentionHelper to handle @mentions
class MentionHelper {
    static func extractMentions(from text: String, teamMembers: [User]) -> [Comment.Mention] {
        var mentions: [Comment.Mention] = []
        let words = text.split(separator: " ")
        
        for word in words {
            if word.hasPrefix("@") {
                let username = String(word.dropFirst())
                if let user = teamMembers.first(where: { $0.name.lowercased() == username.lowercased() }) {
                    if let range = text.range(of: word) {
                        mentions.append(Comment.Mention(userId: user.id ?? "", range: range, in: text))
                    }
                }
            }
        }
        
        return mentions
    }
}
