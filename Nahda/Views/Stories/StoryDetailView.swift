import SwiftUI

struct StoryDetailView: View {
    let story: Story
    let stories: [Story]
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userViewModel = UserViewModel()
    @State private var timer: Timer?
    @State private var progress: CGFloat = 0
    @State private var isPaused: Bool = false
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isLongPressed = false
    
    // Constants for better customization
    private let storyDuration: TimeInterval = 5.0
    private let progressUpdateInterval: TimeInterval = 0.05
    private let dragThreshold: CGFloat = 50
    
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
                    VStack(spacing: 0) {
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
                        StoryHeader(
                            userName: userViewModel.userName(for: stories[currentIndex].userId),
                            timestamp: stories[currentIndex].timestamp,
                            onClose: { dismiss() }
                        )
                        
                        // Story Image
                        Spacer()
                        StoryContent(imageUrl: stories[currentIndex].imageUrl)
                        Spacer()
                    }
                    
                    // Navigation overlay
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: geometry.size.width * 0.3)
                            .onTapGesture {
                                navigateToPrevious()
                            }
                        
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: geometry.size.width * 0.4)
                        
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: geometry.size.width * 0.3)
                            .onTapGesture {
                                navigateToNext()
                            }
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        // Pause when touch starts
                        if !isPaused {
                            pauseStory()
                        }
                    }
                    .onEnded { _ in
                        // Resume when touch ends
                        if isPaused {
                            resumeStory()
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        handleDragGesture(value)
                    }
            )
        }
        .onAppear {
            startTimer()
            userViewModel.fetchUser(userId: stories[currentIndex].userId)
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func handleDragGesture(_ value: DragGesture.Value) {
        let dragDistance = value.translation.width
        if abs(dragDistance) > dragThreshold {
            if dragDistance > 0 {
                navigateToPrevious()
            } else {
                navigateToNext()
            }
        }
        dragOffset = 0
    }
    
    private func navigateToPrevious() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentIndex > 0 {
                currentIndex -= 1
                resetProgress()
            }
        }
    }
    
    private func navigateToNext() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentIndex < stories.count - 1 {
                currentIndex += 1
                resetProgress()
            } else {
                dismiss()
            }
        }
    }
    
    private func pauseStory() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    private func resumeStory() {
        isPaused = false
        startTimer()
    }
    
    private func startTimer() {
        guard !isPaused else { return }
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: progressUpdateInterval, repeats: true) { [self] _ in
            guard !isPaused else { return }
            
            withAnimation(.linear(duration: progressUpdateInterval)) {
                progress += progressUpdateInterval / storyDuration
                if progress >= 1.0 {
                    navigateToNext()
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

// MARK: - Supporting Views
struct StoryHeader: View {
    let userName: String
    let timestamp: Date
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(userName.prefix(1))
                            .font(.caption)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading) {
                    Text(userName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
}

struct StoryContent: View {
    let imageUrl: String
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl)) { image in
            image
                .resizable()
                .scaledToFit()
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
        } placeholder: {
            ProgressView()
                .foregroundColor(.white)
        }
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
//} 
