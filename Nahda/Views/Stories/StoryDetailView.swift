import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct StoryDetailView: View {
    let story: Story
    let stories: [Story]
    let team: Team
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userViewModel = UserViewModel()
    @State private var timer: Timer?
    @State private var progress: CGFloat = 0
    @State private var isPaused: Bool = false
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isLongPressed = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @StateObject private var storyViewModel = StoryViewModel()
    
    // Constants for better customization
    private let storyDuration: TimeInterval = 5.0
    private let progressUpdateInterval: TimeInterval = 0.05
    private let dragThreshold: CGFloat = 50
    
    // Add Firebase references
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    init(story: Story, stories: [Story], team: Team) {
        self.story = story
        self.stories = stories
        self.team = team
        self._currentIndex = State(initialValue: stories.firstIndex(where: { $0.id == story.id }) ?? 0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
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
                        onClose: { 
                            print("🚪 Close action triggered")
                            dismiss() 
                        },
                        onDelete: { },
                        isTeamLeader: isTeamLeader,
                        showDeleteAlert: $showDeleteAlert
                    )
                    .allowsHitTesting(true)
                    
                    // Story Content with overlay
                    ZStack(alignment: .bottomTrailing) {
                        // Story content
                        VStack {
                            Spacer()
                            StoryContent(imageUrl: stories[currentIndex].imageUrl, storyViewModel: StoryViewModel())
                            Spacer()
                        }
                        
                        // Delete button overlay
//                        if isTeamLeader {
//                            Button {
//                                print("🗑️ Delete button tapped")
//                                showDeleteAlert = true
//                            } label: {
//                                Image(systemName: "trash")
//                                    .foregroundColor(.red)
//                                    .font(.system(size: 22))
//                                    .frame(width: 44, height: 44)
//                                    .background(Color.black.opacity(0.6))
//                                    .clipShape(Circle())
//                            }
//                            .buttonStyle(BorderlessButtonStyle())
//                            .padding(.trailing, 20)
//                            .padding(.bottom, 40)
//                            .allowsHitTesting(true)
//                            .zIndex(1)
//                        }
                    }
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
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPaused {
                            pauseStory()
                        }
                    }
                    .onEnded { _ in
                        if isPaused {
                            resumeStory()
                        }
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
        .alert("Delete Story?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { 
                print("❌ Delete cancelled")
                showDeleteAlert = false
            }
            
            Button("Delete", role: .destructive) {
                print("✅ Delete confirmed")
                _Concurrency.Task {
                    guard let storyId = stories[currentIndex].id,
                          let teamId = team.id else {
                        print("❌ Missing IDs")
                        return
                    }
                    
                    do {
                        print("🗑️ Deleting story: \(storyId)")
                        
                        // Delete from Firestore
                        let storyRef = db.collection("teams")
                            .document(teamId)
                            .collection("stories")
                            .document(storyId)
                        try await storyRef.delete()
                        
                        // Delete image if exists
                        if !stories[currentIndex].imageUrl.isEmpty {
                            let storageRef = storage.reference(forURL: stories[currentIndex].imageUrl)
                            try await storageRef.delete()
                        }
                        
                        print("✅ Story deleted successfully")
                        dismiss()
                    } catch {
                        print("❌ Delete error: \(error.localizedDescription)")
                        showError = true
                        errorMessage = "Failed to delete story"
                    }
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
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
    
    private var isTeamLeader: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            print("❌ No current user ID")
            return false 
        }
        print("🔑 Current User ID: \(currentUserId)")
        print("👑 Team Leader ID: \(team.leaderId)")
        return currentUserId == team.leaderId
    }
}

// MARK: - Supporting Views
struct StoryHeader: View {
    let userName: String
    let timestamp: Date
    let onClose: () -> Void
    let onDelete: () -> Void
    let isTeamLeader: Bool
    @Binding var showDeleteAlert: Bool
    
    var body: some View {
        HStack {
            // User info
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
            
            Spacer()
            
            // Only close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.horizontal)
        }
        .padding()
    }
}

struct StoryContent: View {
    let imageUrl: String
    @ObservedObject var storyViewModel: StoryViewModel
    
    var body: some View {
        Group {
            if let cachedImage = storyViewModel.getCachedImage(for: imageUrl) {
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFit()
            } else {
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
