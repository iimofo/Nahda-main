import SwiftUI

struct AddStoryButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Text("Add Story")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct StoryAvatarView: View {
    let member: User
    @State private var hasActiveStory = false // We'll implement this later
    
    var body: some View {
        Button(action: {
            // We'll implement story viewing later
        }) {
            VStack {
                ZStack {
                    Circle()
                        .stroke(hasActiveStory ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(member.name.prefix(1).uppercased())
                                .font(.title3)
                                .bold()
                        )
                }
                
                Text(member.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
        }
    }
} 