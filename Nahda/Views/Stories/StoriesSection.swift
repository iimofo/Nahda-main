import SwiftUI

struct StoriesSection: View {
    let team: Team
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var storyViewModel = StoryViewModel()
    @State private var selectedUserStories: UserStories?
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
                        ForEach(Array(storyViewModel.storiesByUser.keys.sorted()), id: \.self) { userId in
                            if let userStories = storyViewModel.storiesByUser[userId] {
                                UserStoryPreview(
                                    userId: userId,
                                    stories: userStories
                                )
                                .onTapGesture {
                                    selectedUserStories = UserStories(
                                        userId: userId,
                                        stories: userStories
                                    )
                                }
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
        .sheet(item: $selectedUserStories) { userStories in
            StoryDetailView(
                story: userStories.stories[0],
                stories: userStories.stories,
                team: team
            )
            .environmentObject(authViewModel)
            .environmentObject(storyViewModel)
            .edgesIgnoringSafeArea(.all)
            .onDisappear {
                fetchStories()
            }
        }
    }
    
    private func fetchStories() {
        isLoading = true
        storyViewModel.fetchStories(for: team.id ?? "") { success in
            isLoading = false
        }
    }
}

struct UserStoryPreview: View {
    let userId: String
    let stories: [Story]
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        VStack {
            ZStack {
                // Story ring
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 64, height: 64)
                
                // User avatar or initial
                AsyncImage(url: URL(string: stories.first?.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(userViewModel.userName(for: userId).prefix(1))
                                .font(.title3)
                                .bold()
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                // Story count indicator if more than one
                if stories.count > 1 {
                    Text("\(stories.count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .offset(x: 20, y: -20)
                }
            }
            
            Text(userViewModel.userName(for: userId))
                .font(.caption)
                .lineLimit(1)
        }
        .task {
            userViewModel.fetchUser(userId: userId)
        }
    }
} 