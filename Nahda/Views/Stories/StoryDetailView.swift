import SwiftUI

struct StoryDetailView: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        ZStack {
            // Story Image
            AsyncImage(url: URL(string: story.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
            
            // Close button
            VStack {
                HStack {
                    // User info
                    HStack {
                        Text(userViewModel.userName(for: story.userId))
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(story.timestamp, style: .relative)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .task {
            userViewModel.fetchUser(userId: story.userId)
        }
    }
} 