//
//  ContentView.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// ContentView.swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var teamViewModel = TeamViewModel()
    @State private var showIntro = true
    
    var body: some View {
        ZStack {
            if showIntro {
                IntroAnimationView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation {
                                showIntro = false
                            }
                        }
                    }
            } else {
                if let user = authViewModel.currentUser {
                    if user.teamIds?.isEmpty == false {
                        DashboardView()
                            .environmentObject(authViewModel)
                            .environmentObject(teamViewModel)
                    } else {
                        NoTeamView()
                            .environmentObject(authViewModel)
                            .environmentObject(teamViewModel)
                    }
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}

//struct NoTeamView: View {
//    var body: some View {
//        VStack(spacing: 20) {
//            Image(systemName: "person.3.sequence")
//                .font(.system(size: 50))
//                .foregroundColor(.gray)
//            
//            Text("No Team Found")
//                .font(.title2)
//                .bold()
//            
//            Text("Join or create a team to get started")
//                .foregroundColor(.secondary)
//            
//            NavigationLink(destination: CreateTeamView()) {
//                Text("Create Team")
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.blue)
//                    .cornerRadius(10)
//            }
//            .padding(.horizontal)
//        }
//        .padding()
//    }
//}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
