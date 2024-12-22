import SwiftUI

struct NoTeamView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var teamViewModel: TeamViewModel
    @State private var showCreateTeam = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Team Found")
                .font(.title2)
                .bold()
            
            Text("Join or create a team to get started")
                .foregroundColor(.secondary)
            
            Button {
                showCreateTeam = true
            } label: {
                Text("Create Team")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .sheet(isPresented: $showCreateTeam) {
            CreateTeamView()
                .environmentObject(authViewModel)
                .environmentObject(teamViewModel)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
} 
