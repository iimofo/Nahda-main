import SwiftUI

struct StoriesSection: View {
    let team: Team
    @StateObject private var storyViewModel = StoryViewModel()
    @State private var selectedStory: Story?
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Loading stories...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(storyViewModel.stories) { story in
                            StoryPreviewView(story: story)
                                .onTapGesture {
                                    selectedStory = story
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
            }
        }
        .onAppear {
            fetchStories()
        }
        .sheet(item: $selectedStory) { story in
            StoryDetailView(story: story)
        }
    }
    
    private func fetchStories() {
        isLoading = true
        storyViewModel.fetchStories(for: team.id ?? "") { success in
            isLoading = false
        }
    }
}

struct StoryPreviewView: View {
    let story: Story
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: story.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
            )
            
            Text(userViewModel.userName(for: story.userId))
                .font(.caption)
                .lineLimit(1)
        }
        .task {
            userViewModel.fetchUser(userId: story.userId)
        }
    }
} 