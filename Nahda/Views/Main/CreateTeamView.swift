//
//  CreateTeamView.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// CreateTeamView.swift
// CreateTeamView.swift
import SwiftUI

struct CreateTeamView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var teamViewModel: TeamViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var teamName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Team Info")) {
                    TextField("Team Name", text: $teamName)
                }
                
                Section {
                    Button(action: createTeam) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Create Team")
                        }
                    }
                    .disabled(teamName.isEmpty || isLoading)
                }
            }
            .navigationTitle("Create Team")
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
    
    private func createTeam() {
        guard let userId = authViewModel.currentUser?.id else { return }
        isLoading = true
        
        teamViewModel.createTeam(name: teamName, leaderId: userId) { success, error in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Failed to create team"
                showError = true
            }
        }
    }
}
