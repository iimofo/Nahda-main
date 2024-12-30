//struct StoryDetailView: View {
//    let story: Story
//    let team: Team
//    @Environment(\.dismiss) private var dismiss
//    @State private var showDeleteAlert = false
//    @State private var isDeleting = false
//    @State private var errorMessage: String?
//    @State private var showError = false
//    
//    private let storage = Storage.storage()
//    private let db = Firestore.firestore()
//    
//    var body: some View {
//        VStack {
//            // ... existing story content ...
//            
//            if team.leaderId == AuthViewModel.shared.currentUser?.id {
//                Button(role: .destructive, action: {
//                    showDeleteAlert = true
//                }) {
//                    Label("Delete Story", systemImage: "trash")
//                        .frame(minWidth: 44, minHeight: 44)  // Apple's minimum touch target size
//                }
//                .padding()
//                .disabled(isDeleting)
//            }
//        }
//        .alert("Delete Story", isPresented: $showDeleteAlert) {
//            Button("Cancel", role: .cancel) { }
//            Button("Delete", role: .destructive) {
//                Task {
//                    await deleteStory()
//                }
//            }
//        } message: {
//            Text("Are you sure you want to delete this story? This action cannot be undone.")
//        }
//        .alert("Error", isPresented: $showError) {
//            Button("OK", role: .cancel) { }
//        } message: {
//            Text(errorMessage ?? "An unknown error occurred")
//        }
//    }
//    
//    private func deleteStory() async {
//        isDeleting = true
//        
//        do {
//            // 1. Delete image from Storage if it exists
//            if let imageUrl = story.imageUrl {
//                let storageRef = storage.reference(forURL: imageUrl)
//                try await storageRef.delete()
//            }
//            
//            // 2. Delete story document from Firestore
//            guard let storyId = story.id else {
//                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid story ID"])
//            }
//            
//            try await db.collection("teams")
//                .document(team.id ?? "")
//                .collection("stories")
//                .document(storyId)
//                .delete()
//            
//            // 3. Dismiss the view after successful deletion
//            DispatchQueue.main.async {
//                dismiss()
//            }
//            
//        } catch {
//            DispatchQueue.main.async {
//                errorMessage = "Failed to delete story: \(error.localizedDescription)"
//                showError = true
//                isDeleting = false
//            }
//        }
//    }
//} 
