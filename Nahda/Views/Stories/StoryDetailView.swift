import SwiftUI

struct StoryDetailView: View {
    let story: Story
    let stories: [Story]  // All stories
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userViewModel = UserViewModel()
    @State private var timer: Timer?
    @State private var progress: CGFloat = 0
    
    init(story: Story, stories: [Story]) {
        self.story = story
        self.stories = stories
        self._currentIndex = State(initialValue: stories.firstIndex(where: { $0.id == story.id }) ?? 0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Story Content
                if currentIndex < stories.count {
                    VStack {
                        // Progress bars
                        HStack(spacing: 4) {
                            ForEach(Array(stories.enumerated()), id: \.element.id) { index, _ in
                                ProgressBar(
                                    progress: index == currentIndex ? progress : (index < currentIndex ? 1 : 0)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // User info header
                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(userViewModel.userName(for: stories[currentIndex].userId).prefix(1))
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text(userViewModel.userName(for: stories[currentIndex].userId))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(stories[currentIndex].timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
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
                        
                        // Story Image
                        Spacer()
                        AsyncImage(url: URL(string: stories[currentIndex].imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    
                    // Navigation overlay
                    HStack {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if currentIndex > 0 {
                                    currentIndex -= 1
                                    resetProgress()
                                }
                            }
                        
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if currentIndex < stories.count - 1 {
                                    currentIndex += 1
                                    resetProgress()
                                } else {
                                    dismiss()
                                }
                            }
                    }
                }
            }
            .onAppear {
                startTimer()
                userViewModel.fetchUser(userId: stories[currentIndex].userId)
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation {
                progress += 0.01
                if progress >= 1.0 {
                    if currentIndex < stories.count - 1 {
                        currentIndex += 1
                        resetProgress()
                    } else {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetProgress() {
        progress = 0
        startTimer()
    }
}

struct ProgressBar: View {
    let progress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: geometry.size.width, height: 2)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * progress, height: 2)
            }
        }
        .frame(height: 2)
    }
} 