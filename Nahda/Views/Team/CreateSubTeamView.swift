import SwiftUI

struct CreateSubTeamView: View {
    let parentTeam: Team
    @StateObject private var teamViewModel = TeamViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var teamName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subteam Details")) {
                    TextField("Team Name", text: $teamName)
                }
                
                Section {
                    Button(action: createSubTeam) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Create Subteam")
                        }
                    }
                    .disabled(teamName.isEmpty || isLoading)
                }
            }
            .navigationTitle("Create Subteam")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createSubTeam() {
        guard let userId = authViewModel.currentUser?.id else { return }
        isLoading = true
        
        teamViewModel.createSubTeam(
            name: teamName,
            parentTeamId: parentTeam.id ?? "",
            leaderId: userId
        ) { success in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = "Failed to create subteam"
                showError = true
            }
        }
    }
} 
